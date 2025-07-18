import Foundation

struct BankAccount: Identifiable, Codable {
    let id: Int
    var name: String
    var balance: String
    var currency: String
    var createdAt: Date?
    var updatedAt: Date?

    private enum CodingKeys: String, CodingKey {
        case id, name, balance, currency, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id      = try c.decode(Int.self,    forKey: .id)
        name    = try c.decode(String.self, forKey: .name)
        balance = try c.decode(String.self, forKey: .balance)
        currency = try c.decode(String.self, forKey: .currency)

        // Пытаемся распарсить даты, если они есть
        let iso = ISO8601DateFormatter.withFractionalSeconds
        if let createdStr = try? c.decode(String.self, forKey: .createdAt) {
            createdAt = iso.date(from: createdStr)
        } else {
            createdAt = nil
        }
        if let updatedStr = try? c.decode(String.self, forKey: .updatedAt) {
            updatedAt = iso.date(from: updatedStr)
        } else {
            updatedAt = nil
        }
    }
    
    init(
        id: Int,
        name: String,
        balance: String,
        currency: String,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id         = id
        self.name       = name
        self.balance    = balance
        self.currency   = currency
        self.createdAt  = createdAt
        self.updatedAt  = updatedAt
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,       forKey: .id)
        try c.encode(name,     forKey: .name)
        try c.encode(balance,  forKey: .balance)
        try c.encode(currency, forKey: .currency)
        let iso = ISO8601DateFormatter.withFractionalSeconds
        if let d = createdAt {
            try c.encode(iso.string(from: d), forKey: .createdAt)
        }
        if let d = updatedAt {
            try c.encode(iso.string(from: d), forKey: .updatedAt)
        }
    }
}

