import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var store: TransactionsServiceHolder
    
    private let client: NetworkClient = {
        do {
            return try NetworkClient(token: Bundle.main.apiToken)
        } catch {
            fatalError("Не смогли инициализировать NetworkClient: \(error)")
        }
    }()
    
    var body: some View {
        TabView {
            NavigationStack {
                TransactionsListView(
                    vm: TransactionsListViewModel(
                        client: store.client,
                        service: store.service,
                        direction: .outcome,
                        accountId: store.accountId
                    )
                )
            }
            .tabItem { Image("icon_expenses").renderingMode(.template); Text("Расходы") }
            
            NavigationStack {
                TransactionsListView(
                    vm: TransactionsListViewModel(
                        client: store.client,
                        service: store.service,
                        direction: .income,
                        accountId: store.accountId
                    )
                )
            }
            .tabItem { Image("icon_income").renderingMode(.template); Text("Доходы") }
            
            AccountView()
                .tabItem { Image("icon_account").renderingMode(.template); Text("Счет") }
            
            NavigationStack { CategoriesView() }
                .tabItem { Image("icon_categories").renderingMode(.template); Text("Статьи") }
            
            NavigationStack { Text("Настройки") }
                .tabItem { Image("icon_settings").renderingMode(.template); Text("Настройки") }
        }
    }
}

