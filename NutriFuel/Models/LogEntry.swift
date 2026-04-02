//
//  LogEntry.swift
//  NutriFuel
//

import Foundation
import SwiftData

enum MealType: String, CaseIterable, Codable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snacks"

    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "cup.and.saucer.fill"
        }
    }
}

@Model
final class LogEntry {
    var id: UUID
    var food: Food?
    var officialFood: OfficialFood?
    var quantity: Double
    var mealTypeRaw: String
    var date: Date

    var mealType: MealType {
        get { MealType(rawValue: mealTypeRaw) ?? .snack }
        set { mealTypeRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        food: Food,
        quantity: Double = 1.0,
        mealType: MealType = .breakfast,
        date: Date = Date()
    ) {
        self.id = id
        self.food = food
        self.officialFood = nil
        self.quantity = quantity
        self.mealTypeRaw = mealType.rawValue
        self.date = date
    }

    init(
        id: UUID = UUID(),
        officialFood: OfficialFood,
        quantity: Double = 1.0,
        mealType: MealType = .breakfast,
        date: Date = Date()
    ) {
        self.id = id
        self.food = nil
        self.officialFood = officialFood
        self.quantity = quantity
        self.mealTypeRaw = mealType.rawValue
        self.date = date
    }

    // MARK: - Computed Nutrition

    private var nutritionSource: (any NutritionProviding)? {
        if let food { return food }
        if let officialFood { return officialFood }
        return nil
    }

    var foodDisplayName: String {
        nutritionSource?.displayName ?? "Unknown"
    }

    var servingSize: Double {
        nutritionSource?.servingSize ?? 0
    }

    var servingUnit: String {
        nutritionSource?.servingUnit ?? "g"
    }

    var totalCalories: Double {
        (nutritionSource?.calories ?? 0) * quantity
    }

    var totalProtein: Double {
        (nutritionSource?.protein ?? 0) * quantity
    }

    var totalCarbs: Double {
        (nutritionSource?.carbohydrates ?? 0) * quantity
    }

    var totalFat: Double {
        (nutritionSource?.fat ?? 0) * quantity
    }

    var totalFiber: Double {
        (nutritionSource?.fiber ?? 0) * quantity
    }

    var totalSugar: Double {
        (nutritionSource?.sugar ?? 0) * quantity
    }

    var totalSodium: Double {
        (nutritionSource?.sodium ?? 0) * quantity
    }
}
