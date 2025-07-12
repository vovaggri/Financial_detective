enum Direction {
    case income
    case outcome
}

struct Category: Identifiable {
    let id: Int
    var name: String
    var emoji: Character
    var direction: Direction
    
    var isIncome: Bool {
        direction == .income
    }
}
