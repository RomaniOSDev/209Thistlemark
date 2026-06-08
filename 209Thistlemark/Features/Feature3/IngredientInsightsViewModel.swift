import Foundation
import SwiftUI
import Combine

@MainActor
final class IngredientInsightsViewModel: ObservableObject {
    struct InsightSelection: Identifiable {
        var id: String { name }
        let name: String
    }

    @Published var highlightedIngredient: String?
    @Published var highlightedCount = 0
    @Published var selectedIngredientForSheet: InsightSelection?
    @Published var pulseRefresh = false

    func topItems(from store: AppDataStore) -> [(name: String, count: Int)] {
        store.viewCounts
            .sorted { lhs, rhs in
                if lhs.value == rhs.value { return lhs.key < rhs.key }
                return lhs.value > rhs.value
            }
            .prefix(10)
            .map { ($0.key, $0.value) }
    }

    func refresh(store: AppDataStore) {
        FeedbackManager.refreshInsights()
        store.completeSession()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            pulseRefresh.toggle()
        }
    }

    func selectBar(at location: CGPoint, width: CGFloat, items: [(name: String, count: Int)]) {
        guard !items.isEmpty, width > 0 else {
            highlightedIngredient = nil
            highlightedCount = 0
            return
        }
        let barWidth = width / CGFloat(items.count)
        let index = Int((location.x / barWidth).rounded(.down))
        guard items.indices.contains(index) else { return }
        highlightedIngredient = items[index].name
        highlightedCount = items[index].count
    }
}
