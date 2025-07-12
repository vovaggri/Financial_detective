import SwiftUI

final class HistoryViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var totalAmount: Decimal = 0

    @Published var startDate: Date
    @Published var endDate: Date

    let direction: Direction
    let service: TransactionsService
    let accountId: Int

    init(direction: Direction,
         accountId: Int,
         service: TransactionsService) {
        self.direction = direction
        self.accountId = accountId
        self.service = service

        let now = Date()
        let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: now)!
        self.startDate = Calendar.current.startOfDay(for: monthAgo)
        self.endDate   = Calendar.current.date(
            bySettingHour: 23, minute: 59, second: 59,
            of: Calendar.current.startOfDay(for: now)
        )!

        loadHistory()
    }

    func loadHistory() {
        Task {
            let all = try await service.fetchTransactions(
                accountId: accountId,
                startDate: startDate,
                endDate: endDate
            )
            await MainActor.run {
                let filtered = all.filter { $0.category.direction == self.direction }
                self.transactions = filtered
                self.totalAmount = filtered.map(\.amount).reduce(0, +)
            }
        }
    }
}
