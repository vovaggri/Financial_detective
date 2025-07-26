import SwiftUI
import Charts

struct Point: Identifiable {
    let id = UUID()
    let date: Date
    let balance: Decimal
    var balanceDouble: Double { NSDecimalNumber(decimal: balance).doubleValue }
}

struct BalanceHistoryChartView: View {
    enum Period: String, CaseIterable, Identifiable {
        case days   = "Дни"
        case months = "Месяцы"
        var id: Self { self }
    }

    @State private var period: Period = .days
    @State private var selected: Point?
    @State private var touchLocation: CGPoint?

    let currentBalance: Decimal
    let transactions: [Transaction]
    let currencySymbol: String

    // MARK: — данные для графика по выбранному периоду
    private var data: [Point] {
        let cal = Calendar.current
        switch period {
        case .days:
            let today = cal.startOfDay(for: Date())
            let days = (0..<30).map { cal.date(byAdding: .day, value: -$0, to: today)! }.reversed()
            let signed: (Transaction) -> Decimal = { tx in tx.category.isIncome ? tx.amount : -tx.amount }
            return days.map { day in
                let futureSum = transactions
                    .filter { $0.transactionDate > day }
                    .reduce(Decimal(0)) { $0 + signed($1) }
                let balance = currentBalance - futureSum
                return Point(date: day, balance: balance)
            }

        case .months:
            // начало текущего месяца
            let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: Date()))!
            let months = (0..<24).map { cal.date(byAdding: .month, value: -$0, to: monthStart)! }.reversed()
            let signed: (Transaction) -> Decimal = { tx in tx.category.isIncome ? tx.amount : -tx.amount }
            return months.map { m in
                let futureSum = transactions
                    .filter { $0.transactionDate > m }
                    .reduce(Decimal(0)) { $0 + signed($1) }
                let balance = currentBalance - futureSum
                return Point(date: m, balance: balance)
            }
        }
    }

    private var maxYValue: Double {
        let absValues = data.map { abs($0.balanceDouble) }
        return (absValues.max() ?? 0) * 1.1
    }

    private var axisDates: [Date] {
        let dates = data.map(\ .date)
        guard dates.count >= 3 else { return dates }
        let first = dates.first!
        let mid   = dates[dates.count/2]
        let last  = dates.last!
        return [first, mid, last]
    }

    var body: some View {
        VStack(spacing: 8) {
            // Picker над графиком
            Picker("", selection: $period) {
                ForEach(Period.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: period) { _ in
                withAnimation(.easeInOut) {}
            }

            ZStack {
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
                .chartPlotStyle { plotArea in plotArea.background(Color.clear) }
                .background(Color(.systemGray6))
                .frame(minHeight: 140)
                .animation(.easeInOut, value: period)

                // Overlay for touch gestures
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle().fill(Color.clear).contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        touchLocation = value.location
                                        if let date: Date = proxy.value(atX: value.location.x) {
                                            selected = data.min(by: {
                                                abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                                            })
                                        }
                                    }
                                    .onEnded { _ in
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                            selected = nil
                                            touchLocation = nil
                                        }
                                    }
                            )
                    }
                }

                // Tooltip
                if let pt = selected, let loc = touchLocation {
                    VStack(spacing: 2) {
                        Text(pt.date, format: .dateTime.day().month(.twoDigits).year())
                            .font(.caption2)
                        Text("\(pt.balanceDouble >= 0 ? "+" : "-")\(abs(pt.balanceDouble), specifier: "%.0f") \(currencySymbol)")
                            .font(.caption).bold()
                    }
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .position(x: loc.x, y: loc.y - 30)
                }
            }

            HStack {
                let labels = axisDates
                Text(labels[0], format: .dateTime.day().month(.twoDigits))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(labels[1], format: .dateTime.day().month(.twoDigits))
                    .frame(maxWidth: .infinity, alignment: .center)
                Text(labels[2], format: .dateTime.day().month(.twoDigits))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(.caption2)
            .padding(.horizontal, 16)
        }
    }
}

