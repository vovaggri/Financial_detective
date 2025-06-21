import Foundation

enum TransactionsFileCacheError: Error {
    case documentsDirectoryNotFound
    case invalidJSONStructure
}

final class TransactionsFileCache {
    private let fileURL: URL
    private var transactions: [Transaction] = []
    
    var allTransactions: [Transaction] {
        transactions
    }
    
    init(fileName: String = "transactions.json") throws {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        guard let docs = urls.first else {
            throw TransactionsFileCacheError.documentsDirectoryNotFound
        }
        self.fileURL = docs.appendingPathComponent(fileName)
    }
    
    func load() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            transactions = []
            return
        }
        
        let data = try Data(contentsOf: fileURL)
        let jsonAny = try JSONSerialization.jsonObject(with: data, options: [])
        
        guard let array = jsonAny as? [Any] else {
            throw TransactionsFileCacheError.invalidJSONStructure
        }
        
        var parsed = [Transaction]()
        for element in array {
            if let transaction = Transaction.parse(jsonObject: element) {
                parsed.append(transaction)
            }
        }
        
        var unique = [Int: Transaction]()
        for transaction in parsed {
            if unique[transaction.id] == nil {
                unique[transaction.id] = transaction
            }
        }
        transactions = Array(unique.values)
    }
    
    func save() throws {
        let jsonArray = transactions.map { $0.jsonObject }
        
        let data = try JSONSerialization.data(withJSONObject: jsonArray, options: [.prettyPrinted])
        try data.write(to: fileURL, options: [.atomic])
    }
    
    func add(_ transaction: Transaction) {
        guard !transactions.contains(where: { $0.id == transaction.id }) else {
            return
        }
        transactions.append(transaction)
    }
    
    func remove(id: Int) {
        transactions.removeAll { $0.id == id }
    }
    
    /// Полностью сбросить кеш на диск
    func reset() throws {
        // очистить память
        self.transactions.removeAll()
        // перезаписать файл нулевым массивом
        try save()
    }
}
