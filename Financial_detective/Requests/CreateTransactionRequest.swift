import Foundation

struct CreateTransactionRequest: Encodable {
    let accountId: Int
    let categoryId: Int
    let amount: String
    let transactionDate: String
    let comment: String
    
    init(accountId: Int, categoryId: Int, amount: Decimal, transactionDate: Date, comment: String?) {
        self.accountId = accountId
        self.categoryId = categoryId
        // форматируем Decimal -> String
        self.amount = Self.formatAmount(amount)
        // форматируем дату -> ISO8601 с миллисекундами
        self.transactionDate = Self.formatDate(transactionDate)
        self.comment = comment ?? ""
    }
    
    private static func formatAmount(_ value: Decimal) -> String {
        let ns = value as NSDecimalNumber
        // 2 знака после запятой, точка как разделитель
        return String(format: "%.2f", ns.doubleValue)
    }
    
    private static func formatDate(_ date: Date) -> String {
        // ISO8601 с миллисекундами
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}

