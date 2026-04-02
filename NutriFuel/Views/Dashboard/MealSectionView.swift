//
//  MealSectionView.swift
//  NutriFuel
//

import SwiftUI

struct MealSectionView: View {
    let mealType: MealType
    let entries: [LogEntry]
    let onSelect: (LogEntry) -> Void
    let onDelete: (LogEntry) -> Void

    private var sectionCalories: Double {
        entries.reduce(0) { $0 + $1.totalCalories }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(mealType.rawValue)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Spacer()

                Text("\(Int(sectionCalories)) kcal")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppStyle.subtleText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(minHeight: 48)

            if entries.isEmpty {
                HStack {
                    Text("No foods logged yet")
                        .font(.subheadline)
                        .foregroundStyle(AppStyle.subtleText)
                    Spacer()
                    AppChip(text: "Quick add")
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            } else {
                ForEach(entries) { entry in
                    Button {
                        onSelect(entry)
                    } label: {
                        MealEntryRow(entry: entry)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            withAnimation {
                                onDelete(entry)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }

                    if entry.id != entries.last?.id {
                        Divider()
                            .padding(.horizontal, 14)
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: AppStyle.radiusM, style: .continuous)
                .fill(AppStyle.cardTop)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.radiusM, style: .continuous)
                .stroke(AppStyle.border, lineWidth: 1)
        )
        .shadow(color: AppStyle.shadow.opacity(0.55), radius: 10, x: 0, y: 5)
    }
}

struct MealEntryRow: View {
    let entry: LogEntry

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 5) {
                Text(entry.foodDisplayName)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))

                Text("\(entry.quantity, specifier: "%.1f") × \(entry.servingSize, specifier: "%.0f")\(entry.servingUnit)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(AppStyle.subtleText)

                HStack(spacing: 6) {
                    MacroLabel(value: entry.totalProtein, label: "P", color: AppStyle.protein)
                    MacroLabel(value: entry.totalCarbs, label: "C", color: AppStyle.carbs)
                    MacroLabel(value: entry.totalFat, label: "F", color: AppStyle.fat)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(entry.totalCalories))")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

struct MacroLabel: View {
    let value: Double
    let label: String
    let color: Color

    var body: some View {
        Text("\(label) \(Int(value))")
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundStyle(
                color == AppStyle.carbs
                ? AppStyle.carbs.opacity(0.95)
                : color
            )
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(AppStyle.chipBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .stroke(AppStyle.border.opacity(0.85), lineWidth: 1)
            )
    }
}

#Preview {
    MealSectionView(
        mealType: .breakfast,
        entries: [],
        onSelect: { _ in },
        onDelete: { _ in }
    )
    .padding()
}
