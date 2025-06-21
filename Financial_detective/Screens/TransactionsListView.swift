import SwiftUI

struct TransactionsListView: View {
    @StateObject var vm: TransactionsListViewModel

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
                    NavigationLink {
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                        // Верхняя строка: эмоджи + название
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
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .clipShape(
                    RoundedRectangle(cornerRadius: 12)
                )
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
                            direction: vm.direction,
                            accountId: vm.accountId,
                            service: vm.service
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
            
            .task {
                await vm.loadToday()
            }
        }
    }
}


#Preview {
    do {
        let cache = try TransactionsFileCache()
        let mockService = try TransactionsService(cache: cache)
        
        let vm = TransactionsListViewModel(
            direction: .outcome,
            accountId: 1,
            service: mockService
        )
        
        let testAccount = BankAccount(
            id: 1,
            userId: 1,
            name: "Тестовый счет",
            balance: 1000,
            currency: "RUB",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let testCategory = Category(
            id: 1,
            name: "Кафе",
            emoji: "☕",
            direction: .outcome
        )
        
        let testCategory2 = Category(
            id: 2,
            name: "Обед",
            emoji: "🍔",
            direction: .outcome
        )
        
        // Создаем тестовые транзакции
        let testTransactions = [
            Transaction(
                id: 1,
                account: testAccount,
                category: testCategory,
                amount: 350,
                transactionDate: Date(),
                comment: "Кофе",
                createdAt: Date(),
                updatedAt: Date()
            ),
            Transaction(
                id: 2,
                account: testAccount,
                category: testCategory2,
                amount: 680,
                transactionDate: Date().addingTimeInterval(-3600),
                comment: "Обед",
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
        
        for transaction in testTransactions {
            cache.add(transaction)
        }
        try cache.save()
        
        vm.transactions = testTransactions
        
        return AnyView(TransactionsListView(vm: vm))
        
    } catch {
        return AnyView(Text("Ошибка создания превью: \(error.localizedDescription)")
            .padding()
            .background(Color.red.opacity(0.3)))

    }
}


