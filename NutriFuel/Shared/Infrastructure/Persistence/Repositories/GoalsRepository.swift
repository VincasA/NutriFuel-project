import Foundation
import SwiftData

@MainActor
protocol GoalsRepository {
    func loadGoals() -> UserGoals
    func save() throws
}

@MainActor
final class SwiftDataGoalsRepository: GoalsRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadGoals() -> UserGoals {
        UserGoals.fetchOrCreate(in: modelContext)
    }

    func save() throws {
        try modelContext.save()
    }
}
