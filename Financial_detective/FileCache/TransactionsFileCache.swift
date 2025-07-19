import Foundation

enum TransactionsFileCacheError: Error {
    case documentsDirectoryNotFound
    case invalidJSONStructure
}

final class TransactionsFileCache {
    private let fileURL: URL
    private var transactions: [Transaction] = []
    
    /// Текущий набор транзакций
    var allTransactions: [Transaction] {
        transactions
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
        guard fm.fileExists(atPath: fileURL.path) else {
            // если файла нет — считаем, что кеш пуст
            transactions = []
            return
        }
        let data = try Data(contentsOf: fileURL)
        let decoded = try JSONDecoder().decode([Transaction].self, from: data)
        
        // Убираем дубликаты по id
        var unique = [Int: Transaction]()
        for tx in decoded {
            unique[tx.id] = tx
        }
        transactions = Array(unique.values)
    }
    
    /// Сохраняет текущий массив в файл, кодируя через JSONEncoder
    func save() throws {
        let data = try JSONEncoder().encode(transactions)
        try data.write(to: fileURL, options: Data.WritingOptions.atomic)
    }
    
    /// Добавляет транзакцию, если её ещё нет
    func add(_ transaction: Transaction) {
        guard !transactions.contains(where: { $0.id == transaction.id }) else {
            return
        }
        transactions.append(transaction)
    }
    
    /// Удаляет по id
    func remove(id: Int) {
        transactions.removeAll { $0.id == id }
    }
    
    /// Полностью очищает кеш и перезаписывает пустой массив
    func reset() throws {
        transactions.removeAll()
        try save()
    }
}

