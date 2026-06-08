import Foundation

struct Achievement: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let isUnlocked: Bool
}

enum AchievementCatalog {
    static let all: [(id: String, title: String, subtitle: String, icon: String)] = [
        ("first_lookup", "First Lookup", "Looked up your first ingredient.", "sparkles"),
        ("culinary_explorer", "Culinary Explorer", "Looked up 10 different ingredients.", "leaf.fill"),
        ("power_user", "Power User", "Reached 50 items.", "bolt.fill"),
        ("active_user", "Active User", "Completed 10 sessions.", "flame.fill"),
        ("dedicated_user", "Dedicated User", "Completed 50 sessions.", "flame.circle.fill"),
        ("three_day_streak", "Three-Day Streak", "Used the app 3 days in a row.", "calendar.badge.clock"),
        ("week_habit", "Week-Long Habit", "Used the app 7 days in a row.", "calendar.circle.fill"),
        ("time_invested", "Time Invested", "Spent 60 minutes total in the app.", "clock.fill")
    ]
}
