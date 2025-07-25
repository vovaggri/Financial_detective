import Foundation

extension AccountViewModel {
    @MainActor
    func loadHistory() async {
        guard let acc = account else { return }
        let now = Date()
        let cal = Calendar.current
        let start: Date

        switch chartPeriod {
        case .days:
            start = cal.date(byAdding: .day, value: -29,
                              to: cal.startOfDay(for: now))!
        case .months:
            let thisMonthStart = cal.date(
                from: cal.dateComponents([.year, .month], from: now)
            )!
            start = cal.date(byAdding: .month, value: -23,
                              to: thisMonthStart)!
        }

        do {
            txHistory = try await transactionsService
                .fetchTransactions(
                    accountId: acc.id,
                    startDate: start,
                    endDate: now
                )
        } catch {
            print("Ошибка загрузки истории:", error)
        }
    }
}

