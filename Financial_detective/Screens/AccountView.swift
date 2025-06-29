import SwiftUI

let allCurrencyOptions: [CurrencyOption] = [
    .init(code: "RUB", name: "Российский рубль", symbol: "₽"),
    .init(code: "USD", name: "Американский доллар", symbol: "$"),
    .init(code: "EUR", name: "Евро", symbol: "€"),
]

struct AccountView: View {
    @StateObject private var vm = AccountViewModel()
    @FocusState private var amountFieldFocused: Bool
    
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
        NavigationView {
            Form {
                if let account = vm.account {
                    Section(header: EmptyView(), footer: EmptyView()) {
                        HStack {
                            Text("💰   Баланс")
                            Spacer()
                            
                            let opt = option(for: account.currency)
                            if vm.isEditing {
                                TextField(
                                    "Сумма",
                                    value: Binding(
                                        get: { account.balance },
                                        set: { vm.account?.balance = $0 }
                                    ),
                                    format: .number.precision(.fractionLength(0...2))
                                )
                                .foregroundColor(.secondary)
                                .keyboardType(.decimalPad)
                                .focused($amountFieldFocused)
                                .multilineTextAlignment(.trailing)
                            } else {
                                let formatted = Text(
                                    account.balance,
                                    format: .number.precision(.fractionLength(0...2))
                                )
                                
                                formatted
                                    .multilineTextAlignment(.trailing)
                                
                                Text(opt.symbol)
                            }
                        }
                    }
                    .listRowBackground(
                        vm.isEditing ? Color(UIColor.systemBackground) : Color(
                            red: 42/255,
                            green: 232/255,
                            blue: 129/255
                        )
                    )
                    .listRowSeparator(.hidden)
                    
                    Section(header: EmptyView(), footer: EmptyView()) {
                        HStack {
                            Text("Валюта")
                            Spacer()
                            let opt = option(for: account.currency)
                            if vm.isEditing {
                                Text(opt.symbol).foregroundColor(.secondary)
                                Image(systemName: "chevron.forward").foregroundColor(.secondary)
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
                        vm.isEditing ? Color(UIColor.systemBackground) : Color(
                            red: 212/255,
                            green: 250/255,
                            blue: 230/255
                        )
                    )
                    .listRowSeparator(.hidden)
                } else {
                    ProgressView()
                }
                
            }
            .listStyle(.plain)
            .navigationTitle("Мой счет")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    let title = vm.isEditing ? "Сохранить" : "Редактировать"
                    
                    Button(title) {
                        if vm.isEditing {
                            Task { await vm.saveChanges() }
                        } else {
                            vm.toogleEdit()
                        }
                    }
                    .tint(
                        Color(
                            red: 0x6F/255,
                            green: 0x5D/255,
                            blue: 0xB7/255
                        )
                    )
                }
            }
            .confirmationDialog("Валюта", isPresented: $vm.showCurrencyPicker, titleVisibility: .visible) {
                ForEach(allCurrencyOptions) { option in
                    Button("\(option.name) \(option.symbol)") {
                        vm.selectCurrency(option.code)
                    }
                }
                Button("Отмена", role: .cancel) {}
            }
        }
    }
}

#Preview {
    AccountView()
}


