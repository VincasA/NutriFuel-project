import Foundation
import SwiftData

final class OfficialDataResetService {
    private let modelContext: ModelContext
    private let userDefaults: UserDefaults
    private let resetVersion: Int
    private let resetVersionKey: String

    init(
        modelContext: ModelContext,
        userDefaults: UserDefaults = .standard,
        resetVersion: Int = 1,
        resetVersionKey: String = "officialDataResetVersion"
    ) {
        self.modelContext = modelContext
        self.userDefaults = userDefaults
        self.resetVersion = resetVersion
        self.resetVersionKey = resetVersionKey
    }

    func performIfNeeded() {
        guard userDefaults.integer(forKey: resetVersionKey) < resetVersion else { return }

        do {
            let officialEntriesDescriptor = FetchDescriptor<LogEntry>(
                predicate: #Predicate<LogEntry> { entry in
                    entry.officialFood != nil
                }
            )
            let officialEntries = try modelContext.fetch(officialEntriesDescriptor)
            for entry in officialEntries {
                modelContext.delete(entry)
            }

            let officialFoods = try modelContext.fetch(FetchDescriptor<OfficialFood>())
            for food in officialFoods {
                modelContext.delete(food)
            }

            try modelContext.save()
            userDefaults.set(resetVersion, forKey: resetVersionKey)
        } catch {
            assertionFailure("Failed to reset official data: \(error.localizedDescription)")
        }
    }
}
