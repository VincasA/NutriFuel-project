//
//  SettingsViewModel.swift
//  NutriFuel
//

import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class SettingsViewModel {
    var goals: UserGoals

    private let goalsRepository: GoalsRepository

    init(goalsRepository: GoalsRepository) {
        self.goalsRepository = goalsRepository
        self.goals = goalsRepository.loadGoals()
    }

    convenience init(modelContext: ModelContext) {
        self.init(goalsRepository: SwiftDataGoalsRepository(modelContext: modelContext))
    }

    func save() {
        try? goalsRepository.save()
    }
}
