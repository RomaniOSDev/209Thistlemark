import SwiftUI

struct IngredientInsightsView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = IngredientInsightsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    VStack(spacing: 14) {
                        if items.isEmpty {
                            emptyState
                        } else {
                            topStatsCard
                            chartCard
                            mostViewedCard
                        }

                        refreshButton
                    }
                    .padding(14)
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $viewModel.selectedIngredientForSheet) { selection in
                InsightIngredientSheet(name: selection.name, count: store.viewCounts[selection.name, default: 0])
            }
        }
    }

    private var items: [(name: String, count: Int)] {
        viewModel.topItems(from: store)
    }

    private var emptyState: some View {
        AppCard {
            VStack(spacing: 12) {
                AppArtworkView(name: "CalmInsights", height: 160)
                Text("No insights yet - start exploring ingredients!")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color("AppTextPrimary"))
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var chartCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitleRow(title: "Usage Trends", subtitle: "Drag across bars for details")

                GeometryReader { proxy in
                    let maxCount = max(items.map(\.count).max() ?? 1, 1)
                    HStack(alignment: .bottom, spacing: 6) {
                        ForEach(items, id: \.name) { item in
                            let heightFactor = CGFloat(item.count) / CGFloat(maxCount)
                            VStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(item.name == viewModel.highlightedIngredient ? Color("AppPrimary") : Color("AppAccent"))
                                    .frame(height: max(22, (proxy.size.height - 36) * heightFactor))
                                Text(item.name)
                                    .font(.caption2)
                                    .foregroundStyle(Color("AppTextSecondary"))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                viewModel.selectBar(at: value.location, width: proxy.size.width, items: items)
                            }
                    )
                }
                .frame(height: 220)

                if let highlighted = viewModel.highlightedIngredient {
                    Text("\(highlighted): \(viewModel.highlightedCount) views")
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
        }
    }

    private var mostViewedCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 8) {
                SectionTitleRow(title: "Most Viewed", subtitle: "Tap a row for a quick detail sheet")
                ForEach(Array(items.enumerated()), id: \.element.name) { index, item in
                    Button {
                        FeedbackManager.tap()
                        viewModel.selectedIngredientForSheet = .init(name: item.name)
                    } label: {
                        RankedIngredientCell(
                            rank: index + 1,
                            name: item.name,
                            count: item.count
                        )
                    }
                    .buttonStyle(.plain)
                    if index < items.count - 1 {
                        Divider().overlay(Color("AppTextSecondary").opacity(0.2))
                    }
                }
            }
        }
    }

    private var refreshButton: some View {
        Button {
            viewModel.refresh(store: store)
        } label: {
            Text("Refresh Insights")
                .font(.headline)
                .foregroundStyle(Color("AppTextPrimary"))
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Color("AppPrimary"), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .scaleEffect(viewModel.pulseRefresh ? 1 : 0.98)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.pulseRefresh)
    }

    private var topStatsCard: some View {
        AppCard {
            HStack(spacing: 10) {
                MetricCell(
                    title: "Tracked items",
                    value: "\(store.trackedIngredients.count)",
                    symbol: "books.vertical.fill"
                )
                MetricCell(
                    title: "Total views",
                    value: "\(store.viewCounts.values.reduce(0, +))",
                    symbol: "eye.fill"
                )
            }
        }
    }
}

private struct InsightIngredientSheet: View {
    let name: String
    let count: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text(name)
                    .font(.title2.bold())
                    .foregroundStyle(Color("AppTextPrimary"))
                Text("Total views: \(count)")
                    .font(.body)
                    .foregroundStyle(Color("AppTextSecondary"))
                Spacer()
            }
            .padding(20)
            .background(AppBackgroundView())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        FeedbackManager.tap()
                        dismiss()
                    }
                }
            }
        }
    }
}
