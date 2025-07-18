import SwiftUI

struct TransactionFormView: View {
    private enum Field: Hashable {
        case amount
        case comment
    }
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: TransactionFormViewModel
    @State private var showValidationAlert = false
    @FocusState private var focusedField: Field?
    
    private let decimalSeparator = Locale.current.decimalSeparator ?? "."
    
    init(transaction: Transaction? = nil,
         direction: Direction,
         accountId: Int,
         transactionsService: TransactionsService,
         categoriesService: CategoriesService,
         bankAccountsService: BankAccountsService
    ) {
        _viewModel = StateObject(
            wrappedValue: TransactionFormViewModel(
                transaction: transaction,
                direction: direction,
                accountId: accountId,
                transactionsService: transactionsService,
                categoriesService: categoriesService,
                bankAccountsService: bankAccountsService
            )
        )
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    // Выбор статьи с chevron
                    Picker("Статья", selection: $viewModel.selectedCategoryId) {
                        ForEach(viewModel.categories) { cat in
                            Text("\(cat.emoji) \(cat.name)").tag(cat.id)
                        }
                    }
                    .pickerStyle(.navigationLink)

                    // Ввод суммы
                    HStack {
                        Text("Сумма")
                        Spacer()
                        TextField("Сумма", text: $viewModel.amountString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        // Фильтр на ввод: только цифры и один разделитель
                            .onChange(of: viewModel.amountString) { newValue in
                                // оставляем только цифры и разделитель
                                let allowed = CharacterSet.decimalDigits
                                    .union(CharacterSet(charactersIn: decimalSeparator))
                                var filtered = newValue.unicodeScalars
                                    .filter { allowed.contains($0) }
                                    .map(Character.init)
                                // не больше одного разделителя
                                if filtered.filter({ String($0) == decimalSeparator }).count > 1 {
                                    // удаляем последний введённый
                                    if let idx = filtered.lastIndex(of: Character(decimalSeparator)) {
                                        filtered.remove(at: idx)
                                    }
                                }
                                let result = String(filtered)
                                if result != newValue {
                                    viewModel.amountString = result
                                }
                            }
                    }

                    // Выбор даты
                    HStack {
                        Text("Дата")
                        Spacer()
                        DatePicker(
                            "",
                            selection: $viewModel.date,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .frame(width: 100, height: 23)
                        .padding(.vertical, 6)
                        .background(Color(red: 212/255,
                                          green: 250/255,
                                          blue: 230/255))
                        .cornerRadius(8)
                    }

                    // Выбор времени
                    HStack {
                        Text("Время")
                        Spacer()
                        DatePicker(
                            "",
                            selection: $viewModel.date,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .frame(width: 45, height: 23)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color(red: 212/255, green: 250/255, blue: 230/255))
                        .cornerRadius(8)
                    }

                    // Комментарий
                    HStack(alignment: .top) {
                        TextField("Комментарий", text: $viewModel.comment)
                            .multilineTextAlignment(.leading)
                    }
                }

                // Кнопка удаления при редактировании
                if viewModel.isEditing {
                    Section {
                        Button(role: .destructive) {
                            Task {
                                try? await viewModel.delete()
                                dismiss()
                            }
                        } label: {
                            Text(
                                viewModel.direction == .outcome
                                ? "Удалить расход"
                                : "Удалить доход"
                            )
                        }
                    }
                }
            }
            .navigationTitle(
                viewModel.isEditing
                ? (viewModel.direction == .outcome ? "Мои Расходы" : "Мои Доходы")
                : (viewModel.direction == .outcome ? "Новый расход" : "Новый доход")
            )
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                        .foregroundStyle(Color(red: 0x6F/255,
                                                     green: 0x5D/255,
                                                     blue: 0xB7/255))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        if viewModel.canSave {
                            Task {
                                try? await viewModel.save()
                                dismiss()
                            }
                        } else {
                            showValidationAlert = true
                        }
                    }
                    .foregroundStyle(Color(red: 0x6F/255,
                                                 green: 0x5D/255,
                                                 blue: 0xB7/255))
                }
            }
            .alert("Неполная форма", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Пожалуйста, заполните все обязательные поля")
            }
            .alert("Ошибка", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { _ in viewModel.errorMessage = nil }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }

            .task { await viewModel.loadData() }
        }
        .background(Color.clear.contentShape(Rectangle())
            .onTapGesture {
                focusedField = nil
            }
        )
    }
}

