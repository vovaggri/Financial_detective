import UIKit
import PieChart

final class AnalysisViewController: UIViewController {

    // MARK: — UI

    private let headerContainer = UIView()
    private let startPicker = UIDatePicker()
    private let endPicker = UIDatePicker()
    private let sumLabel = UILabel()
    private let transactionsLabel = UILabel()

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let tableContainerView = UIView()
    
    private let sortControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Дата", "Сумма"])
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()
    
    private var tableViewHeightConstraint: NSLayoutConstraint!

    // MARK: — VM

    let viewModel: AnalysisViewModel
    let pieChartView = PieChartView()
    public let client: NetworkClient

    // MARK: — Init

    init(viewModel: AnalysisViewModel, client: NetworkClient) {
        self.viewModel = viewModel
        self.client = client
        super.init(nibName: nil, bundle: nil)
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: — Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemGray6

        configurePickers()
        sortControl.addTarget(self, action: #selector(didChangeSorting(_:)), for: .valueChanged)
        configureSumLabel()
        setupHeader()
        configurePieChartView()
        view.addSubview(transactionsLabel)
        configureTransactionsLabel()
        setupTableView()
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadTransactions()
      }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableViewHeightConstraint.constant = tableView.contentSize.height
    }

    // MARK: — Setup Header

    private func setupHeader() {
        headerContainer.backgroundColor = .systemBackground
        headerContainer.layer.cornerRadius = 12
        headerContainer.layer.masksToBounds = true
        view.addSubview(headerContainer)
        headerContainer.translatesAutoresizingMaskIntoConstraints = false

        // строки
        let row1 = labeledRow(title: "Период: начало", view: startPicker)
        let row2 = labeledRow(title: "Период: конец", view: endPicker)
        let row3 = labeledRow(title: "Сортировка", view: sortControl)
        let row4 = labeledRow(title: "Сумма", view: sumLabel)

        // сепаратор
        func sep() -> UIView {
            let v = UIView()
            v.backgroundColor = .separator
            v.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                v.heightAnchor.constraint(equalToConstant: 1.0/UIScreen.main.scale)
            ])
            return v
        }

        // теперь с spacing = 12
        let stack = UIStackView(arrangedSubviews: [
            row1, sep(),
            row2, sep(),
            row3, sep(),
            row4
        ])
        stack.axis = .vertical
        stack.spacing = 9 

        headerContainer.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // карточка
            headerContainer.topAnchor.constraint(
              equalTo: view.topAnchor,
              constant: 150
            ),
            headerContainer.leadingAnchor.constraint(
              equalTo: view.leadingAnchor,
              constant: 16
            ),
            headerContainer.trailingAnchor.constraint(
              equalTo: view.trailingAnchor,
              constant: -16
            ),

            // внутренние отступы карточки увеличены до 12
            stack.topAnchor.constraint(
              equalTo: headerContainer.topAnchor,
              constant: 7
            ),
            stack.leadingAnchor.constraint(
              equalTo: headerContainer.leadingAnchor,
              constant: 16
            ),
            stack.trailingAnchor.constraint(
              equalTo: headerContainer.trailingAnchor,
              constant: -12
            ),
            stack.bottomAnchor.constraint(
              equalTo: headerContainer.bottomAnchor,
              constant: -12
            ),
        ])
    }


    private func labeledRow(title: String, view: UIView) -> UIStackView {
        let lbl = UILabel()
        lbl.text = title
        lbl.font = .systemFont(ofSize: 16)
        let row = UIStackView(arrangedSubviews: [lbl, view])
        row.axis = .horizontal
        row.distribution = .equalSpacing
        view.translatesAutoresizingMaskIntoConstraints = false
        return row
    }
    
    private func configurePieChartView() {
        view.addSubview(pieChartView)
        pieChartView.translatesAutoresizingMaskIntoConstraints = false
        pieChartView.pinTop(to: headerContainer.bottomAnchor, 16)
        pieChartView.pinLeft(to: view, 20)
        pieChartView.pinRight(to: view, 20)
        pieChartView.setHeight(200)
    }
    
    private func configurePickers() {
        let green = UIColor(hex: "D4FAE6")
        
        [startPicker, endPicker].forEach { picker in
            picker.datePickerMode = .date
            picker.preferredDatePickerStyle = .compact
            picker.addTarget(self, action: #selector(didChangeDate(_:)), for: .valueChanged)
            
            // Фиксированный размер
            picker.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                picker.widthAnchor.constraint(equalToConstant: 138),
                picker.heightAnchor.constraint(equalToConstant: 34)
            ])
            
            // Прозрачный фон для всего пикера
            picker.backgroundColor = .clear
            
            // Находим и стилизуем реальную кнопку
            if let button = findButton(in: picker) {
                button.backgroundColor = green
                button.layer.cornerRadius = 8
                button.clipsToBounds = true
                
                button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
            }
        }
        
        startPicker.date = viewModel.startDate
        endPicker.date   = viewModel.endDate
    }
    
    private func findButton(in view: UIView) -> UIButton? {
        if let button = view as? UIButton {
            return button
        }
        for subview in view.subviews {
            if let button = findButton(in: subview) {
                return button
            }
        }
        return nil
    }

    private func configureSumLabel() {
        sumLabel.font = .systemFont(ofSize: 17)
        sumLabel.textAlignment = .right
        
        // Считаем общую сумму
        let total = viewModel.transactions.map(\.amount).reduce(0, +)
        
        // Целая часть
        let intPart = NSDecimalNumber(decimal: total).intValue
        // Дробная часть (копейки/центы)
        let fracDecimal = (total - Decimal(intPart)) * 100
        let fracPart = NSDecimalNumber(decimal: fracDecimal).intValue
        
        // Формируем строку: либо "350", либо "123,45"
        let amountString: String
        if fracPart == 0 {
            amountString = "\(intPart)"
        } else {
            amountString = "\(intPart),\(String(format: "%02d", fracPart))"
        }
        
        // Подставляем символ валюты по коду (расширьте switch при необходимости)
        let currencyCode = viewModel.transactions.first?.account.currency ?? "RUB"
        let currencySymbol: String = {
            switch currencyCode {
            case "RUB": return "₽"
            case "USD": return "$"
            case "EUR": return "€"
            default:    return currencyCode
            }
        }()
        
        // И финальный текст
        sumLabel.text = "\(amountString) \(currencySymbol)"
    }
    
    private func configureTransactionsLabel() {
        transactionsLabel.text = "ОПЕРАЦИИ"
        transactionsLabel.font = .systemFont(ofSize: 13)
        transactionsLabel.textColor = .secondaryLabel
        
        transactionsLabel.pinTop(to: pieChartView.bottomAnchor, 16)
        transactionsLabel.pinLeft(to: headerContainer.leadingAnchor)
    }

    // MARK: — Setup Table
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TransactionCell.self, forCellReuseIdentifier: "TxCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // 1. Отключаем скролл
        tableView.isScrollEnabled = false
        
        // 2. Контейнер с круглыми углами
        tableContainerView.backgroundColor = .systemBackground
        tableContainerView.layer.cornerRadius = 12
        tableContainerView.layer.masksToBounds = true
        tableContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(tableContainerView)
        tableContainerView.addSubview(tableView)
        
        // 3. Создаём и активируем высотную констрейнт для таблицы
        tableViewHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 0)
        tableViewHeightConstraint.isActive = true
        
        NSLayoutConstraint.activate([
            // контейнер растёт вниз от header
            tableContainerView.topAnchor.constraint(equalTo: transactionsLabel.bottomAnchor, constant: 5),
            tableContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            // не привязываем контейнер к bottom — его высота задаётся содержимым
            
            // tableView внутри контейнера по всем сторонам
            tableView.topAnchor.constraint(equalTo: tableContainerView.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: tableContainerView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: tableContainerView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: tableContainerView.bottomAnchor),
        ])
        
        tableView.separatorInset = .init(top: 0, left: 16, bottom: 0, right: 16)
    }
    
    // MARK: — Bind VM

    private func bindViewModel() {
        viewModel.onTransactionChange = { [weak self] txs in
            guard let self = self else { return }
            // 1) обновляем таблицу
            self.tableView.reloadData()
            
            // 2) группируем по категории и обновляем PieChart
            let grouped = Dictionary(grouping: txs, by: { $0.category.name })
            let entities = grouped.map { key, txs in
                Entity(value: txs.map(\.amount).reduce(0, +), label: key)
            }
            self.pieChartView.entities = entities
        }

        viewModel.onTotalAmountChange = { [weak self] _ in
            self?.configureSumLabel()
        }
        viewModel.onError = { print("Ошибка:", $0) }
        viewModel.loadTransactions()
    }

    // MARK: — Actions

    @objc private func didChangeDate(_ sender: UIDatePicker) {
        let chosen = sender.date
        var newStart = viewModel.startDate
        var newEnd   = viewModel.endDate

        if sender === startPicker {
            // Пользователь поменял начало → 00:00 выбранного дня
            newStart = chosen.atStartOfDay
            // ★ если начало стало позже конца — подтягиваем конец
            if newStart > viewModel.endDate {
                newEnd = chosen.atEndOfDay
            }
        } else {
            // Пользователь поменял конец → 23:59:59 выбранного дня
            newEnd = chosen.atEndOfDay
            // ★ если конец стал раньше начала — подтягиваем начало
            if newEnd < viewModel.startDate {
                newStart = chosen.atStartOfDay
            }
        }

        // 1) обновляем модель
        viewModel.startDate = newStart
        viewModel.endDate   = newEnd

        // 2) обновляем UI обоих пикеров (дата + время, но UI рисует только дату)
        startPicker.setDate(newStart, animated: true)
        endPicker.setDate(newEnd, animated: true)

        // 3) перезагружаем транзакции под новым диапазоном
        viewModel.loadTransactions()
    }
    
    @objc private func didChangeSorting(_ sender: UISegmentedControl) {
        viewModel.sortOption = sender.selectedSegmentIndex == 0 ? .date : .amount
    }
    
    @objc private func didTapBack() {
        navigationController?.popViewController(animated: true)
    }
}

extension AnalysisViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        viewModel.transactions.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let tx   = viewModel.transactions[indexPath.row]
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "TxCell",
            for: indexPath
        ) as! TransactionCell
        cell.configure(with: tx, viewModel.transactions.map(\.amount).reduce(0, +))
        return cell
    }
}
