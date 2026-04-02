import SwiftUI

struct FoodEditorSections: View {
    @Binding var draft: FoodDraft
    @Binding var showMicros: Bool

    var body: some View {
        Section("Basic Info") {
            TextField("Food Name *", text: $draft.name)
                .textInputAutocapitalization(.words)

            TextField("Brand (optional)", text: $draft.brand)
                .textInputAutocapitalization(.words)

            TextField("Barcode (optional)", text: $draft.barcode)
                .keyboardType(.numberPad)

            HStack {
                TextField("Serving Size", text: $draft.servingSize)
                    .keyboardType(.decimalPad)
                    .frame(maxWidth: 100)

                Picker("Unit", selection: $draft.servingUnit) {
                    ForEach(FoodDraft.servingUnits, id: \.self) { unit in
                        Text(unit).tag(unit)
                    }
                }
                .pickerStyle(.menu)
            }
        }

        Section("Calories & Macros") {
            FoodEditorNumberField(label: "Calories (kcal) *", text: $draft.calories)
            FoodEditorNumberField(label: "Protein (g) *", text: $draft.protein)
            FoodEditorNumberField(label: "Carbohydrates (g) *", text: $draft.carbohydrates)
            FoodEditorNumberField(label: "Fat (g) *", text: $draft.fat)
            FoodEditorNumberField(label: "Fiber (g)", text: $draft.fiber)
            FoodEditorNumberField(label: "Sugar (g)", text: $draft.sugar)
        }

        Section {
            DisclosureGroup("Micronutrients (optional)", isExpanded: $showMicros) {
                FoodEditorNumberField(label: "Sodium (mg)", text: $draft.sodium)
                FoodEditorNumberField(label: "Potassium (mg)", text: $draft.potassium)
                FoodEditorNumberField(label: "Calcium (mg)", text: $draft.calcium)
                FoodEditorNumberField(label: "Iron (mg)", text: $draft.iron)
                FoodEditorNumberField(label: "Vitamin C (mg)", text: $draft.vitaminC)
                FoodEditorNumberField(label: "Vitamin D (IU)", text: $draft.vitaminD)
            }
        }
    }
}

private struct FoodEditorNumberField: View {
    let label: String
    @Binding var text: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            TextField("0", text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 100)
        }
        .contentShape(Rectangle())
    }
}
