import XCTest
@testable import Financial_detective

final class TransactionParsingTests: XCTestCase {
    var sampleJSON: [String:Any] = [:]
    
    override func setUpWithError() throws {
        sampleJSON = [
            "id": 1,
            "account": [
                "id": 1,
                "name": "Основной счет",
                "balance": "1000.00",
                "currency": "RUB"
            ],
            "category": [
                "id": 2,
                "name": "Кофе",
                "emoji": "☕️",
                "isIncome": false
            ],
            "amount": "500.00",
            "transactionDate": "2025-06-12T12:14:54.070Z",
            "comment": "Тестовая операция",
            "createdAt": "2025-06-12T12:14:54.070Z",
            "updatedAt": "2025-06-12T12:14:54.070Z"
        ]
    }
    
    func testParseValidTransaction() throws {
        guard let transaction = Transaction.parse(jsonObject: sampleJSON) else {
            XCTFail("parse(jsonObject:) return nil for valid JSON")
            return
        }
        XCTAssertEqual(transaction.id, 1)
        XCTAssertEqual(transaction.amount, Decimal(string: "500.00"))
        XCTAssertEqual(transaction.category.id, 2)
        XCTAssertEqual(transaction.category.isIncome, false)
        XCTAssertEqual(transaction.account.name, "Основной счет")
    }
    
    func testRoundTripJsonObject() throws {
        guard let transaction1 = Transaction.parse(jsonObject: sampleJSON) else {
            XCTFail("initial parse failed")
            return
        }
        let jsonObj = transaction1.jsonObject
        guard let transaction2 = Transaction.parse(jsonObject: jsonObj) else {
            XCTFail("round-trip parse failed")
            return
        }
        // check the pair of key properties
        XCTAssertEqual(transaction2.id, transaction1.id)
        XCTAssertEqual(transaction2.amount, transaction1.amount)
        XCTAssertEqual(transaction2.category.emoji, transaction1.category.emoji)
    }
}
