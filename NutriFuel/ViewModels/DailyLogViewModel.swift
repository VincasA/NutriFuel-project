//
//  DailyLogViewModel.swift
//  NutriFuel
//

import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class DailyLogViewModel {
    var selectedDate: Date = Date()
    var entries: [LogEntry] = [] {
        didSet {
            entriesByMeal = Dictionary(grouping: entries, by: \.mealType)
            dayTotals = NutritionCalculator.totals(for: entries)
        }
    }
    private(set) var entriesByMeal: [MealType: [LogEntry]] = [:]
    private(set) var dayTotals: NutritionCalculator.DayTotals = .init()

    private let logEntryRepository: LogEntryRepository

    init(logEntryRepository: LogEntryRepository) {
        self.logEntryRepository = logEntryRepository
        fetchEntries()
    }

    convenience init(modelContext: ModelContext) {
        self.init(logEntryRepository: SwiftDataLogEntryRepository(modelContext: modelContext))
    }

    func fetchEntries() {
        entries = logEntryRepository.fetchEntries(on: selectedDate)
    }

    func entries(for mealType: MealType) -> [LogEntry] {
        entriesByMeal[mealType] ?? []
    }

    func addEntry(food: Food, quantity: Double, mealType: MealType, date: Date? = nil) {
        let entryDate = date ?? selectedDate
        logEntryRepository.insert(food: food, quantity: quantity, mealType: mealType, date: entryDate)
        save()
        fetchEntries()
    }

    func addOfficialEntry(officialFood: OfficialFood, quantity: Double, mealType: MealType, date: Date? = nil) {
        let entryDate = date ?? selectedDate
        logEntryRepository.insert(officialFood: officialFood, quantity: quantity, mealType: mealType, date: entryDate)
        save()
        fetchEntries()
    }

    func deleteEntry(_ entry: LogEntry) {
        logEntryRepository.delete(entry)
        save()
        fetchEntries()
    }

    func goToNextDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        fetchEntries()
    }

    func goToPreviousDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        fetchEntries()
    }

    func goToDate(_ date: Date) {
        selectedDate = date
        fetchEntries()
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter
    }()

    var dateString: String {
        if isToday {
            return "Today"
        }
        if Calendar.current.isDateInYesterday(selectedDate) {
            return "Yesterday"
        }
        if Calendar.current.isDateInTomorrow(selectedDate) {
            return "Tomorrow"
        }
        return Self.shortDateFormatter.string(from: selectedDate)
    }

    func save() {
        try? logEntryRepository.save()
    }
}
