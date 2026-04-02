import SwiftUI
import SwiftData
import UIKit

private typealias EditLogQuantityUnit = ServingQuantityUnit

struct EditLogEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let entry: LogEntry

    @State private var quantityText = ""
    @State private var quantityUnit: EditLogQuantityUnit = .serving
    @State private var mealType: MealType = .snack
    @State private var date: Date = Date()

    @State private var showError = false
    @State private var errorText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Food") {
                    Text(entry.foodDisplayName)
                        .font(.headline)
                }

                Section("Entry") {
                    HStack {
                        TextField("Quantity", text: $quantityText)
                            .keyboardType(.decimalPad)
                        Picker("Unit", selection: $quantityUnit) {
                            ForEach(EditLogQuantityUnit.allCases) { unit in
                                Text(unit.label).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    Picker("Meal", selection: $mealType) {
                        ForEach(MealType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }

                    DatePicker("Date", selection: $date, displayedComponents: [.date])
                }

                Section {
                    Button(role: .destructive) {
                        deleteEntry()
                    } label: {
                        Label("Delete Entry", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Edit Log Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.bold)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        hideKeyboard()
                    }
                }
            }
            .alert("Could Not Save", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorText)
            }
            .onAppear {
                quantityUnit = defaultUnit(for: entry.servingUnit)
                let convertedAmount = ServingUnitConverter.amountFromServings(
                    servings: entry.quantity,
                    outputUnit: quantityUnit,
                    servingSize: entry.servingSize,
                    servingUnit: entry.servingUnit
                )
                quantityText = String(format: "%.2f", convertedAmount ?? entry.quantity)
                mealType = entry.mealType
                date = entry.date
            }
        }
    }

    private func saveChanges() {
        guard let amount = LocalizedDecimalParser.parse(quantityText), amount > 0 else {
            errorText = "Quantity must be a positive number."
            showError = true
            return
        }

        if entry.servingSize > 0 {
            guard let servings = ServingUnitConverter.amountInServings(
                amount: amount,
                amountUnit: quantityUnit,
                servingSize: entry.servingSize,
                servingUnit: entry.servingUnit
            ), servings > 0 else {
                errorText = "Cannot convert \(quantityUnit.label) for this food serving unit (\(entry.servingUnit))."
                showError = true
                return
            }
            entry.quantity = servings
        } else {
            entry.quantity = amount
        }
        entry.mealType = mealType
        entry.date = date

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorText = "Failed to save changes: \(error.localizedDescription)"
            showError = true
        }
    }

    private func deleteEntry() {
        modelContext.delete(entry)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorText = "Failed to delete entry: \(error.localizedDescription)"
            showError = true
        }
    }

    private func defaultUnit(for servingUnit: String) -> EditLogQuantityUnit {
        ServingQuantityUnit.fromFoodServingUnit(servingUnit)
    }
}

private func hideKeyboard() {
    UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder),
        to: nil,
        from: nil,
        for: nil
    )
}
