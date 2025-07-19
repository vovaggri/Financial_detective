import Foundation

extension BankAccountsService {
    /// Получает список счетов и возвращает первый `id`
    func fetchFirstAccountId() async throws -> Int {
        // получаем массив счетов
        let accounts: [BankAccount] = try await client.request(
            path: API.listAccounts.path,
            method: API.listAccounts.method,
            body: Optional<EmptyBody>.none as EmptyBody?
        )
        guard let first = accounts.first else {
            throw NSError(domain: "BankAccountsService", code: 404, userInfo: [NSLocalizedDescriptionKey: "No accounts found"])
        }
        return first.id
    }
}

