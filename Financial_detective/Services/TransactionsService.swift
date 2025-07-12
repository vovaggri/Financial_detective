import Foundation

enum TransactionServiceError: Error {
    case notFound(id: Int)
}

final class TransactionsService {
    private let cache: TransactionsFileCache
    
    init(cache: TransactionsFileCache) throws {
        self.cache = cache
        try cache.load()
    }
    
    func fetchTransactions(accountId: Int, startDate: Date? = nil, endDate: Date? = nil) async throws -> [Transaction] {
        var list = cache.allTransactions.filter { $0.account.id == accountId }
        
        if let from = startDate {
            list = list.filter { $0.transactionDate >= from }
        }
        if let to = endDate {
            list = list.filter { $0.transactionDate <= to }
        }
        
        return list
    }
    
    func createTransaction(_ transaction: Transaction) async throws -> Transaction {
        let newId = (cache.allTransactions.map { $0.id }.max() ?? 0) + 1
        let now = Date()
        let newTransaction = Transaction(
            id: newId,
            account: transaction.account,
            category: transaction.category,
            amount: transaction.amount,
            transactionDate: transaction.transactionDate,
            comment: transaction.comment,
            createdAt: now,
            updatedAt: now
        )
        cache.add(newTransaction)
        try cache.save()
        return newTransaction
    }

    
    func updateTransaction(_ transaction: Transaction) async throws -> Transaction {
        guard let old = cache.allTransactions.first(where: { $0.id == transaction.id }) else {
            throw TransactionServiceError.notFound(id: transaction.id)
        }
        
        let now = Date()
        let updated = Transaction(id: old.id, account: transaction.account, category: transaction.category, amount: transaction.amount, transactionDate: transaction.transactionDate, createdAt: old.createdAt, updatedAt: now)
        
        cache.remove(id: transaction.id)
        cache.add(transaction)
        try cache.save()
        
        return updated
    }
    
    func deleteTransaction(id: Int) async throws {
        cache.remove(id: id)
        try cache.save()
    }
}
