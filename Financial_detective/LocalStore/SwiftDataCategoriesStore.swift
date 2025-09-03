import SwiftData

@available(iOS 17, *)
actor SwiftDataCategoriesStore {
    private let container: ModelContainer
    init(inMemory: Bool = false) {
        let conf = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        self.container = try! ModelContainer(for: SDCategoryEntity.self, configurations: conf)
    }

    func getAll() throws -> [Category] {
        let ctx = ModelContext(container)
        let rows = try ctx.fetch(FetchDescriptor<SDCategoryEntity>())
        return rows.map { $0.toModel() }
    }

    func replace(for direction: Direction?, with items: [Category]) throws {
        let ctx = ModelContext(container)
        let all = try ctx.fetch(FetchDescriptor<SDCategoryEntity>())
        if let dir = direction {
            all.filter { $0.isIncome == (dir == .income) }.forEach { ctx.delete($0) }
        } else {
            all.forEach { ctx.delete($0) }
        }
        items.forEach { ctx.insert(SDCategoryEntity(from: $0)) }
        try ctx.save()
    }
}
