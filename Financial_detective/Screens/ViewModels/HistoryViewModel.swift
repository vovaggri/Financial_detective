import Foundation

final class HistoryViewModel: ObservableObject {
    // MARK: — Теперь у нас есть client
    let client: NetworkClient
    let service: TransactionsService
    let direction: Direction
    let accountId: Int

    @Published var transactions: [Transaction] = []
    @Published var totalAmount: Decimal = 0
    @Published var startDate: Date
    @Published var endDate: Date

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
        let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: now)!
        self.startDate = Calendar.current.startOfDay(for: monthAgo)
        self.endDate   = Calendar.current.date(
            bySettingHour: 23, minute: 59, second: 59,
            of: Calendar.current.startOfDay(for: now)
        )!

        Task {
            await loadHistory()
        }
    }

    @MainActor
    func loadHistory() async {
        // рассчитываем локальный диапазон по startDate и endDate, но дополнительно фильтруем по локальным дням
        let calendar = Calendar.current

        do {
            // 1) Получаем все транзакции из сервиса (UTC‑диапазон на бэке)
            let all = try await service.fetchTransactions(
                accountId: accountId,
                startDate: startDate,
                endDate: endDate
            )
            // 2) Фильтруем по направлению и по «локальной» дате
            let filtered = all.filter { tx in
                guard tx.category.direction == direction else { return false }
                // проверяем, что transactionDate попадает в один из дней [startDate…endDate] именно по локальному календарю
                return calendar.startOfDay(for: tx.transactionDate) >= calendar.startOfDay(for: startDate)
                    && calendar.startOfDay(for: tx.transactionDate) <= calendar.startOfDay(for: endDate)
            }

            // 3) Обновляем паблишблы
            self.transactions = filtered
            self.totalAmount  = filtered.map(\.amount).reduce(0, +)
        } catch {
            print("Ошибка при загрузке транзакций: \(error)")
        }
    }

}
