import SwiftUI

final class AccountViewModel: ObservableObject {
    @Published var account: BankAccount?
    @Published var isEditing = false
    @Published var showCurrencyPicker = false
    @Published var isBalanceHidden = false
    
    // Список доступных валют (можно вынести в сервис)
    let currencies = ["RUB", "USD", "EUR"]
    
    private let service = BankAccountsService()
    
    init() {
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
    func saveChanges() async {
        guard let guardAccount = account else { return }
        do {
            account = try await service.updateAccount(guardAccount)
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
