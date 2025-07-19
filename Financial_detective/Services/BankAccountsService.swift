import Foundation

final class BankAccountsService {
    let client: NetworkClient
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
    
    func updateAccount(id: Int, name: String, balance: String, currency: String) async throws -> BankAccount {
        let body = UpdateAccountRequest(name: name, balance: balance, currency: currency)
        return try await client.request(
            path: API.updateAccount(id: id).path,
            method: API.updateAccount(id: id).method,
            body: body
        )
    }
}



struct EmptyBody: Encodable {}
