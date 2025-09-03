import Foundation
import SwiftData

@Model
final class SDTransactionBackupEntity {
    @Attribute(.unique) var id: Int
    var actionRaw: String
    var payloadJSON: Data?
    var updatedAt: Date

    init(id: Int, actionRaw: String, payloadJSON: Data?, updatedAt: Date) {
        self.id = id
        self.actionRaw = actionRaw
        self.payloadJSON = payloadJSON
        self.updatedAt = updatedAt
    }
}
