import Foundation
import SwiftUI
import Combine

@MainActor
final class TrackedIngredientsViewModel: ObservableObject {
    enum SortMode: String, CaseIterable, Identifiable {
        case name = "Name"
        case recent = "Recent"
        var id: String { rawValue }
    }

    @Published var sortMode: SortMode = .name
    @Published var searchText = ""
    @Published var newIngredientName = ""
    @Published var addError: String?
    @Published var shakeTrigger: CGFloat = 0
    @Published var showingAddSheet = false

    func sortedIngredients(store: AppDataStore) -> [String] {
        let source = store.trackedIngredients.filter { searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? true : $0.localizedCaseInsensitiveContains(searchText) }
        switch sortMode {
        case .name:
            return source.sorted {
                $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
            }
        case .recent:
            return source.sorted { lhs, rhs in
                let left = store.ingredientLastAccessed[lhs] ?? .distantPast
                let right = store.ingredientLastAccessed[rhs] ?? .distantPast
                return left > right
            }
        }
    }

    func addIngredient(store: AppDataStore) {
        let candidate = newIngredientName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !candidate.isEmpty else {
            addError = "Please enter an ingredient name."
            shakeTrigger += 1
            FeedbackManager.warning()
            return
        }
        if store.trackedIngredients.contains(where: { $0.caseInsensitiveCompare(candidate) == .orderedSame }) {
            addError = "This ingredient is already tracked."
            shakeTrigger += 1
            FeedbackManager.warning()
            return
        }

        store.trackedIngredients.append(candidate)
        store.ingredientLastAccessed[candidate] = Date()
        store.recalculateItemsCreated()
        store.completeSession()
        FeedbackManager.vibrateLight()
        addError = nil
        newIngredientName = ""
        showingAddSheet = false
    }

    func delete(_ ingredient: String, store: AppDataStore) {
        FeedbackManager.tap()
        store.trackedIngredients.removeAll(where: { $0 == ingredient })
        store.viewCounts[ingredient] = nil
        store.ingredientLastAccessed[ingredient] = nil
        store.recalculateItemsCreated()
    }

    func viewIngredient(_ ingredient: String, store: AppDataStore) {
        store.markIngredientViewed(ingredient)
    }

    func togglePantryStatus(for ingredientName: String, store: AppDataStore) {
        guard let index = store.ingredients.firstIndex(where: { $0.name.caseInsensitiveCompare(ingredientName) == .orderedSame }) else {
            return
        }
        FeedbackManager.tap()
        store.ingredients[index].pantryStatus = store.ingredients[index].pantryStatus == .inPantry ? .needToBuy : .inPantry
        store.ingredients[index].updatedAt = Date()
    }
}
