import SwiftUI
import Charts

struct BalanceHistoryChartView: View {
    struct Point: Identifiable {
        let id = UUID()
        let date: Date
        let balance: Decimal
        var balanceDouble: Double { NSDecimalNumber(decimal: balance).doubleValue }
    }
    
    let currentBalance: Decimal
    let transactions: [Transaction]

    // 1) Точки за 30 дней
    private var data: [Point] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let days = (0..<30).map {
            cal.date(byAdding: .day, value: -$0, to: today)!
        }.reversed()
        let signed: (Transaction) -> Decimal = { tx in
            tx.category.isIncome ? tx.amount : -tx.amount
        }
        return days.map { day in
            let futureSum = transactions
                .filter { $0.transactionDate > day }
                .reduce(Decimal(0)) { $0 + signed($1) }
            let balance = currentBalance - futureSum
            return Point(date: day, balance: balance)
        }
    }
    
    // 2) Максимум по Y с запасом
    private var maxYValue: Double {
        let absValues = data.map { abs($0.balanceDouble) }
        return (absValues.max() ?? 0) * 1.1
    }
    
    // 3) Три ключевые даты для подписей
    private var axisDates: [Date] {
        let dates = data.map(\.date)
        guard dates.count >= 3 else { return dates }
        let first = dates.first!
        let mid   = dates[dates.count/2]
        let last  = dates.last!
        return [first, mid, last]
    }

    var body: some View {
        VStack(spacing: 4) {
            // сам график без подписи X‑оси
            Chart {
                ForEach(data) { pt in
                    BarMark(
                        x: .value("Дата", pt.date),
                        y: .value("Баланс", abs(pt.balanceDouble)),
                        width: .fixed(6)
                    )
                    .foregroundStyle(pt.balanceDouble >= 0 ? Color(red: 42/255, green: 232/255, blue: 129/255) : Color(red: 255/255, green: 95/255, blue: 0/255))
                }
            }
            .chartYScale(domain: 0...maxYValue)
            .chartXAxis(.hidden)       // скрываем встроенные подписи
            .chartYAxis(.hidden)
            .chartPlotStyle { plotArea in
                plotArea.background(Color.clear)
            }
            .background(Color(.systemGray6))
            .frame(minHeight: 120)
            
            // и собственные подписи под графиком
            HStack {
                Text(axisDates[0], format: .dateTime.day().month(.twoDigits))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(axisDates[1], format: .dateTime.day().month(.twoDigits))
                    .frame(maxWidth: .infinity, alignment: .center)
                Text(axisDates[2], format: .dateTime.day().month(.twoDigits))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(.caption2)
            .padding(.horizontal, 16)
        }
    }
}

