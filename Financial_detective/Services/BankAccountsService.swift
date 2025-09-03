import Foundation

final class BankAccountsService {
    let client: NetworkClient
    private let accountId: Int
    private let local = SwiftDataAccountStore()   // SwiftData-only

    init(client: NetworkClient, accountId: Int = 83) {
        self.client = client
        self.accountId = accountId
    }

    func fetchAccount() async throws -> BankAccount {
        do {
            let acc: BankAccount = try await client.request(
                path: API.getAccount(id: accountId).path,
                method: API.getAccount(id: accountId).method
            )
            try? local.save(acc)
            return acc
        } catch {
            if let cached = (try? local.get()) ?? nil {
                return cached
            }
            throw error
        }
    }

    func updateAccount(id: Int, name: String, balance: String, currency: String) async throws -> BankAccount {
        let body = UpdateAccountRequest(name: name, balance: balance, currency: currency)
        let updated: BankAccount = try await client.request(
            path: API.updateAccount(id: id).path,
            method: API.updateAccount(id: id).method,
            body: body
        )
        try? local.save(updated)
        return updated
    }
}
