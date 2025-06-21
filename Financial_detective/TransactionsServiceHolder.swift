import SwiftUI

final class TransactionsServiceHolder: ObservableObject {
    let service: TransactionsService
    let accountId = 1

    init() {
        let cache = try! TransactionsFileCache()

        try! cache.reset()

        let now = Date()
        
        let mockAccount = BankAccount(
            id: accountId,
            userId: accountId,
            name: "Основной счёт",
            balance: 1000.0,
            currency: "RUB",
            createdAt: now,
            updatedAt: now
        )

        let cat1 = Category(id: 1, name: "Кафе", emoji: "☕", direction: .outcome)
        let cat2 = Category(id: 2, name: "Обед", emoji: "🍔", direction: .outcome)
        let cat3 = Category(id: 3, name: "Зарплата", emoji: "💰", direction: .income)

        let txA = Transaction(
            id: 0,
            account: mockAccount,
            category: cat1,
            amount: 123.45,
            transactionDate: now,
            comment: "Эспрессо",
            createdAt: now,
            updatedAt: now
        )
        let txB = Transaction(
            id: 1,
            account: mockAccount,
            category: cat2,
            amount: 350,
            transactionDate: now.addingTimeInterval(-3600),
            comment: "Ланч",
            createdAt: now,
            updatedAt: now
        )
        let txC = Transaction(
            id: 2,
            account: mockAccount,
            category: cat3,
            amount: 500,
            transactionDate: now,
            createdAt: now, updatedAt: now
        )

        cache.add(txA)
        cache.add(txB)
        cache.add(txC)
        try! cache.save()

        self.service = try! TransactionsService(cache: cache)
    }
}
