import SwiftUI

final class TransactionsListViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var totalAmount: Decimal = 0
    
    let direction: Direction
    let service: TransactionsService
    let accountId: Int

    init(direction: Direction,
         accountId: Int,
         service: TransactionsService) {
        self.direction = direction
        self.accountId = accountId
        self.service = service
    }

    @MainActor
    func loadToday() async {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end   = calendar.date(
            bySettingHour: 23, minute: 59, second: 59,
            of: start
        )!

        do {
            let all = try await service.fetchTransactions(
                accountId: accountId,
                startDate: start,
                endDate: end
            )
            let filtered = all.filter { $0.category.direction == direction }

            // обновляем UI
            transactions = filtered
            totalAmount  = filtered.map(\.amount).reduce(0, +)
        } catch {
            print("Ошибка при загрузке транзакций: \(error)")
        }
    }
}
