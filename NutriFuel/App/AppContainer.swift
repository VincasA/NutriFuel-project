import Foundation
import SwiftData

@MainActor
final class AppContainer {
    let modelContainer: ModelContainer

    private var modelContext: ModelContext {
        modelContainer.mainContext
    }

    lazy var foodRepository: FoodRepository = SwiftDataFoodRepository(modelContext: modelContext)
    lazy var logEntryRepository: LogEntryRepository = SwiftDataLogEntryRepository(modelContext: modelContext)
    lazy var goalsRepository: GoalsRepository = SwiftDataGoalsRepository(modelContext: modelContext)
    lazy var officialFoodRepository: OfficialFoodProviding = OfficialFoodRepository(modelContext: modelContext)

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func makeDailyLogViewModel() -> DailyLogViewModel {
        DailyLogViewModel(logEntryRepository: logEntryRepository)
    }

    func makeFoodDatabaseViewModel() -> FoodDatabaseViewModel {
        FoodDatabaseViewModel(foodRepository: foodRepository)
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(goalsRepository: goalsRepository)
    }

    var environment: AppEnvironment {
        AppEnvironment(
            makeDailyLogViewModel: { [unowned self] in
                makeDailyLogViewModel()
            },
            makeFoodDatabaseViewModel: { [unowned self] in
                makeFoodDatabaseViewModel()
            },
            makeSettingsViewModel: { [unowned self] in
                makeSettingsViewModel()
            },
            officialFoodRepository: officialFoodRepository,
            foodRepository: foodRepository,
            goalsRepository: goalsRepository
        )
    }
}
