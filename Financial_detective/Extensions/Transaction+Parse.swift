import Foundation

extension Transaction {
    static func parse(jsonObject: Any) -> Transaction? {
        // Parse Transaction
        guard
            let dict = jsonObject as? [String: Any],
    
            let id = dict["id"] as? Int,
            let amountString = dict["amount"] as? String,
            let amount = Decimal(string: amountString),
            let transactionDateString = dict["transactionDate"] as? String,
            let createdAtString = dict["createdAt"] as? String,
            let updatedAtString = dict["updatedAt"] as? String,
            let transactionDate = ISO8601DateFormatter().date(from: transactionDateString),
            let createdAt = ISO8601DateFormatter().date(from: createdAtString),
            let updatedAt = ISO8601DateFormatter().date(from: updatedAtString)
        else {
            return nil
        }
        let comment = dict["comment"] as? String
        
        // Parse BankAccount
        guard
            let accDict = dict["account"] as? [String: Any],
            let accId = accDict["id"] as? Int,
            let userId = accDict["userId"] as? Int,
            let accName = accDict["name"] as? String,
            let accBalanceString = accDict["balance"] as? String,
            let accBalance = Decimal(string: accBalanceString),
            let accCurrency = accDict["currency"] as? String,
            let accCreatedAtString = accDict["createdAt"] as? String,
            let accUpdatedAtString = accDict["updatedAt"] as? String,
            let accCreatedAt = ISO8601DateFormatter().date(from: accCreatedAtString),
            let accUpdatedAt = ISO8601DateFormatter().date(from: accUpdatedAtString)
        else {
            return nil
        }
        let account = BankAccount (id: accId, userId: userId, name: accName, balance: accBalance, currency: accCurrency, createdAt: accCreatedAt, updatedAt: accUpdatedAt)
        
        // Parse Category
        guard
            let catDict = dict["category"] as? [String: Any],
            let catId = catDict["id"] as? Int,
            let catName = catDict["name"] as? String,
            let catEmojiString = catDict["emoji"] as? String,
            catEmojiString.count == 1,
            let catEmojiChar = catEmojiString.first,
            let isIncome = catDict["isIncome"] as? Bool
        else {
            return nil
        }
        let direction: Direction = isIncome ? .income : .outcome
        let category = Category (id: catId, name: catName, emoji: catEmojiChar, direction: direction)
        
        return Transaction(id: id, account: account, category: category, amount: amount, transactionDate: transactionDate, comment: comment, createdAt: createdAt, updatedAt: updatedAt)
    }
    
    var jsonObject: Any {
        let formatter = ISO8601DateFormatter()
        
        let accountDict: [String: Any] = [
            "id": account.id,
            "userId": account.userId,
            "name": account.name,
            "balance": String(describing: account.balance),
            "currency": account.currency,
            "createdAt": formatter.string(from: account.createdAt),
            "updatedAt": formatter.string(from: account.updatedAt)
        ]
        
        let categoryDict: [String: Any] = [
            "id": category.id,
            "name": category.name,
            "emoji": String(describing: category.emoji),
            "isIncome": category.isIncome
        ]
        
        return [
            "id": id,
            "accountId": accountDict,
            "categoryId": categoryDict,
            "amount": String(describing: amount),
            "transactionDate": formatter.string(from: transactionDate),
            "comment": comment as Any,
            "createdAt": formatter.string(from: createdAt),
            "updatedAt": formatter.string(from: updatedAt)
        ]
    }
}
