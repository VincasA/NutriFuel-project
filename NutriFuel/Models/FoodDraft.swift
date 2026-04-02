import Foundation

struct FoodDraft: Equatable {
    static let servingUnits = ["serving", "g", "ml", "oz", "piece", "cup", "tbsp", "tsp", "slice"]

    var name: String = ""
    var brand: String = ""
    var servingSize: String = "100"
    var servingUnit: String = "g"
    var calories: String = ""
    var protein: String = ""
    var carbohydrates: String = ""
    var fat: String = ""
    var fiber: String = ""
    var sugar: String = ""
    var sodium: String = ""
    var potassium: String = ""
    var calcium: String = ""
    var iron: String = ""
    var vitaminC: String = ""
    var vitaminD: String = ""
    var barcode: String = ""

    init() {}

    init(food: Food) {
        self.init(
            name: food.name,
            brand: food.brand,
            servingSize: food.servingSize,
            servingUnit: food.servingUnit,
            calories: food.calories,
            protein: food.protein,
            carbohydrates: food.carbohydrates,
            fat: food.fat,
            fiber: food.fiber,
            sugar: food.sugar,
            sodium: food.sodium,
            potassium: food.potassium,
            calcium: food.calcium,
            iron: food.iron,
            vitaminC: food.vitaminC,
            vitaminD: food.vitaminD,
            barcode: food.barcode
        )
    }

    init(officialFood: OfficialFood) {
        self.init(
            name: officialFood.name,
            brand: officialFood.brandOwner,
            servingSize: officialFood.servingSize,
            servingUnit: officialFood.servingUnit,
            calories: officialFood.calories,
            protein: officialFood.protein,
            carbohydrates: officialFood.carbohydrates,
            fat: officialFood.fat,
            fiber: officialFood.fiber,
            sugar: officialFood.sugar,
            sodium: officialFood.sodium,
            potassium: officialFood.potassium,
            calcium: officialFood.calcium,
            iron: officialFood.iron,
            vitaminC: officialFood.vitaminC,
            vitaminD: officialFood.vitaminD,
            barcode: officialFood.gtinUpc
        )
    }

    init(
        name: String,
        brand: String?,
        servingSize: Double,
        servingUnit: String,
        calories: Double,
        protein: Double,
        carbohydrates: Double,
        fat: Double,
        fiber: Double?,
        sugar: Double?,
        sodium: Double?,
        potassium: Double?,
        calcium: Double?,
        iron: Double?,
        vitaminC: Double?,
        vitaminD: Double?,
        barcode: String?
    ) {
        self.name = name
        self.brand = brand ?? ""
        self.servingSize = Self.string(from: servingSize)
        self.servingUnit = servingUnit
        self.calories = Self.string(from: calories)
        self.protein = Self.string(from: protein)
        self.carbohydrates = Self.string(from: carbohydrates)
        self.fat = Self.string(from: fat)
        self.fiber = Self.string(from: fiber)
        self.sugar = Self.string(from: sugar)
        self.sodium = Self.string(from: sodium)
        self.potassium = Self.string(from: potassium)
        self.calcium = Self.string(from: calcium)
        self.iron = Self.string(from: iron)
        self.vitaminC = Self.string(from: vitaminC)
        self.vitaminD = Self.string(from: vitaminD)
        self.barcode = barcode ?? ""
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedBrand: String {
        brand.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedBarcode: String? {
        let normalized = OFFProductDTO.normalizeBarcode(barcode)
        return normalized.isEmpty ? nil : normalized
    }

    var servingSizeValue: Double? {
        LocalizedDecimalParser.parse(servingSize)
    }

    var caloriesValue: Double? {
        LocalizedDecimalParser.parse(calories)
    }

    var proteinValue: Double? {
        LocalizedDecimalParser.parse(protein)
    }

    var carbohydratesValue: Double? {
        LocalizedDecimalParser.parse(carbohydrates)
    }

    var fatValue: Double? {
        LocalizedDecimalParser.parse(fat)
    }

    var fiberValue: Double? {
        Self.optionalValue(from: fiber)
    }

    var sugarValue: Double? {
        Self.optionalValue(from: sugar)
    }

    var sodiumValue: Double? {
        Self.optionalValue(from: sodium)
    }

    var potassiumValue: Double? {
        Self.optionalValue(from: potassium)
    }

    var calciumValue: Double? {
        Self.optionalValue(from: calcium)
    }

    var ironValue: Double? {
        Self.optionalValue(from: iron)
    }

    var vitaminCValue: Double? {
        Self.optionalValue(from: vitaminC)
    }

    var vitaminDValue: Double? {
        Self.optionalValue(from: vitaminD)
    }

    var hasMicros: Bool {
        sodiumValue != nil ||
        potassiumValue != nil ||
        calciumValue != nil ||
        ironValue != nil ||
        vitaminCValue != nil ||
        vitaminDValue != nil
    }

    var isValid: Bool {
        !trimmedName.isEmpty &&
        (servingSizeValue ?? 0) > 0 &&
        caloriesValue != nil &&
        proteinValue != nil &&
        carbohydratesValue != nil &&
        fatValue != nil
    }

    func isEquivalent(to other: FoodDraft) -> Bool {
        trimmedName == other.trimmedName &&
        trimmedBrand == other.trimmedBrand &&
        servingUnit == other.servingUnit &&
        normalizedBarcode == other.normalizedBarcode &&
        Self.numericEquals(servingSizeValue, other.servingSizeValue) &&
        Self.numericEquals(caloriesValue, other.caloriesValue) &&
        Self.numericEquals(proteinValue, other.proteinValue) &&
        Self.numericEquals(carbohydratesValue, other.carbohydratesValue) &&
        Self.numericEquals(fatValue, other.fatValue) &&
        Self.numericEquals(fiberValue, other.fiberValue) &&
        Self.numericEquals(sugarValue, other.sugarValue) &&
        Self.numericEquals(sodiumValue, other.sodiumValue) &&
        Self.numericEquals(potassiumValue, other.potassiumValue) &&
        Self.numericEquals(calciumValue, other.calciumValue) &&
        Self.numericEquals(ironValue, other.ironValue) &&
        Self.numericEquals(vitaminCValue, other.vitaminCValue) &&
        Self.numericEquals(vitaminDValue, other.vitaminDValue)
    }

    func makeFood(isListedInDatabase: Bool = true) -> Food {
        Food(
            name: trimmedName,
            brand: trimmedBrand.isEmpty ? nil : trimmedBrand,
            isListedInDatabase: isListedInDatabase,
            servingSize: servingSizeValue ?? 100,
            servingUnit: servingUnit,
            calories: caloriesValue ?? 0,
            protein: proteinValue ?? 0,
            carbohydrates: carbohydratesValue ?? 0,
            fat: fatValue ?? 0,
            fiber: fiberValue,
            sugar: sugarValue,
            sodium: sodiumValue,
            potassium: potassiumValue,
            calcium: calciumValue,
            iron: ironValue,
            vitaminC: vitaminCValue,
            vitaminD: vitaminDValue,
            barcode: normalizedBarcode
        )
    }

    func apply(to food: Food, isListedInDatabase: Bool? = nil) {
        food.name = trimmedName
        food.brand = trimmedBrand.isEmpty ? nil : trimmedBrand
        if let isListedInDatabase {
            food.isListedInDatabase = isListedInDatabase
        }
        food.servingSize = servingSizeValue ?? 100
        food.servingUnit = servingUnit
        food.calories = caloriesValue ?? 0
        food.protein = proteinValue ?? 0
        food.carbohydrates = carbohydratesValue ?? 0
        food.fat = fatValue ?? 0
        food.fiber = fiberValue
        food.sugar = sugarValue
        food.sodium = sodiumValue
        food.potassium = potassiumValue
        food.calcium = calciumValue
        food.iron = ironValue
        food.vitaminC = vitaminCValue
        food.vitaminD = vitaminDValue
        food.barcode = normalizedBarcode
    }

    private static func optionalValue(from text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return LocalizedDecimalParser.parse(trimmed)
    }

    private static func numericEquals(_ lhs: Double?, _ rhs: Double?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            true
        case let (lhs?, rhs?):
            abs(lhs - rhs) < 0.0001
        default:
            false
        }
    }

    private static func string(from value: Double?) -> String {
        guard let value else { return "" }
        if abs(value.rounded() - value) < 0.0001 {
            return String(Int(value.rounded()))
        }
        return String(format: "%.2f", value)
            .replacingOccurrences(of: "\\.?0+$", with: "", options: .regularExpression)
    }
}
