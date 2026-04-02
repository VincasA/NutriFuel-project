//
//  FoodDetailView.swift
//  NutriFuel
//

import SwiftUI

struct FoodDetailView: View {
    let food: Food
    @State private var showEditSheet = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                headerCard
                energyCard
                macrosCard

                if hasMicros {
                    microsCard
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .navigationTitle("Food Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Edit") {
                showEditSheet = true
            }
        }
        .sheet(isPresented: $showEditSheet) {
            AddEditFoodView(modelContext: modelContext, food: food)
        }
        .appPageBackground()
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(food.name)
                .font(.system(size: 26, weight: .bold, design: .rounded))

            if let brand = food.brand, !brand.isEmpty {
                Text(brand)
                    .font(.subheadline)
                    .foregroundStyle(AppStyle.subtleText)
            }

            HStack(spacing: 6) {
                AppChip(text: "\(String(format: "%.0f", food.servingSize))\(food.servingUnit) serving")
                if let barcode = food.barcode, !barcode.isEmpty {
                    AppChip(text: "Barcode \(barcode)")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .appCardStyle()
    }

    private var energyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeadline("Energy")
            NutritionRow(label: "Calories", value: food.calories, unit: "kcal", color: AppStyle.accent)
        }
        .padding(14)
        .appCardStyle()
    }

    private var macrosCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeadline("Macronutrients")
            NutritionRow(label: "Protein", value: food.protein, unit: "g", color: AppStyle.protein)
            NutritionRow(label: "Carbohydrates", value: food.carbohydrates, unit: "g", color: AppStyle.carbs)
            NutritionRow(label: "Fat", value: food.fat, unit: "g", color: AppStyle.fat)
            if let fiber = food.fiber {
                NutritionRow(label: "Fiber", value: fiber, unit: "g", color: .brown)
            }
            if let sugar = food.sugar {
                NutritionRow(label: "Sugar", value: sugar, unit: "g", color: .purple)
            }
        }
        .padding(14)
        .appCardStyle()
    }

    private var microsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeadline("Micronutrients")
            if let sodium = food.sodium {
                NutritionRow(label: "Sodium", value: sodium, unit: "mg", color: .gray)
            }
            if let potassium = food.potassium {
                NutritionRow(label: "Potassium", value: potassium, unit: "mg", color: .gray)
            }
            if let calcium = food.calcium {
                NutritionRow(label: "Calcium", value: calcium, unit: "mg", color: .gray)
            }
            if let iron = food.iron {
                NutritionRow(label: "Iron", value: iron, unit: "mg", color: .gray)
            }
            if let vitC = food.vitaminC {
                NutritionRow(label: "Vitamin C", value: vitC, unit: "mg", color: .yellow)
            }
            if let vitD = food.vitaminD {
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
        food.sodium != nil || food.potassium != nil || food.calcium != nil ||
        food.iron != nil || food.vitaminC != nil || food.vitaminD != nil
    }
}

struct NutritionRow: View {
    let label: String
    let value: Double
    let unit: String
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.subheadline)

            Spacer()

            Text("\(value, specifier: "%.1f") \(unit)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(AppStyle.subtleText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .appInputBackground(radius: 12)
    }
}

#Preview {
    NavigationStack {
        FoodDetailView(food: Food(
            name: "Chicken Breast",
            brand: "Store Brand",
            servingSize: 100,
            servingUnit: "g",
            calories: 165,
            protein: 31,
            carbohydrates: 0,
            fat: 3.6,
            fiber: 0,
            sugar: 0,
            sodium: 74,
            barcode: "1234567890123"
        ))
    }
}
