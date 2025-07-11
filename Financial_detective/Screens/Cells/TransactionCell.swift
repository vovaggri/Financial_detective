import UIKit

final class TransactionCell: UITableViewCell {
    private let emojiContainerView = UIView()
    private let emojiLabel = UILabel()
    private let nameLabel = UILabel()
    private let commentLabel = UILabel()
    private let percentLabel = UILabel()
    private let amountLabel = UILabel()
    private let chevronImageView = UIImageView(
        image: UIImage(systemName: "chevron.forward")
    )
    private let hStack = UIStackView()
    
    private var allAmount: Decimal = 0.0
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        emojiLabel.font = .systemFont(ofSize: 14.5)
        emojiLabel.textAlignment = .center
        
        nameLabel.font = .systemFont(ofSize: 17)
        
        commentLabel.font = .systemFont(ofSize: 15)
        commentLabel.textColor = .secondaryLabel
        
        percentLabel.textAlignment = .right
        percentLabel.font = .systemFont(ofSize: 17)
        amountLabel.textAlignment = .right
        amountLabel.font = .systemFont(ofSize: 17)
        
        // Настраиваем chevron
        chevronImageView.tintColor = .secondaryLabel
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        chevronImageView.setContentHuggingPriority(.required, for: .horizontal)
        chevronImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        // Emoji Container
        emojiContainerView.backgroundColor = UIColor(red: 212/255, green: 250/255, blue: 230/255, alpha: 1) // #D4FAE6
        emojiContainerView.layer.cornerRadius = 16
        emojiContainerView.translatesAutoresizingMaskIntoConstraints = false
        emojiContainerView.widthAnchor.constraint(equalToConstant: 32).isActive = true
        emojiContainerView.heightAnchor.constraint(equalToConstant: 32).isActive = true
        
        emojiContainerView.addSubview(emojiLabel)
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emojiLabel.centerXAnchor.constraint(equalTo: emojiContainerView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: emojiContainerView.centerYAnchor)
        ])
        
        let textStack = UIStackView(arrangedSubviews: [nameLabel, commentLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        
        let secTextStack = UIStackView(arrangedSubviews: [percentLabel, amountLabel])
        secTextStack.axis = .vertical
        secTextStack.spacing = 4
        
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = 8
        hStack.addArrangedSubview(emojiContainerView)
        hStack.addArrangedSubview(textStack)
        hStack.addArrangedSubview(secTextStack)
        hStack.addArrangedSubview(chevronImageView)
        
        contentView.addSubview(hStack)
        hStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            hStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            hStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            hStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with transaction: Transaction, _ totalAmount: Decimal) {
        emojiLabel.text   = String(transaction.category.emoji)
        nameLabel.text    = transaction.category.name
        commentLabel.text = transaction.comment ?? ""
        
        let amount = transaction.amount
        let intPart = NSDecimalNumber(decimal: amount).intValue
        let fracDecimal = (amount - Decimal(intPart)) * 100
        let fracPart = NSDecimalNumber(decimal: fracDecimal).intValue
        
        let amountString: String
        if fracPart == 0 {
            amountString = "\(intPart)"
        } else {
            amountString = "\(intPart),\(String(format: "%02d", fracPart))"
        }
        
        // 3) Получаем символ валюты (₽ для RUB, $ для USD и т.п.)
        let currencySymbol: String = {
            switch transaction.account.currency {
            case "RUB": return "₽"
            case "USD": return "$"
            case "EUR": return "€"
            default:    return transaction.account.currency
            }
        }()
        
        // 4) Собираем финальную строку: число + пробел + символ
        amountLabel.text = "\(amountString) \(currencySymbol)"  // неразрывный пробел
        
        // ————————————————————————————
        // Процент как и раньше (целая часть)
        let fraction: Decimal = transaction.amount / totalAmount
        percentLabel.text = fraction.formatted(
            .percent
                .precision(.fractionLength(0))
        )
    }
}
