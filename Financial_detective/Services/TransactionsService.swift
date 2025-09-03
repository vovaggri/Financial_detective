import Foundation

struct EmptyResponse: Decodable {}

enum TransactionServiceError: Error {
    case notFound(id: Int)
}

final class TransactionsService {
    let client: NetworkClient
    private let cache: TransactionsFileCache

    // MARK: Backup storage (file-based, unique by id)
    private let backupURL: URL
    private let backupQueue = DispatchQueue(label: "ru.finapp.transactions.backup")
    private var backupItems: [Int: TransactionBackupItem] = [:]

    init(client: NetworkClient, cache: TransactionsFileCache) {
        self.client = client
        self.cache = cache

        // Prepare backup file location
        let fm = FileManager.default
        if let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first {
            self.backupURL = docs.appendingPathComponent("transactions_backup.json")
        } else {
            // fallback to tmp if Documents is not available
            self.backupURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("transactions_backup.json")
        }
        // Load existing backup into memory
        self._loadBackup()
    }

    // MARK: - Backup helpers

    private func _loadBackup() {
        backupQueue.sync {
            guard let data = try? Data(contentsOf: backupURL) else { return }
            if let list = try? JSONDecoder().decode([TransactionBackupItem].self, from: data) {
                self.backupItems = Dictionary(uniqueKeysWithValues: list.map { ($0.id, $0) })
            }
        }
    }

    private func _saveBackup() {
        backupQueue.sync {
            let list = Array(self.backupItems.values)
            if let data = try? JSONEncoder().encode(list) {
                try? data.write(to: backupURL, options: .atomic)
            }
        }
    }

    /// Return pending items sorted by updatedAt asc
    private func _pendingBackup() -> [TransactionBackupItem] {
        backupQueue.sync {
            Array(self.backupItems.values).sorted { $0.updatedAt < $1.updatedAt }
        }
    }

    /// Upsert with coalescing by id
    private func _upsertBackup(_ item: TransactionBackupItem) {
        backupQueue.sync {
            if var current = self.backupItems[item.id] {
                switch (current.action, item.action) {
                case (.create, .update):
                    current.payload = item.payload
                case (.create, .delete):
                    // create → delete => remove from backup
                    self.backupItems[item.id] = nil
                    self._saveBackup()
                    return
                case (.update, .update):
                    current.payload = item.payload
                case (.update, .delete):
                    current.action = .delete
                    current.payload = nil
                case (.delete, .create):
                    current.action = .create
                    current.payload = item.payload
                default:
                    current = item
                }
                current.updatedAt = item.updatedAt
                self.backupItems[item.id] = current
            } else {
                self.backupItems[item.id] = item
            }
            self._saveBackup()
        }
    }

    private func _removeBackup(ids: [Int]) {
        guard !ids.isEmpty else { return }
        backupQueue.sync {
            ids.forEach { self.backupItems[$0] = nil }
            self._saveBackup()
        }
    }

    /// Try to push backup to backend; updates local cache accordingly. Returns ids synced.
    private func _flushBackup() async -> [Int] {
        let items = _pendingBackup()
        guard !items.isEmpty else { return [] }
        var synced: [Int] = []

        for item in items {
            do {
                switch item.action {
                case .create:
                    guard let tx = item.payload else { continue }
                    // Try to create remotely
                    let created: Transaction = try await client.request(
                        path: API.createTransaction.path,
                        method: API.createTransaction.method,
                        body: CreateTransactionRequest(
                            accountId: tx.account.id,
                            categoryId: tx.category.id,
                            amount: tx.amount,
                            transactionDate: tx.transactionDate,
                            comment: tx.comment
                        )
                    )
                    // Replace temp in local cache if needed
                    if tx.id != created.id {
                        cache.remove(id: tx.id)
                    }
                    cache.add(created)
                    try? cache.save()
                    synced.append(item.id)

                case .update:
                    guard let tx = item.payload else { continue }
                    let updated: Transaction = try await client.request(
                        path: API.updateTransaction(id: tx.id).path,
                        method: API.updateTransaction(id: tx.id).method,
                        body: CreateTransactionRequest(
                            accountId: tx.account.id,
                            categoryId: tx.category.id,
                            amount: tx.amount,
                            transactionDate: tx.transactionDate,
                            comment: tx.comment
                        )
                    )
                    cache.remove(id: updated.id)
                    cache.add(updated)
                    try? cache.save()
                    synced.append(item.id)

                case .delete:
                    try await client.requestVoid(
                        path: API.deleteTransaction(id: item.id).path,
                        method: API.deleteTransaction(id: item.id).method
                    )
                    cache.remove(id: item.id)
                    try? cache.save()
                    synced.append(item.id)
                }
            } catch {
                // keep in backup; will try next time
            }
        }

        if !synced.isEmpty {
            _removeBackup(ids: synced)
        }
        return synced
    }
    
    func fetchTransactions(
        accountId: Int,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) async throws -> [Transaction] {
        // 1) Flush backup first (best effort)
        await _flushBackup()

        // 2) Build request path with query
        var path = "/api/v1/transactions/account/\(accountId)/period"
        let df = DateFormatter()
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "yyyy-MM-dd"

        var params = [String]()
        if let from = startDate { params.append("startDate=\(df.string(from: from))") }
        if let to   = endDate   { params.append("endDate=\(df.string(from: to))") }
        if !params.isEmpty { path += "?" + params.joined(separator: "&") }

        do {
            // 3) Network fetch
            let remote: [Transaction] = try await client.request(path: path, method: "GET")

            // 4) Save to cache
            try? cache.reset()
            remote.forEach(cache.add)
            try? cache.save()

            return remote
        } catch {
            // 5) Offline: merge cache + backup and filter by period
            let stored = cache.allTransactions
            let pending = _pendingBackup()

            var byId = Dictionary(uniqueKeysWithValues: stored.map { ($0.id, $0) })
            for item in pending {
                switch item.action {
                case .create, .update:
                    if let tx = item.payload { byId[tx.id] = tx }
                case .delete:
                    byId[item.id] = nil
                }
            }

            let merged = Array(byId.values).filter { tx in
                let d = tx.transactionDate
                if let s = startDate, d < s { return false }
                if let e = endDate,   d > e { return false }
                return true
            }
            return merged
        }
    }

    func createTransaction(
      accountId: Int,
      categoryId: Int,
      amount: Decimal,
      date: Date,
      comment: String?
    ) async throws -> Transaction {
      let body = CreateTransactionRequest(
          accountId: accountId,
          categoryId: categoryId,
          amount: amount,
          transactionDate: date,
          comment: comment
      )

      do {
          let created: Transaction = try await client.request(
              path: API.createTransaction.path,
              method: API.createTransaction.method,
              body: body
          )
          cache.add(created)
          try cache.save()
          // cleanup any stale backup for this id
          _removeBackup(ids: [created.id])
          return created
      } catch NetworkError.decodingError(let underlying) {
          // Treat as success: server likely created but returned unexpected body; refresh list
          let fresh = try await fetchTransactions(accountId: accountId)
          if let last = fresh.max(by: { $0.id < $1.id }) { return last }
          throw NetworkError.decodingError(underlying)
      } catch {
          // Offline: add to backup with temporary id and reflect in cache so UI shows item
          let tempId = makeTempTransactionId()
          let placeholderAccount = BankAccount(id: accountId, name: "—", balance: "0", currency: "", createdAt: nil, updatedAt: nil)
          let placeholderCategory = Category(id: categoryId, name: "—", emoji: "❓", direction: .outcome)

          let tx = Transaction(
              id: tempId,
              account: placeholderAccount,
              category: placeholderCategory,
              amount: amount,
              transactionDate: date,
              comment: comment,
              createdAt: Date(),
              updatedAt: Date()
          )

          _upsertBackup(TransactionBackupItem(id: tx.id, action: .create, payload: tx, updatedAt: Date()))
          cache.add(tx)
          try? cache.save()
          return tx
      }
    }
    
    func updateTransaction(_ tx: Transaction) async throws -> Transaction {
        let body = CreateTransactionRequest(
            accountId:    tx.account.id,
            categoryId:   tx.category.id,
            amount:       tx.amount,
            transactionDate: tx.transactionDate,
            comment:      tx.comment
        )

        do {
            let updated: Transaction = try await client.request(
                path: API.updateTransaction(id: tx.id).path,
                method: API.updateTransaction(id: tx.id).method,
                body: body
            )
            cache.remove(id: tx.id)
            cache.add(updated)
            try cache.save()
            _removeBackup(ids: [tx.id])
            return updated
        } catch {
            // offline: stage update and reflect it locally
            _upsertBackup(TransactionBackupItem(id: tx.id, action: .update, payload: tx, updatedAt: Date()))
            cache.remove(id: tx.id)
            cache.add(tx)
            try? cache.save()
            return tx
        }
    }

    func deleteTransaction(id: Int) async throws {
        do {
            try await client.requestVoid(path: API.deleteTransaction(id: id).path,
                                         method: API.deleteTransaction(id: id).method)
            cache.remove(id: id)
            try? cache.save()
            _removeBackup(ids: [id])
        } catch {
            _upsertBackup(TransactionBackupItem(id: id, action: .delete, payload: nil, updatedAt: Date()))
            cache.remove(id: id) // optimistic local delete
            try? cache.save()
        }
    }
    
    func fetchTransactionsPeriod(
        accountId: Int,
        startDate: Date,
        endDate: Date
    ) async throws -> [Transaction] {
        // Используем офлайн-способ с бэкапом и кешем
        try await fetchTransactions(
            accountId: accountId,
            startDate: startDate,
            endDate: endDate
        )
    }
}
