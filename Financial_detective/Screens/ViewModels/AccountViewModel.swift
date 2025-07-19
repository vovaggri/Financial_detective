import SwiftUI

final class AccountViewModel: ObservableObject {
    @Published var account: BankAccount?
    @Published var isEditing = false
    @Published var showCurrencyPicker = false
    @Published var isBalanceHidden = false
    
    // Список доступных валют (можно вынести в сервис)
    let currencies = ["RUB", "USD", "EUR"]
    
    private let service: BankAccountsService
    
    init() {
        let client = try! NetworkClient(token: Bundle.main.apiToken)
        self.service = BankAccountsService(client: client)
        
        Task {
            await loadAccount()
        }
    }
    
    @MainActor
    func loadAccount() async {
        do {
            account = try await service.fetchAccount()
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
            account = try await service.updateAccount(
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
