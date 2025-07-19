enum Direction: String, Codable {
    case income
    case outcome
}

struct Category: Identifiable, Codable {
    let id: Int
    var name: String
    var emoji: Character
    var direction: Direction
    
    var isIncome: Bool {
        direction == .income
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, name, emoji, isIncome
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id   = try container.decode(Int.self,    forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        
        let emojiString = try container.decode(String.self, forKey: .emoji)
        guard let ch = emojiString.first else {
            throw DecodingError.dataCorruptedError(
                forKey: .emoji,
                in: container,
                debugDescription: "Expected non-empty string for emoji"
            )
        }
        emoji = ch
        
        let inc = try container.decode(Bool.self, forKey: .isIncome)
        direction = inc ? .income : .outcome
    }
    
    // Новый memberwise-инициализатор
    init(id: Int, name: String, emoji: Character, direction: Direction) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.direction = direction
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id,       forKey: .id)
        try container.encode(name,     forKey: .name)
        try container.encode(String(emoji), forKey: .emoji)
        try container.encode(isIncome, forKey: .isIncome)
    }
}

