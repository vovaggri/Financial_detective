import Foundation

enum NetworkError: Error {
    case invalidURL
    case httpError(statusCode: Int, data: Data)
    case decodingError(Error)
    case encodingError(Error)
    case unknown(Error)
}

// type erasure для удобства
private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init<T: Encodable>(_ value: T) { _encode = value.encode }
    func encode(to encoder: Encoder) throws { try _encode(encoder) }
}

final class NetworkClient {
    let baseURL: URL
    let token: String
    let session: URLSession
    
    init(baseURLString: String = "https://shmr-finance.ru", token: String, session: URLSession = .shared) throws {
        guard let url = URL(string: baseURLString) else {
            throw NetworkError.invalidURL
        }
        self.baseURL = url
        self.token = token
        self.session = session
    }
    
    func request<Req: Encodable, Res: Decodable>(path: String, method: String = "GET", body: Req? = nil) async throws -> Res {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw NetworkError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        if method.uppercased() != "GET" {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        if let body = body {
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let encoded = try encoder.encode(body)
                if let jsonString = String(data: encoded, encoding: .utf8) {
                    print("📦 Encoded body JSON:\n\(jsonString)")
                }
                req.httpBody = encoded
            } catch {
                throw NetworkError.encodingError(error)
            }
        }
        
        let (data, response): (Data, URLResponse)
        print("➡️ Request: \(method) \(baseURL)\(path)")
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw NetworkError.unknown(error)
        }
        
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidURL
        }
        guard (200..<300).contains(http.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Нечитаемый ответ"
            print("""
            \n❌ HTTP Error \(http.statusCode)
            URL: \(req.url?.absoluteString ?? "")
            Headers: \(req.allHTTPHeaderFields ?? [:])
            Response: \(errorBody)
            """)
            throw NetworkError.httpError(statusCode: http.statusCode, data: data)
        }
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .useDefaultKeys
            decoder.dateDecodingStrategy = .custom { decoder in
                let c = try decoder.singleValueContainer()
                let s = try c.decode(String.self)

                // ISO8601 с миллисекундами
                if let d = NetworkClient.iso8601FS.date(from: s) { return d }
                // ISO8601 без миллисекунд
                if let d = NetworkClient.iso8601.date(from: s) { return d }
                // На всякий: дата без времени
                if let d = NetworkClient.yyyyMMdd.date(from: s) { return d }

                throw DecodingError.dataCorruptedError(in: c, debugDescription: "Invalid date: \(s)")
            }
            return try decoder.decode(Res.self, from: data)
            
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
    
    func request<Response: Decodable>(
        path: String,
        method: String
    ) async throws -> Response {
        // переиспользуем универсальную версию
        return try await request(path: path, method: method, body: Optional<Data>.none)
    }
    
    /// Вызывай для DELETE/PUT, где нет тела ответа (204/empty)
    func requestVoid(
        path: String,
        method: String,
        body: (any Encodable)? = nil
    ) async throws {
        guard let url = URL(string: path, relativeTo: baseURL) else { throw NetworkError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if method.uppercased() != "GET" {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let body {
            let encoded = try JSONEncoder().encode(AnyEncodable(body))
            req.httpBody = encoded
        }
        
        print("➡️ Request: \(method) \(baseURL)\(path)")
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidURL }
        guard (200..<300).contains(http.statusCode) else {
            throw NetworkError.httpError(statusCode: http.statusCode, data: data)
        }
        // ничего не декодируем
    }
}
