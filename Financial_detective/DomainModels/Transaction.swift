import Foundation

struct Transaction: Identifiable, Codable {
    let id: Int
    var account: BankAccount
    var category: Category
    var amount: Decimal
    var transactionDate: Date
    var comment: String?
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, account, category, amount, transactionDate, comment, createdAt, updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        // 1) Простой декодинг числовых и вложенных полей
        id       = try c.decode(Int.self,    forKey: .id)
        account  = try c.decode(BankAccount.self, forKey: .account)
        category = try c.decode(Category.self,    forKey: .category)

        // 2) Считать amount как строку и конвертить в Decimal
        let amountStr = try c.decode(String.self, forKey: .amount)
        guard let dec = Decimal(string: amountStr) else {
            throw DecodingError.dataCorruptedError(
                forKey: .amount,
                in: c,
                debugDescription: "Cannot convert \(amountStr) to Decimal"
            )
        }
        amount = dec

        // 3) Даты — сначала с дробями, потом без
        let txDateStr  = try c.decode(String.self, forKey: .transactionDate)
        let createdStr = try c.decode(String.self, forKey: .createdAt)
        let updatedStr = try c.decode(String.self, forKey: .updatedAt)

        let isoFrac = ISO8601DateFormatter.withFractionalSeconds
        let isoBase = ISO8601DateFormatter() // стандартный без дробей

        func parseDate(_ s: String, key: CodingKeys) throws -> Date {
            if let d = isoFrac.date(from: s) {
                return d
            }
            if let d = isoBase.date(from: s) {
                return d
            }
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: c,
                debugDescription: "Cannot parse date: \(s)"
            )
        }

        transactionDate = try parseDate(txDateStr,  key: .transactionDate)
        createdAt       = try parseDate(createdStr,   key: .createdAt)
        updatedAt       = try parseDate(updatedStr,   key: .updatedAt)

        comment = try c.decodeIfPresent(String.self, forKey: .comment)
    }
    
    init(
        id: Int,
        account: BankAccount,
        category: Category,
            amount: Decimal,
            transactionDate: Date,
            comment: String?,
            createdAt: Date,
            updatedAt: Date
        ) {
            self.id = id
            self.account = account
            self.category = category
            self.amount = amount
            self.transactionDate = transactionDate
            self.comment = comment
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,       forKey: .id)
        try c.encode(account,  forKey: .account)
        try c.encode(category, forKey: .category)
        // обратно в строку
        try c.encode(String(describing: amount), forKey: .amount)

        let iso = ISO8601DateFormatter.withFractionalSeconds
        try c.encode(iso.string(from: transactionDate), forKey: .transactionDate)
        try c.encode(iso.string(from: createdAt),       forKey: .createdAt)
        try c.encode(iso.string(from: updatedAt),       forKey: .updatedAt)
        try c.encodeIfPresent(comment,                  forKey: .comment)
    }
}

