import Foundation

enum TransactionsFileCacheError: Error {
    case documentsDirectoryNotFound
    case invalidJSONStructure
}

final class TransactionsFileCache {
    private let fileURL: URL
    private let lockQueue = DispatchQueue(label: "ru.yourapp.transactionsCache")
    private var transactions: [Transaction] = []
    
    /// Текущий набор транзакций
    var allTransactions: [Transaction] {
        lockQueue.sync {
            Array(transactions)
        }
    }
    
    /// Конструирует cache на файл transactions.json в documents
    init(fileName: String = "transactions.json") throws {
        let fm = FileManager.default
        guard let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw TransactionsFileCacheError.documentsDirectoryNotFound
        }
        self.fileURL = docs.appendingPathComponent(fileName)
    }
    
    /// Загружает из диска, декодируя JSON в [Transaction]
    func load() throws {
        let fm = FileManager.default
        let decoded: [Transaction]
        if fm.fileExists(atPath: fileURL.path) {
            let data = try Data(contentsOf: fileURL)
            decoded = try JSONDecoder().decode([Transaction].self, from: data)
        } else {
            decoded = []
        }
        
        // убираем дубликаты
        var unique = [Int: Transaction]()
        for tx in decoded {
            unique[tx.id] = tx
        }
        let deduped = Array(unique.values)
        
        // записываем в кеш
        lockQueue.sync {
            transactions = deduped
        }
    }
    
    /// Сохраняет текущий массив в файл, кодируя через JSONEncoder
    func save() throws {
        // Забираем снимок и кодируем его внутри lockQueue
        let data = try lockQueue.sync { () -> Data in
            try JSONEncoder().encode(transactions)
        }
        try data.write(to: fileURL, options: .atomic)
    }
    
    /// Добавляет транзакцию, если её ещё нет
    func add(_ transaction: Transaction) {
        lockQueue.sync {
            guard !transactions.contains(where: { $0.id == transaction.id }) else { return }
            transactions.append(transaction)
        }
    }
    
    /// Удаляет по id
    func remove(id: Int) {
        lockQueue.sync {
            transactions.removeAll { $0.id == id }
        }
    }
    
    /// Полностью очищает кеш и перезаписывает пустой массив
    func reset() throws {
        try lockQueue.sync {
            transactions.removeAll()
            let data = try JSONEncoder().encode(transactions)
            try data.write(to: fileURL, options: .atomic)
        }
    }
}

