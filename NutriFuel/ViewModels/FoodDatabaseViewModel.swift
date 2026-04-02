//
//  FoodDatabaseViewModel.swift
//  NutriFuel
//

import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class FoodDatabaseViewModel {
    var searchText: String = "" {
        didSet { fetchFoods() }
    }
    var foods: [Food] = []

    private let foodRepository: FoodRepository
    private let defaultFetchLimit: Int

    init(foodRepository: FoodRepository, defaultFetchLimit: Int = 200) {
        self.foodRepository = foodRepository
        self.defaultFetchLimit = defaultFetchLimit
        fetchFoods()
    }

    convenience init(modelContext: ModelContext, defaultFetchLimit: Int = 200) {
        self.init(
            foodRepository: SwiftDataFoodRepository(modelContext: modelContext),
            defaultFetchLimit: defaultFetchLimit
        )
    }

    func fetchFoods() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        foods = foodRepository.fetchFoods(
            matching: query.isEmpty ? nil : query,
            limit: defaultFetchLimit
        )
    }

    func addFood(_ food: Food) {
        foodRepository.insert(food)
        save()
        fetchFoods()
    }

    func deleteFood(_ food: Food) {
        foodRepository.delete(food)
        save()
        fetchFoods()
    }

    func findFoodsByBarcode(_ barcode: String) -> [Food] {
        foodRepository.findFoodsByBarcode(barcode)
    }

    func save() {
        try? foodRepository.save()
    }
}
