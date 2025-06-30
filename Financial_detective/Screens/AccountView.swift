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
                        // Баланс
                        Section(header: EmptyView(), footer: EmptyView()) {
                            HStack {
                                Text("💰   Баланс")
                                Spacer()
                                
                                if vm.isEditing {
                                    TextField("Сумма", text: $textBalance)
                                      .keyboardType(.decimalPad)
                                      .focused($amountFieldFocused)
                                      .multilineTextAlignment(.trailing)
                                      .onChange(of: textBalance) { new in
                                        let sep = Locale.current.decimalSeparator ?? ","
                                        let allowed = CharacterSet.decimalDigits.union(CharacterSet(charactersIn: sep))
                                        let filtered = String(new.unicodeScalars.filter { allowed.contains($0) })
                                        if filtered != new {
                                          textBalance = filtered
                                        }

                                        let normalized = filtered.replacingOccurrences(of: sep, with: ".")
                                        if let dec = Decimal(string: normalized) {
                                          vm.account?.balance = dec
                                        }
                                      }
                                } else {
                                    HStack(spacing: 0) {
                                        Text(
                                            account.balance,
                                            format: .number.precision(.fractionLength(0...2))
                                        )
                                        .modifier(SpoilerModifier(isActive: vm.isBalanceHidden))
                                        Text(" \(option(for: account.currency).symbol)")
                                    }
                                    .opacity(vm.isBalanceHidden ? 0.7 : 1)
                                }
                            }
                        }
                        .listRowBackground(
                            vm.isEditing
                            ? Color(.systemBackground)
                            : Color(red: 42/255, green: 232/255, blue: 129/255)
                        )
                        .listRowSeparator(.hidden)
                        
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
                                Task { await vm.saveChanges() }
                            } else {
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

#Preview {
    AccountView()
}



