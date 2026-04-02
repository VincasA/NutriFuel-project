import Foundation
import SwiftData

@MainActor
protocol LogEntryRepository {
    func fetchEntries(on date: Date) -> [LogEntry]
    func insert(food: Food, quantity: Double, mealType: MealType, date: Date)
    func insert(officialFood: OfficialFood, quantity: Double, mealType: MealType, date: Date)
    func delete(_ entry: LogEntry)
    func save() throws
}

@MainActor
final class SwiftDataLogEntryRepository: LogEntryRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchEntries(on date: Date) -> [LogEntry] {
        let start = NutritionCalculator.startOfDay(date)
        let end = NutritionCalculator.endOfDay(date)
        let descriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate<LogEntry> { entry in
                entry.date >= start && entry.date <= end
            },
            sortBy: [SortDescriptor(\.date)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func insert(food: Food, quantity: Double, mealType: MealType, date: Date) {
        let entry = LogEntry(food: food, quantity: quantity, mealType: mealType, date: date)
        modelContext.insert(entry)
    }

    func insert(officialFood: OfficialFood, quantity: Double, mealType: MealType, date: Date) {
        let entry = LogEntry(officialFood: officialFood, quantity: quantity, mealType: mealType, date: date)
        modelContext.insert(entry)
    }

    func delete(_ entry: LogEntry) {
        modelContext.delete(entry)
    }

    func save() throws {
        try modelContext.save()
    }
}
