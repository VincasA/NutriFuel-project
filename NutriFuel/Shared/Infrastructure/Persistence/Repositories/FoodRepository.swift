import Foundation
import SwiftData

@MainActor
protocol FoodRepository {
    func fetchFoods(matching query: String?, limit: Int) -> [Food]
    func insert(_ food: Food)
    func delete(_ food: Food)
    func findFoodsByBarcode(_ barcode: String) -> [Food]
    func save() throws
}

@MainActor
final class SwiftDataFoodRepository: FoodRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchFoods(matching query: String?, limit: Int = 200) -> [Food] {
        let trimmedQuery = query?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let fetchLimit = max(limit, 1)
        var descriptor = FetchDescriptor<Food>(
            predicate: #Predicate<Food> { food in
                food.isListedInDatabase != false
            },
            sortBy: [SortDescriptor(\.name), SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = trimmedQuery.isEmpty ? fetchLimit : max(fetchLimit * 5, 200)
        let fetchedFoods = (try? modelContext.fetch(descriptor)) ?? []

        guard !trimmedQuery.isEmpty else {
            return Array(fetchedFoods.prefix(fetchLimit))
        }

        return fetchedFoods
            .filter {
                $0.name.localizedStandardContains(trimmedQuery) ||
                ($0.brand?.localizedStandardContains(trimmedQuery) ?? false) ||
                ($0.barcode?.localizedStandardContains(trimmedQuery) ?? false)
            }
            .prefix(fetchLimit)
            .map { $0 }
    }

    func insert(_ food: Food) {
        modelContext.insert(food)
    }

    func delete(_ food: Food) {
        modelContext.delete(food)
    }

    func findFoodsByBarcode(_ barcode: String) -> [Food] {
        let normalized = OFFProductDTO.normalizeBarcode(barcode)
        guard !normalized.isEmpty else { return [] }

        let descriptor = FetchDescriptor<Food>(
            predicate: #Predicate<Food> { food in
                food.isListedInDatabase != false &&
                food.barcode == normalized
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse), SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func save() throws {
        try modelContext.save()
    }
}
