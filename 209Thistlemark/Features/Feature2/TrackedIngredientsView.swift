import SwiftUI

struct TrackedIngredientsView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = TrackedIngredientsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                VStack(spacing: 12) {
                    searchBar
                    Picker("Sort", selection: $viewModel.sortMode) {
                        ForEach(TrackedIngredientsViewModel.SortMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 14)
                    content
                }
                .padding(.top, 10)
            }
            .navigationTitle("Ingredient Tracker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        FeedbackManager.tap()
                        viewModel.showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color("AppTextPrimary"))
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddSheet) {
                addIngredientSheet
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        let ingredients = viewModel.sortedIngredients(store: store)
        if ingredients.isEmpty {
            VStack(spacing: 10) {
                Spacer()
                AppArtworkView(name: "CalmDashboard", height: 180)
                    .padding(.horizontal, 20)
                Text("No Ingredients Tracked")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))
                Text("Track your favorite ingredients!")
                    .font(.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                Spacer()
            }
            .padding(.horizontal, 20)
        } else {
            List {
                ForEach(ingredients, id: \.self) { ingredient in
                    NavigationLink {
                        TrackedIngredientDetailView(ingredientName: ingredient)
                            .onAppear { viewModel.viewIngredient(ingredient, store: store) }
                    } label: {
                        trackedRow(ingredient)
                    }
                    .listRowBackground(Color("AppSurface"))
                    .swipeActions {
                        Button("Delete", role: .destructive) {
                            viewModel.delete(ingredient, store: store)
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button("Toggle Pantry") {
                            viewModel.togglePantryStatus(for: ingredient, store: store)
                        }
                        .tint(Color("AppPrimary"))
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color("AppTextSecondary"))
            TextField("Search tracked ingredients", text: $viewModel.searchText)
                .foregroundStyle(Color("AppTextPrimary"))
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color("AppSurface"), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal, 14)
    }

    private func trackedRow(_ ingredient: String) -> some View {
        let status = store.ingredients.first(where: { $0.name.caseInsensitiveCompare(ingredient) == .orderedSame })?.pantryStatus ?? .inPantry
        return HStack(spacing: 12) {
            Image(systemName: status == .needToBuy ? "cart.badge.plus" : "leaf.fill")
                .foregroundStyle(status == .needToBuy ? Color("AppPrimary") : Color("AppAccent"))
                .frame(width: 30, height: 30)
                .background(Color("AppBackground"), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(ingredient)
                    .foregroundStyle(Color("AppTextPrimary"))
                Text(status.rawValue)
                    .font(.caption2)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            Spacer()
            Text("\(store.viewCounts[ingredient, default: 0])")
                .foregroundStyle(Color("AppTextSecondary"))
                .font(.caption.weight(.semibold))
        }
    }

    private var addIngredientSheet: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    VStack(spacing: 12) {
                        AppCard {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionTitleRow(title: "New Ingredient", subtitle: "Add it to your tracked list")
                                TextField("Ingredient name", text: $viewModel.newIngredientName)
                                    .textInputAutocapitalization(.words)
                                    .disableAutocorrection(true)
                                    .modifier(ShakeEffect(animatableData: viewModel.shakeTrigger))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 11)
                                    .appDepthCard(cornerRadius: 12, elevated: false)
                                if let addError = viewModel.addError {
                                    Text(addError)
                                        .font(.footnote)
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                    }
                    .padding(14)
                }
            }
            .navigationTitle("Add Ingredient")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        FeedbackManager.tap()
                        viewModel.showingAddSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.addIngredient(store: store)
                    }
                }
            }
        }
    }
}

private struct TrackedIngredientDetailView: View {
    @EnvironmentObject private var store: AppDataStore
    let ingredientName: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                card(title: "Description", body: descriptionText)
                card(title: "Usage", body: usageText)
                card(title: "Pantry Availability", body: pantryStatusText)
                if !pairingsText.isEmpty {
                    card(title: "Pairs Well With", body: pairingsText)
                }
                if !notesText.isEmpty {
                    card(title: "Quick Notes", body: notesText)
                }
                card(title: "Views", body: "\(store.viewCounts[ingredientName, default: 0]) lookups")
            }
            .padding(14)
        }
        .background(AppBackgroundView())
        .navigationTitle(ingredientName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var matchedIngredient: Ingredient? {
        store.ingredients.first(where: { $0.name.caseInsensitiveCompare(ingredientName) == .orderedSame })
    }

    private var descriptionText: String {
        matchedIngredient?.details ?? "Add this ingredient to Home to attach a detailed description."
    }

    private var usageText: String {
        matchedIngredient?.usage.isEmpty == false
            ? (matchedIngredient?.usage ?? "")
            : "No usage tips yet."
    }

    private var pantryStatusText: String {
        matchedIngredient?.pantryStatus.rawValue ?? "Unknown"
    }

    private var pairingsText: String {
        matchedIngredient?.pairings.joined(separator: ", ") ?? ""
    }

    private var notesText: String {
        matchedIngredient?.quickNotes ?? ""
    }

    private func card(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color("AppAccent"))
            Text(body)
                .foregroundStyle(Color("AppTextPrimary"))
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color("AppSurface"), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
