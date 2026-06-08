import SwiftUI

struct IngredientTrackerView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = IngredientTrackerViewModel()
    @State private var featuredIngredientName: String?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                AppBackgroundView()
                ScrollView {
                    VStack(spacing: 12) {
                        heroWidget
                        pantrySummary
                        quickWidgets
                        searchField
                        filterPicker
                        missingFilterToggle
                        contentList
                    }
                    .padding(.bottom, 88)
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)

                addButton
                    .padding(.trailing, 20)
                    .padding(.bottom, 24)

                SuccessCheckmarkOverlay(isVisible: viewModel.showSuccessOverlay)
            }
            .navigationTitle("Ingredient Tracker")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $viewModel.isPresentingEditor) {
                IngredientEditorSheet(
                    ingredient: viewModel.editingIngredient,
                    inlineError: viewModel.inlineError,
                    shakeTrigger: viewModel.shakeTrigger
                ) { name, details, usage, nutrition, symbol, pantryStatus, tags, collections, substitutions, pairings, notes, shelfLife in
                    viewModel.saveIngredient(
                        name: name,
                        details: details,
                        usage: usage,
                        nutritionInfo: nutrition,
                        symbol: symbol,
                        pantryStatus: pantryStatus,
                        tags: tags,
                        collections: collections,
                        substitutions: substitutions,
                        pairings: pairings,
                        quickNotes: notes,
                        shelfLife: shelfLife,
                        in: store
                    )
                }
            }
        }
    }

    private var pantrySummary: some View {
        let total = store.ingredients.count
        let missing = store.ingredients.filter(\.isMissing).count
        let available = max(total - missing, 0)
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                MetricCell(title: "All", value: "\(total)", symbol: "tray.full.fill")
                    .frame(width: 125)
                MetricCell(title: "In Pantry", value: "\(available)", symbol: "checkmark.seal.fill")
                    .frame(width: 125)
                MetricCell(title: "Need to Buy", value: "\(missing)", symbol: "cart.badge.plus")
                    .frame(width: 125)
            }
        }
    }

    private var heroWidget: some View {
        AppCard {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ingredient Dashboard")
                        .font(.title3.bold())
                        .foregroundStyle(Color("AppTextPrimary"))
                    Text("Keep your pantry organized and quickly reference culinary essentials.")
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .lineLimit(3)
                    if let featuredIngredientName {
                        Text("Today focus: \(featuredIngredientName)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color("AppAccent"))
                    }
                }
                Spacer()
                AppArtworkView(name: "CalmHero", height: 96)
                    .frame(width: 96)
            }
        }
        .onAppear {
            updateFeaturedIngredient()
        }
        .onChange(of: store.viewCounts) { _, _ in
            updateFeaturedIngredient()
        }
    }

    private var quickWidgets: some View {
        HStack(spacing: 10) {
            quickWidgetButton(
                title: "Add New",
                subtitle: "Create ingredient",
                icon: "plus.circle.fill"
            ) {
                viewModel.openNewIngredientForm()
            }
            quickWidgetButton(
                title: "Need to Buy",
                subtitle: "\(store.ingredients.filter(\.isMissing).count) items",
                icon: "cart.fill"
            ) {
                FeedbackManager.tap()
                viewModel.onlyMissing = true
            }
            quickWidgetButton(
                title: "Random Pick",
                subtitle: "Inspire cooking",
                icon: "sparkles"
            ) {
                FeedbackManager.tap()
                if let random = store.ingredients.randomElement() {
                    featuredIngredientName = random.name
                }
            }
        }
    }

    private func quickWidgetButton(title: String, subtitle: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(Color("AppPrimary"))
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
            .padding(10)
            .appDepthCard(cornerRadius: 14, elevated: false)
        }
        .buttonStyle(.plain)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color("AppTextSecondary"))
            TextField("Search ingredients", text: $viewModel.searchText)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .foregroundStyle(Color("AppTextPrimary"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .appDepthCard(cornerRadius: 14, elevated: false)
    }

    private var filterPicker: some View {
        Picker("Filter", selection: $viewModel.filterMode) {
            ForEach(IngredientTrackerViewModel.FilterMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    private var missingFilterToggle: some View {
        Toggle(isOn: $viewModel.onlyMissing) {
            Text("Only missing")
                .foregroundStyle(Color("AppTextPrimary"))
                .font(.subheadline.weight(.semibold))
        }
        .toggleStyle(.switch)
        .tint(Color("AppPrimary"))
        .padding(12)
        .appDepthCard(cornerRadius: 14, elevated: false)
    }

    @ViewBuilder
    private var contentList: some View {
        let ingredients = viewModel.filteredIngredients(from: store)
        if ingredients.isEmpty {
            AppCard {
                VStack(spacing: 12) {
                    AppArtworkView(name: "CalmPantry", height: 160)
                    Text("No ingredients added yet. Tap '+' to start tracking your favorites!")
                        .font(.body)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    Text("No ingredients added yet")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color("AppTextPrimary"))
                }
                .frame(maxWidth: .infinity)
            }
        } else {
            LazyVStack(spacing: 10) {
                ForEach(ingredients) { ingredient in
                    ingredientCard(ingredient)
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button("Edit") {
                                viewModel.openEdit(ingredient)
                            }
                            .tint(Color("AppPrimary"))
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button("Delete", role: .destructive) {
                                viewModel.delete(ingredient, in: store)
                            }
                        }
                }
            }
        }
    }

    private func ingredientCard(_ ingredient: Ingredient) -> some View {
        let isExpanded = viewModel.expandedIngredientIDs.contains(ingredient.id)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: ingredient.sfSymbol)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Color("AppPrimary"))
                    .frame(width: 42, height: 42)
                    .background(Color("AppBackground"), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(ingredient.name)
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                    Text(ingredient.shortDescription)
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .lineLimit(2)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Text(ingredient.pantryStatus.rawValue)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            ingredient.isMissing ? Color("AppPrimary").opacity(0.55) : Color("AppAccent").opacity(0.45),
                            in: Capsule()
                        )
                    if ingredient.soonToExpire {
                        Text("Soon to expire")
                            .font(.caption2)
                            .foregroundStyle(Color("AppAccent"))
                    }
                }
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundStyle(Color("AppTextSecondary"))
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nutritional Information")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color("AppAccent"))
                    Text(ingredient.nutritionInfo.isEmpty ? "No nutrition details added yet." : ingredient.nutritionInfo)
                        .font(.footnote)
                        .foregroundStyle(Color("AppTextPrimary"))
                    Text("Usage Tips")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color("AppAccent"))
                    Text(ingredient.usage.isEmpty ? "No usage tips added yet." : ingredient.usage)
                        .font(.footnote)
                        .foregroundStyle(Color("AppTextPrimary"))

                    if !ingredient.tags.isEmpty {
                        Text("Tags")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color("AppAccent"))
                        FlowRow(items: ingredient.tags)
                    }

                    if !ingredient.collections.isEmpty {
                        Text("Collections")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color("AppAccent"))
                        FlowRow(items: ingredient.collections)
                    }

                    if !ingredient.substitutions.isEmpty {
                        Text("Substitutions")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color("AppAccent"))
                        ForEach(ingredient.substitutions) { substitution in
                            Text("\(substitution.fromAmount) -> \(substitution.toAmount)")
                                .font(.footnote)
                                .foregroundStyle(Color("AppTextPrimary"))
                        }
                    }

                    if !ingredient.pairings.isEmpty {
                        Text("Pairs well with")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color("AppAccent"))
                        Text(ingredient.pairings.joined(separator: ", "))
                            .font(.footnote)
                            .foregroundStyle(Color("AppTextPrimary"))
                    }

                    if !ingredient.quickNotes.isEmpty {
                        Text("Quick notes")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color("AppAccent"))
                        Text(ingredient.quickNotes)
                            .font(.footnote)
                            .foregroundStyle(Color("AppTextPrimary"))
                    }

                    Text("Shelf Life")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color("AppAccent"))
                    Text("Fridge: \(ingredient.shelfLife.fridgeDays)d, Pantry: \(ingredient.shelfLife.pantryDays)d, Freezer: \(ingredient.shelfLife.freezerDays)d")
                        .font(.footnote)
                        .foregroundStyle(Color("AppTextPrimary"))
                    if !ingredient.shelfLife.storageTips.isEmpty {
                        Text("Storage tips: \(ingredient.shelfLife.storageTips)")
                            .font(.footnote)
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                viewModel.toggleExpansion(ingredient, in: store)
            }
        }
        .padding(12)
        .appDepthCard(cornerRadius: 14, elevated: false)
    }

    private func updateFeaturedIngredient() {
        let top = store.viewCounts.sorted { $0.value > $1.value }.first?.key
        featuredIngredientName = top
    }

    private var addButton: some View {
        Button(action: viewModel.openNewIngredientForm) {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color("AppTextPrimary"))
                .frame(width: 58, height: 58)
                .background(
                    LinearGradient(
                        colors: [Color("AppPrimary"), Color("AppAccent")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Circle()
                )
                .shadow(color: Color.black.opacity(0.22), radius: 6, x: 0, y: 4)
        }
        .accessibilityLabel("Add ingredient")
    }
}

private struct IngredientEditorSheet: View {
    let ingredient: Ingredient?
    let inlineError: String?
    let shakeTrigger: CGFloat
    let onSave: (
        String,
        String,
        String,
        String,
        String,
        Ingredient.PantryStatus,
        [String],
        [String],
        [Ingredient.Substitution],
        [String],
        String,
        Ingredient.ShelfLife
    ) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var details: String
    @State private var usage: String
    @State private var nutrition: String
    @State private var symbol: String
    @State private var pantryStatus: Ingredient.PantryStatus
    @State private var selectedTags: Set<String>
    @State private var selectedCollections: Set<String>
    @State private var pairingText: String
    @State private var notes: String
    @State private var storageTips: String
    @State private var fridgeDays: Int
    @State private var pantryDays: Int
    @State private var freezerDays: Int
    @State private var substitutionInputs: [SubInput]

    private let availableTags = ["Baking", "Sauces", "Fermented", "Seasonal"]
    private let availableCollections = ["My Essentials", "Weekend Cooking", "Exam Prep"]

    init(
        ingredient: Ingredient?,
        inlineError: String?,
        shakeTrigger: CGFloat,
        onSave: @escaping (
            String,
            String,
            String,
            String,
            String,
            Ingredient.PantryStatus,
            [String],
            [String],
            [Ingredient.Substitution],
            [String],
            String,
            Ingredient.ShelfLife
        ) -> Bool
    ) {
        self.ingredient = ingredient
        self.inlineError = inlineError
        self.shakeTrigger = shakeTrigger
        self.onSave = onSave
        _name = State(initialValue: ingredient?.name ?? "")
        _details = State(initialValue: ingredient?.details ?? "")
        _usage = State(initialValue: ingredient?.usage ?? "")
        _nutrition = State(initialValue: ingredient?.nutritionInfo ?? "")
        _symbol = State(initialValue: ingredient?.sfSymbol ?? "leaf.fill")
        _pantryStatus = State(initialValue: ingredient?.pantryStatus ?? .inPantry)
        _selectedTags = State(initialValue: Set(ingredient?.tags ?? []))
        _selectedCollections = State(initialValue: Set(ingredient?.collections ?? []))
        _pairingText = State(initialValue: ingredient?.pairings.joined(separator: ", ") ?? "")
        _notes = State(initialValue: ingredient?.quickNotes ?? "")
        _storageTips = State(initialValue: ingredient?.shelfLife.storageTips ?? "")
        _fridgeDays = State(initialValue: ingredient?.shelfLife.fridgeDays ?? 5)
        _pantryDays = State(initialValue: ingredient?.shelfLife.pantryDays ?? 14)
        _freezerDays = State(initialValue: ingredient?.shelfLife.freezerDays ?? 30)
        _substitutionInputs = State(initialValue: Self.makeSubInputs(from: ingredient?.substitutions ?? []))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    VStack(spacing: 12) {
                        AppCard {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionTitleRow(title: "Ingredient", subtitle: "Core reference details")
                                TextField("Name", text: $name)
                                    .modifier(editorFieldStyle())
                                TextField("Brief description", text: $details, axis: .vertical)
                                    .lineLimit(2...4)
                                    .modifier(ShakeEffect(animatableData: shakeTrigger))
                                    .modifier(editorFieldStyle())
                                TextField("Usage tips", text: $usage, axis: .vertical)
                                    .lineLimit(2...4)
                                    .modifier(editorFieldStyle())
                                TextField("Nutritional information", text: $nutrition, axis: .vertical)
                                    .lineLimit(2...4)
                                    .modifier(editorFieldStyle())
                                TextField("SF Symbol (e.g. leaf.fill)", text: $symbol)
                                    .modifier(editorFieldStyle())
                            }
                        }

                        AppCard {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionTitleRow(title: "Pantry Availability")
                                Picker("Status", selection: $pantryStatus) {
                                    ForEach(Ingredient.PantryStatus.allCases) { status in
                                        Text(status.rawValue).tag(status)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }

                        AppCard {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionTitleRow(title: "Smart Tags")
                                SelectableFlow(items: availableTags, selected: $selectedTags)
                            }
                        }

                        AppCard {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionTitleRow(title: "Collections")
                                SelectableFlow(items: availableCollections, selected: $selectedCollections)
                            }
                        }

                        AppCard {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionTitleRow(title: "Substitutions", subtitle: "Up to 5 alternatives")
                                ForEach($substitutionInputs) { $input in
                                    VStack(alignment: .leading, spacing: 8) {
                                        TextField("Original amount", text: $input.fromAmount)
                                            .modifier(editorFieldStyle())
                                        TextField("Replacement amount", text: $input.toAmount)
                                            .modifier(editorFieldStyle())
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }

                        AppCard {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionTitleRow(title: "Pairing Guide")
                                TextField("Comma-separated pairings", text: $pairingText, axis: .vertical)
                                    .lineLimit(2...4)
                                    .modifier(editorFieldStyle())
                            }
                        }

                        AppCard {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionTitleRow(title: "Quick Notes")
                                TextField("Add your practical note", text: $notes, axis: .vertical)
                                    .lineLimit(3...6)
                                    .modifier(editorFieldStyle())
                            }
                        }

                        AppCard {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionTitleRow(title: "Shelf Life + Storage Tips")
                                Stepper("Fridge days: \(fridgeDays)", value: $fridgeDays, in: 0...90)
                                Stepper("Pantry days: \(pantryDays)", value: $pantryDays, in: 0...180)
                                Stepper("Freezer days: \(freezerDays)", value: $freezerDays, in: 0...365)
                                TextField("Storage tips", text: $storageTips, axis: .vertical)
                                    .lineLimit(2...4)
                                    .modifier(editorFieldStyle())
                            }
                        }

                        if let inlineError {
                            AppCard {
                                Text(inlineError)
                                    .font(.footnote)
                                    .foregroundStyle(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .padding(14)
                }
            }
            .navigationTitle(ingredient == nil ? "Add Ingredient" : "Edit Ingredient")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        FeedbackManager.tap()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let substitutions = substitutionInputs.compactMap { input -> Ingredient.Substitution? in
                            let from = input.fromAmount.trimmingCharacters(in: .whitespacesAndNewlines)
                            let to = input.toAmount.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !from.isEmpty, !to.isEmpty else { return nil }
                            return Ingredient.Substitution(id: UUID(), fromAmount: from, toAmount: to)
                        }
                        let pairings = pairingText
                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }

                        let shelfLife = Ingredient.ShelfLife(
                            fridgeDays: fridgeDays,
                            pantryDays: pantryDays,
                            freezerDays: freezerDays,
                            storageTips: storageTips.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        let didSave = onSave(
                            name,
                            details,
                            usage,
                            nutrition,
                            symbol.isEmpty ? "leaf.fill" : symbol,
                            pantryStatus,
                            Array(selectedTags),
                            Array(selectedCollections),
                            substitutions,
                            pairings,
                            notes,
                            shelfLife
                        )
                        if didSave {
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    private func editorFieldStyle() -> some ViewModifier {
        EditorFieldStyleModifier()
    }

    private static func makeSubInputs(from substitutions: [Ingredient.Substitution]) -> [SubInput] {
        var inputs = substitutions.map { SubInput(id: $0.id, fromAmount: $0.fromAmount, toAmount: $0.toAmount) }
        while inputs.count < 5 {
            inputs.append(SubInput(id: UUID(), fromAmount: "", toAmount: ""))
        }
        return Array(inputs.prefix(5))
    }
}

private struct EditorFieldStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .appDepthCard(cornerRadius: 12, elevated: false)
    }
}

private struct SubInput: Identifiable {
    let id: UUID
    var fromAmount: String
    var toAmount: String
}

private struct FlowRow: View {
    let items: [String]

    var body: some View {
        FlexibleWrap(items: items) { value in
            Text(value)
                .font(.caption)
                .foregroundStyle(Color("AppTextPrimary"))
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color("AppPrimary").opacity(0.3), in: Capsule())
        }
    }
}

private struct SelectableFlow: View {
    let items: [String]
    @Binding var selected: Set<String>

    var body: some View {
        FlexibleWrap(items: items) { value in
            Button {
                FeedbackManager.tap()
                if selected.contains(value) {
                    selected.remove(value)
                } else {
                    selected.insert(value)
                }
            } label: {
                Text(value)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        selected.contains(value)
                            ? Color("AppPrimary")
                            : Color("AppSurface"),
                        in: Capsule()
                    )
            }
            .buttonStyle(.plain)
        }
    }
}

private struct FlexibleWrap<Content: View>: View {
    let items: [String]
    let content: (String) -> Content

    var body: some View {
        GeometryReader { proxy in
            wrapped(in: proxy.size.width)
        }
        .frame(minHeight: 44)
    }

    private func wrapped(in width: CGFloat) -> some View {
        var x: CGFloat = 0
        var y: CGFloat = 0

        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                content(item)
                    .alignmentGuide(.leading) { dimension in
                        if x + dimension.width > width {
                            x = 0
                            y -= dimension.height + 8
                        }
                        let result = x
                        x += dimension.width + 8
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = y
                        if item == items.last { y = 0 }
                        return result
                    }
            }
        }
    }
}
