import UIKit

final class TransactionCell: UITableViewCell {
    private let emojiLabel = UILabel()
    private let nameLabel = UILabel()
    private let commentLabel = UILabel()
    private let amountLabel = UILabel()
    private let hStack = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        emojiLabel.font = .systemFont(ofSize: 14.5)
        nameLabel.font = .systemFont(ofSize: 17)
        commentLabel.font = .systemFont(ofSize: 15)
        commentLabel.textColor = .secondaryLabel
        amountLabel.textAlignment = .right
        
        let textStack = UIStackView(arrangedSubviews: [nameLabel, commentLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = 12
        hStack.addArrangedSubview(emojiLabel)
        hStack.addArrangedSubview(textStack)
        hStack.addArrangedSubview(amountLabel)
        
        contentView.addSubview(hStack)
        hStack.translatesAutoresizingMaskIntoConstraints = false
        
        hStack.pinTop(to: contentView.topAnchor, 8)
        hStack.pinBottom(to: contentView.bottomAnchor, 8)
        hStack.pinLeft(to: contentView.leadingAnchor, 16)
        hStack.pinRight(to: contentView.trailingAnchor, 16)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with transaction: Transaction) {
        emojiLabel.text = String(transaction.category.emoji)
        nameLabel.text = transaction.category.name
        commentLabel.text = transaction.comment ?? ""
        amountLabel.text = transaction.amount.formatted(.currency(code: transaction.account.currency))
    }
}
