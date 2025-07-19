import Foundation

// Если вдруг вам прилетел [String: Any] и вы хотите скормить его JSONDecoder’у:
extension Transaction {
    /// Создать Transaction из „сырых” JSON‑словарей
    static func from(jsonObject: Any) throws -> Transaction {
        // 1) Сконвертировать Any -> Data
        let data = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
        // 2) Раскодировать через Codable
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Transaction.self, from: data)
    }

    /// Превратить текущий объект в JSON‑словарь [String: Any]
    var asJSONObject: Any {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try! encoder.encode(self)
        return try! JSONSerialization.jsonObject(with: data, options: [])
    }
}

