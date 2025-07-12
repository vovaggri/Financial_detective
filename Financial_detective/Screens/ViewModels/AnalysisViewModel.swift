import Foundation

final class AnalysisViewModel {
    enum SortOption {
        case date
        case amount
    }
    
    public let service: TransactionsService
    public let accountId: Int
    public let direction: Direction
    
    var onTransactionChange: (([Transaction]) -> Void)?
    var onTotalAmountChange: ((Decimal) -> Void)?
    var onError: ((Error) -> Void)?
    
    var transactions: [Transaction] = [] {
        didSet {
            onTransactionChange?(transactions)
            totalAmount = transactions.map(\.amount).reduce(0, +)
        }
    }
    
    private(set) var totalAmount: Decimal = 0 {
        didSet {
            onTotalAmountChange?(totalAmount)
        }
    }
    
    var startDate: Date {
        didSet {
            loadTransactions()
        }
    }
    
    var endDate: Date {
        didSet {
            loadTransactions()
        }
    }
    
    var sortOption: SortOption = .date {
        didSet {
            loadTransactions()
        }
    }
    
    init(direction: Direction, accountId: Int, service: TransactionsService) {
        self.direction = direction
        self.accountId = accountId
        self.service = service
        
        let now = Date()
        self.endDate = now
        self.startDate = Calendar.current.date(byAdding: .month, value: -1, to: now)!
        loadTransactions()
    }
    
    func loadTransactions() {
        if startDate > endDate {
            endDate = startDate
        }
        
        Task {
            do {
                let all = try await service.fetchTransactions(
                    accountId: accountId,
                    startDate: startDate,
                    endDate: endDate
                )
                // Фильтруем по направлению
                var filtered = all.filter { $0.category.direction == direction }
                
                // Сортируем в зависимости от опции
                switch sortOption {
                case .date:
                    // по возрастанию даты операции
                    filtered.sort { $0.transactionDate < $1.transactionDate }
                case .amount:
                    // по возрастанию суммы
                    filtered.sort { $0.amount < $1.amount }
                }
                
                await MainActor.run {
                    self.transactions = filtered
                }
            } catch {
                await MainActor.run {
                    self.onError?(error)
                }
            }
        }
    }
}
