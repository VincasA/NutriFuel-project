import SwiftUI
import SwiftData

struct OfficialFoodDetailView: View {
    let officialFood: OfficialFood

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var statusMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    headerCard
                    sourceCard
                    energyCard
                    macrosCard

                    if hasMicros {
                        microsCard
                    }

                    if let statusMessage {
                        Text(statusMessage)
                            .font(.subheadline)
                            .foregroundStyle(AppStyle.accentStrong)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .appCardStyle()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .navigationTitle("Official Open Food Facts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save as Custom") {
                        saveAsCustom()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .appPageBackground()
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(officialFood.name)
                .font(.system(size: 26, weight: .bold, design: .rounded))

            if let brandOwner = officialFood.brandOwner, !brandOwner.isEmpty {
                Text(brandOwner)
                    .font(.subheadline)
                    .foregroundStyle(AppStyle.subtleText)
            }

            HStack(spacing: 6) {
                AppChip(text: "\(String(format: "%.0f", officialFood.servingSize))\(officialFood.servingUnit) serving")
                AppChip(text: officialFood.gtinUpc)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .appCardStyle()
    }

    private var sourceCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeadline("Source")
            HStack {
                Label("Open Food Facts", systemImage: "building.columns")
                Spacer()
                Text("ID: \(officialFood.fdcId)")
                    .font(.caption)
                    .foregroundStyle(AppStyle.subtleText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .appInputBackground(radius: 12)
        }
        .padding(14)
        .appCardStyle()
    }

    private var energyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeadline("Energy")
            NutritionRow(label: "Calories", value: officialFood.calories, unit: "kcal", color: AppStyle.accent)
        }
        .padding(14)
        .appCardStyle()
    }

    private var macrosCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeadline("Macronutrients")
            NutritionRow(label: "Protein", value: officialFood.protein, unit: "g", color: AppStyle.protein)
            NutritionRow(label: "Carbohydrates", value: officialFood.carbohydrates, unit: "g", color: AppStyle.carbs)
            NutritionRow(label: "Fat", value: officialFood.fat, unit: "g", color: AppStyle.fat)
            if let fiber = officialFood.fiber {
                NutritionRow(label: "Fiber", value: fiber, unit: "g", color: .brown)
            }
            if let sugar = officialFood.sugar {
                NutritionRow(label: "Sugar", value: sugar, unit: "g", color: .purple)
            }
        }
        .padding(14)
        .appCardStyle()
    }

    private var microsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeadline("Micronutrients")
            if let sodium = officialFood.sodium {
                NutritionRow(label: "Sodium", value: sodium, unit: "mg", color: .gray)
            }
            if let potassium = officialFood.potassium {
                NutritionRow(label: "Potassium", value: potassium, unit: "mg", color: .gray)
            }
            if let calcium = officialFood.calcium {
                NutritionRow(label: "Calcium", value: calcium, unit: "mg", color: .gray)
            }
            if let iron = officialFood.iron {
                NutritionRow(label: "Iron", value: iron, unit: "mg", color: .gray)
            }
            if let vitC = officialFood.vitaminC {
                NutritionRow(label: "Vitamin C", value: vitC, unit: "mg", color: .yellow)
            }
            if let vitD = officialFood.vitaminD {
                NutritionRow(label: "Vitamin D", value: vitD, unit: "IU", color: .yellow)
            }
        }
        .padding(14)
        .appCardStyle()
    }

    private func sectionHeadline(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .textCase(.uppercase)
            .foregroundStyle(AppStyle.subtleText)
    }

    private var hasMicros: Bool {
        officialFood.sodium != nil || officialFood.potassium != nil || officialFood.calcium != nil ||
        officialFood.iron != nil || officialFood.vitaminC != nil || officialFood.vitaminD != nil
    }

    private func saveAsCustom() {
        let custom = FoodDraft(officialFood: officialFood).makeFood(isListedInDatabase: true)

        modelContext.insert(custom)
        do {
            try modelContext.save()
            statusMessage = "Saved to Custom Foods."
        } catch {
            statusMessage = "Failed to save custom copy: \(error.localizedDescription)"
        }
    }
}

#Preview {
    OfficialFoodDetailView(
        officialFood: OfficialFood(
            fdcId: 123,
            gtinUpc: "0123456789012",
            name: "Greek Yogurt",
            brandOwner: "Brand",
            servingSize: 170,
            servingUnit: "g",
            calories: 120,
            protein: 15,
            carbohydrates: 8,
            fat: 2
        )
    )
    .modelContainer(for: [Food.self, OfficialFood.self, LogEntry.self, UserGoals.self], inMemory: true)
}
