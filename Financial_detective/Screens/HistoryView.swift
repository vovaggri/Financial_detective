import SwiftUI

struct HistoryView: View {
    @StateObject var vm: HistoryViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showForm = false
    @State private var editingTx: Transaction?
    
    private let client: NetworkClient = {
        do {
            return try NetworkClient(token: "")
        } catch {
            fatalError("Не смогли инициализировать NetworkClient: \(error)")
        }
    }()
    
    let accent = Color("AccentColor")

    var body: some View {
        Form {
            Section() {
                HStack {
                    Text("Начало")
                    Spacer()
                    DatePicker(
                        "",
                        selection: $vm.startDate,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .tint(accent)
                    .padding(.vertical, 1)    
                    .padding(.horizontal, 1)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(accent.opacity(0.12))
                    )
                }
                HStack {
                    Text("Конец")
                    Spacer()
                    DatePicker(
                        "",
                        selection: $vm.endDate,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .tint(accent)
                    .padding(.vertical, 1)
                    .padding(.horizontal, 1)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(accent.opacity(0.12))
                    )
                }
                HStack {
                    Text("Сумма")
                    Spacer()
                    Text(vm.totalAmount.formatted(.currency(code: vm.transactions.first?.account.currency ?? "RUB")))
                }
            }

            Section(header: Text("ОПЕРАЦИИ")) {
                List(vm.transactions) { tx in
                    Button {
                        editingTx = tx
                    } label: {
                        HistoryTransactionRow(tx: tx)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .fullScreenCover(item: $editingTx, onDismiss: {
            Task { await vm.loadHistory() }
        }) { tx in
            TransactionFormView(
                transaction: tx,
                direction: vm.direction,
                accountId: vm.accountId,
                transactionsService: vm.service,
                categoriesService: CategoriesService(client: vm.client),
                bankAccountsService: BankAccountsService(client: vm.client)
            )
            .interactiveDismissDisabled()
        }
        .background(Color(.systemGray6).ignoresSafeArea())
        .navigationTitle("Моя история")
        .navigationBarTitleDisplayMode(.large)
        
        // Скрываем стандартный back
        .navigationBarBackButtonHidden(true)
        
        // Вставляем свой
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.backward")
                        Text("Назад")
                    }
                }
                .foregroundColor(Color(red: 0x6F/255,
                                       green: 0x5D/255,
                                       blue: 0xB7/255))
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    let viewModel = AnalysisViewModel(client: client, service: vm.service, direction: vm.direction, accountId: vm.accountId)
                    AnalysisViewControllerRepresentable(viewModel: viewModel)
                        .ignoresSafeArea()
                        .navigationBarTitleDisplayMode(.large)
                        .navigationTitle("Анализ")
                } label: {
                    Image(systemName: "document")
                        .foregroundColor(Color(red: 0x6F/255, green: 0x5D/255, blue: 0xB7/255))
                }
            }
        }
        
        .onChange(of: vm.startDate) { newStart in
            if newStart > vm.endDate {
                vm.endDate = newStart
            }
            Task {
                await vm.loadHistory()
            }
        }
        .onChange(of: vm.endDate) { newEnd in
            if newEnd < vm.startDate {
                vm.startDate = newEnd
            }
            Task {
                await vm.loadHistory()
            }
        }
        .background(Color(.systemGray6).ignoresSafeArea())
    }
}

private struct HistoryTransactionRow: View {
    let tx: Transaction

    var body: some View {
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
            VStack(alignment: .trailing) {
                Text(tx.amount.formatted(.currency(code: tx.account.currency)))
                Text(tx.transactionDate, style: .time)
                    .font(.caption)
            }
        }
    }
}
