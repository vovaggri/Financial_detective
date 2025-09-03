import Foundation
import Combine

final class TransactionsServiceHolder: ObservableObject {
    let service: TransactionsService
    let client: NetworkClient
    let categoriesService: CategoriesService
    let bankAccountsService: BankAccountsService
    let accountId: Int

    init(accountId: Int = 83, token: String) {
        self.accountId = accountId
        do {
            let client = try NetworkClient(token: token)
            self.client = client

            let cache  = try TransactionsFileCache()
            self.service = TransactionsService(client: client, cache: cache)

            self.categoriesService   = CategoriesService(client: client)
            self.bankAccountsService = BankAccountsService(client: client, accountId: accountId)
        } catch {
            fatalError("TransactionsServiceHolder init failed: \(error)")
        }
    }
}

