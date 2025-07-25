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
    let currencySymbol: String

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
    
    @State private var selected: Point?
    @State private var touchLocation: CGPoint?
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // 1) сам график
                Chart {
                    ForEach(data) { pt in
                        BarMark(
                            x: .value("Дата", pt.date),
                            y: .value("Баланс", abs(pt.balanceDouble)),
                            width: .fixed(6)
                        )
                        .foregroundStyle(
                            pt.balanceDouble >= 0
                            ? Color(red: 42/255, green: 232/255, blue: 129/255)
                            : Color(red: 255/255, green: 95/255, blue: 0/255)
                        )
                    }
                }
                .chartYScale(domain: 0...maxYValue)
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartPlotStyle { plotArea in
                    plotArea.background(Color.clear)
                }
                .background(Color(.systemGray6))
                .frame(minHeight: 120)
                // 2) оверлей для распознавания жеста и вычисления точки
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle().fill(Color.clear).contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        touchLocation = value.location
                                        if let date: Date = proxy.value(atX: value.location.x) {
                                            // выбираем ближайшую точку по дате
                                            selected = data.min {
                                                abs($0.date.timeIntervalSince(date))
                                                < abs($1.date.timeIntervalSince(date))
                                            }
                                        }
                                    }
                                    .onEnded { _ in
                                        // после отпускания скрываем тултип через секунду
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                            selected = nil
                                            touchLocation = nil
                                        }
                                    }
                            )
                    }
                }
                
                // 3) тултип поверх графика
                if let pt = selected, let loc = touchLocation {
                    // выводим две строки: дата и сумма
                    VStack(spacing: 2) {
                        Text(pt.date, format: .dateTime.day().month(.twoDigits).year())
                            .font(.caption2)
                        Text("\(pt.balanceDouble >= 0 ? "+" : "-")\(abs(pt.balanceDouble), specifier: "%.0f") \(currencySymbol)")
                            .font(.caption).bold()
                    }
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    // позиционируем тултип там, где касание (сдвиг чуть выше)
                    .position(x: loc.x, y: loc.y - 30)
                }
            }
            
            // 4) подписи дат снизу (по трем точкам)
            let dates = [data.first?.date, data[data.count/2].date, data.last?.date]
            HStack {
                Text(dates[0]!, format: .dateTime.day().month(.twoDigits))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(dates[1]!, format: .dateTime.day().month(.twoDigits))
                    .frame(maxWidth: .infinity, alignment: .center)
                Text(dates[2]!, format: .dateTime.day().month(.twoDigits))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(.caption2)
            .padding(.horizontal, 16)
        }
    }
}

