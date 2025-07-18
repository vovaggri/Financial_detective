import Foundation

final class BankAccountsService {
    private let client: NetworkClient
    private let accountId: Int
    
    init(client: NetworkClient, accountId: Int = 83) {
        self.client = client
        self.accountId = accountId
    }
    
    func fetchAccount() async throws -> BankAccount {
        try await client.request(path: API.getAccount(id: accountId).path,
                                 method: API.getAccount(id: accountId).method,
                                 body: Optional<EmptyBody>.none as EmptyBody?)
    }
    
    func updateAccount(_ updated: BankAccount) async throws -> BankAccount {
        try await client.request(path: API.updateAccount(id: accountId).path,
                                 method: API.updateAccount(id: accountId).method,
                                 body: updated)
    }
}

struct EmptyBody: Encodable {}
