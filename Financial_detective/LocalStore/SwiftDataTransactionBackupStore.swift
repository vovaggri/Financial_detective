import Foundation
import SwiftData

@available(iOS 17, macOS 14, *)
actor SwiftDataTransactionBackupStore: TransactionsBackupStore {
    private let container: ModelContainer

    init(inMemory: Bool = false) {
        let conf = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        self.container = try! ModelContainer(for: SDTransactionBackupEntity.self, configurations: conf)
    }

    func pending() async throws -> [TransactionBackupItem] {
        let ctx = ModelContext(container)
        let rows = try ctx.fetch(FetchDescriptor<SDTransactionBackupEntity>())
        return try rows.map { try $0.toItem() }
            .sorted(by: { $0.updatedAt < $1.updatedAt })
    }

    func upsert(_ item: TransactionBackupItem) async throws {
        let ctx = ModelContext(container)
        if let row = try ctx.fetch(FetchDescriptor<SDTransactionBackupEntity>(
            predicate: #Predicate { $0.id == item.id }
        )).first {
            var current = try row.toItem()
            // Коалесцирование действий
            switch (current.action, item.action) {
            case (.create, .update):
                current.payload = item.payload
                current.updatedAt = item.updatedAt
            case (.create, .delete):
                ctx.delete(row)           // create → delete => ничего не надо
                try ctx.save()
                return
            case (.update, .update):
                current.payload = item.payload
                current.updatedAt = item.updatedAt
            case (.update, .delete):
                current.action = .delete
                current.payload = nil
                current.updatedAt = item.updatedAt
            case (.delete, .create):
                current.action = .create
                current.payload = item.payload
                current.updatedAt = item.updatedAt
            default:
                current = item
            }
            try row.apply(current)
        } else {
            let row = SDTransactionBackupEntity(
                id: item.id,
                actionRaw: item.action.rawValue,
                payloadJSON: try item.payload.map { try JSONEncoder().encode($0) },
                updatedAt: item.updatedAt
            )
            ctx.insert(row)
        }
        try ctx.save()
    }

    func remove(ids: [Int]) async throws {
        guard !ids.isEmpty else { return }
        let ctx = ModelContext(container)
        let rows = try ctx.fetch(FetchDescriptor<SDTransactionBackupEntity>(
            predicate: #Predicate { ids.contains($0.id) }
        ))
        rows.forEach { ctx.delete($0) }
        try ctx.save()
    }
}
