//
//  MacroRingView.swift
//  NutriFuel
//

import SwiftUI

struct MacroRingView: View {
    let progress: Double
    let color: Color
    let label: String
    let valueText: String

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    init(progress: Double, color: Color, label: String = "", valueText: String = "") {
        self.progress = progress
        self.color = color
        self.label = label
        self.valueText = valueText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !label.isEmpty {
                HStack(alignment: .firstTextBaseline) {
                    Text(label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Text(valueText)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppStyle.subtleText)
                }
            }

            ProgressView(value: clampedProgress)
                .tint(color)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label.isEmpty ? "Macro progress" : label)
        .accessibilityValue("\(Int(clampedProgress * 100)) percent of goal, \(valueText)")
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle()
    }
}

struct CalorieRingView: View {
    let consumed: Double
    let goal: Double

    private var progress: Double {
        NutritionCalculator.progress(consumed, goal: goal)
    }

    private var remaining: Double {
        NutritionCalculator.remaining(consumed, goal: goal)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppStyle.accent.opacity(0.16), lineWidth: 14)

            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [AppStyle.accentStrong, AppStyle.accent, AppStyle.accentStrong]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.8), value: progress)

            VStack(spacing: 2) {
                Text("\(Int(remaining))")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())

                Text("remaining")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppStyle.subtleText)
            }
        }
        .frame(width: 120, height: 120)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Calories remaining")
        .accessibilityValue("\(Int(remaining)) of \(Int(goal)) kilocalories remaining")
    }
}

#Preview {
    VStack(spacing: 20) {
        CalorieRingView(consumed: 1450, goal: 2000)

        HStack(spacing: 24) {
            MacroRingView(progress: 0.7, color: .blue, label: "Protein", valueText: "105g")
            MacroRingView(progress: 0.5, color: .orange, label: "Carbs", valueText: "125g")
            MacroRingView(progress: 0.6, color: .pink, label: "Fat", valueText: "39g")
        }
    }
    .padding()
}
