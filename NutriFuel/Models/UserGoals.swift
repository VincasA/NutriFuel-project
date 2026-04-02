//
//  UserGoals.swift
//  NutriFuel
//

import Foundation
import SwiftData

@Model
final class UserGoals {
    var id: UUID
    var calorieGoal: Double
    var proteinGoal: Double
    var carbsGoal: Double
    var fatGoal: Double
    var fiberGoal: Double?
    var sugarGoal: Double?
    var sodiumGoal: Double?

    init(
        id: UUID = UUID(),
        calorieGoal: Double = 2000,
        proteinGoal: Double = 150,
        carbsGoal: Double = 250,
        fatGoal: Double = 65,
        fiberGoal: Double? = 30,
        sugarGoal: Double? = 50,
        sodiumGoal: Double? = 2300
    ) {
        self.id = id
        self.calorieGoal = calorieGoal
        self.proteinGoal = proteinGoal
        self.carbsGoal = carbsGoal
        self.fatGoal = fatGoal
        self.fiberGoal = fiberGoal
        self.sugarGoal = sugarGoal
        self.sodiumGoal = sodiumGoal
    }

    /// Fetch the singleton UserGoals, creating one with defaults if none exists.
    static func fetchOrCreate(in context: ModelContext) -> UserGoals {
        let descriptor = FetchDescriptor<UserGoals>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let goals = UserGoals()
        context.insert(goals)
        return goals
    }
}
