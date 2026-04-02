//
//  HistoryView.swift
//  NutriFuel
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \LogEntry.date, order: .reverse) private var allEntries: [LogEntry]
    @State private var selectedDate: Date?
    @State private var showDayDetail = false
    @State private var loggedDays: [Date: [LogEntry]] = [:]
    @State private var weeklyAverage: Double = 0

    private var sortedDays: [Date] {
        loggedDays.keys.sorted(by: >)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    weeklyAverageCard

                    if sortedDays.isEmpty {
                        ContentUnavailableView(
                            "No History Yet",
                            systemImage: "calendar",
                            description: Text("Start logging meals to see your history")
                        )
                        .padding(.top, 40)
                    } else {
                        ForEach(sortedDays, id: \.self) { day in
                            let dayEntries = loggedDays[day] ?? []
                            Button {
                                selectedDate = day
                                showDayDetail = true
                            } label: {
                                DayHistoryRow(date: day, entries: dayEntries)
                            }
                            .buttonStyle(.plain)
                            .contentShape(Rectangle())
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .navigationTitle("History")
            .sheet(isPresented: $showDayDetail) {
                if let date = selectedDate {
                    DayDetailSheet(date: date)
                }
            }
            .onAppear(perform: recomputeDerivedState)
            .onChange(of: allEntries) { _, _ in
                recomputeDerivedState()
            }
        }
        .appPageBackground()
    }

    private func recomputeDerivedState() {
        let calendar = Calendar.current
        loggedDays = Dictionary(grouping: allEntries) { entry in
            calendar.startOfDay(for: entry.date)
        }

        let now = Date()
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else {
            weeklyAverage = 0
            return
        }
        let weekStart = calendar.startOfDay(for: weekAgo)
        let weekEntries = allEntries.filter { $0.date >= weekStart }
        let totalCals = weekEntries.reduce(0.0) { $0 + $1.totalCalories }
        let daysWithData = Set(weekEntries.map { calendar.startOfDay(for: $0.date) }).count
        weeklyAverage = daysWithData > 0 ? totalCals / Double(daysWithData) : 0
    }

    private var weeklyAverageCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("7-Day Average")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .textCase(.uppercase)
                .foregroundStyle(AppStyle.subtleText)

            Text("\(Int(weeklyAverage)) kcal/day")
                .font(.system(size: 30, weight: .bold, design: .rounded))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .appCardStyle()
    }
}

struct DayHistoryRow: View {
    let date: Date
    let entries: [LogEntry]

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter
    }()

    private var totalCalories: Double {
        entries.reduce(0) { $0 + $1.totalCalories }
    }

    private var totalProtein: Double {
        entries.reduce(0) { $0 + $1.totalProtein }
    }

    private var totalCarbs: Double {
        entries.reduce(0) { $0 + $1.totalCarbs }
    }

    private var totalFat: Double {
        entries.reduce(0) { $0 + $1.totalFat }
    }

    private var dateString: String {
        Self.shortDateFormatter.string(from: date)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(dateString)
                    .font(.system(size: 16, weight: .bold, design: .rounded))

                Text("\(entries.count) items logged")
                    .font(.caption)
                    .foregroundStyle(AppStyle.subtleText)

                HStack(spacing: 6) {
                    MacroLabel(value: totalProtein, label: "P", color: AppStyle.protein)
                    MacroLabel(value: totalCarbs, label: "C", color: AppStyle.carbs)
                    MacroLabel(value: totalFat, label: "F", color: AppStyle.fat)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(totalCalories))")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(AppStyle.accentStrong)
                Text("kcal")
                    .font(.caption2)
                    .foregroundStyle(AppStyle.subtleText)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .appCardStyle()
    }
}

struct DayDetailSheet: View {
    let date: Date
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var entries: [LogEntry] = []
    @State private var editingEntry: LogEntry?

    private var totals: NutritionCalculator.DayTotals {
        NutritionCalculator.totals(for: entries)
    }

    private static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()

    private var dateString: String {
        Self.fullDateFormatter.string(from: date)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Daily Totals") {
                    NutritionRow(label: "Calories", value: totals.calories, unit: "kcal", color: AppStyle.accent)
                    NutritionRow(label: "Protein", value: totals.protein, unit: "g", color: AppStyle.protein)
                    NutritionRow(label: "Carbs", value: totals.carbs, unit: "g", color: AppStyle.carbs)
                    NutritionRow(label: "Fat", value: totals.fat, unit: "g", color: AppStyle.fat)
                }

                ForEach(MealType.allCases, id: \.self) { mealType in
                    let mealEntries = entries.filter { $0.mealType == mealType }
                    if !mealEntries.isEmpty {
                        Section {
                            ForEach(mealEntries, id: \.id) { entry in
                                Button {
                                    editingEntry = entry
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(entry.foodDisplayName)
                                                .font(.subheadline)
                                            Text("\(entry.quantity, specifier: "%.1f") × \(entry.servingSize, specifier: "%.0f")\(entry.servingUnit)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text("\(Int(entry.totalCalories)) kcal")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    .contentShape(Rectangle())
                                    .frame(minHeight: 44)
                                }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        delete(entry)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        } header: {
                            Label(mealType.rawValue, systemImage: mealType.icon)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(dateString)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Done") { dismiss() }
            }
            .sheet(item: $editingEntry, onDismiss: fetchEntries) { entry in
                EditLogEntryView(entry: entry)
            }
            .onAppear(perform: fetchEntries)
            .onChange(of: date) { _, _ in
                fetchEntries()
            }
        }
    }

    private func delete(_ entry: LogEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
        fetchEntries()
    }

    private func fetchEntries() {
        let start = NutritionCalculator.startOfDay(date)
        guard let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: start) else {
            entries = []
            return
        }

        let descriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate<LogEntry> { entry in
                entry.date >= start && entry.date < nextDay
            },
            sortBy: [SortDescriptor(\LogEntry.date)]
        )

        entries = (try? modelContext.fetch(descriptor)) ?? []
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [Food.self, OfficialFood.self, LogEntry.self, UserGoals.self], inMemory: true)
}
