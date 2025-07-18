//import SwiftUI
//
//struct ServicesTestView: View {
//    @State private var categories: [Category] = []
//    @State private var account: BankAccount?
//    @State private var transactions: [Transaction] = []
//    @State private var errorMessage: String?
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            Text("Categories: \(categories.map(\.name).joined(separator: ", "))")
//            Text("Account: \(account.map(\.name) ?? "—")")
//            Text("Transactions: \(transactions.count)")
//            if let err = errorMessage {
//                Text("Error: \(err)").foregroundColor(.red)
//            }
//            Spacer()
//        }
//        .padding()
//        .task {
//            await runTests()
//        }
//    }
//    
//    private func runTests() async {
//        do {
//            // CategoriesService
//            let categoriesService = CategoriesService()
//            categories = try await categoriesService.categories()
//            print("Categories:", categories)
//            
//            guard let firstCategory = categories.first else {
//                print("There is no catagories")
//                return
//            }
//            
//            // BankAccountsService
//            let bankAccountsService = BankAccountsService()
//            let acc = try await bankAccountsService.fetchAccount()
//            account = acc
//            print("Account: ", acc)
//            
//            // TransactionsService
//            let cache = try TransactionsFileCache()
//            let transactionService = try await TransactionsService(cache: cache)
//            
//            let amountString = "123.45"
//                guard let amount = Decimal(string: amountString) else {
//                    print("Conver from Decimal to \(amountString) impossible")
//                    return
//                }
//            
//            let now = Date()
//            let newTransaction = Transaction(id: 0, account: acc, category: firstCategory, amount: amount, transactionDate: now, comment: "Test", createdAt: now, updatedAt: now)
//            
//            let created = try await transactionService.createTransaction(newTransaction)
//            print("Created transaction id:", created.id)
//            print("Created transaction account: ", created.account)
//            print("Created transaction category: ", created.category)
//            print("Created transaction amount: ", created.amount)
//            print("Created transaction date", created.transactionDate)
//            
//            let all = try await transactionService.fetchTransactions(accountId: acc.id)
//            transactions = all
//            print("Fetched transaction count:", all.count)
//        } catch {
//            errorMessage = error.localizedDescription
//            print("Service test error:", error)
//        }
//    }
//}
