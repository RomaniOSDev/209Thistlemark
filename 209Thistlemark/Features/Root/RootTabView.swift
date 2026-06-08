import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var selectedTab: RootTab = .home

    var body: some View {
        ZStack {
            AppBackgroundView()
            VStack(spacing: 0) {
                Group {
                    switch selectedTab {
                    case .home:
                        IngredientTrackerView()
                    case .library:
                        ReferenceHubView()
                    case .stats:
                        StatsAchievementsView()
                    case .settings:
                        SettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                CustomTabBar(selectedTab: $selectedTab)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }
            .overlay(alignment: .top) {
                AchievementBannerView(text: store.activeAchievementBanner)
            }
        }
    }
}

private struct CustomTabBar: View {
    @Binding var selectedTab: RootTab

    var body: some View {
        HStack(spacing: 10) {
            ForEach(RootTab.allCases) { tab in
                TabItemButton(tab: tab, isActive: selectedTab == tab) {
                    FeedbackManager.tap()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(10)
        .appDepthCard(cornerRadius: 20, elevated: true)
    }
}

private struct TabItemButton: View {
    let tab: RootTab
    let isActive: Bool
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 17, weight: .semibold))
                Text(tab.title)
                    .font(.caption.weight(.semibold))
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(isActive ? Color("AppTextPrimary") : Color("AppTextSecondary"))
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        isActive
                            ? LinearGradient(
                                colors: [Color("AppPrimary"), Color("AppAccent")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.2), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

private enum RootTab: String, CaseIterable, Identifiable {
    case home
    case library
    case stats
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .library: return "Library"
        case .stats: return "Stats"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home: return "square.grid.2x2.fill"
        case .library: return "book.pages.fill"
        case .stats: return "chart.bar.xaxis"
        case .settings: return "gearshape.fill"
        }
    }
}
