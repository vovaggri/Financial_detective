import Foundation

final class BankAccountsService {
    private var account: BankAccount
    
    init() {
        let now = Date()
        account = BankAccount(id: 1, userId: 1, name: "Основной счет", balance: 1000.00, currency: "RUB", createdAt: now, updatedAt: now)
    }
    
    func fetchAccount() async throws -> BankAccount {
        return account
    }
    
    func updateAccount(_ updated: BankAccount) async throws -> BankAccount {
        let now = Date()
        account = BankAccount(id: updated.id, userId: updated.userId, name: updated.name, balance: updated.balance, currency: updated.currency, createdAt: updated.createdAt, updatedAt: now)
        return account
    }
}

