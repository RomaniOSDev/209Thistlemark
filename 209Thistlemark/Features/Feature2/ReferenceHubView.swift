import SwiftUI

struct ReferenceHubView: View {
    @State private var selection: HubSelection = .tracker

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                ForEach(HubSelection.allCases) { item in
                    Button {
                        FeedbackManager.tap()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selection = item
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: item.icon)
                            Text(item.title)
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(selection == item ? Color("AppTextPrimary") : Color("AppTextSecondary"))
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(
                            selection == item
                                ? LinearGradient(
                                    colors: [Color("AppPrimary"), Color("AppAccent")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color("AppSurface"), Color("AppBackground").opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .shadow(color: Color.black.opacity(0.12), radius: 5, x: 0, y: 3)

            Group {
                switch selection {
                case .tracker:
                    TrackedIngredientsView()
                case .insights:
                    IngredientInsightsView()
                case .converter:
                    KitchenConverterView()
                }
            }
            .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
        .animation(.easeInOut(duration: 0.3), value: selection)
    }
}

private enum HubSelection: String, CaseIterable, Identifiable {
    case tracker
    case insights
    case converter

    var id: String { rawValue }
    var title: String {
        switch self {
        case .tracker: return "Tracker"
        case .insights: return "Insights"
        case .converter: return "Converter"
        }
    }

    var icon: String {
        switch self {
        case .tracker: return "list.bullet.rectangle.portrait.fill"
        case .insights: return "chart.xyaxis.line"
        case .converter: return "arrow.left.arrow.right.circle.fill"
        }
    }
}
