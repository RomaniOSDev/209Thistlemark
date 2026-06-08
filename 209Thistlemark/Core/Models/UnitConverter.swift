import Foundation

enum KitchenUnit: String, CaseIterable, Identifiable {
    case tsp
    case tbsp
    case cup
    case ml
    case g
    case oz

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tsp: return "tsp"
        case .tbsp: return "tbsp"
        case .cup: return "cup"
        case .ml: return "ml"
        case .g: return "g"
        case .oz: return "oz"
        }
    }

    var volumeInML: Double? {
        switch self {
        case .tsp: return 4.92892
        case .tbsp: return 14.7868
        case .cup: return 236.588
        case .ml: return 1
        case .g, .oz: return nil
        }
    }

    var weightInGrams: Double? {
        switch self {
        case .g: return 1
        case .oz: return 28.3495
        case .tsp, .tbsp, .cup, .ml: return nil
        }
    }
}

enum DensityProfile: String, CaseIterable, Identifiable {
    case water = "Water"
    case flour = "Flour"
    case sugar = "Sugar"
    case butter = "Butter"

    var id: String { rawValue }

    // grams per 1 ml
    var gramsPerML: Double {
        switch self {
        case .water: return 1
        case .flour: return 0.53
        case .sugar: return 0.85
        case .butter: return 0.96
        }
    }
}
