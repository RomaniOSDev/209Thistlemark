import Foundation

struct Ingredient: Identifiable, Codable, Hashable {
    enum PantryStatus: String, Codable, CaseIterable, Hashable, Identifiable {
        case inPantry = "In Pantry"
        case needToBuy = "Need to Buy"
        var id: String { rawValue }
    }

    struct Substitution: Codable, Hashable, Identifiable {
        let id: UUID
        var fromAmount: String
        var toAmount: String
    }

    struct ShelfLife: Codable, Hashable {
        var fridgeDays: Int
        var pantryDays: Int
        var freezerDays: Int
        var storageTips: String
    }

    let id: UUID
    var name: String
    var details: String
    var usage: String
    var nutritionInfo: String
    var sfSymbol: String
    var pantryStatus: PantryStatus
    var tags: [String]
    var collections: [String]
    var substitutions: [Substitution]
    var pairings: [String]
    var quickNotes: String
    var shelfLife: ShelfLife
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID,
        name: String,
        details: String,
        usage: String,
        nutritionInfo: String,
        sfSymbol: String,
        pantryStatus: PantryStatus,
        tags: [String],
        collections: [String],
        substitutions: [Substitution],
        pairings: [String],
        quickNotes: String,
        shelfLife: ShelfLife,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.details = details
        self.usage = usage
        self.nutritionInfo = nutritionInfo
        self.sfSymbol = sfSymbol
        self.pantryStatus = pantryStatus
        self.tags = tags
        self.collections = collections
        self.substitutions = substitutions
        self.pairings = pairings
        self.quickNotes = quickNotes
        self.shelfLife = shelfLife
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        details = try container.decodeIfPresent(String.self, forKey: .details) ?? ""
        usage = try container.decodeIfPresent(String.self, forKey: .usage) ?? ""
        nutritionInfo = try container.decodeIfPresent(String.self, forKey: .nutritionInfo) ?? ""
        sfSymbol = try container.decodeIfPresent(String.self, forKey: .sfSymbol) ?? "leaf.fill"
        pantryStatus = try container.decodeIfPresent(PantryStatus.self, forKey: .pantryStatus) ?? .inPantry
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        collections = try container.decodeIfPresent([String].self, forKey: .collections) ?? []
        substitutions = try container.decodeIfPresent([Substitution].self, forKey: .substitutions) ?? []
        pairings = try container.decodeIfPresent([String].self, forKey: .pairings) ?? []
        quickNotes = try container.decodeIfPresent(String.self, forKey: .quickNotes) ?? ""
        shelfLife = try container.decodeIfPresent(ShelfLife.self, forKey: .shelfLife) ?? .defaultValue
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
}

extension Ingredient {
    static let defaultShelfLife = ShelfLife.defaultValue

    var shortDescription: String {
        let source = details.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty else { return "No description available." }
        return String(source.prefix(90))
    }

    var isMissing: Bool {
        pantryStatus == .needToBuy
    }

    var soonToExpire: Bool {
        let days = max(shelfLife.fridgeDays, shelfLife.pantryDays)
        guard days > 0 else { return false }
        let thresholdDate = Calendar.current.date(byAdding: .day, value: max(days - 2, 1), to: createdAt) ?? createdAt
        return Date() >= thresholdDate && pantryStatus == .inPantry
    }
}

extension Ingredient.ShelfLife {
    static let defaultValue = Ingredient.ShelfLife(
        fridgeDays: 5,
        pantryDays: 14,
        freezerDays: 30,
        storageTips: ""
    )
}
