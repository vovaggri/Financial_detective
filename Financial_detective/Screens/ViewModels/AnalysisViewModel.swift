import Foundation

final class AnalysisViewModel {
    enum SortOption {
        case date
        case amount
    }
    
    // MARK: — Входные параметры
    /// Для передачи во UIViewControllerRepresentable
    let client: NetworkClient
    /// Для загрузки транзакций
    let service: TransactionsService
    let accountId: Int
    let direction: Direction
    
    // MARK: — Колбеки для ViewController
    var onTransactionChange: (([Transaction]) -> Void)?
    var onTotalAmountChange: ((Decimal) -> Void)?
    var onError: ((Error) -> Void)?
    
    // MARK: — Данные
    private(set) var transactions: [Transaction] = [] {
        didSet {
            onTransactionChange?(transactions)
            totalAmount = transactions.map(\.amount).reduce(0, +)
        }
    }
    private(set) var totalAmount: Decimal = 0 {
        didSet {
            onTotalAmountChange?(totalAmount)
        }
    }
    
    // MARK: — Параметры фильтрации/сортировки
    var startDate: Date {
        didSet { loadTransactions() }
    }
    var endDate: Date {
        didSet { loadTransactions() }
    }
    var sortOption: SortOption = .date {
        didSet { loadTransactions() }
    }
    
    // MARK: — Init
    init(
        client: NetworkClient,
        service: TransactionsService,
        direction: Direction,
        accountId: Int
    ) {
        self.client    = client
        self.service   = service
        self.direction = direction
        self.accountId = accountId
        
        let now = Date()
        self.endDate   = now
        self.startDate = Calendar.current.date(
            byAdding: .month,
            value: -1,
            to: now
        )!
        
        loadTransactions()
    }
    
    // MARK: — Загрузка транзакций
    func loadTransactions() {
        // Отрабатываем случай, когда пользователь перепутал даты
        if startDate > endDate {
            endDate = startDate
        }

        Task {
            do {
                // 1) Получаем весь массив из бэка
                let all = try await service.fetchTransactions(
                    accountId: accountId,
                    startDate: startDate,
                    endDate: endDate
                )

                // 2) Создаём календарь для локальных вычислений
                let calendar = Calendar.current

                // 3) Фильтруем по направлению и по локальной дате
                let filtered = all.filter { tx in
                    guard tx.category.direction == direction else { return false }
                    let txDay = calendar.startOfDay(for: tx.transactionDate)
                    let startDay = calendar.startOfDay(for: startDate)
                    let endDay   = calendar.startOfDay(for: endDate)
                    return txDay >= startDay && txDay <= endDay
                }

                // 4) Сортируем
                let sorted = filtered.sorted { a, b in
                    switch sortOption {
                    case .date:   return a.transactionDate < b.transactionDate
                    case .amount: return a.amount          < b.amount
                    }
                }

                // 5) Вызываем колбэки на главном потоке
                await MainActor.run {
                    self.transactions = sorted
                }
            } catch {
                await MainActor.run {
                    self.onError?(error)
                }
            }
        }
    }
}

