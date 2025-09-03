import SwiftUI

struct TransactionsListView: View {
    @EnvironmentObject var store: TransactionsServiceHolder
    @StateObject var vm: TransactionsListViewModel
    @State private var showForm = false
    @State private var editingTx: Transaction?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack {
                    Text("Всего")
                    Spacer()
                    Text(
                        vm.totalAmount
                        .formatted(.currency(code: vm.transactions.first?.account.currency ?? "RUB"))
                    )
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                )
                
                HStack {
                    Text("ОПЕРАЦИИ")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)

                List(vm.transactions) { tx in
                    Button {
                        editingTx = tx
                    } label: {
                        TransactionRow(tx: tx)
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .clipShape(
                    RoundedRectangle(cornerRadius: 12)
                )
            }
            .overlay(
                Button {
                    showForm = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 56))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(
                            .white,
                            Color.accentColor
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Создать операцию"),
                alignment: .bottomTrailing
            )
            .padding(.bottom, 16)
            .fullScreenCover(item: $editingTx, onDismiss: {
                Task { await vm.loadToday() }
            }) { tx in
                TransactionFormView(
                    transaction: tx,
                    direction: vm.direction,
                    accountId: vm.accountId,
                    transactionsService: vm.service,
                    categoriesService: store.categoriesService,
                    bankAccountsService: store.bankAccountsService
                )
                .interactiveDismissDisabled()
            }
            .fullScreenCover(isPresented: $showForm, onDismiss: {
                Task { await vm.loadToday() }
            }) {
                TransactionFormView(
                    direction: vm.direction,
                    accountId: vm.accountId,
                    transactionsService: vm.service,
                    categoriesService: store.categoriesService,
                    bankAccountsService: store.bankAccountsService
                )
                .interactiveDismissDisabled()
            }
            .padding(.horizontal)
            .background(Color(.systemGray6))

            .navigationTitle(
                vm.direction == .income
                ? "Доходы сегодня"
                : "Расходы сегодня"
            )
            .navigationBarTitleDisplayMode(.large)
                
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        // Инициализируем HistoryViewModel теми же параметрами
                        HistoryView(
                            vm: HistoryViewModel(
                                client: vm.client,
                                service: vm.service,
                                direction: vm.direction,
                                accountId: vm.accountId
                            )
                        )
                    } label: {
                        Image(systemName: "clock")
                            .foregroundColor(Color(red: 0x6F/255,
                                                   green: 0x5D/255,
                                                   blue: 0xB7/255)
                            )
                    }
                }
            }
            .listStyle(.plain)
            .onAppear {
                Task {
                    await vm.loadToday()
                }
            }
        }
    }
}

private struct TransactionRow: View {
    let tx: Transaction

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("\(tx.category.emoji)")
                VStack(alignment: .leading, spacing: 4) {
                    Text(tx.category.name)
                    if let comment = tx.comment, !comment.isEmpty {
                        Text(comment)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Text(tx.amount.formatted(.currency(code: tx.account.currency)))
            }
        }
        .padding(.vertical, 8)
        .listRowBackground(Color.white)
    }
}


//#Preview {
//    do {
//        let cache = try TransactionsFileCache()
//        let mockService = try TransactionsService(cache: cache)
//        
//        let vm = TransactionsListViewModel(
//            direction: .outcome,
//            accountId: 1,
//            service: mockService
//        )
//        
//        let testAccount = BankAccount(
//            id: 1,
//            userId: 1,
//            name: "Тестовый счет",
//            balance: 1000,
//            currency: "RUB",
//            createdAt: Date(),
//            updatedAt: Date()
//        )
//        
//        let testCategory = Category(
//            id: 1,
//            name: "Кафе",
//            emoji: "☕",
//            direction: .outcome
//        )
//        
//        let testCategory2 = Category(
//            id: 2,
//            name: "Обед",
//            emoji: "🍔",
//            direction: .outcome
//        )
//        
//        // Создаем тестовые транзакции
//        let testTransactions = [
//            Transaction(
//                id: 1,
//                account: testAccount,
//                category: testCategory,
//                amount: 350,
//                transactionDate: Date(),
//                comment: "Кофе",
//                createdAt: Date(),
//                updatedAt: Date()
//            ),
//            Transaction(
//                id: 2,
//                account: testAccount,
//                category: testCategory2,
//                amount: 680,
//                transactionDate: Date().addingTimeInterval(-3600),
//                comment: "Обед",
//                createdAt: Date(),
//                updatedAt: Date()
//            )
//        ]
//        
//        for transaction in testTransactions {
//            cache.add(transaction)
//        }
//        try cache.save()
//        
//        vm.transactions = testTransactions
//        
//        return AnyView(TransactionsListView(vm: vm))
//        
//    } catch {
//        return AnyView(Text("Ошибка создания превью: \(error.localizedDescription)")
//            .padding()
//            .background(Color.red.opacity(0.3)))
//
//    }
//}
//

