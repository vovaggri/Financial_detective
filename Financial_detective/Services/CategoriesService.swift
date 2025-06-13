final class CategoriesService {
    private let allCategories: [Category] = [
        Category(id: 1, name: "Зарплата", emoji: "💵", direction: .income),
        Category(id: 2, name: "Кофе", emoji: "☕️", direction: .outcome),
        Category(id: 3, name: "Продукты", emoji: "🛒", direction: .outcome),
        Category(id: 4, name: "Подарки", emoji: "🎁", direction: .outcome),
        Category(id: 5, name: "Подработка", emoji: "👨‍💻", direction: .income)
    ]
    
    func categories() async throws -> [Category] {
        return allCategories
    }
    
    func categories(direction: Direction) async throws -> [Category] {
        return allCategories.filter { $0.direction == direction }
    }
}
