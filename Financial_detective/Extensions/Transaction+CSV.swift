import Foundation

extension Transaction {
    static func parseCSV(_ csv: String) -> [Transaction] {
        let lines = csv
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard lines.count >= 2 else { return [] }
        
        let header = lines[0]
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        let indices = Dictionary(
            uniqueKeysWithValues: header.enumerated().map { ($1, $0) }
        )
        
        var result = [Transaction]()
        let formatter = ISO8601DateFormatter.withFractionalSeconds
        
        for line in lines.dropFirst() {
            let cols = line.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces)
            }
            
            guard
                let idStr = columnValue("id", in: cols, using: indices),
                let id = Int(idStr),
                let amountStr = columnValue("amount", in: cols, using: indices),
                let amount = Decimal(string: amountStr),
                let transactionDateStr = columnValue("transactionDate", in: cols, using: indices),
                let transactionDate = formatter.date(from: transactionDateStr),
                let comment = columnValue("comment", in: cols, using: indices),
                let createdStr = columnValue("createdAt", in: cols, using: indices),
                let createrAt = formatter.date(from: createdStr),
                let updatedStr = columnValue("updatedAt", in: cols, using: indices),
                let updatedAt = formatter.date(from: updatedStr)
            else {
                continue
            }
            
            guard
                let accIdStr = columnValue("accountId", in: cols, using: indices),
                let accId = Int(accIdStr),
                let accName = columnValue("accountName", in: cols, using: indices),
                let balanceStr = columnValue("accountBalance", in: cols, using: indices),
                let balance = Decimal(string: balanceStr),
                let currency = columnValue("accountCurrency",  in: cols, using: indices)
            else {
                continue
            }
            
            let account = BankAccount(id: accId, name: accName, balance: balanceStr, currency: currency, createdAt: createrAt, updatedAt: updatedAt)
            
            guard
                let catIdStr = columnValue("categoryId", in: cols, using: indices),
                let catId = Int(catIdStr),
                let catName = columnValue("categoryName", in: cols, using: indices),
                let emojiStr = columnValue("emoji", in: cols, using: indices),
                let emojiCh = emojiStr.first,
                let isIncStr = columnValue("isIncome", in: cols, using: indices),
                let isInc = Bool(isIncStr)
            else {
                continue
            }
            
            let category = Category(id: catId, name: catName, emoji: emojiCh, direction: isInc ? .income : .outcome)
            
            let transaction = Transaction(id: id, account: account, category: category, amount: amount, transactionDate: transactionDate, comment: comment, createdAt: createrAt, updatedAt: updatedAt)
            
            result.append(transaction)
        }
        
        return result
    }
    
    private static func columnValue(
        _ name: String,
        in cols: [String],
        using indices: [String: Int]
    ) -> String? {
        guard let idx = indices[name], idx < cols.count else {
            return nil
        }
        return cols[idx]
    }

}
