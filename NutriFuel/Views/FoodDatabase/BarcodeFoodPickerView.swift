import SwiftUI

struct BarcodeFoodPickerView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let subtitle: String
    let foods: [Food]
    let onSelect: (Food) -> Void

    var body: some View {
        NavigationStack {
            List(foods, id: \.id) { food in
                Button {
                    onSelect(food)
                    dismiss()
                } label: {
                    BarcodeFoodPickerRow(food: food)
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .top) {
                Text(subtitle)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppStyle.subtleText)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
                    .frame(maxWidth: .infinity)
                    .background(AppStyle.pageBackgroundTop)
            }
        }
        .appPageBackground()
    }
}

private struct BarcodeFoodPickerRow: View {
    let food: Food

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(food.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)

                HStack(spacing: 6) {
                    AppChip(text: "\(Int(food.calories)) kcal", isActive: true, activeTint: AppStyle.accent)
                    AppChip(text: "\(String(format: "%.0f", food.servingSize))\(food.servingUnit)")
                }

                if let barcode = food.barcode, !barcode.isEmpty {
                    Text("Barcode \(barcode)")
                        .font(.caption)
                        .foregroundStyle(AppStyle.subtleText)
                }
            }

            Spacer(minLength: 12)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppStyle.subtleText)
        }
        .padding(14)
        .contentShape(Rectangle())
        .appCardStyle()
    }
}
