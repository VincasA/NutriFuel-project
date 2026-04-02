import Foundation

enum FoodCatalogSource: String, CaseIterable, Identifiable {
    case custom
    case officialOpenFoodFacts

    var id: String { rawValue }
}
