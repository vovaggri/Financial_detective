import Foundation

enum TransactionFileCacheError: Error {
    case documentsDirectoryNotFound
}

final class TransactionFileCache {
    private let fileURL: URL
    private var transactions: [Transaction] = []
    
    var allTransactions: [Transaction] {
        transactions
    }
    
    init(fileName: String) throws {
        let fileManager = FileManager.default
        let urls = fileManager.
    }
}
