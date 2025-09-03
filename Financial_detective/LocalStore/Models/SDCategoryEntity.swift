import SwiftData

@Model
final class SDCategoryEntity {
    @Attribute(.unique) var id: Int
    var name: String
    var emoji: String
    var isIncome: Bool

    init(id: Int, name: String, emoji: String, isIncome: Bool) {
        self.id = id; self.name = name; self.emoji = emoji; self.isIncome = isIncome
    }
}

extension SDCategoryEntity {
    convenience init(from c: Category) {
        self.init(id: c.id, name: c.name, emoji: String(c.emoji), isIncome: c.isIncome)
    }
    func toModel() -> Category {
        Category(id: id, name: name, emoji: emoji.first ?? "❓", direction: isIncome ? .income : .outcome)
    }
}
