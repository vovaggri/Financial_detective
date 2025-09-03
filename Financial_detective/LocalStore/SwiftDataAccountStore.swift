import Foundation
import SwiftData

@available(iOS 17, *)
final class SwiftDataAccountStore {
    private let container: ModelContainer
    init(inMemory: Bool = false) {
        let conf = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        self.container = try! ModelContainer(for: SDBankAccountEntity.self, configurations: conf)
    }

    func get() throws -> BankAccount? {
        let ctx = ModelContext(container)
        return try ctx.fetch(FetchDescriptor<SDBankAccountEntity>()).first?.toModel()
    }

    func save(_ account: BankAccount) throws {
        let ctx = ModelContext(container)
        if let row = try ctx.fetch(FetchDescriptor<SDBankAccountEntity>(
            predicate: #Predicate { $0.id == account.id }
        )).first {
            row.name = account.name
            row.balance = account.balance
            row.currency = account.currency
            row.createdAt = account.createdAt
            row.updatedAt = account.updatedAt
        } else {
            ctx.insert(SDBankAccountEntity(from: account))
        }
        try ctx.save()
    }
}
