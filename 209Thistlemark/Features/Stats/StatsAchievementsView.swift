import SwiftUI

struct StatsAchievementsView: View {
    @EnvironmentObject private var store: AppDataStore
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    VStack(spacing: 14) {
                        metricsStrip
                        summaryCard
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(store.achievements()) { achievement in
                                achievementCell(achievement)
                            }
                        }
                    }
                    .padding(14)
                }
            }
            .navigationTitle("Stats & Achievements")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var metricsStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                MetricCell(
                    title: "Total items",
                    value: "\(store.itemsCreated)",
                    symbol: "leaf.fill"
                )
                .frame(width: 140)
                MetricCell(
                    title: "Sessions",
                    value: "\(store.totalSessionsCompleted)",
                    symbol: "clock.badge.checkmark.fill"
                )
                .frame(width: 140)
                MetricCell(
                    title: "Current streak",
                    value: "\(store.streakDays)d",
                    symbol: "flame.fill"
                )
                .frame(width: 140)
                MetricCell(
                    title: "Active minutes",
                    value: "\(store.totalMinutesUsed / 60)",
                    symbol: "timer"
                )
                .frame(width: 140)
            }
        }
    }

    private var summaryCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitleRow(
                    title: "Summary Metrics",
                    subtitle: "Track your progress and consistency."
                )
                metricRow("Items created", "\(store.itemsCreated)")
                metricRow("Sessions completed", "\(store.totalSessionsCompleted)")
                metricRow("Current streak", "\(store.streakDays) day(s)")
                metricRow("Total active time", "\(store.totalMinutesUsed / 60) min")
            }
        }
    }

    private func metricRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color("AppTextSecondary"))
            Spacer()
            Text(value)
                .foregroundStyle(Color("AppTextPrimary"))
                .fontWeight(.semibold)
        }
    }

    private func achievementCell(_ achievement: Achievement) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: achievement.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(achievement.isUnlocked ? Color("AppAccent") : Color("AppTextSecondary"))
                    Spacer()
                    Image(systemName: achievement.isUnlocked ? "checkmark.seal.fill" : "lock.fill")
                        .foregroundStyle(achievement.isUnlocked ? Color("AppPrimary") : Color("AppTextSecondary"))
                        .font(.caption)
                }
                Text(achievement.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(2)
                Text(achievement.subtitle)
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(3)
            }
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        }
    }
}
