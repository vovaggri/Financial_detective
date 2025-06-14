import XCTest
@testable import Financial_detective

final class TransactionCSVTests: XCTestCase {
    let sampleCSV = """
    id,accountId,accountName,accountBalance,accountCurrency,categoryId,categoryName,emoji,isIncome,amount,transactionDate,comment,createdAt,updatedAt
    1,1,Основной счет,1000.00,RUB,2,Кофе,☕️,false,500.00,2025-06-12T12:14:54.070Z,Тестовая операция,2025-06-12T12:14:54.070Z,2025-06-12T12:14:54.070Z
    bad,row,should,be,skipped
    """
    
    func testParseCSV_singleValidRow() {
        let transactions = Transaction.parseCSV(sampleCSV)
        XCTAssertEqual(transactions.count, 1, "Должна распарситься ровно одна строка")

        let transaction = transactions[0]
        XCTAssertEqual(transaction.id, 1)
        XCTAssertEqual(transaction.account.id, 1)
        XCTAssertEqual(transaction.account.name, "Основной счет")
        XCTAssertEqual(transaction.account.balance, Decimal(string: "1000.00"))
        XCTAssertEqual(transaction.category.id, 2)
        XCTAssertEqual(transaction.category.emoji, "☕️")
        XCTAssertEqual(transaction.category.isIncome, false)
        XCTAssertEqual(transaction.amount, Decimal(string: "500.00"))
            
        // Проверяем дату на примере
        let fmt = ISO8601DateFormatter.withFractionalSeconds
        let expectedDate = fmt.date(from: "2025-06-12T12:14:54.070Z")
        XCTAssertEqual(transaction.transactionDate, expectedDate)
            
        XCTAssertEqual(transaction.comment, "Тестовая операция")
    }
    
    func testParseCSV_emptyOrBadCSV() {
        XCTAssertTrue(Transaction.parseCSV("").isEmpty)
        XCTAssertTrue(Transaction.parseCSV("id,accountId").isEmpty)
    }
}
