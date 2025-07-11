import UIKit

final class AnalysisViewController: UIViewController {

    // MARK: — UI

    private let headerContainer = UIView()
    private let startPicker = UIDatePicker()
    private let endPicker = UIDatePicker()
    private let sumLabel = UILabel()

    private let tableView = UITableView(frame: .zero, style: .plain)

    // MARK: — VM

    private let viewModel: AnalysisViewModel

    // MARK: — Init

    init(viewModel: AnalysisViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: — Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Анализ"

        let backItem = UIBarButtonItem(
            title: "Назад",
            style: .plain,
            target: self,
            action: #selector(didTapBack)
        )
        backItem.tintColor = UIColor(hex: "#6F5DB7") ?? .systemPurple
        navigationItem.leftBarButtonItem = backItem
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemGray6
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        view.backgroundColor = .systemGray6

        configurePickers()
        configureSumLabel()
        setupHeader()
        setupTableView()
        bindViewModel()
    }

    // MARK: — Setup Header

    private func setupHeader() {
        headerContainer.backgroundColor = .systemBackground
        headerContainer.layer.cornerRadius = 12
        view.addSubview(headerContainer)
        headerContainer.translatesAutoresizingMaskIntoConstraints = false

        // строки
        let row1 = labeledRow(title: "Период: начало", view: startPicker)
        let row2 = labeledRow(title: "Период: конец", view: endPicker)
        let row3 = labeledRow(title: "Сумма", view: sumLabel)

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
            row3
        ])
        stack.axis = .vertical
        stack.spacing = 9   // <-- увеличили расстояние между всеми элементами

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

    private func configurePickers() {
        [startPicker, endPicker].forEach {
            $0.datePickerMode = .date
            $0.preferredDatePickerStyle = .compact
            $0.addTarget(self, action: #selector(didChangeDate(_:)), for: .valueChanged)
            // даём им фиксированную ширину и включаем interaction
            $0.widthAnchor.constraint(equalToConstant: 138).isActive = true
            $0.heightAnchor.constraint(equalToConstant: 34).isActive = true
            $0.isUserInteractionEnabled = true
        }
        startPicker.date = viewModel.startDate
        endPicker.date   = viewModel.endDate
    }

    private func configureSumLabel() {
        sumLabel.font = .systemFont(ofSize: 17)
        sumLabel.textAlignment = .right
        // сразу прописываем начальную сумму
        let total = viewModel.transactions.map(\.amount).reduce(0, +)
        sumLabel.text = total.formatted(
            .currency(code: viewModel.transactions.first?.account.currency ?? "RUB")
        )
    }

    // MARK: — Setup Table

    private func setupTableView() {
        tableView.dataSource = self
        tableView.register(TransactionCell.self, forCellReuseIdentifier: "TxCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(
                equalTo: headerContainer.bottomAnchor,
                constant: 16
            ),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),
        ])
        tableView.backgroundColor = .clear
        tableView.separatorInset = .init(top: 0, left: 16, bottom: 0, right: 16)
    }

    // MARK: — Bind VM

    private func bindViewModel() {
        viewModel.onTransactionChange = { [weak self] _ in
            self?.tableView.reloadData()
        }
        viewModel.onTotalAmountChange = { [weak self] total in
            guard let self = self else { return }
            self.sumLabel.text = total.formatted(
                .currency(code: self.viewModel.transactions.first?.account.currency ?? "RUB")
            )
        }
        viewModel.onError = { print("Ошибка:", $0) }
        viewModel.loadTransactions()
    }

    // MARK: — Actions

    @objc private func didChangeDate(_ sender: UIDatePicker) {
        if sender === startPicker {
            viewModel.startDate = sender.date
            if sender.date > endPicker.date {
                endPicker.date = sender.date
            }
        } else {
            viewModel.endDate = sender.date
            if sender.date < startPicker.date {
                startPicker.date = sender.date
            }
        }
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
        cell.configure(with: tx)
        return cell
    }
}
