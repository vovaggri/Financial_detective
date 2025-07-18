import Foundation

enum NetworkError: Error {
    case invalidURL
    case httpError(statusCode: Int, data: Data)
    case decodingError(Error)
    case encodingError(Error)
    case unknown(Error)
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
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let str = try container.decode(String.self)
                guard let date = ISO8601DateFormatter.withFractionalSeconds.date(from: str) else {
                    throw DecodingError.dataCorruptedError(in: container,
                        debugDescription: "Invalid date: \(str)")
                }
                return date
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
}
