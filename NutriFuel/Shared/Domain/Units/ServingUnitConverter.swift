import Foundation

enum ServingQuantityUnit: String, CaseIterable, Identifiable {
    case serving
    case gram
    case hundredGrams
    case kilogram
    case milliliter
    case hundredMilliliters
    case liter
    case ounce
    case piece
    case cup
    case tablespoon
    case teaspoon
    case slice

    var id: String { rawValue }

    var label: String {
        switch self {
        case .serving: return "serving"
        case .gram: return "g"
        case .hundredGrams: return "100g"
        case .kilogram: return "kg"
        case .milliliter: return "ml"
        case .hundredMilliliters: return "100ml"
        case .liter: return "l"
        case .ounce: return "oz"
        case .piece: return "piece"
        case .cup: return "cup"
        case .tablespoon: return "tbsp"
        case .teaspoon: return "tsp"
        case .slice: return "slice"
        }
    }

    static func fromFoodServingUnit(_ unit: String) -> ServingQuantityUnit {
        switch unit.lowercased() {
        case "g", "gram", "grams": return .gram
        case "kg": return .kilogram
        case "ml": return .milliliter
        case "l": return .liter
        case "oz": return .ounce
        case "piece": return .piece
        case "cup": return .cup
        case "tbsp": return .tablespoon
        case "tsp": return .teaspoon
        case "slice": return .slice
        case "serving": return .serving
        default: return .serving
        }
    }

    static func defaultLoggingUnit(for servingUnit: String) -> ServingQuantityUnit {
        switch fromFoodServingUnit(servingUnit) {
        case .gram, .hundredGrams, .kilogram, .ounce:
            .hundredGrams
        case .milliliter, .hundredMilliliters, .liter, .cup, .tablespoon, .teaspoon:
            .hundredMilliliters
        case .serving, .piece, .slice:
            .serving
        }
    }
}

enum ServingUnitConverter {
    private enum QuantityDimension {
        case mass
        case volume
        case count
    }

    private struct NormalizedQuantity {
        let value: Double
        let dimension: QuantityDimension
    }

    static func amountInServings(
        amount: Double,
        amountUnit: ServingQuantityUnit,
        servingSize: Double,
        servingUnit: String
    ) -> Double? {
        guard amount > 0 else { return nil }
        guard let input = normalizedQuantity(unit: amountUnit, amount: amount),
              let serving = normalizedQuantity(unit: .fromFoodServingUnit(servingUnit), amount: servingSize),
              input.dimension == serving.dimension,
              serving.value > 0 else {
            return nil
        }
        return input.value / serving.value
    }

    static func amountFromServings(
        servings: Double,
        outputUnit: ServingQuantityUnit,
        servingSize: Double,
        servingUnit: String
    ) -> Double? {
        guard servings > 0,
              let output = normalizedQuantity(unit: outputUnit, amount: 1),
              let serving = normalizedQuantity(unit: .fromFoodServingUnit(servingUnit), amount: servingSize),
              output.dimension == serving.dimension,
              output.value > 0 else {
            return nil
        }
        let baseValue = servings * serving.value
        return baseValue / output.value
    }

    private static func normalizedQuantity(unit: ServingQuantityUnit, amount: Double) -> NormalizedQuantity? {
        switch unit {
        case .serving, .piece, .slice:
            return NormalizedQuantity(value: amount, dimension: .count)
        case .gram:
            return NormalizedQuantity(value: amount, dimension: .mass)
        case .hundredGrams:
            return NormalizedQuantity(value: amount * 100, dimension: .mass)
        case .kilogram:
            return NormalizedQuantity(value: amount * 1000, dimension: .mass)
        case .ounce:
            return NormalizedQuantity(value: amount * 28.3495, dimension: .mass)
        case .milliliter:
            return NormalizedQuantity(value: amount, dimension: .volume)
        case .hundredMilliliters:
            return NormalizedQuantity(value: amount * 100, dimension: .volume)
        case .liter:
            return NormalizedQuantity(value: amount * 1000, dimension: .volume)
        case .cup:
            return NormalizedQuantity(value: amount * 240, dimension: .volume)
        case .tablespoon:
            return NormalizedQuantity(value: amount * 15, dimension: .volume)
        case .teaspoon:
            return NormalizedQuantity(value: amount * 5, dimension: .volume)
        }
    }
}
