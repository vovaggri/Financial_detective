import Foundation

enum API {
    static let accounts     = "/api/v1/accounts"
    static let categories   = "/api/v1/categories"
    static let transactions = "/api/v1/transactions"
    
    case getAccount(id: Int)
    case updateAccount(id: Int)
    case listCategories(direction: Direction?)
    case fetchTransactions(accountId: Int, from: Date?, to: Date?)       // теперь без параметров, тело будет отдельно
    case getTransaction(id: Int)
    case createTransaction
    case updateTransaction(id: Int)
    case deleteTransaction(id: Int)
    case listAccounts
    
    var path: String {
        switch self {
        case .listAccounts:
            return Self.accounts
        case .getAccount(let id):        return "\(Self.accounts)/\(id)"
        case .updateAccount(let id):     return "\(Self.accounts)/\(id)"
        case .listCategories(let direction):
            if let dir = direction {
                let isIncome = dir == .income ? "true" : "false"
                return "/api/v1/categories/type/\(isIncome)"
            } else {
                return "/api/v1/categories"
            }
        case .fetchTransactions(let accountId, _, _):
            return "/api/v1/transactions/account/\(accountId)/period"
        case .getTransaction(let id):    return "\(Self.transactions)/\(id)"
        case .createTransaction:         return Self.transactions
        case .updateTransaction(let id):
            return "/api/v1/transactions/\(id)"
        case .deleteTransaction(let id): return "\(Self.transactions)/\(id)"
        }
    }
    
    var method: String {
        switch self {
        case .getAccount, .listCategories, .getTransaction, .fetchTransactions, .listAccounts:
            return "GET"
        case .createTransaction:
            return "POST"
        case .updateAccount, .updateTransaction:
            return "PUT"
        case .deleteTransaction:
            return "DELETE"
        }
    }
}

