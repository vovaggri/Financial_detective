import Foundation

/// Тело POST /transactions для фильтрации
struct TransactionsFilterRequest: Encodable {
    let accountId: Int
    let from: String?   // ISO‑строка
    let to: String?
    
    init(accountId: Int, from: Date?, to: Date?) {
        let iso = ISO8601DateFormatter.withFractionalSeconds
        self.accountId = accountId
        self.from = from.map { iso.string(from: $0) }
        self.to   = to  .map { iso.string(from: $0) }
    }
}

