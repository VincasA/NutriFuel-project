//
//  NutriFuelTests.swift
//  NutriFuelTests
//

import Testing
import Foundation
import SwiftData
@testable import NutriFuel

// MARK: - parseDouble tests (comma/period decimal handling)

/// Parses a numeric string accepting both comma and period as decimal separator.
/// Duplicated here for direct unit testing of the logic.
private func parseDouble(_ text: String) -> Double? {
    let normalized = text.replacingOccurrences(of: ",", with: ".")
    return Double(normalized)
}

@Suite("Decimal Parsing")
struct ParseDoubleTests {

    @Test("Parses period as decimal separator")
    func periodSeparator() {
        #expect(parseDouble("1.5") == 1.5)
        #expect(parseDouble("100.25") == 100.25)
        #expect(parseDouble("0.1") == 0.1)
    }

    @Test("Parses comma as decimal separator")
    func commaSeparator() {
        #expect(parseDouble("1,5") == 1.5)
        #expect(parseDouble("100,25") == 100.25)
        #expect(parseDouble("0,1") == 0.1)
    }

    @Test("Parses whole numbers")
    func wholeNumbers() {
        #expect(parseDouble("100") == 100.0)
        #expect(parseDouble("0") == 0.0)
        #expect(parseDouble("2000") == 2000.0)
    }

    @Test("Returns nil for invalid input")
    func invalidInput() {
        #expect(parseDouble("") == nil)
        #expect(parseDouble("abc") == nil)
        #expect(parseDouble("12.3.4") == nil)
        #expect(parseDouble("12,3,4") == nil)
    }

    @Test("Handles edge cases")
    func edgeCases() {
        #expect(parseDouble(".5") == 0.5)
        #expect(parseDouble(",5") == 0.5)
        #expect(parseDouble("5.") == 5.0)
        #expect(parseDouble("5,") == 5.0)
    }
}

// MARK: - NutritionCalculator tests

@Suite("NutritionCalculator")
struct NutritionCalculatorTests {

    @Test("Progress clamps to 0-1 range")
    func progressClamping() {
        #expect(NutritionCalculator.progress(500, goal: 2000) == 0.25)
        #expect(NutritionCalculator.progress(2000, goal: 2000) == 1.0)
        #expect(NutritionCalculator.progress(3000, goal: 2000) == 1.0) // clamped
        #expect(NutritionCalculator.progress(0, goal: 2000) == 0.0)
        #expect(NutritionCalculator.progress(100, goal: 0) == 0.0)   // zero goal
    }

    @Test("Remaining never goes negative")
    func remainingNonNegative() {
        #expect(NutritionCalculator.remaining(500, goal: 2000) == 1500)
        #expect(NutritionCalculator.remaining(2000, goal: 2000) == 0)
        #expect(NutritionCalculator.remaining(2500, goal: 2000) == 0)  // clamped at 0
        #expect(NutritionCalculator.remaining(0, goal: 2000) == 2000)
    }

    @Test("Macro percentages add up to 100")
    func macroPercentages() {
        // 100g protein (400 cal), 100g carbs (400 cal), 44.4g fat (400 cal) → 33/33/33
        let result = NutritionCalculator.macroPercentages(protein: 100, carbs: 100, fat: 44.44)
        #expect(abs(result.proteinPct - 33.33) < 0.5)
        #expect(abs(result.carbsPct - 33.33) < 0.5)
        #expect(abs(result.fatPct - 33.33) < 0.5)
    }

    @Test("Macro percentages with zero intake")
    func macroPercentagesZero() {
        let result = NutritionCalculator.macroPercentages(protein: 0, carbs: 0, fat: 0)
        #expect(result.proteinPct == 0)
        #expect(result.carbsPct == 0)
        #expect(result.fatPct == 0)
    }

    @Test("Start of day returns midnight")
    func startOfDay() {
        let date = Date()
        let start = NutritionCalculator.startOfDay(date)
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: start)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    @Test("End of day returns 23:59:59")
    func endOfDay() {
        let date = Date()
        let end = NutritionCalculator.endOfDay(date)
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: end)
        #expect(components.hour == 23)
        #expect(components.minute == 59)
        #expect(components.second == 59)
    }

    @Test("Start and end are on the same calendar day")
    func sameDay() {
        let date = Date()
        let start = NutritionCalculator.startOfDay(date)
        let end = NutritionCalculator.endOfDay(date)
        #expect(Calendar.current.isDate(start, inSameDayAs: end))
    }
}

// MARK: - MealType tests

@Suite("MealType")
struct MealTypeTests {

    @Test("All cases have correct raw values")
    func rawValues() {
        #expect(MealType.breakfast.rawValue == "Breakfast")
        #expect(MealType.lunch.rawValue == "Lunch")
        #expect(MealType.dinner.rawValue == "Dinner")
        #expect(MealType.snack.rawValue == "Snacks")
    }

    @Test("All cases have SF Symbol icons")
    func iconsExist() {
        for meal in MealType.allCases {
            #expect(!meal.icon.isEmpty)
        }
    }

    @Test("CaseIterable returns 4 cases")
    func allCasesCount() {
        #expect(MealType.allCases.count == 4)
    }

    @Test("Codable round-trip")
    func codableRoundTrip() throws {
        for meal in MealType.allCases {
            let encoded = try JSONEncoder().encode(meal)
            let decoded = try JSONDecoder().decode(MealType.self, from: encoded)
            #expect(decoded == meal)
        }
    }
}

// MARK: - Food model tests

@Suite("Food Model")
struct FoodModelTests {

    @Test("Display name without brand")
    func displayNameNoBrand() {
        let food = Food(name: "Chicken Breast")
        #expect(food.displayName == "Chicken Breast")
    }

    @Test("Display name with brand")
    func displayNameWithBrand() {
        let food = Food(name: "Chicken Breast", brand: "Organic Farm")
        #expect(food.displayName == "Chicken Breast (Organic Farm)")
    }

    @Test("Display name with empty brand")
    func displayNameEmptyBrand() {
        let food = Food(name: "Chicken Breast", brand: "")
        #expect(food.displayName == "Chicken Breast")
    }

    @Test("Default values are sensible")
    func defaultValues() {
        let food = Food(name: "Test")
        #expect(food.servingSize == 100)
        #expect(food.servingUnit == "g")
        #expect(food.calories == 0)
        #expect(food.protein == 0)
        #expect(food.carbohydrates == 0)
        #expect(food.fat == 0)
        #expect(food.barcode == nil)
        #expect(food.brand == nil)
    }

    @Test("All nutrition fields store correctly")
    func nutritionFields() {
        let food = Food(
            name: "Full Food",
            servingSize: 150,
            servingUnit: "ml",
            calories: 250,
            protein: 20,
            carbohydrates: 30,
            fat: 10,
            fiber: 5,
            sugar: 8,
            sodium: 200,
            potassium: 400,
            calcium: 100,
            iron: 2,
            vitaminC: 15,
            vitaminD: 600,
            barcode: "1234567890123"
        )
        #expect(food.calories == 250)
        #expect(food.protein == 20)
        #expect(food.carbohydrates == 30)
        #expect(food.fat == 10)
        #expect(food.fiber == 5)
        #expect(food.sugar == 8)
        #expect(food.sodium == 200)
        #expect(food.potassium == 400)
        #expect(food.calcium == 100)
        #expect(food.iron == 2)
        #expect(food.vitaminC == 15)
        #expect(food.vitaminD == 600)
        #expect(food.barcode == "1234567890123")
    }
}

// MARK: - LogEntry computed nutrition tests

@Suite("LogEntry Computed Nutrition")
struct LogEntryNutritionTests {

    private func makeFoodAndEntry(
        calories: Double = 200,
        protein: Double = 20,
        carbs: Double = 30,
        fat: Double = 10,
        fiber: Double? = 5,
        sugar: Double? = 8,
        quantity: Double = 1.0
    ) -> LogEntry {
        let food = Food(
            name: "Test Food",
            calories: calories,
            protein: protein,
            carbohydrates: carbs,
            fat: fat,
            fiber: fiber,
            sugar: sugar
        )
        return LogEntry(food: food, quantity: quantity, mealType: .breakfast)
    }

    @Test("Single serving totals match food values")
    func singleServing() {
        let entry = makeFoodAndEntry(quantity: 1.0)
        #expect(entry.totalCalories == 200)
        #expect(entry.totalProtein == 20)
        #expect(entry.totalCarbs == 30)
        #expect(entry.totalFat == 10)
        #expect(entry.totalFiber == 5)
        #expect(entry.totalSugar == 8)
    }

    @Test("Double serving doubles all values")
    func doubleServing() {
        let entry = makeFoodAndEntry(quantity: 2.0)
        #expect(entry.totalCalories == 400)
        #expect(entry.totalProtein == 40)
        #expect(entry.totalCarbs == 60)
        #expect(entry.totalFat == 20)
    }

    @Test("Half serving halves all values")
    func halfServing() {
        let entry = makeFoodAndEntry(quantity: 0.5)
        #expect(entry.totalCalories == 100)
        #expect(entry.totalProtein == 10)
        #expect(entry.totalCarbs == 15)
        #expect(entry.totalFat == 5)
    }

    @Test("Fractional quantities (1.5 servings)")
    func fractionalServing() {
        let entry = makeFoodAndEntry(calories: 100, protein: 10, carbs: 20, fat: 5, quantity: 1.5)
        #expect(entry.totalCalories == 150)
        #expect(entry.totalProtein == 15)
        #expect(entry.totalCarbs == 30)
        #expect(entry.totalFat == 7.5)
    }

    @Test("Zero quantity returns zero")
    func zeroQuantity() {
        let entry = makeFoodAndEntry(quantity: 0)
        #expect(entry.totalCalories == 0)
        #expect(entry.totalProtein == 0)
    }

    @Test("MealType stored correctly")
    func mealTypeStorage() {
        let food = Food(name: "Test")
        let entry = LogEntry(food: food, quantity: 1, mealType: .dinner)
        #expect(entry.mealType == .dinner)
        #expect(entry.mealTypeRaw == "Dinner")
    }
}

// MARK: - NutritionCalculator.totals aggregation tests

@Suite("NutritionCalculator Aggregation")
struct NutritionCalculatorAggregationTests {

    private func makeEntry(cal: Double, protein: Double, carbs: Double, fat: Double) -> LogEntry {
        let food = Food(name: "F", calories: cal, protein: protein, carbohydrates: carbs, fat: fat)
        return LogEntry(food: food, quantity: 1.0, mealType: .breakfast)
    }

    @Test("Totals from multiple entries")
    func multipleTotals() {
        let entries = [
            makeEntry(cal: 300, protein: 25, carbs: 40, fat: 10),
            makeEntry(cal: 200, protein: 15, carbs: 20, fat: 8),
            makeEntry(cal: 100, protein: 5, carbs: 15, fat: 2),
        ]
        let totals = NutritionCalculator.totals(for: entries)
        #expect(totals.calories == 600)
        #expect(totals.protein == 45)
        #expect(totals.carbs == 75)
        #expect(totals.fat == 20)
    }

    @Test("Totals from empty array")
    func emptyTotals() {
        let totals = NutritionCalculator.totals(for: [])
        #expect(totals.calories == 0)
        #expect(totals.protein == 0)
        #expect(totals.carbs == 0)
        #expect(totals.fat == 0)
    }
}

// MARK: - UserGoals defaults

@Suite("UserGoals")
struct UserGoalsTests {

    @Test("Default values are reasonable")
    func defaults() {
        let goals = UserGoals()
        #expect(goals.calorieGoal == 2000)
        #expect(goals.proteinGoal == 150)
        #expect(goals.carbsGoal == 250)
        #expect(goals.fatGoal == 65)
        #expect(goals.fiberGoal == 30)
        #expect(goals.sugarGoal == 50)
        #expect(goals.sodiumGoal == 2300)
    }

    @Test("Custom values are stored")
    func customValues() {
        let goals = UserGoals(
            calorieGoal: 1800,
            proteinGoal: 120,
            carbsGoal: 200,
            fatGoal: 55
        )
        #expect(goals.calorieGoal == 1800)
        #expect(goals.proteinGoal == 120)
        #expect(goals.carbsGoal == 200)
        #expect(goals.fatGoal == 55)
    }
}

// MARK: - Data flow tests for add-log behavior

@Suite("Food Barcode Lookup")
struct FoodBarcodeLookupTests {

    @Test("Finds visible foods by barcode")
    func findsExistingBarcode() throws {
        let container = try ModelContainer(
            for: Food.self, OfficialFood.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let vm = FoodDatabaseViewModel(modelContext: context)

        let known = Food(name: "Known", calories: 100, protein: 10, carbohydrates: 10, fat: 2, barcode: "111222333")
        context.insert(known)
        try context.save()

        let found = vm.findFoodsByBarcode("111222333")
        #expect(found.map(\.id) == [known.id])
    }

    @Test("Ignores hidden foods during barcode lookup")
    func ignoresHiddenFoods() throws {
        let container = try ModelContainer(
            for: Food.self, OfficialFood.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let vm = FoodDatabaseViewModel(modelContext: context)

        context.insert(Food(
            name: "Hidden",
            isListedInDatabase: false,
            calories: 100,
            protein: 10,
            carbohydrates: 10,
            fat: 2,
            barcode: "111222333"
        ))
        try context.save()

        #expect(vm.findFoodsByBarcode("111222333").isEmpty)
    }

    @Test("Returns empty array for unknown barcode")
    func unknownBarcode() throws {
        let container = try ModelContainer(
            for: Food.self, OfficialFood.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let vm = FoodDatabaseViewModel(modelContext: context)

        #expect(vm.findFoodsByBarcode("does-not-exist").isEmpty)
    }

    @Test("Fetch foods excludes hidden items")
    func fetchFoodsExcludesHiddenItems() throws {
        let container = try ModelContainer(
            for: Food.self, OfficialFood.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let repository = SwiftDataFoodRepository(modelContext: context)

        context.insert(Food(name: "Visible", calories: 100, protein: 10, carbohydrates: 10, fat: 2))
        context.insert(Food(name: "Hidden", isListedInDatabase: false, calories: 100, protein: 10, carbohydrates: 10, fat: 2))
        try context.save()

        let foods = repository.fetchFoods(matching: nil, limit: 10)
        #expect(foods.map(\.name) == ["Visible"])
    }
}

@Suite("Daily Log Add Entry")
struct DailyLogAddEntryTests {

    @Test("Creates an entry with expected values")
    func addsEntry() throws {
        let container = try ModelContainer(
            for: Food.self, OfficialFood.self, LogEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let vm = DailyLogViewModel(modelContext: context)
        let food = Food(name: "Eggs", calories: 155, protein: 13, carbohydrates: 1.1, fat: 11)
        context.insert(food)
        try context.save()

        vm.addEntry(food: food, quantity: 2.0, mealType: .breakfast)

        #expect(vm.entries.count == 1)
        #expect(vm.entries.first?.mealType == .breakfast)
        #expect(vm.entries.first?.totalCalories == 310)
    }
}

// MARK: - Open Food Facts mapping and repository behavior

@Suite("Open Food Facts Mapping")
struct OFFMappingTests {

    @Test("Prefers 100ml nutriments when nutrition_data_per is 100ml")
    func mappingPriority100ml() {
        let product = OFFProductPayload(
            code: "000123",
            productName: "Drink",
            brands: "Test Brand",
            servingSize: "330 ml",
            servingQuantity: 330,
            servingQuantityUnit: "ml",
            nutritionDataPer: "100ml",
            nutriments: OFFNutriments(
                energyKcal: 99,
                energyKcal100g: 111,
                energyKcal100ml: 42,
                proteins: 9,
                proteins100g: 10,
                proteins100ml: 3,
                carbohydrates: 12,
                carbohydrates100g: 13,
                carbohydrates100ml: 4,
                fat: 15,
                fat100g: 16,
                fat100ml: 1,
                fiber: 7,
                fiber100g: 8,
                fiber100ml: 0.5,
                sugars: 6,
                sugars100g: 7,
                sugars100ml: 2,
                sodium: 0.2,
                sodium100g: 0.3,
                sodium100ml: 0.12,
                sodiumUnit: "g"
            )
        )

        let dto = OFFProductDTO.from(product: product, expectedBarcode: "000123")
        #expect(dto != nil)
        #expect(dto?.servingSize == 100)
        #expect(dto?.servingUnit == "ml")
        #expect(dto?.calories == 42)
        #expect(dto?.protein == 3)
        #expect(dto?.carbohydrates == 4)
        #expect(dto?.fat == 1)
        #expect(dto?.fiber == 0.5)
        #expect(dto?.sugar == 2)
        #expect(dto?.sodium == 120)
    }

    @Test("Rejects non-matching barcode")
    func barcodeMismatch() {
        let product = OFFProductPayload(
            code: "999999999999",
            productName: "Different",
            brands: nil,
            servingSize: nil,
            servingQuantity: nil,
            servingQuantityUnit: nil,
            nutritionDataPer: nil,
            nutriments: nil
        )

        let dto = OFFProductDTO.from(product: product, expectedBarcode: "012345678905")
        #expect(dto == nil)
    }
}

@Suite("Open Food Facts Decoding")
struct OFFDecodingTests {

    @Test("Decodes product response status and product payload")
    func productResponseDecode() throws {
        let data = """
        {
          "status": 1,
          "product": {
            "code": "123",
            "product_name": "Decoded Product",
            "brands": "Brand",
            "nutrition_data_per": "100g",
            "nutriments": {
              "energy-kcal_100g": 250,
              "proteins_100g": 10
            }
          }
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(OFFProductResponse.self, from: data)
        #expect(decoded.status == 1)
        #expect(decoded.product?.code == "123")
        #expect(decoded.product?.productName == "Decoded Product")
    }

    @Test("Decodes not-found product response")
    func productNotFoundDecode() throws {
        let data = """
        {
          "status": 0,
          "status_verbose": "product not found"
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(OFFProductResponse.self, from: data)
        #expect(decoded.status == 0)
        #expect(decoded.product == nil)
    }

    @Test("Decodes search response page size and products")
    func searchResponseDecode() throws {
        let data = """
        {
          "count": 2,
          "page_size": 2,
          "products": [
            { "code": "111", "product_name": "One", "nutriments": {} },
            { "code": "222", "product_name": "Two", "nutriments": {} }
          ]
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(OFFSearchResponse.self, from: data)
        #expect(decoded.count == 2)
        #expect(decoded.pageSize == 2)
        #expect(decoded.products.count == 2)
    }
}

private enum OFFClientMockError: Error {
    case forced
}

private final class OFFClientMock: OpenFoodFactsProductFetching {
    var productResult: OFFProductDTO?
    var searchResult: [OFFProductDTO]
    var fetchError: Error?
    var searchError: Error?
    var fetchCallCount = 0
    var searchCallCount = 0

    init(productResult: OFFProductDTO? = nil, searchResult: [OFFProductDTO] = []) {
        self.productResult = productResult
        self.searchResult = searchResult
    }

    func fetchProduct(barcode: String) async throws -> OFFProductDTO? {
        fetchCallCount += 1
        if let fetchError { throw fetchError }
        return productResult
    }

    func searchProducts(query: String, limit: Int) async throws -> [OFFProductDTO] {
        searchCallCount += 1
        if let searchError { throw searchError }
        return Array(searchResult.prefix(limit))
    }
}

@Suite("OfficialFoodRepository")
struct OfficialFoodRepositoryTests {

    private func makeDTO(code: String, name: String, calories: Double) -> OFFProductDTO {
        OFFProductDTO(
            surrogateId: OFFProductDTO.stableSurrogateId(forCode: code),
            code: code,
            name: name,
            brandOwner: "Brand",
            servingSize: 100,
            servingUnit: "g",
            calories: calories,
            protein: 10,
            carbohydrates: 12,
            fat: 3,
            fiber: 1,
            sugar: 2,
            sodium: 200,
            potassium: nil,
            calcium: nil,
            iron: nil,
            vitaminC: nil,
            vitaminD: nil
        )
    }

    @MainActor
    private func makeRepository(
        now: @escaping () -> Date = Date.init,
        refreshInterval: TimeInterval = 60 * 60 * 24 * 30,
        client: OFFClientMock
    ) throws -> (OfficialFoodRepository, ModelContext) {
        let container = try ModelContainer(
            for: OfficialFood.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let repository = OfficialFoodRepository(
            modelContext: context,
            offClient: client,
            now: now,
            refreshInterval: refreshInterval
        )
        return (repository, context)
    }

    @Test("Returns fresh cached food without network call")
    @MainActor
    func cacheHitFresh() async throws {
        let now = Date()
        let client = OFFClientMock()
        let (repository, context) = try makeRepository(now: { now }, client: client)

        let cached = OfficialFood(
            fdcId: 1,
            gtinUpc: "111",
            name: "Cached",
            calories: 100,
            protein: 10,
            carbohydrates: 10,
            fat: 3,
            lastSyncedAt: now.addingTimeInterval(-120)
        )
        context.insert(cached)
        try context.save()

        let resolved = try await repository.lookupByBarcode("111")
        #expect(resolved?.fdcId == 1)
        #expect(client.fetchCallCount == 0)
    }

    @Test("Stale cached food refreshes from Open Food Facts")
    @MainActor
    func staleRefresh() async throws {
        let now = Date()
        let client = OFFClientMock(productResult: makeDTO(code: "111", name: "OFF Fresh", calories: 220))
        let (repository, context) = try makeRepository(
            now: { now },
            refreshInterval: 60,
            client: client
        )

        let stale = OfficialFood(
            fdcId: OFFProductDTO.stableSurrogateId(forCode: "111"),
            gtinUpc: "111",
            name: "Old",
            calories: 100,
            protein: 10,
            carbohydrates: 10,
            fat: 5,
            lastSyncedAt: now.addingTimeInterval(-3600)
        )
        context.insert(stale)
        try context.save()

        let refreshed = try await repository.lookupByBarcode("111")
        #expect(client.fetchCallCount == 1)
        #expect(refreshed?.name == "OFF Fresh")
        #expect(refreshed?.calories == 220)
    }

    @Test("When OFF returns no match, stale cached item is still returned")
    @MainActor
    func staleNoRemoteMatchFallsBackToCache() async throws {
        let now = Date()
        let client = OFFClientMock(productResult: nil)
        let (repository, context) = try makeRepository(
            now: { now },
            refreshInterval: 60,
            client: client
        )

        let stale = OfficialFood(
            fdcId: OFFProductDTO.stableSurrogateId(forCode: "555"),
            gtinUpc: "555",
            name: "Cached Stale",
            calories: 140,
            protein: 6,
            carbohydrates: 18,
            fat: 4,
            lastSyncedAt: now.addingTimeInterval(-3600)
        )
        context.insert(stale)
        try context.save()

        let resolved = try await repository.lookupByBarcode("555")
        #expect(client.fetchCallCount == 1)
        #expect(resolved?.name == "Cached Stale")
        #expect(resolved?.calories == 140)
    }

    @Test("Network error falls back to cached item")
    @MainActor
    func networkErrorFallsBackToCache() async throws {
        let now = Date()
        let client = OFFClientMock(productResult: nil)
        client.fetchError = OFFClientMockError.forced
        let (repository, context) = try makeRepository(
            now: { now },
            refreshInterval: 60,
            client: client
        )

        let stale = OfficialFood(
            fdcId: OFFProductDTO.stableSurrogateId(forCode: "777"),
            gtinUpc: "777",
            name: "Cached On Error",
            calories: 90,
            protein: 3,
            carbohydrates: 12,
            fat: 2,
            lastSyncedAt: now.addingTimeInterval(-7200)
        )
        context.insert(stale)
        try context.save()

        let resolved = try await repository.lookupByBarcode("777")
        #expect(client.fetchCallCount == 1)
        #expect(resolved?.name == "Cached On Error")
    }

    @Test("Text search upserts results and deduplicates by barcode")
    @MainActor
    func searchUpsertsAndDeduplicates() async throws {
        let sharedCode = "123"
        let searchResult = [
            makeDTO(code: sharedCode, name: "First", calories: 100),
            makeDTO(code: sharedCode, name: "First Duplicate", calories: 100),
            makeDTO(code: "456", name: "Second", calories: 200),
        ]
        let client = OFFClientMock(searchResult: searchResult)
        let (repository, context) = try makeRepository(client: client)

        let resolved = try await repository.searchByText("test", limit: 20)
        #expect(client.searchCallCount == 1)
        #expect(resolved.count == 2)

        let all = try context.fetch(FetchDescriptor<OfficialFood>())
        #expect(all.count == 2)
        #expect(all.contains(where: { $0.gtinUpc == sharedCode }))
        #expect(all.contains(where: { $0.gtinUpc == "456" }))
    }
}

@Suite("Official Data Reset")
struct OfficialDataResetServiceTests {

    private func makeDefaults() -> (UserDefaults, String) {
        let suiteName = "OfficialDataResetServiceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let key = "reset.version.\(UUID().uuidString)"
        return (defaults, key)
    }

    @Test("First run deletes official foods and official-linked log entries")
    @MainActor
    func firstRunDeletesOfficialData() throws {
        let container = try ModelContainer(
            for: Food.self, OfficialFood.self, LogEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let (defaults, versionKey) = makeDefaults()

        let custom = Food(name: "Custom")
        context.insert(custom)
        let customEntry = LogEntry(food: custom, quantity: 1, mealType: .breakfast)
        context.insert(customEntry)

        let official = OfficialFood(fdcId: 123, gtinUpc: "123", name: "Official")
        context.insert(official)
        let officialEntry = LogEntry(officialFood: official, quantity: 1, mealType: .lunch)
        context.insert(officialEntry)
        try context.save()

        let service = OfficialDataResetService(
            modelContext: context,
            userDefaults: defaults,
            resetVersion: 1,
            resetVersionKey: versionKey
        )
        service.performIfNeeded()

        let officialFoods = try context.fetch(FetchDescriptor<OfficialFood>())
        let logEntries = try context.fetch(FetchDescriptor<LogEntry>())
        #expect(officialFoods.isEmpty)
        #expect(logEntries.count == 1)
        #expect(logEntries.first?.food?.name == "Custom")
        #expect(defaults.integer(forKey: versionKey) == 1)
    }

    @Test("Second run is no-op after version marker is set")
    @MainActor
    func secondRunIsNoOp() throws {
        let container = try ModelContainer(
            for: Food.self, OfficialFood.self, LogEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let (defaults, versionKey) = makeDefaults()

        let service = OfficialDataResetService(
            modelContext: context,
            userDefaults: defaults,
            resetVersion: 1,
            resetVersionKey: versionKey
        )
        service.performIfNeeded()

        let newOfficial = OfficialFood(fdcId: 555, gtinUpc: "555", name: "After Reset")
        context.insert(newOfficial)
        try context.save()

        service.performIfNeeded()

        let officialFoods = try context.fetch(FetchDescriptor<OfficialFood>())
        #expect(officialFoods.count == 1)
        #expect(officialFoods.first?.gtinUpc == "555")
    }
}

@Suite("LogEntry Official Food")
struct LogEntryOfficialFoodTests {

    @Test("Totals resolve from official food when custom food is nil")
    func officialOnlyTotals() {
        let official = OfficialFood(
            fdcId: 900,
            gtinUpc: "900",
            name: "Official",
            servingSize: 100,
            servingUnit: "g",
            calories: 80,
            protein: 5,
            carbohydrates: 12,
            fat: 2,
            fiber: 1,
            sugar: 4
        )
        let entry = LogEntry(officialFood: official, quantity: 2.0, mealType: .lunch)

        #expect(entry.foodDisplayName == "Official")
        #expect(entry.totalCalories == 160)
        #expect(entry.totalProtein == 10)
        #expect(entry.totalCarbs == 24)
        #expect(entry.totalFat == 4)
        #expect(entry.totalFiber == 2)
        #expect(entry.totalSugar == 8)
    }
}
