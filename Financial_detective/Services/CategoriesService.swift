final class CategoriesService {
    private let client: NetworkClient
    
    init(client: NetworkClient) {
        self.client = client
    }
    
    func categories(direction: Direction? = nil) async throws -> [Category] {
        try await client.request(
            path: API.listCategories(direction: direction).path,
            method: API.listCategories(direction: direction).method
        )
    }

}
