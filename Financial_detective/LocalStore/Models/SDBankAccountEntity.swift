import Foundation
import SwiftData

@Model
final class SDBankAccountEntity {
    @Attribute(.unique) var id: Int
    var name: String
    var balance: String
    var currency: String
    var createdAt: Date?
    var updatedAt: Date?

    init(id: Int, name: String, balance: String, currency: String, createdAt: Date?, updatedAt: Date?) {
        self.id = id; self.name = name; self.balance = balance; self.currency = currency
        self.createdAt = createdAt; self.updatedAt = updatedAt
    }
}

extension SDBankAccountEntity {
    convenience init(from a: BankAccount) {
        self.init(id: a.id, name: a.name, balance: a.balance, currency: a.currency,
                  createdAt: a.createdAt, updatedAt: a.updatedAt)
    }
    func toModel() -> BankAccount {
        BankAccount(id: id, name: name, balance: balance, currency: currency,
                    createdAt: createdAt, updatedAt: updatedAt)
    }
}
