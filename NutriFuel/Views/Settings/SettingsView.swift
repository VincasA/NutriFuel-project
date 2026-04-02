//
//  SettingsView.swift
//  NutriFuel
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.appEnvironment) private var appEnvironment
    @State private var viewModel: SettingsViewModel?
    @State private var showSavedAlert = false

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    SettingsForm(viewModel: viewModel, showSavedAlert: $showSavedAlert)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Settings")
            .task {
                if viewModel == nil {
                    viewModel = appEnvironment.makeSettingsViewModel()
                }
            }
            .alert("Settings Saved", isPresented: $showSavedAlert) {
            } message: {
                Text("Your daily goals have been updated.")
            }
        }
        .appPageBackground()
    }
}

enum GoalFocusField: Hashable {
    case calorie
    case protein
    case carbs
    case fat
    case fiber
    case sugar
    case sodium
}

struct SettingsForm: View {
    @Bindable var viewModel: SettingsViewModel
    @Binding var showSavedAlert: Bool
    @AppStorage("appAppearance") private var appAppearanceRaw = AppAppearance.system.rawValue
    @FocusState private var focusedField: GoalFocusField?

    @State private var calorieGoal = 0.0
    @State private var proteinGoal = 0.0
    @State private var carbsGoal = 0.0
    @State private var fatGoal = 0.0
    @State private var fiberGoal: Double?
    @State private var sugarGoal: Double?
    @State private var sodiumGoal: Double?

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                mainGoalsCard
                appearanceCard
                optionalGoalsCard

                Button {
                    saveGoals()
                    showSavedAlert = true
                } label: {
                    Text("Save Goals")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            LinearGradient(
                                colors: [AppStyle.accent, AppStyle.accentStrong],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                }
                .buttonStyle(.plain)

                aboutCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .task {
            loadGoals()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
    }

    private var mainGoalsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            cardHeadline("Main Goals")
            GoalField(
                label: "Calories",
                unit: "kcal",
                value: $calorieGoal,
                color: AppStyle.accent,
                focusField: .calorie,
                focusedField: $focusedField
            )
            GoalField(
                label: "Protein",
                unit: "g",
                value: $proteinGoal,
                color: AppStyle.protein,
                focusField: .protein,
                focusedField: $focusedField
            )
            GoalField(
                label: "Carbs",
                unit: "g",
                value: $carbsGoal,
                color: AppStyle.carbs,
                focusField: .carbs,
                focusedField: $focusedField
            )
            GoalField(
                label: "Fat",
                unit: "g",
                value: $fatGoal,
                color: AppStyle.fat,
                focusField: .fat,
                focusedField: $focusedField
            )
        }
        .padding(14)
        .appCardStyle()
    }

    private var appearanceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            cardHeadline("Appearance")
            Picker("Theme", selection: $appAppearanceRaw) {
                ForEach(AppAppearance.allCases) { appearance in
                    Text(appearance.label).tag(appearance.rawValue)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(14)
        .appCardStyle()
    }

    private var optionalGoalsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            cardHeadline("Optional Goals")
            OptionalGoalField(
                label: "Fiber",
                unit: "g",
                value: $fiberGoal,
                color: .brown,
                focusField: .fiber,
                focusedField: $focusedField
            )
            OptionalGoalField(
                label: "Sugar",
                unit: "g",
                value: $sugarGoal,
                color: .purple,
                focusField: .sugar,
                focusedField: $focusedField
            )
            OptionalGoalField(
                label: "Sodium",
                unit: "mg",
                value: $sodiumGoal,
                color: .gray,
                focusField: .sodium,
                focusedField: $focusedField
            )

            HStack(spacing: 6) {
                if let fiberGoal {
                    AppChip(text: "Fiber \(Int(fiberGoal))g")
                }
                if let sugarGoal {
                    AppChip(text: "Sugar \(Int(sugarGoal))g")
                }
                if let sodiumGoal {
                    AppChip(text: "Sodium \(Int(sodiumGoal))mg")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .appCardStyle()
    }

    private var aboutCard: some View {
        VStack(spacing: 8) {
            settingsReadOnlyRow(label: "Version", value: "Beta V0.3")
            settingsReadOnlyRow(label: "Data Storage", value: "On-Device Only")
        }
        .padding(14)
        .appCardStyle()
    }

    private func cardHeadline(_ text: String) -> some View {
        Text(text)
            .font(.footnote.bold())
            .textCase(.uppercase)
            .foregroundStyle(AppStyle.subtleText)
    }

    private func settingsReadOnlyRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(AppStyle.subtleText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .appInputBackground(radius: 12)
    }

    private func loadGoals() {
        let goals = viewModel.goals
        calorieGoal = goals.calorieGoal
        proteinGoal = goals.proteinGoal
        carbsGoal = goals.carbsGoal
        fatGoal = goals.fatGoal
        fiberGoal = goals.fiberGoal
        sugarGoal = goals.sugarGoal
        sodiumGoal = goals.sodiumGoal
    }

    private func saveGoals() {
        let goals = viewModel.goals
        goals.calorieGoal = calorieGoal
        goals.proteinGoal = proteinGoal
        goals.carbsGoal = carbsGoal
        goals.fatGoal = fatGoal
        goals.fiberGoal = fiberGoal
        goals.sugarGoal = sugarGoal
        goals.sodiumGoal = sodiumGoal
        viewModel.save()
    }
}

struct GoalField: View {
    let label: String
    let unit: String
    @Binding var value: Double
    let color: Color
    let focusField: GoalFocusField
    @FocusState.Binding var focusedField: GoalFocusField?

    var body: some View {
        HStack {
            labelView

            Spacer()

            TextField(
                "0",
                value: $value,
                format: .number.precision(.fractionLength(0))
            )
            .keyboardType(.numberPad)
            .multilineTextAlignment(.trailing)
            .focused($focusedField, equals: focusField)
            .frame(maxWidth: 80)

            Text(unit)
                .font(.caption)
                .foregroundStyle(AppStyle.subtleText)
                .frame(width: 36, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .appInputBackground(radius: 12)
    }

    private var labelView: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.subheadline)
        }
    }
}

struct OptionalGoalField: View {
    let label: String
    let unit: String
    @Binding var value: Double?
    let color: Color
    let focusField: GoalFocusField
    @FocusState.Binding var focusedField: GoalFocusField?

    var body: some View {
        HStack {
            labelView

            Spacer()

            TextField(
                "Optional",
                value: $value,
                format: .number.precision(.fractionLength(0))
            )
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .focused($focusedField, equals: focusField)
            .frame(maxWidth: 80)

            Text(unit)
                .font(.caption)
                .foregroundStyle(AppStyle.subtleText)
                .frame(width: 36, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .appInputBackground(radius: 12)
    }

    private var labelView: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.subheadline)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Food.self, OfficialFood.self, UserGoals.self], inMemory: true)
}
