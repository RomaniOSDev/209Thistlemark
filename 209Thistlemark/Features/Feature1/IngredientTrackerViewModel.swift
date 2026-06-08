import Foundation
import SwiftUI
import Combine

@MainActor
final class IngredientTrackerViewModel: ObservableObject {
    enum FilterMode: String, CaseIterable, Identifiable {
        case all = "All Ingredients"
        case frequent = "Frequently Viewed"
        var id: String { rawValue }
    }

    @Published var searchText = ""
    @Published var filterMode: FilterMode = .all
    @Published var onlyMissing = false
    @Published var expandedIngredientIDs: Set<UUID> = []
    @Published var editingIngredient: Ingredient?
    @Published var isPresentingEditor = false
    @Published var showSuccessOverlay = false
    @Published var shakeTrigger: CGFloat = 0
    @Published var inlineError: String?

    func filteredIngredients(from store: AppDataStore) -> [Ingredient] {
        let source: [Ingredient]
        switch filterMode {
        case .all:
            source = store.ingredients
        case .frequent:
            let frequentNames = Set(store.frequentViews.map { $0.lowercased() })
            source = store.ingredients.filter { frequentNames.contains($0.name.lowercased()) }
        }

        var result = source
        if onlyMissing {
            result = result.filter(\.isMissing)
        }

        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            result = result.filter { ingredient in
                ingredient.name.localizedCaseInsensitiveContains(searchText)
                || ingredient.details.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func openNewIngredientForm() {
        FeedbackManager.tap()
        editingIngredient = nil
        isPresentingEditor = true
    }

    func openEdit(_ ingredient: Ingredient) {
        FeedbackManager.tap()
        editingIngredient = ingredient
        isPresentingEditor = true
    }

    func delete(_ ingredient: Ingredient, in store: AppDataStore) {
        FeedbackManager.tap()
        store.ingredients.removeAll(where: { $0.id == ingredient.id })
        store.recalculateItemsCreated()
    }

    func toggleExpansion(_ ingredient: Ingredient, in store: AppDataStore) {
        FeedbackManager.tap()
        if expandedIngredientIDs.contains(ingredient.id) {
            expandedIngredientIDs.remove(ingredient.id)
        } else {
            expandedIngredientIDs.insert(ingredient.id)
            store.markIngredientViewed(ingredient.name)
        }
    }

    func saveIngredient(
        name: String,
        details: String,
        usage: String,
        nutritionInfo: String,
        symbol: String,
        pantryStatus: Ingredient.PantryStatus,
        tags: [String],
        collections: [String],
        substitutions: [Ingredient.Substitution],
        pairings: [String],
        quickNotes: String,
        shelfLife: Ingredient.ShelfLife,
        in store: AppDataStore
    ) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedDetails.isEmpty else {
            inlineError = "Please enter both a name and a short description."
            shakeTrigger += 1
            FeedbackManager.warning()
            return false
        }

        if var editingIngredient {
            editingIngredient.name = trimmedName
            editingIngredient.details = trimmedDetails
            editingIngredient.usage = usage.trimmingCharacters(in: .whitespacesAndNewlines)
            editingIngredient.nutritionInfo = nutritionInfo.trimmingCharacters(in: .whitespacesAndNewlines)
            editingIngredient.sfSymbol = symbol
            editingIngredient.pantryStatus = pantryStatus
            editingIngredient.tags = tags
            editingIngredient.collections = collections
            editingIngredient.substitutions = Array(substitutions.prefix(5))
            editingIngredient.pairings = pairings
            editingIngredient.quickNotes = quickNotes.trimmingCharacters(in: .whitespacesAndNewlines)
            editingIngredient.shelfLife = shelfLife
            editingIngredient.updatedAt = Date()
            if let index = store.ingredients.firstIndex(where: { $0.id == editingIngredient.id }) {
                store.ingredients[index] = editingIngredient
            }
        } else {
            let ingredient = Ingredient(
                id: UUID(),
                name: trimmedName,
                details: trimmedDetails,
                usage: usage.trimmingCharacters(in: .whitespacesAndNewlines),
                nutritionInfo: nutritionInfo.trimmingCharacters(in: .whitespacesAndNewlines),
                sfSymbol: symbol,
                pantryStatus: pantryStatus,
                tags: tags,
                collections: collections,
                substitutions: Array(substitutions.prefix(5)),
                pairings: pairings,
                quickNotes: quickNotes.trimmingCharacters(in: .whitespacesAndNewlines),
                shelfLife: shelfLife,
                createdAt: Date(),
                updatedAt: Date()
            )
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                store.ingredients.append(ingredient)
            }
        }

        inlineError = nil
        store.recalculateItemsCreated()
        store.completeSession()
        FeedbackManager.save()
        showSuccessMoment()
        isPresentingEditor = false
        editingIngredient = nil
        return true
    }

    private func showSuccessMoment() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showSuccessOverlay = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation(.easeInOut(duration: 0.25)) {
                self.showSuccessOverlay = false
            }
        }
    }
}
