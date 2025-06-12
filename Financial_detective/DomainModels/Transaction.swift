import Foundation

struct Transaction {
    let id: Int
    var account: BankAccount
    var category: Category
    var amount: Decimal
    var transactionDate: Date
    var comment: String?
    var createdAt: Date
    var updatedAt: Date
}
