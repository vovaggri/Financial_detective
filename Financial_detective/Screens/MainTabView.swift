import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var store: TransactionsServiceHolder

    var body: some View {
        TabView {
            NavigationStack {
                TransactionsListView(
                  vm: TransactionsListViewModel(
                    direction: .outcome,
                    accountId: store.accountId,
                    service: store.service
                  )
                )
            }
            .tabItem {
                Image("icon_expenses")
                    .renderingMode(.template)
                Text("Расходы")
            }

            NavigationStack {
                TransactionsListView(
                  vm: TransactionsListViewModel(
                    direction: .income,
                    accountId: store.accountId,
                    service: store.service
                  )
                )
            }
            .tabItem {
                Image("icon_income")
                    .renderingMode(.template)
                Text("Доходы")
            }

            NavigationStack {
                // stub
                Text("Счет")
            }
            .tabItem {
                Image("icon_account")
                    .renderingMode(.template)
                Text("Счет")
            }

            NavigationStack {
                Text("Статьи")
            }
            .tabItem {
                Image("icon_categories")
                    .renderingMode(.template)
                Text("Статьи")
            }

            NavigationStack {
                Text("Настройки")
            }
            .tabItem {
                Image("icon_settings")
                    .renderingMode(.template)
                Text("Настройки")
            }
        }
    }
}

