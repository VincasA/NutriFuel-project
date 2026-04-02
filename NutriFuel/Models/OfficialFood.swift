import Foundation
import SwiftData

@Model
final class OfficialFood {
    var id: UUID
    @Attribute(.unique) var fdcId: Int
    var gtinUpc: String
    var name: String
    var brandOwner: String?
    var servingSize: Double
    var servingUnit: String
    var calories: Double
    var protein: Double
    var carbohydrates: Double
    var fat: Double
    var fiber: Double?
    var sugar: Double?
    var sodium: Double?
    var potassium: Double?
    var calcium: Double?
    var iron: Double?
    var vitaminC: Double?
    var vitaminD: Double?
    var lastSyncedAt: Date
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \LogEntry.officialFood)
    var logEntries: [LogEntry]?

    init(
        id: UUID = UUID(),
        fdcId: Int,
        gtinUpc: String,
        name: String,
        brandOwner: String? = nil,
        servingSize: Double = 100,
        servingUnit: String = "g",
        calories: Double = 0,
        protein: Double = 0,
        carbohydrates: Double = 0,
        fat: Double = 0,
        fiber: Double? = nil,
        sugar: Double? = nil,
        sodium: Double? = nil,
        potassium: Double? = nil,
        calcium: Double? = nil,
        iron: Double? = nil,
        vitaminC: Double? = nil,
        vitaminD: Double? = nil,
        lastSyncedAt: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.fdcId = fdcId
        self.gtinUpc = gtinUpc
        self.name = name
        self.brandOwner = brandOwner
        self.servingSize = servingSize
        self.servingUnit = servingUnit
        self.calories = calories
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.potassium = potassium
        self.calcium = calcium
        self.iron = iron
        self.vitaminC = vitaminC
        self.vitaminD = vitaminD
        self.lastSyncedAt = lastSyncedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var displayName: String {
        if let brandOwner, !brandOwner.isEmpty {
            return "\(name) (\(brandOwner))"
        }
        return name
    }
}

extension OfficialFood: NutritionProviding {
    var brandLabel: String? { brandOwner }
}
