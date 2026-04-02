import Foundation

protocol NutritionProviding {
    var name: String { get }
    var brandLabel: String? { get }
    var displayName: String { get }
    var servingSize: Double { get }
    var servingUnit: String { get }
    var calories: Double { get }
    var protein: Double { get }
    var carbohydrates: Double { get }
    var fat: Double { get }
    var fiber: Double? { get }
    var sugar: Double? { get }
    var sodium: Double? { get }
}
