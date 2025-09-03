import Foundation

private let _encoder = JSONEncoder()
private let _decoder = JSONDecoder()

extension SDTransactionEntity {
    convenience init(from tx: Transaction) throws {
        let acc = try _encoder.encode(tx.account)
        let cat = try _encoder.encode(tx.category)
        self.init(id: tx.id,
                  accountJSON: acc,
                  categoryJSON: cat,
                  amountString: String(describing: tx.amount),
                  transactionDate: tx.transactionDate,
                  comment: tx.comment,
                  createdAt: tx.createdAt,
                  updatedAt: tx.updatedAt)
    }

    func toModel() throws -> Transaction {
        let acc = try _decoder.decode(BankAccount.self, from: accountJSON)
        let cat = try _decoder.decode(Category.self, from: categoryJSON)
        guard let dec = Decimal(string: amountString) else {
            throw NSError(domain: "SwiftData", code: -1, userInfo: [NSLocalizedDescriptionKey: "Bad amount"])
        }
        return Transaction(id: id,
                           account: acc,
                           category: cat,
                           amount: dec,
                           transactionDate: transactionDate,
                           comment: comment,
                           createdAt: createdAt,
                           updatedAt: updatedAt)
    }
}

extension SDTransactionBackupEntity {
    func toItem() throws -> TransactionBackupItem {
        let action = TransactionBackupAction(rawValue: actionRaw) ?? .update
        let payload = payloadJSON.flatMap { try? _decoder.decode(Transaction.self, from: $0) }
        return TransactionBackupItem(id: id, action: action, payload: payload, updatedAt: updatedAt)
    }

    func apply(_ item: TransactionBackupItem) throws {
        self.actionRaw = item.action.rawValue
        self.payloadJSON = try item.payload.map { try _encoder.encode($0) }
        self.updatedAt = item.updatedAt
    }
}
