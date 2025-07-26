import SwiftUI

final class AccountViewModel: ObservableObject {
    enum ChartPeriod: String, CaseIterable, Identifiable {
        case days   = "Дни"
        case months = "Месяцы"
        var id: Self { self }
    }
    
    @Published var account: BankAccount?
    @Published var isEditing = false
    @Published var showCurrencyPicker = false
    @Published var isBalanceHidden = false
    @Published var txHistory: [Transaction] = []
    @Published var chartPeriod: ChartPeriod = .days
    
    // MARK: — сервисы
    let accountsService: BankAccountsService
    let transactionsService: TransactionsService
    // Список доступных валют (можно вынести в сервис)
    let currencies = ["RUB", "USD", "EUR"]
    
    init() {
        // создаём один NetworkClient и один TransactionsFileCache
        let client = try! NetworkClient(token: Bundle.main.apiToken)
        let cache  = try! TransactionsFileCache()
        
        self.accountsService     = BankAccountsService(client: client)
        self.transactionsService = TransactionsService(client: client, cache: cache)
        
        Task {
            await loadAccount()
            await loadHistory()
        }
    }
    
    @MainActor
    func loadAccount() async {
        do {
            account = try await accountsService.fetchAccount()
        } catch {
            print("Error loading: ", error)
        }
    }
    
    @MainActor
    func refresh() async {
        await loadAccount()
    }
    
    @MainActor
    func saveChanges(newBalance: String) async {
        guard let acc = account else { return }
        do {
            account = try await accountsService.updateAccount(
                id: acc.id,
                name: acc.name,   
                balance: newBalance,
                currency: acc.currency
            )
            isEditing = false
        } catch {
            print("Save error: ", error)
        }
    }

    
    func toogleEdit() {
        isEditing.toggle()
    }
    
    func toggleBalanceHidden() {
        withAnimation(.spring()) {
            isBalanceHidden.toggle()
        }
    }
    
    func selectCurrency(_ new: String) {
        guard new != account?.currency else { return }
        account?.currency = new
    }
}
