import Foundation
import SwiftUI
import Combine

@MainActor
final class AppDataStore: ObservableObject {
    @Published var hasSeenOnboarding = false { didSet { saveValue(hasSeenOnboarding, key: Keys.hasSeenOnboarding) } }
    @Published var totalSessionsCompleted = 0 { didSet { saveValue(totalSessionsCompleted, key: Keys.totalSessionsCompleted) } }
    @Published var totalMinutesUsed = 0 { didSet { saveValue(totalMinutesUsed, key: Keys.totalMinutesUsed) } }
    @Published var streakDays = 0 { didSet { saveValue(streakDays, key: Keys.streakDays) } }
    @Published var lastActivityDate: Date? { didSet { saveDate(lastActivityDate, key: Keys.lastActivityDate) } }
    @Published var achievementsUnlocked: [String: Date] = [:] { didSet { saveCodable(achievementsUnlocked, key: Keys.achievementsUnlocked) } }

    @Published var ingredients: [Ingredient] = [] { didSet { saveCodable(ingredients, key: Keys.ingredients); syncDerivedCollections() } }
    @Published var frequentViews: [String] = [] { didSet { saveCodable(frequentViews, key: Keys.frequentViews) } }
    @Published var trackedIngredients: [String] = [] { didSet { saveCodable(trackedIngredients, key: Keys.trackedIngredients); syncDerivedCollections() } }
    @Published var viewCounts: [String: Int] = [:] { didSet { saveCodable(viewCounts, key: Keys.viewCounts); syncInsightArrays() } }
    @Published var ingredientLastAccessed: [String: Date] = [:] { didSet { saveCodable(ingredientLastAccessed, key: Keys.ingredientLastAccessed) } }

    @Published var itemsCreated = 0 { didSet { saveValue(itemsCreated, key: Keys.itemsCreated) } }
    @Published var insightIngredients: [String] = [] { didSet { saveCodable(insightIngredients, key: Keys.insightIngredients) } }
    @Published var insightViewCounts: [Int] = [] { didSet { saveCodable(insightViewCounts, key: Keys.insightViewCounts) } }
    @Published var activeAchievementBanner: String?

    var totalMinutes: Int { totalMinutesUsed }
    var sessionsCompleted: Int { totalSessionsCompleted }

    private let defaults = UserDefaults.standard
    private var isBootstrapping = false
    private var queuedAchievementIDs: [String] = []
    private var isShowingBanner = false

    init() {
        isBootstrapping = true
        loadAll()
        isBootstrapping = false
        evaluateAchievementsIfNeeded()
    }

    func completeSession() {
        totalSessionsCompleted += 1
        registerActivity()
        evaluateAchievementsIfNeeded()
    }

    func addUsageTime(seconds: Int) {
        guard seconds > 0 else { return }
        totalMinutesUsed += seconds
        evaluateAchievementsIfNeeded()
    }

    func markIngredientViewed(_ name: String) {
        guard !name.isEmpty else { return }
        frequentViews.append(name)
        viewCounts[name, default: 0] += 1
        ingredientLastAccessed[name] = Date()
        registerActivity()
        evaluateAchievementsIfNeeded()
    }

    func recalculateItemsCreated() {
        let namesFromCards = Set(ingredients.map { $0.name.lowercased() })
        let namesFromTracker = Set(trackedIngredients.map { $0.lowercased() })
        itemsCreated = namesFromCards.union(namesFromTracker).count
        evaluateAchievementsIfNeeded()
    }

    func unlockIfNeeded(id: String) {
        guard achievementsUnlocked[id] == nil else { return }
        achievementsUnlocked[id] = Date()
        FeedbackManager.complete()
        queuedAchievementIDs.append(id)
        presentNextBannerIfNeeded()
    }

    func resetAllData() {
        Keys.all.forEach(defaults.removeObject(forKey:))
        hasSeenOnboarding = false
        totalSessionsCompleted = 0
        totalMinutesUsed = 0
        streakDays = 0
        lastActivityDate = nil
        achievementsUnlocked = [:]
        ingredients = []
        frequentViews = []
        trackedIngredients = []
        viewCounts = [:]
        ingredientLastAccessed = [:]
        itemsCreated = 0
        insightIngredients = []
        insightViewCounts = []
        activeAchievementBanner = nil
        queuedAchievementIDs = []
        isShowingBanner = false
        NotificationCenter.default.post(name: .dataReset, object: nil)
    }

    func achievements() -> [Achievement] {
        AchievementCatalog.all.map { definition in
            Achievement(
                id: definition.id,
                title: definition.title,
                subtitle: definition.subtitle,
                icon: definition.icon,
                isUnlocked: achievementsUnlocked[definition.id] != nil
            )
        }
    }

    private func registerActivity() {
        let now = Date()
        let calendar = Calendar.current
        if let last = lastActivityDate {
            if calendar.isDate(now, inSameDayAs: last) {
                lastActivityDate = now
                return
            }

            if let dayDiff = calendar.dateComponents([.day], from: calendar.startOfDay(for: last), to: calendar.startOfDay(for: now)).day {
                if dayDiff == 1 {
                    streakDays += 1
                } else if dayDiff > 1 {
                    streakDays = 1
                }
            }
        } else {
            streakDays = 1
        }
        lastActivityDate = now
    }

    private func evaluateAchievementsIfNeeded() {
        if itemsCreated >= 1 { unlockIfNeeded(id: "first_lookup") }
        if itemsCreated >= 10 { unlockIfNeeded(id: "culinary_explorer") }
        if itemsCreated >= 50 { unlockIfNeeded(id: "power_user") }
        if totalSessionsCompleted >= 10 { unlockIfNeeded(id: "active_user") }
        if totalSessionsCompleted >= 50 { unlockIfNeeded(id: "dedicated_user") }
        if streakDays >= 3 { unlockIfNeeded(id: "three_day_streak") }
        if streakDays >= 7 { unlockIfNeeded(id: "week_habit") }
        if totalMinutesUsed >= 3600 { unlockIfNeeded(id: "time_invested") }
    }

    private func presentNextBannerIfNeeded() {
        guard !isShowingBanner, let nextID = queuedAchievementIDs.first else { return }
        isShowingBanner = true
        queuedAchievementIDs.removeFirst()

        let title = AchievementCatalog.all.first(where: { $0.id == nextID })?.title ?? "Achievement Unlocked"
        withAnimation(.easeInOut(duration: 0.3)) {
            activeAchievementBanner = "Achievement unlocked: \(title)"
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
                self.activeAchievementBanner = nil
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                guard let self else { return }
                self.isShowingBanner = false
                self.presentNextBannerIfNeeded()
            }
        }
    }

    private func syncDerivedCollections() {
        if isBootstrapping { return }
        recalculateItemsCreated()
    }

    private func syncInsightArrays() {
        let sorted = viewCounts.sorted { lhs, rhs in
            if lhs.value == rhs.value { return lhs.key < rhs.key }
            return lhs.value > rhs.value
        }
        insightIngredients = sorted.map(\.key)
        insightViewCounts = sorted.map(\.value)
    }

    private func loadAll() {
        hasSeenOnboarding = defaults.bool(forKey: Keys.hasSeenOnboarding)
        totalSessionsCompleted = defaults.integer(forKey: Keys.totalSessionsCompleted)
        totalMinutesUsed = defaults.integer(forKey: Keys.totalMinutesUsed)
        streakDays = defaults.integer(forKey: Keys.streakDays)
        lastActivityDate = defaults.object(forKey: Keys.lastActivityDate) as? Date
        achievementsUnlocked = readCodable([String: Date].self, key: Keys.achievementsUnlocked) ?? [:]

        ingredients = readCodable([Ingredient].self, key: Keys.ingredients) ?? []
        frequentViews = readCodable([String].self, key: Keys.frequentViews) ?? []
        trackedIngredients = readCodable([String].self, key: Keys.trackedIngredients) ?? []
        viewCounts = readCodable([String: Int].self, key: Keys.viewCounts) ?? [:]
        ingredientLastAccessed = readCodable([String: Date].self, key: Keys.ingredientLastAccessed) ?? [:]
        itemsCreated = defaults.integer(forKey: Keys.itemsCreated)
        insightIngredients = readCodable([String].self, key: Keys.insightIngredients) ?? []
        insightViewCounts = readCodable([Int].self, key: Keys.insightViewCounts) ?? []

        if itemsCreated == 0 && (!ingredients.isEmpty || !trackedIngredients.isEmpty) {
            recalculateItemsCreated()
        }
        if insightIngredients.isEmpty && !viewCounts.isEmpty {
            syncInsightArrays()
        }
    }

    private func saveDate(_ value: Date?, key: String) {
        if isBootstrapping { return }
        defaults.set(value, forKey: key)
    }

    private func saveValue<T>(_ value: T, key: String) {
        if isBootstrapping { return }
        defaults.set(value, forKey: key)
    }

    private func saveCodable<T: Codable>(_ value: T, key: String) {
        if isBootstrapping { return }
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private func readCodable<T: Codable>(_ type: T.Type, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(type, from: data)
    }
}

private enum Keys {
    static let hasSeenOnboarding = "hasSeenOnboarding"
    static let totalSessionsCompleted = "totalSessionsCompleted"
    static let totalMinutesUsed = "totalMinutesUsed"
    static let streakDays = "streakDays"
    static let lastActivityDate = "lastActivityDate"
    static let achievementsUnlocked = "achievementsUnlocked"

    static let ingredients = "ingredients"
    static let frequentViews = "frequentViews"
    static let trackedIngredients = "trackedIngredients"
    static let viewCounts = "viewCounts"
    static let ingredientLastAccessed = "lastAccessed"
    static let itemsCreated = "itemsCreated"
    static let insightIngredients = "insightIngredients"
    static let insightViewCounts = "insightViewCounts"

    static let all = [
        hasSeenOnboarding,
        totalSessionsCompleted,
        totalMinutesUsed,
        streakDays,
        lastActivityDate,
        achievementsUnlocked,
        ingredients,
        frequentViews,
        trackedIngredients,
        viewCounts,
        ingredientLastAccessed,
        itemsCreated,
        insightIngredients,
        insightViewCounts
    ]
}
