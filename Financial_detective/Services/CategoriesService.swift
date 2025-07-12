final class CategoriesService {
    private let allCategories: [Category] = [
        Category(id: 1, name: "Зарплата", emoji: "💵", direction: .income),
        Category(id: 2, name: "Кофе", emoji: "☕️", direction: .outcome),
        Category(id: 3, name: "Продукты", emoji: "🛒", direction: .outcome),
        Category(id: 4, name: "Подарки", emoji: "🎁", direction: .outcome),
        Category(id: 5, name: "Подработка", emoji: "👨‍💻", direction: .income),
        Category(id: 6, name: "Аптека", emoji: "💜", direction: .outcome),
        Category(id: 7, name: "Аренда квартиры", emoji: "🏠", direction: .outcome),
        Category(id: 8, name: "Обед", emoji: "🍔", direction: .outcome)
    ]
    
    func categories() async throws -> [Category] {
        return allCategories
    }
    
    func categories(direction: Direction) async throws -> [Category] {
        return allCategories.filter { $0.direction == direction }
    }
}
