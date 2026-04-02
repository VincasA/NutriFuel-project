//
//  NutritionCalculator.swift
//  NutriFuel
//

import Foundation

struct NutritionCalculator {

    struct DayTotals {
        var calories: Double = 0
        var protein: Double = 0
        var carbs: Double = 0
        var fat: Double = 0
        var fiber: Double = 0
        var sugar: Double = 0
        var sodium: Double = 0
    }

    static func totals(for entries: [LogEntry]) -> DayTotals {
        var result = DayTotals()
        for entry in entries {
            result.calories += entry.totalCalories
            result.protein += entry.totalProtein
            result.carbs += entry.totalCarbs
            result.fat += entry.totalFat
            result.fiber += entry.totalFiber
            result.sugar += entry.totalSugar
            result.sodium += entry.totalSodium
        }
        return result
    }

    static func progress(_ current: Double, goal: Double) -> Double {
        guard goal > 0 else { return 0 }
        return min(current / goal, 1.0)
    }

    static func remaining(_ current: Double, goal: Double) -> Double {
        max(goal - current, 0)
    }

    static func macroPercentages(protein: Double, carbs: Double, fat: Double) -> (proteinPct: Double, carbsPct: Double, fatPct: Double) {
        let totalCalFromMacros = (protein * 4) + (carbs * 4) + (fat * 9)
        guard totalCalFromMacros > 0 else { return (0, 0, 0) }
        return (
            proteinPct: (protein * 4) / totalCalFromMacros * 100,
            carbsPct: (carbs * 4) / totalCalFromMacros * 100,
            fatPct: (fat * 9) / totalCalFromMacros * 100
        )
    }

    /// Returns the start of the given date (midnight).
    static func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    /// Returns the end of the given date (23:59:59).
    static func endOfDay(_ date: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfDay(date))!.addingTimeInterval(-1)
    }
}
