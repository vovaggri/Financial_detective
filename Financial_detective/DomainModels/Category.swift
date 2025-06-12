enum Direction {
    case income
    case outcome
}

struct Category {
    let id: Int
    var name: String
    var emoji: String
    var direction: Direction
    
    var isIncome: Bool {
        direction == .income
    }
}
