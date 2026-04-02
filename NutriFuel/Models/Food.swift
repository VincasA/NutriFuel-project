//
//  Food.swift
//  NutriFuel
//

import Foundation
import SwiftData

@Model
final class Food {
    var id: UUID
    var name: String
    var brand: String?
    var isListedInDatabase: Bool?
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
    var barcode: String?
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \LogEntry.food)
    var logEntries: [LogEntry]?

    init(
        id: UUID = UUID(),
        name: String,
        brand: String? = nil,
        isListedInDatabase: Bool = true,
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
        barcode: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.isListedInDatabase = isListedInDatabase
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
        self.barcode = barcode
        self.createdAt = createdAt
    }

    var displayName: String {
        if let brand = brand, !brand.isEmpty {
            return "\(name) (\(brand))"
        }
        return name
    }

    var isVisibleInDatabase: Bool {
        isListedInDatabase ?? true
    }
}

extension Food: NutritionProviding {
    var brandLabel: String? { brand }
}
