import Foundation

struct EmptyResponse: Decodable {}

enum TransactionServiceError: Error {
    case notFound(id: Int)
}

final class TransactionsService {
    let client: NetworkClient
    private let cache: TransactionsFileCache

    init(client: NetworkClient, cache: TransactionsFileCache) {
        self.client = client
        self.cache = cache
    }
    
    func fetchTransactions(
        accountId: Int,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) async throws -> [Transaction] {
        // 1) Формируем базовый путь и query-параметры
        var path = "/api/v1/transactions/account/\(accountId)/period"
        let df = DateFormatter()
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "yyyy-MM-dd"
        
        var params = [String]()
        if let from = startDate {
            params.append("startDate=\(df.string(from: from))")
        }
        if let to = endDate {
            params.append("endDate=\(df.string(from: to))")
        }
        if !params.isEmpty {
            path += "?" + params.joined(separator: "&")
        }
        
        // 2) Вызываем универсальный request (GET без body)
        let remote: [Transaction] = try await client.request(
            path: path,
            method: "GET"
        )
        
        // 3) Сохраняем в кеш
        try? cache.reset()
        remote.forEach(cache.add)
        try? cache.save()
        
        return remote
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

      let created: Transaction = try await client.request(
        path: API.createTransaction.path,
        method: API.createTransaction.method,
        body: body
      )
      cache.add(created)
      try cache.save()
      return created
    }


    func updateTransaction(_ tx: Transaction) async throws -> Transaction {
        let updated: Transaction = try await client.request(
            path: API.updateTransaction(id: tx.id).path,
            method: API.updateTransaction(id: tx.id).method,
            body: tx
        )
        cache.remove(id: tx.id)
        cache.add(updated)
        try cache.save()
        return updated
    }

    func deleteTransaction(id: Int) async throws {
        do {
            let _: EmptyResponse = try await client.request(
                path: API.deleteTransaction(id: id).path,
                method: API.deleteTransaction(id: id).method,
                body: Optional<EmptyBody>.none as EmptyBody?
            )
        } catch let NetworkError.httpError(status, _) where status == 404 {
            throw TransactionServiceError.notFound(id: id)
        } catch {
            throw error
        }
        cache.remove(id: id)
        try cache.save()
    }
    
    func fetchTransactionsPeriod(
        accountId: Int,
        startDate: Date,
        endDate: Date
      ) async throws -> [Transaction] {
        // 1) Собираем query-параметры в строку YYYY-MM-DD
        let df = DateFormatter()
        df.timeZone   = TimeZone(secondsFromGMT: 0)   // UTC
        df.dateFormat = "yyyy-MM-dd"
        
        var path = "/api/v1/transactions/account/\(accountId)/period"
        let qs = [
          "startDate=\(df.string(from: startDate))",
          "endDate=\(df.string(from: endDate))"
        ].joined(separator: "&")
        path += "?\(qs)"
        
        // 2) Делаем запрос через client.request (c кешем внутри)
        return try await client.request(path: path, method: "GET", body: Optional<Data>.none)
      }
}

