//
//  DashboardView.swift
//  NutriFuel
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.appEnvironment) private var appEnvironment
    let externalLogVM: DailyLogViewModel?
    @State private var logVM: DailyLogViewModel?
    @State private var goals: UserGoals?
    @State private var selectedFoodDetail: Food?
    @State private var selectedOfficialFoodDetail: OfficialFood?

    init(externalLogVM: DailyLogViewModel? = nil) {
        self.externalLogVM = externalLogVM
    }

    var body: some View {
        NavigationStack {
            Group {
                if let logVM = logVM, let goals = goals {
                    DashboardContent(
                        logVM: logVM,
                        goals: goals,
                        onSelectEntry: handleSelectedEntry,
                        onDeleteEntry: { entry in
                            logVM.deleteEntry(entry)
                        }
                    )
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("NutriFuel")
            .task {
                if logVM == nil {
                    logVM = externalLogVM ?? appEnvironment.makeDailyLogViewModel()
                }
                if goals == nil {
                    goals = appEnvironment.goalsRepository.loadGoals()
                }
            }
            .sheet(item: $selectedFoodDetail) { food in
                NavigationStack {
                    FoodDetailView(food: food)
                }
            }
            .sheet(item: $selectedOfficialFoodDetail) { officialFood in
                OfficialFoodDetailView(officialFood: officialFood)
            }
        }
    }

    private func handleSelectedEntry(_ entry: LogEntry) {
        if let food = entry.food {
            selectedFoodDetail = food
            return
        }

        if let officialFood = entry.officialFood {
            selectedOfficialFoodDetail = officialFood
        }
    }
}

struct DashboardContent: View {
    @Bindable var logVM: DailyLogViewModel
    let goals: UserGoals
    let onSelectEntry: (LogEntry) -> Void
    let onDeleteEntry: (LogEntry) -> Void

    private var totals: NutritionCalculator.DayTotals {
        logVM.dayTotals
    }

    private var calorieProgress: Double {
        NutritionCalculator.progress(totals.calories, goal: goals.calorieGoal)
    }

    private var dateHeaderString: String {
        if Calendar.current.isDateInToday(logVM.selectedDate) {
            return "Today, " + logVM.selectedDate.formatted(.dateTime.month(.wide).day())
        } else {
            return logVM.selectedDate.formatted(.dateTime.weekday(.wide).month(.wide).day())
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                dateNavigationHeader

                calorieCard

                macroRingsSection

                VStack(spacing: 12) {
                    ForEach(MealType.allCases, id: \.self) { mealType in
                        MealSectionView(
                            mealType: mealType,
                            entries: logVM.entries(for: mealType),
                            onSelect: onSelectEntry,
                            onDelete: onDeleteEntry
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .appPageBackground()
    }

    private var dateNavigationHeader: some View {
        HStack {
            Button {
                logVM.goToPreviousDay()
            } label: {
                Label("Previous day", systemImage: "chevron.left")
                    .labelStyle(.iconOnly)
                    .font(.title3.weight(.semibold))
                    .frame(minWidth: 44, minHeight: 44)
            }
            .contentShape(Rectangle())

            Spacer()

            Text(dateHeaderString)
                .font(.headline.bold())
                .textCase(.uppercase)

            Spacer()

            Button {
                logVM.goToNextDay()
            } label: {
                Label("Next day", systemImage: "chevron.right")
                    .labelStyle(.iconOnly)
                    .font(.title3.weight(.semibold))
                    .frame(minWidth: 44, minHeight: 44)
            }
            .contentShape(Rectangle())
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .foregroundStyle(.primary)
    }

    private var calorieCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CALORIES SUMMARY")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(AppStyle.subtleText)

            HStack(spacing: 12) {
                CalorieRingView(consumed: totals.calories, goal: goals.calorieGoal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("\(Int(totals.calories)) / \(Int(goals.calorieGoal)) kcal")
                        .font(.system(size: 22, weight: .bold, design: .rounded))

//                    HStack(spacing: 6) {
//                        AppChip(
//                            text: calorieProgress <= 1 ? "On track" : "Over target",
//                            isActive: true,
//                            activeTint: calorieProgress <= 1 ? AppStyle.accent : AppStyle.fat
//                        )
//                        AppChip(text: "Goal + fiber")
//                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .appCardStyle()
        .padding(.horizontal, 16)
    }

    private var macroRingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MACROS")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(AppStyle.subtleText)
                .padding(.horizontal, 16)

            HStack(spacing: 8) {
                MacroRingView(
                    progress: NutritionCalculator.progress(totals.protein, goal: goals.proteinGoal),
                    color: AppStyle.protein,
                    label: "Protein",
                    valueText: "\(Int(totals.protein))g"
                )
                MacroRingView(
                    progress: NutritionCalculator.progress(totals.carbs, goal: goals.carbsGoal),
                    color: AppStyle.carbs,
                    label: "Carbs",
                    valueText: "\(Int(totals.carbs))g"
                )
                MacroRingView(
                    progress: NutritionCalculator.progress(totals.fat, goal: goals.fatGoal),
                    color: AppStyle.fat,
                    label: "Fat",
                    valueText: "\(Int(totals.fat))g"
                )
            }
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Food.self, OfficialFood.self, LogEntry.self, UserGoals.self], inMemory: true)
}
