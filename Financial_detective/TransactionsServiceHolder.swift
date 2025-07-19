import Foundation
import Combine

final class TransactionsServiceHolder: ObservableObject {
    let service: TransactionsService
    let accountId: Int

    init(
        accountId: Int = 83,
        token: String
    ) {
        self.accountId = accountId

        do {
            // 1) Создаём клиент с реальным Bearer‑token
            let client = try NetworkClient(token: token)

            // 2) Открываем или создаём кеш-файл
            let cache = try TransactionsFileCache()

            // 3) Сразу инициализируем сервис с client + cache
            self.service = TransactionsService(client: client, cache: cache)
        } catch {
            // если что-то пошло не так — сразу понятный crash
            fatalError("TransactionsServiceHolder init failed: \(error)")
        }
    }
}

