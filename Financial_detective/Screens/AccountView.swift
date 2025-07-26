import SwiftUI

let allCurrencyOptions: [CurrencyOption] = [
    .init(code: "RUB", name: "Российский рубль", symbol: "₽"),
    .init(code: "USD", name: "Американский доллар", symbol: "$"),
    .init(code: "EUR", name: "Евро", symbol: "€"),
]

struct AccountView: View {
    @StateObject private var vm = AccountViewModel()
    @FocusState private var amountFieldFocused: Bool
    @State private var textBalance: String = ""
    @State private var isShakeEnabled = true
    
    private let currencyDict: [String: CurrencyOption] = {
        Dictionary(uniqueKeysWithValues:
                    allCurrencyOptions.map { ($0.code, $0) }
        )
    }()
    
    private func option(for code: String) -> CurrencyOption {
        currencyDict[code]
        ?? CurrencyOption(code: code, name: code, symbol: "")
    }
    
    var body: some View {
        ZStack {
            // MARK: — ShakeDetector на весь экран
            ShakeDetectorView {
                guard !vm.isEditing else { return }
                vm.toggleBalanceHidden()
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            
            // MARK: — Основной NavigationView + Form
            NavigationView {
                Form {
                    if let account = vm.account {
                        BalanceSection(
                            isEditing: vm.isEditing,
                            isBalanceHidden: vm.isBalanceHidden,
                            textBalance: $textBalance,
                            amountFieldFocused: $amountFieldFocused,
                            account: account,
                            option: option
                        )
                        // Валюта
                        Section(header: EmptyView(), footer: EmptyView()) {
                            HStack {
                                Text("Валюта")
                                Spacer()
                                let opt = option(for: account.currency)
                                if vm.isEditing {
                                    Text(opt.symbol).foregroundColor(.secondary)
                                    Image(systemName: "chevron.forward")
                                        .foregroundColor(.secondary)
                                } else {
                                    Text(opt.symbol)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if vm.isEditing {
                                    vm.showCurrencyPicker.toggle()
                                }
                            }
                        }
                        .listRowBackground(
                            vm.isEditing
                            ? Color(.systemBackground)
                            : Color(red: 212/255, green: 250/255, blue: 230/255)
                        )
                        .listRowSeparator(.hidden)
                        // **График баланса**
                        if !vm.isEditing {
                            // Сам график
                            BalanceHistoryChartView(
                                currentBalance: Decimal(string: account.balance) ?? 0,
                                transactions: vm.txHistory, currencySymbol: vm.account?.currency ?? "₽"
                            )
                            .onAppear { Task { await vm.loadHistory() } }
                            .padding(.horizontal, 5)
                            .listRowInsets(EdgeInsets())
                            // Убираем встроенные разделители у Form
                            .listRowSeparator(.hidden)
                            // Задаём фон «ячейки» (или .clear)
                            .listRowBackground(Color(.systemGray6))
                        }
                    } else {
                        ProgressView()
                    }
                }
                .listStyle(.plain)
                .refreshable { await vm.refresh() }
                .navigationTitle("Мой счёт")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        let title = vm.isEditing ? "Сохранить" : "Редактировать"
                        Button(title) {
                            if vm.isEditing {
                                Task { await vm.saveChanges(newBalance: textBalance) }
                            } else {
                                if let account = vm.account {
                                    textBalance = account.balance
                                }
                                vm.toogleEdit()
                            }
                        }
                        .tint(Color(red: 0x6F/255, green: 0x5D/255, blue: 0xB7/255))
                    }
                }
                .confirmationDialog(
                    "Валюта",
                    isPresented: $vm.showCurrencyPicker,
                    titleVisibility: .visible
                ) {
                    ForEach(allCurrencyOptions) { opt in
                        Button("\(opt.name) \(opt.symbol)") {
                            vm.selectCurrency(opt.code)
                        }
                    }
                    Button("Отмена", role: .cancel) {}
                }
                .onChange(of: vm.isEditing) { editing in
                    isShakeEnabled = !editing
                }
            }
        }
    }
}

private struct BalanceSection: View {
    let isEditing: Bool
    let isBalanceHidden: Bool
    @Binding var textBalance: String
    var amountFieldFocused: FocusState<Bool>.Binding
    var account: BankAccount
    let option: (String) -> CurrencyOption

    var body: some View {
        Section(header: EmptyView(), footer: EmptyView()) {
            HStack {
                Text("💰   Баланс")
                Spacer()
                if isEditing {
                    TextField("Сумма", text: $textBalance)
                        .keyboardType(.decimalPad)
                        .focused(amountFieldFocused)
                        .multilineTextAlignment(.trailing)
                    // onChange logic можно добавить здесь, если нужно
                } else {
                    HStack(spacing: 0) {
                        Text(account.balance)
                            .modifier(SpoilerModifier(isActive: isBalanceHidden))
                        Text(" \(option(account.currency).symbol)")
                    }
                    .opacity(isBalanceHidden ? 0.7 : 1)
                }
            }
        }
        .listRowBackground(
            isEditing
            ? Color(.systemBackground)
            : Color(red: 42/255, green: 232/255, blue: 129/255)
        )
        .listRowSeparator(.hidden)
    }
}

//#Preview {
//    AccountView()
//}



