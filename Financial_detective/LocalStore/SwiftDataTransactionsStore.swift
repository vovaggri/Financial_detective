import Foundation
import SwiftData

@available(iOS 17, macOS 14, *)
actor SwiftDataTransactionsStore: TransactionsLocalStore {
    private let container: ModelContainer

    init(inMemory: Bool = false) {
        let conf = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        self.container = try! ModelContainer(for: SDTransactionEntity.self, configurations: conf)
    }

    func all() async throws -> [Transaction] {
        let ctx = ModelContext(container)
        let rows = try ctx.fetch(FetchDescriptor<SDTransactionEntity>())
        return try rows.map { try $0.toModel() }
    }

    func replaceAll(_ items: [Transaction]) async throws {
        let ctx = ModelContext(container)
        let existing = try ctx.fetch(FetchDescriptor<SDTransactionEntity>())
        existing.forEach { ctx.delete($0) }
        for tx in items {
            ctx.insert(try SDTransactionEntity(from: tx))
        }
        try ctx.save()
    }

    func upsert(_ tx: Transaction) async throws {
        let ctx = ModelContext(container)
        if let row = try ctx.fetch(FetchDescriptor<SDTransactionEntity>(
            predicate: #Predicate { $0.id == tx.id }
        )).first {
            let fresh = try SDTransactionEntity(from: tx)
            row.accountJSON = fresh.accountJSON
            row.categoryJSON = fresh.categoryJSON
            row.amountString = fresh.amountString
            row.transactionDate = fresh.transactionDate
            row.comment = fresh.comment
            row.createdAt = fresh.createdAt
            row.updatedAt = fresh.updatedAt
        } else {
            ctx.insert(try SDTransactionEntity(from: tx))
        }
        try ctx.save()
    }

    func delete(id: Int) async throws {
        let ctx = ModelContext(container)
        if let row = try ctx.fetch(FetchDescriptor<SDTransactionEntity>(
            predicate: #Predicate { $0.id == id }
        )).first {
            ctx.delete(row)
            try ctx.save()
        }
    }
}
