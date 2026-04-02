import SwiftUI
import SwiftData

struct AddEditFoodView: View {
    @Environment(\.dismiss) private var dismiss

    let modelContext: ModelContext
    let food: Food?
    let onSave: ((Food) -> Void)?

    @State private var draft: FoodDraft
    @State private var showMicros: Bool
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    private var isEditing: Bool { food != nil }

    init(
        modelContext: ModelContext,
        food: Food? = nil,
        prefilledBarcode: String? = nil,
        onSave: ((Food) -> Void)? = nil
    ) {
        self.modelContext = modelContext
        self.food = food
        self.onSave = onSave

        let initialDraft: FoodDraft
        if let food {
            initialDraft = FoodDraft(food: food)
        } else {
            var draft = FoodDraft()
            draft.barcode = prefilledBarcode ?? ""
            initialDraft = draft
        }

        _draft = State(initialValue: initialDraft)
        _showMicros = State(initialValue: initialDraft.hasMicros)
    }

    var body: some View {
        NavigationStack {
            Form {
                FoodEditorSections(draft: $draft, showMicros: $showMicros)
            }
            .navigationTitle(isEditing ? "Edit Food" : "Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: saveFood)
                        .disabled(!draft.isValid)
                        .fontWeight(.bold)
                }
            }
            .alert("Could Not Save Food", isPresented: $showErrorAlert) {} message: {
                Text(errorMessage)
            }
        }
    }

    private func saveFood() {
        guard draft.isValid else {
            errorMessage = "Enter a name, serving size, calories, and macros before saving."
            showErrorAlert = true
            return
        }

        do {
            let savedFood: Food
            if let food {
                draft.apply(to: food, isListedInDatabase: true)
                savedFood = food
            } else {
                let newFood = draft.makeFood(isListedInDatabase: true)
                modelContext.insert(newFood)
                savedFood = newFood
            }

            try modelContext.save()
            onSave?(savedFood)
            dismiss()
        } catch {
            errorMessage = "Failed to save food: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
}

#Preview {
    AddEditFoodView(
        modelContext: try! ModelContainer(for: Food.self).mainContext
    )
}
