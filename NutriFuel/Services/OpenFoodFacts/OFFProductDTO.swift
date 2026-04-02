import Foundation

struct OFFProductDTO: Equatable {
    let surrogateId: Int
    let code: String
    let name: String
    let brandOwner: String?
    let servingSize: Double
    let servingUnit: String
    let calories: Double
    let protein: Double
    let carbohydrates: Double
    let fat: Double
    let fiber: Double?
    let sugar: Double?
    let sodium: Double?
    let potassium: Double?
    let calcium: Double?
    let iron: Double?
    let vitaminC: Double?
    let vitaminD: Double?
}

extension OFFProductDTO {
    static func from(product: OFFProductPayload, expectedBarcode: String?) -> OFFProductDTO? {
        let normalizedCode = normalizeBarcode(product.code)
        guard !normalizedCode.isEmpty else { return nil }

        let normalizedExpected = normalizeBarcode(expectedBarcode)
        if !normalizedExpected.isEmpty && normalizedExpected != normalizedCode {
            return nil
        }

        let trimmedName = (product.productName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedName = trimmedName.isEmpty ? "Unnamed Product" : trimmedName
        let trimmedBrand = (product.brands ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedBrand = trimmedBrand.isEmpty ? nil : trimmedBrand

        let nutritionPer = (product.nutritionDataPer ?? "").lowercased()
        let prefer100ml = nutritionPer == "100ml"
        let servingUnit = prefer100ml ? "ml" : "g"

        let calories = product.nutriments?.preferredValue(
            defaultValue: product.nutriments?.energyKcal,
            value100g: product.nutriments?.energyKcal100g,
            value100ml: product.nutriments?.energyKcal100ml,
            prefer100ml: prefer100ml
        ) ?? 0

        let protein = product.nutriments?.preferredValue(
            defaultValue: product.nutriments?.proteins,
            value100g: product.nutriments?.proteins100g,
            value100ml: product.nutriments?.proteins100ml,
            prefer100ml: prefer100ml
        ) ?? 0

        let carbohydrates = product.nutriments?.preferredValue(
            defaultValue: product.nutriments?.carbohydrates,
            value100g: product.nutriments?.carbohydrates100g,
            value100ml: product.nutriments?.carbohydrates100ml,
            prefer100ml: prefer100ml
        ) ?? 0

        let fat = product.nutriments?.preferredValue(
            defaultValue: product.nutriments?.fat,
            value100g: product.nutriments?.fat100g,
            value100ml: product.nutriments?.fat100ml,
            prefer100ml: prefer100ml
        ) ?? 0

        let fiber = product.nutriments?.preferredValue(
            defaultValue: product.nutriments?.fiber,
            value100g: product.nutriments?.fiber100g,
            value100ml: product.nutriments?.fiber100ml,
            prefer100ml: prefer100ml
        )

        let sugar = product.nutriments?.preferredValue(
            defaultValue: product.nutriments?.sugars,
            value100g: product.nutriments?.sugars100g,
            value100ml: product.nutriments?.sugars100ml,
            prefer100ml: prefer100ml
        )

        let sodium = product.nutriments?.preferredValue(
            defaultValue: product.nutriments?.sodium,
            value100g: product.nutriments?.sodium100g,
            value100ml: product.nutriments?.sodium100ml,
            prefer100ml: prefer100ml
        ).map {
            OFFUnitConverter.toMilligrams(value: $0, unit: product.nutriments?.sodiumUnit)
        }

        return OFFProductDTO(
            surrogateId: stableSurrogateId(forCode: normalizedCode),
            code: normalizedCode,
            name: resolvedName,
            brandOwner: resolvedBrand,
            servingSize: 100,
            servingUnit: servingUnit,
            calories: calories,
            protein: protein,
            carbohydrates: carbohydrates,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            potassium: nil,
            calcium: nil,
            iron: nil,
            vitaminC: nil,
            vitaminD: nil
        )
    }

    static func normalizeBarcode(_ raw: String?) -> String {
        (raw ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func stableSurrogateId(forCode code: String) -> Int {
        var hash: UInt64 = 14695981039346656037
        for byte in code.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1099511628211
        }

        let positive = Int(truncatingIfNeeded: hash & 0x7fff_ffff_ffff_ffff)
        return positive == 0 ? 1 : positive
    }
}

struct OFFProductPayload: Decodable {
    let code: String?
    let productName: String?
    let brands: String?
    let servingSize: String?
    let servingQuantity: Double?
    let servingQuantityUnit: String?
    let nutritionDataPer: String?
    let nutriments: OFFNutriments?

    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case brands
        case servingSize = "serving_size"
        case servingQuantity = "serving_quantity"
        case servingQuantityUnit = "serving_quantity_unit"
        case nutritionDataPer = "nutrition_data_per"
        case nutriments
    }

    init(
        code: String?,
        productName: String?,
        brands: String?,
        servingSize: String?,
        servingQuantity: Double?,
        servingQuantityUnit: String?,
        nutritionDataPer: String?,
        nutriments: OFFNutriments?
    ) {
        self.code = code
        self.productName = productName
        self.brands = brands
        self.servingSize = servingSize
        self.servingQuantity = servingQuantity
        self.servingQuantityUnit = servingQuantityUnit
        self.nutritionDataPer = nutritionDataPer
        self.nutriments = nutriments
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decodeIfPresent(String.self, forKey: .code)
        productName = try container.decodeIfPresent(String.self, forKey: .productName)
        brands = try container.decodeIfPresent(String.self, forKey: .brands)
        servingSize = try container.decodeIfPresent(String.self, forKey: .servingSize)
        servingQuantity = container.decodeFlexibleDoubleIfPresent(forKey: .servingQuantity)
        servingQuantityUnit = try container.decodeIfPresent(String.self, forKey: .servingQuantityUnit)
        nutritionDataPer = try container.decodeIfPresent(String.self, forKey: .nutritionDataPer)
        nutriments = try container.decodeIfPresent(OFFNutriments.self, forKey: .nutriments)
    }
}

struct OFFNutriments: Decodable {
    let energyKcal: Double?
    let energyKcal100g: Double?
    let energyKcal100ml: Double?

    let proteins: Double?
    let proteins100g: Double?
    let proteins100ml: Double?

    let carbohydrates: Double?
    let carbohydrates100g: Double?
    let carbohydrates100ml: Double?

    let fat: Double?
    let fat100g: Double?
    let fat100ml: Double?

    let fiber: Double?
    let fiber100g: Double?
    let fiber100ml: Double?

    let sugars: Double?
    let sugars100g: Double?
    let sugars100ml: Double?

    let sodium: Double?
    let sodium100g: Double?
    let sodium100ml: Double?
    let sodiumUnit: String?

    enum CodingKeys: String, CodingKey {
        case energyKcal = "energy-kcal"
        case energyKcal100g = "energy-kcal_100g"
        case energyKcal100ml = "energy-kcal_100ml"

        case proteins
        case proteins100g = "proteins_100g"
        case proteins100ml = "proteins_100ml"

        case carbohydrates
        case carbohydrates100g = "carbohydrates_100g"
        case carbohydrates100ml = "carbohydrates_100ml"

        case fat
        case fat100g = "fat_100g"
        case fat100ml = "fat_100ml"

        case fiber
        case fiber100g = "fiber_100g"
        case fiber100ml = "fiber_100ml"

        case sugars
        case sugars100g = "sugars_100g"
        case sugars100ml = "sugars_100ml"

        case sodium
        case sodium100g = "sodium_100g"
        case sodium100ml = "sodium_100ml"
        case sodiumUnit = "sodium_unit"
    }

    func preferredValue(defaultValue: Double?, value100g: Double?, value100ml: Double?, prefer100ml: Bool) -> Double? {
        if prefer100ml {
            return firstNonNil([value100ml, defaultValue, value100g])
        }
        return firstNonNil([value100g, defaultValue, value100ml])
    }

    private func firstNonNil(_ candidates: [Double?]) -> Double? {
        candidates.compactMap { $0 }.first
    }
}

private enum OFFUnitConverter {
    static func toMilligrams(value: Double, unit: String?) -> Double {
        switch (unit ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "mg":
            return value
        case "g":
            return value * 1_000
        case "µg", "mcg", "ug":
            return value / 1_000
        default:
            return value
        }
    }
}

private extension KeyedDecodingContainer {
    func decodeFlexibleDoubleIfPresent(forKey key: Key) -> Double? {
        if let value = try? decodeIfPresent(Double.self, forKey: key) {
            return value
        }

        if let intValue = try? decodeIfPresent(Int.self, forKey: key) {
            return Double(intValue)
        }

        if let stringValue = try? decodeIfPresent(String.self, forKey: key) {
            let normalized = stringValue
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: ",", with: ".")
            return Double(normalized)
        }

        return nil
    }
}
