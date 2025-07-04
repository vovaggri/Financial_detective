import SwiftUI

@MainActor
final class CategoriesViewModel: ObservableObject {
    @Published var allCategories: [Category] = []
    @Published var searchText: String = ""
    
    private let service = CategoriesService()
    
    func loadCategories() async {
        do {
            allCategories = try await service.categories()
        } catch {
            print("Failed loading categories: ", error)
        }
    }
    
    var filteredCategories: [Category] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return allCategories
        }
        return allCategories.filter { category in
            category.name.fuxxyMatches(query)
        }
    }
}
