import Foundation
import SwiftData

@Model
final class SDTransactionEntity {
    @Attribute(.unique) var id: Int
    var accountJSON: Data
    var categoryJSON: Data
    var amountString: String
    var transactionDate: Date
    var comment: String?
    var createdAt: Date
    var updatedAt: Date

    init(id: Int, accountJSON: Data, categoryJSON: Data, amountString: String,
         transactionDate: Date, comment: String?, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.accountJSON = accountJSON
        self.categoryJSON = categoryJSON
        self.amountString = amountString
        self.transactionDate = transactionDate
        self.comment = comment
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
