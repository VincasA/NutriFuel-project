import SwiftUI

struct AppEnvironment {
    var makeDailyLogViewModel: () -> DailyLogViewModel
    var makeFoodDatabaseViewModel: () -> FoodDatabaseViewModel
    var makeSettingsViewModel: () -> SettingsViewModel
    var officialFoodRepository: OfficialFoodProviding
    var foodRepository: FoodRepository
    var goalsRepository: GoalsRepository

    static var placeholder: AppEnvironment {
        let unavailableMessage = "AppEnvironment is not configured."

        return AppEnvironment(
            makeDailyLogViewModel: { fatalError(unavailableMessage) },
            makeFoodDatabaseViewModel: { fatalError(unavailableMessage) },
            makeSettingsViewModel: { fatalError(unavailableMessage) },
            officialFoodRepository: PlaceholderOfficialFoodRepository(),
            foodRepository: PlaceholderFoodRepository(),
            goalsRepository: PlaceholderGoalsRepository()
        )
    }
}

private struct AppEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppEnvironment = .placeholder
}

extension EnvironmentValues {
    var appEnvironment: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}

@MainActor
private final class PlaceholderOfficialFoodRepository: OfficialFoodProviding {
    func lookupByBarcode(_ barcode: String) async throws -> OfficialFood? {
        fatalError("OfficialFoodProviding unavailable.")
    }

    func searchByText(_ query: String, limit: Int) async throws -> [OfficialFood] {
        fatalError("OfficialFoodProviding unavailable.")
    }
}

@MainActor
private final class PlaceholderFoodRepository: FoodRepository {
    func fetchFoods(matching query: String?, limit: Int) -> [Food] {
        fatalError("FoodRepository unavailable.")
    }

    func insert(_ food: Food) {
        fatalError("FoodRepository unavailable.")
    }

    func delete(_ food: Food) {
        fatalError("FoodRepository unavailable.")
    }

    func findFoodsByBarcode(_ barcode: String) -> [Food] {
        fatalError("FoodRepository unavailable.")
    }

    func save() throws {
        fatalError("FoodRepository unavailable.")
    }
}

@MainActor
private final class PlaceholderGoalsRepository: GoalsRepository {
    func loadGoals() -> UserGoals {
        fatalError("GoalsRepository unavailable.")
    }

    func save() throws {
        fatalError("GoalsRepository unavailable.")
    }
}
