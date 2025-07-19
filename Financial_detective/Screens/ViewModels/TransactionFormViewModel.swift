import SwiftUI

@MainActor
final class TransactionFormViewModel: ObservableObject {
    @Published var errorMessage: String?
    
    // MARK: - Входные параметры
    private let existingTransaction: Transaction?
    let isEditing: Bool
    let direction: Direction
    let accountId: Int
    let transactionsService: TransactionsService
    let categoriesService: CategoriesService
    let bankAccountsService: BankAccountsService

    private var account: BankAccount?

    // MARK: - Публикуемые свойства
    @Published var categories: [Category] = []
    @Published var selectedCategoryId: Int = 0
    @Published var amountString: String = ""
    @Published var date: Date = Date()
    @Published var comment: String = ""

    init(
        transaction: Transaction?,
        direction: Direction,
        accountId: Int,
        transactionsService: TransactionsService,
        categoriesService: CategoriesService,
        bankAccountsService: BankAccountsService
    ) {
        self.existingTransaction = transaction
        self.isEditing = transaction != nil
        self.direction = direction
        self.accountId = accountId
        self.transactionsService = transactionsService
        self.categoriesService = categoriesService
        self.bankAccountsService = bankAccountsService

        if let tx = transaction {
            selectedCategoryId = tx.category.id
            amountString = tx.amount.description
            date = tx.transactionDate
            comment = tx.comment ?? ""
            account = tx.account
        } else {
            date = Date()
        }
    }

    /// Текущая категория
    var currentCategory: Category? {
        categories.first(where: { $0.id == selectedCategoryId })
    }

    /// Можно ли сохранить?
    var canSave: Bool {
        guard
            Decimal(string: amountString.replacingOccurrences(of: ",", with: ".")) != nil,
            categories.contains(where: { $0.id == selectedCategoryId }),
            (isEditing ? true : account != nil)
        else { return false }
        return true
    }

    /// Загрузка категорий (и счёта при создании)
    func loadData() async {
        do {
            categories = try await categoriesService.categories(direction: direction)
            if !isEditing {
                account = try await bankAccountsService.fetchAccount()
            }
            if selectedCategoryId == 0 {
                selectedCategoryId = categories.first?.id ?? 0
            }
        } catch {
            print("Ошибка загрузки данных: \(error)")
        }
    }

    /// Сохранение (создание или обновление)
    /// Сохранение (создание или обновление)
    func save() async {
        guard
            let account = account,
            let category = categories.first(where: { $0.id == selectedCategoryId }),
            let amount = Decimal(string: amountString.replacingOccurrences(of: ",", with: "."))
        else { return }

        let tx = Transaction(
            id: existingTransaction?.id ?? 0,
            account: account,
            category: category,
            amount: amount,
            transactionDate: date,
            comment: comment.isEmpty ? nil : comment,
            createdAt: existingTransaction?.createdAt ?? Date(),
            updatedAt: Date()
        )

        do {
            if isEditing {
                _ = try await transactionsService.updateTransaction(tx)
            } else {
                _ = try await transactionsService.createTransaction(
                    accountId: tx.account.id,
                    categoryId: tx.category.id,
                    amount: tx.amount,
                    date: tx.transactionDate,
                    comment: tx.comment
                )
            }
        } catch let NetworkError.httpError(statusCode, data) {
            // 🎯 Здесь у тебя есть statusCode и тело ответа
            print("❌ Ошибка HTTP: \(statusCode)")

            // Например:
            switch statusCode {
            case 400:
                // Некорректные данные
                await MainActor.run {
                    // Обнови @Published состояние ошибки
                    self.errorMessage = "Некорректные данные, проверьте ввод"
                }
            case 401:
                await MainActor.run {
                    self.errorMessage = "Неавторизован — проверь токен"
                }
            case 404:
                await MainActor.run {
                    self.errorMessage = "Счет или категория не найдены"
                }
            default:
                await MainActor.run {
                    self.errorMessage = "Неизвестная ошибка (\(statusCode))"
                }
            }
        } catch {
            // Любая другая ошибка (например, сеть)
            await MainActor.run {
                self.errorMessage = "Сетевая ошибка: \(error.localizedDescription)"
            }
        }
    }


    /// Удаление операции
    func delete() async throws {
        guard let id = existingTransaction?.id else { return }
        do {
            try await transactionsService.deleteTransaction(id: id)
        } catch TransactionServiceError.notFound(let id) {
            throw TransactionServiceError.notFound(id: id)
        } catch {
            throw error
        }
    }
}
