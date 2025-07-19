import Foundation

final class TransactionsListViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var totalAmount: Decimal = 0
    
    public let client: NetworkClient
    
    let direction: Direction
    let service: TransactionsService
    let accountId: Int

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
    }

    @MainActor
    func loadToday() async {
        // рассчитываем локальный диапазон «сегодня»
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end   = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: start)!

        do {
            let all = try await service.fetchTransactions(
                accountId: accountId,
                startDate: start,
                endDate: end
            )
            // 1) оставляем только нужное направление
            // 2) и только те, которые попадают в «сегодня» по локальной дате
            let filtered = all.filter {
                $0.category.direction == direction
                && calendar.isDate($0.transactionDate, inSameDayAs: Date())
            }

            transactions = filtered
            totalAmount  = filtered.map(\.amount).reduce(0, +)
        } catch {
            print("Ошибка при загрузке транзакций: \(error)")
        }
    }

}
