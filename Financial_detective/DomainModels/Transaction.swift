import Foundation

struct Transaction {
    let id: Int
    let accountId: Int
    let categoryId: Int
    var amount: Decimal
    var transactionAt: Date
    var comment: String
    var createdAt: Date
    var updatedAt: Date
}
