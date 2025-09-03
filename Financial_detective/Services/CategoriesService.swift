final class CategoriesService {
    private let client: NetworkClient
    private let local = SwiftDataCategoriesStore()  // только SwiftData

    init(client: NetworkClient) { self.client = client }

    func categories(direction: Direction? = nil) async throws -> [Category] {
        do {
            let remote: [Category] = try await client.request(
                path: API.listCategories(direction: direction).path,
                method: API.listCategories(direction: direction).method
            )
            try await local.replace(for: direction, with: remote)
            return remote
        } catch {
            let cached = try await local.getAll()
            return cached.filter { direction == nil ? true : ($0.direction == direction!) }
        }
    }
}
