import SwiftUI
import SwiftData

private typealias LogQuantityUnit = ServingQuantityUnit

private enum LoggableFoodSelection: Identifiable {
    case custom(Food)
    case official(OfficialFood)

    var id: String {
        switch self {
        case .custom(let food): return "custom:\(food.id.uuidString)"
        case .official(let food): return "official:\(food.id.uuidString)"
        }
    }

    var nutrition: any NutritionProviding {
        switch self {
        case .custom(let food): return food
        case .official(let food): return food
        }
    }

    var foodDraft: FoodDraft {
        switch self {
        case .custom(let food):
            FoodDraft(food: food)
        case .official(let food):
            FoodDraft(officialFood: food)
        }
    }

    var name: String { nutrition.name }
    var subtitle: String? { nutrition.brandLabel }
    var servingSize: Double { nutrition.servingSize }
    var servingUnit: String { nutrition.servingUnit }
    var calories: Double { nutrition.calories }

    var sourceLabel: String {
        switch self {
        case .custom: return "Custom"
        case .official: return "Open Food Facts"
        }
    }

    var sourceTint: Color {
        switch self {
        case .custom: return AppStyle.accent
        case .official: return AppStyle.secondaryAccent
        }
    }
}

private struct RecentLoggableFood: Identifiable {
    let id: String
    let selection: LoggableFoodSelection
}

struct AddLogEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appEnvironment) private var appEnvironment

    @Bindable var logVM: DailyLogViewModel
    @State var mealType: MealType
    let startsInOfficialLookup: Bool
    let prefilledBarcode: String?

    @Query(
        filter: #Predicate<Food> { food in
            food.isListedInDatabase != false
        },
        sort: \Food.name
    ) private var visibleFoods: [Food]
    @Query(sort: \OfficialFood.name) private var allOfficialFoods: [OfficialFood]
    @Query private var recentEntries: [LogEntry]

    @State private var searchText = ""
    @State private var selectedFoodForLogging: LoggableFoodSelection?
    @State private var isSearchingOfficialFoods = false
    @State private var isResolvingPrefilledBarcode = false
    @State private var statusMessage: String?
    @State private var showScanner = false
    @State private var didApplyInitialRoute = false
    @State private var pendingScannedBarcode: String?
    @State private var barcodeMatches: [Food] = []

    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    init(
        logVM: DailyLogViewModel,
        mealType: MealType,
        startsInOfficialLookup: Bool = false,
        prefilledBarcode: String? = nil
    ) {
        self.logVM = logVM
        _mealType = State(initialValue: mealType)
        self.startsInOfficialLookup = startsInOfficialLookup
        self.prefilledBarcode = prefilledBarcode

        var descriptor = FetchDescriptor<LogEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        descriptor.fetchLimit = 200
        _recentEntries = Query(descriptor)
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var recentFoods: [RecentLoggableFood] {
        var seen = Set<String>()
        var items: [RecentLoggableFood] = []
        items.reserveCapacity(30)

        for entry in recentEntries {
            if let food = entry.food {
                let key = "custom:\(food.id.uuidString)"
                if seen.insert(key).inserted {
                    items.append(RecentLoggableFood(id: key, selection: .custom(food)))
                }
            } else if let officialFood = entry.officialFood {
                let key = "official:\(officialFood.id.uuidString)"
                if seen.insert(key).inserted {
                    items.append(RecentLoggableFood(id: key, selection: .official(officialFood)))
                }
            }

            if items.count >= 30 {
                break
            }
        }

        return items
    }

    private var filteredCustomFoods: [Food] {
        guard !trimmedSearchText.isEmpty else { return [] }
        let query = trimmedSearchText
        return visibleFoods.filter {
            matches($0.name, query: query) ||
            matches($0.brand, query: query) ||
            matches($0.barcode, query: query)
        }
    }

    private var filteredOfficialFoods: [OfficialFood] {
        guard !trimmedSearchText.isEmpty else { return [] }
        let query = trimmedSearchText
        return allOfficialFoods.filter {
            matches($0.name, query: query) ||
            matches($0.brandOwner, query: query) ||
            matches($0.gtinUpc, query: query)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if !trimmedSearchText.isEmpty {
                        searchOnlineButton
                    }

                    if isResolvingPrefilledBarcode || isSearchingOfficialFoods {
                        progressCard
                    }

                    if let statusMessage {
                        statusCard(statusMessage)
                    }

                    resultsContent
                }
                .padding(16)
                .padding(.bottom, 24)
            }
            .appPageBackground()
            .navigationTitle("Search Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Scan Food", systemImage: "barcode.viewfinder") {
                        showScanner = true
                    }
                    .labelStyle(.iconOnly)
                }
            }
        }
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search foods by name, brand, or barcode"
        )
        .sheet(item: $selectedFoodForLogging) { selectedFood in
            FoodLoggingDetailsView(
                selection: selectedFood,
                selectedDay: logVM.selectedDate,
                initialMealType: mealType
            ) { submission in
                logSelection(submission)
            }
        }
        .sheet(isPresented: $showScanner, onDismiss: handleScannedBarcode) {
            BarcodeScannerView { barcode in
                pendingScannedBarcode = barcode
                showScanner = false
            }
        }
        .sheet(isPresented: barcodePickerIsPresented) {
            BarcodeFoodPickerView(
                title: "Choose Custom Food",
                subtitle: "Multiple saved custom foods use this barcode. Pick the one you want to log.",
                foods: barcodeMatches,
                onSelect: { food in
                    statusMessage = "Matched custom food: \(food.displayName)"
                    selectedFoodForLogging = .custom(food)
                }
            )
            .presentationDetents([.medium, .large])
        }
        .alert("Could Not Continue", isPresented: $showErrorAlert) {} message: {
            Text(errorMessage)
        }
        .task {
            applyInitialRouteIfNeeded()
        }
    }

    private var searchOnlineButton: some View {
        Button {
            searchOfficialFoodsOnline()
        } label: {
            Label("Search \"\(trimmedSearchText)\" in Open Food Facts", systemImage: "globe")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
        }
        .buttonStyle(.bordered)
        .tint(AppStyle.secondaryAccent)
        .disabled(trimmedSearchText.isEmpty || isSearchingOfficialFoods || isResolvingPrefilledBarcode)
    }

    private var progressCard: some View {
        HStack(spacing: 10) {
            ProgressView()
            Text(isResolvingPrefilledBarcode ? "Identifying scanned food..." : "Searching Open Food Facts...")
                .font(.subheadline)
                .foregroundStyle(AppStyle.subtleText)
            Spacer()
        }
        .padding(14)
        .appCardStyle()
    }

    private func statusCard(_ message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(AppStyle.accentStrong)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .appCardStyle()
    }

    @ViewBuilder
    private var resultsContent: some View {
        if trimmedSearchText.isEmpty {
            recentSection
        } else {
            searchResultsSections
        }
    }

    @ViewBuilder
    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Recently Logged")

            if recentFoods.isEmpty {
                ContentUnavailableView(
                    "No Recently Logged Foods",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Start with Search Food or Scan Food to build your history.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .appCardStyle()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(recentFoods) { item in
                        selectionRow(item.selection)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var searchResultsSections: some View {
        let hasCustom = !filteredCustomFoods.isEmpty
        let hasOfficial = !filteredOfficialFoods.isEmpty

        if !hasCustom && !hasOfficial {
            ContentUnavailableView(
                "No Foods Found",
                systemImage: "fork.knife",
                description: Text("Try a different keyword or run online search to import official foods.")
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .appCardStyle()
        } else {
            VStack(alignment: .leading, spacing: 12) {
                if hasCustom {
                    VStack(alignment: .leading, spacing: 8) {
                        sectionTitle("Custom Foods")
                        LazyVStack(spacing: 8) {
                            ForEach(filteredCustomFoods, id: \.id) { food in
                                selectionRow(.custom(food))
                            }
                        }
                    }
                }

                if hasOfficial {
                    VStack(alignment: .leading, spacing: 8) {
                        sectionTitle("Official Foods")
                        LazyVStack(spacing: 8) {
                            ForEach(filteredOfficialFoods, id: \.id) { food in
                                selectionRow(.official(food))
                            }
                        }
                    }
                }
            }
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .textCase(.uppercase)
            .foregroundStyle(AppStyle.subtleText)
            .padding(.top, 2)
    }

    private func selectionRow(_ selection: LoggableFoodSelection) -> some View {
        Button {
            selectedFoodForLogging = selection
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(selection.name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    if let subtitle = selection.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(AppStyle.subtleText)
                    }

                    HStack(spacing: 6) {
                        AppChip(text: selection.sourceLabel, isActive: true, activeTint: selection.sourceTint)
                        Text("\(selection.servingSize, specifier: "%.0f")\(selection.servingUnit) serving")
                            .font(.caption2)
                            .foregroundStyle(AppStyle.subtleText)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(selection.calories))")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(selection.sourceTint)
                    Text("kcal")
                        .font(.caption2)
                        .foregroundStyle(AppStyle.subtleText)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
            .appCardStyle()
        }
        .buttonStyle(.plain)
    }

    private var barcodePickerIsPresented: Binding<Bool> {
        Binding(
            get: { !barcodeMatches.isEmpty },
            set: { isPresented in
                if !isPresented {
                    barcodeMatches = []
                }
            }
        )
    }

    private func applyInitialRouteIfNeeded() {
        guard !didApplyInitialRoute else { return }
        didApplyInitialRoute = true

        let normalizedBarcode = OFFProductDTO.normalizeBarcode(prefilledBarcode)
        if !normalizedBarcode.isEmpty {
            resolveScannedBarcode(normalizedBarcode)
            return
        }

        if startsInOfficialLookup {
            showScanner = true
        }
    }

    private func handleScannedBarcode() {
        guard let pendingScannedBarcode else { return }
        resolveScannedBarcode(pendingScannedBarcode)
        self.pendingScannedBarcode = nil
    }

    private func resolveScannedBarcode(_ barcode: String) {
        let normalizedBarcode = OFFProductDTO.normalizeBarcode(barcode)
        guard !normalizedBarcode.isEmpty else {
            statusMessage = "Invalid barcode. Try scanning again."
            return
        }

        let matchingCustomFoods = appEnvironment.foodRepository.findFoodsByBarcode(normalizedBarcode)
        switch matchingCustomFoods.count {
        case 0:
            break
        case 1:
            let customFood = matchingCustomFoods[0]
            statusMessage = "Matched custom food: \(customFood.displayName)"
            selectedFoodForLogging = .custom(customFood)
            return
        default:
            statusMessage = "Choose a saved custom food for this barcode."
            barcodeMatches = matchingCustomFoods
            return
        }

        isResolvingPrefilledBarcode = true
        statusMessage = nil

        Task { @MainActor in
            defer { isResolvingPrefilledBarcode = false }

            do {
                if let officialFood = try await appEnvironment.officialFoodRepository.lookupByBarcode(normalizedBarcode) {
                    statusMessage = "Matched official food: \(officialFood.displayName)"
                    selectedFoodForLogging = .official(officialFood)
                } else {
                    statusMessage = "No food matched this barcode. Search by name to continue."
                }
            } catch {
                showError("Barcode lookup failed: \(error.localizedDescription)")
            }
        }
    }

    private func searchOfficialFoodsOnline() {
        let query = trimmedSearchText
        guard !query.isEmpty else { return }

        isSearchingOfficialFoods = true
        statusMessage = nil

        Task { @MainActor in
            defer { isSearchingOfficialFoods = false }

            do {
                let results = try await appEnvironment.officialFoodRepository.searchByText(query, limit: 20)
                if results.isEmpty {
                    statusMessage = "No Open Food Facts results found for \"\(query)\"."
                } else {
                    statusMessage = "Imported \(results.count) Open Food Facts result(s)."
                }
            } catch {
                showError("Open Food Facts search failed: \(error.localizedDescription)")
            }
        }
    }

    private func logSelection(_ submission: LogSubmission) -> Bool {
        do {
            let foodToLog: Food?
            if submission.hasNutritionChanges {
                let correctedFood = submission.draft.makeFood(isListedInDatabase: submission.saveAsCustomFood)
                modelContext.insert(correctedFood)
                try modelContext.save()
                foodToLog = correctedFood
            } else {
                foodToLog = nil
            }

            if let foodToLog {
                logVM.addEntry(
                    food: foodToLog,
                    quantity: submission.servings,
                    mealType: submission.mealType,
                    date: submission.timestamp
                )
            } else {
                switch submission.selection {
                case .custom(let food):
                    logVM.addEntry(food: food, quantity: submission.servings, mealType: submission.mealType, date: submission.timestamp)
                case .official(let food):
                    logVM.addOfficialEntry(officialFood: food, quantity: submission.servings, mealType: submission.mealType, date: submission.timestamp)
                }
            }

            dismiss()
            return true
        } catch {
            showError("Failed to save corrected food: \(error.localizedDescription)")
            return false
        }
    }

    private func showError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
    }

    private func matches(_ candidate: String?, query: String) -> Bool {
        guard let candidate else { return false }
        return candidate.localizedStandardContains(query)
    }
}

private struct LogSubmission {
    let selection: LoggableFoodSelection
    let draft: FoodDraft
    let saveAsCustomFood: Bool
    let hasNutritionChanges: Bool
    let servings: Double
    let mealType: MealType
    let timestamp: Date
}

private struct FoodLoggingDetailsView: View {
    @Environment(\.dismiss) private var dismiss

    let selection: LoggableFoodSelection
    let selectedDay: Date
    let initialMealType: MealType
    let onLog: (LogSubmission) -> Bool

    @State private var mealType: MealType
    @State private var amountText = "1.0"
    @State private var quantityUnit: LogQuantityUnit
    @State private var timestamp: Date
    @State private var draft: FoodDraft
    @State private var originalDraft: FoodDraft
    @State private var showNutritionEditor = false
    @State private var showMicros = false
    @State private var saveEditedFoodToCustom = false

    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    init(
        selection: LoggableFoodSelection,
        selectedDay: Date,
        initialMealType: MealType,
        onLog: @escaping (LogSubmission) -> Bool
    ) {
        self.selection = selection
        self.selectedDay = selectedDay
        self.initialMealType = initialMealType
        self.onLog = onLog

        let initialDraft = selection.foodDraft
        _mealType = State(initialValue: initialMealType)
        _quantityUnit = State(initialValue: LogQuantityUnit.defaultLoggingUnit(for: selection.servingUnit))
        _timestamp = State(initialValue: Self.defaultEntryTimestamp(for: selectedDay))
        _draft = State(initialValue: initialDraft)
        _originalDraft = State(initialValue: initialDraft)
        _showMicros = State(initialValue: initialDraft.hasMicros)
    }

    private var enteredAmount: Double {
        max(LocalizedDecimalParser.parse(amountText) ?? 0, 0)
    }

    private var draftServingSize: Double {
        draft.servingSizeValue ?? 100
    }

    private var servingsAmount: Double? {
        ServingUnitConverter.amountInServings(
            amount: enteredAmount,
            amountUnit: quantityUnit,
            servingSize: draftServingSize,
            servingUnit: draft.servingUnit
        )
    }

    private var resolvedTimestamp: Date {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: selectedDay)
        let dayEnd = NutritionCalculator.endOfDay(selectedDay)

        if timestamp >= dayStart && timestamp <= dayEnd {
            return timestamp
        }

        return Self.defaultEntryTimestamp(for: selectedDay)
    }

    private var hasDraftChanges: Bool {
        !draft.isEquivalent(to: originalDraft)
    }

    private var computedCalories: Double {
        (servingsAmount ?? 0) * (draft.caloriesValue ?? 0)
    }

    private var computedProtein: Double {
        (servingsAmount ?? 0) * (draft.proteinValue ?? 0)
    }

    private var computedCarbs: Double {
        (servingsAmount ?? 0) * (draft.carbohydratesValue ?? 0)
    }

    private var computedFat: Double {
        (servingsAmount ?? 0) * (draft.fatValue ?? 0)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    foodHeaderCard
                    caloriesAndMacrosCard
                    nutritionFactsCard
                    portionAndAmountCard
                    logMetaCard

                    if hasDraftChanges {
                        correctedFoodCard
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .appPageBackground()
            .navigationTitle("Log Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: submit) {
                    Text("Add Food")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppStyle.accentStrong)
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 10)
                .background(.ultraThinMaterial)
            }
        }
        .sheet(isPresented: $showNutritionEditor) {
            FoodNutritionEditorView(draft: $draft, showMicros: $showMicros)
        }
        .alert("Could Not Add Food", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onChange(of: hasDraftChanges) { _, hasChanges in
            if !hasChanges {
                saveEditedFoodToCustom = false
            }
        }
    }

    private var foodHeaderCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(draft.trimmedName.isEmpty ? selection.name : draft.trimmedName)
                .font(.system(size: 26, weight: .bold, design: .rounded))

            if !draft.trimmedBrand.isEmpty {
                Text(draft.trimmedBrand)
                    .font(.subheadline)
                    .foregroundStyle(AppStyle.subtleText)
            } else if let subtitle = selection.subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppStyle.subtleText)
            }

            HStack(spacing: 6) {
                AppChip(text: selection.sourceLabel, isActive: true, activeTint: selection.sourceTint)
                AppChip(text: "\(String(format: "%.0f", draftServingSize))\(draft.servingUnit) serving")

                if hasDraftChanges {
                    AppChip(text: "Edited", isActive: true, activeTint: AppStyle.secondaryAccent)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .appCardStyle()
    }

    private var caloriesAndMacrosCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calories")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .textCase(.uppercase)
                .foregroundStyle(AppStyle.subtleText)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(Int(computedCalories.rounded()))")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(AppStyle.accentStrong)

                Text("kcal")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppStyle.subtleText)
            }

            HStack(spacing: 8) {
                macroTile(label: "Protein", value: computedProtein, color: AppStyle.protein)
                macroTile(label: "Carbs", value: computedCarbs, color: AppStyle.carbs)
                macroTile(label: "Fat", value: computedFat, color: AppStyle.fat)
            }
        }
        .padding(14)
        .appCardStyle()
    }

    private func macroTile(label: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(AppStyle.subtleText)
            Text("\(value, specifier: "%.1f")g")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .appInputBackground(radius: 12)
    }

    private var nutritionFactsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Nutrition Facts")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .textCase(.uppercase)
                    .foregroundStyle(AppStyle.subtleText)

                Spacer()

                Button(hasDraftChanges ? "Edit Again" : "Edit Nutrition") {
                    showNutritionEditor = true
                }
                .font(.caption.weight(.semibold))
            }

            NutritionRow(label: "Calories", value: computedCalories, unit: "kcal", color: AppStyle.accent)
            NutritionRow(label: "Protein", value: computedProtein, unit: "g", color: AppStyle.protein)
            NutritionRow(label: "Carbohydrates", value: computedCarbs, unit: "g", color: AppStyle.carbs)
            NutritionRow(label: "Fat", value: computedFat, unit: "g", color: AppStyle.fat)

            if let fiber = draft.fiberValue {
                NutritionRow(label: "Fiber", value: (servingsAmount ?? 0) * fiber, unit: "g", color: .brown)
            }
            if let sugar = draft.sugarValue {
                NutritionRow(label: "Sugar", value: (servingsAmount ?? 0) * sugar, unit: "g", color: .purple)
            }
            if let sodium = draft.sodiumValue {
                NutritionRow(label: "Sodium", value: (servingsAmount ?? 0) * sodium, unit: "mg", color: .gray)
            }
            if let potassium = draft.potassiumValue {
                NutritionRow(label: "Potassium", value: (servingsAmount ?? 0) * potassium, unit: "mg", color: .gray)
            }
            if let calcium = draft.calciumValue {
                NutritionRow(label: "Calcium", value: (servingsAmount ?? 0) * calcium, unit: "mg", color: .gray)
            }
            if let iron = draft.ironValue {
                NutritionRow(label: "Iron", value: (servingsAmount ?? 0) * iron, unit: "mg", color: .gray)
            }
            if let vitaminC = draft.vitaminCValue {
                NutritionRow(label: "Vitamin C", value: (servingsAmount ?? 0) * vitaminC, unit: "mg", color: .yellow)
            }
            if let vitaminD = draft.vitaminDValue {
                NutritionRow(label: "Vitamin D", value: (servingsAmount ?? 0) * vitaminD, unit: "IU", color: .yellow)
            }
        }
        .padding(14)
        .appCardStyle()
    }

    private var portionAndAmountCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Portion Size")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .textCase(.uppercase)
                .foregroundStyle(AppStyle.subtleText)

            HStack {
                Text("Unit")
                    .font(.subheadline)
                    .foregroundStyle(AppStyle.subtleText)

                Spacer()

                Picker("Unit", selection: $quantityUnit) {
                    ForEach(LogQuantityUnit.allCases) { unit in
                        Text(unit.label).tag(unit)
                    }
                }
                .pickerStyle(.menu)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .appInputBackground(radius: 12)

            Text("1 serving = \(draftServingSize, specifier: "%.0f") \(draft.servingUnit)")
                .font(.caption)
                .foregroundStyle(AppStyle.subtleText)

            HStack(spacing: 10) {
                TextField("1.0", text: $amountText)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .frame(height: 46)
                    .appInputBackground(radius: 12)

                Button("Decrease amount", systemImage: "minus") {
                    adjustAmount(by: -1)
                }
                .labelStyle(.iconOnly)
                .font(.system(size: 16, weight: .bold))
                .frame(width: 44, height: 44)
                .appInputBackground(radius: 12)
                .buttonStyle(.plain)
                .contentShape(Rectangle())

                Button("Increase amount", systemImage: "plus") {
                    adjustAmount(by: 1)
                }
                .labelStyle(.iconOnly)
                .font(.system(size: 16, weight: .bold))
                .frame(width: 44, height: 44)
                .appInputBackground(radius: 12)
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }

            if servingsAmount == nil {
                Text("This unit cannot be converted for the selected serving reference.")
                    .font(.caption)
                    .foregroundStyle(AppStyle.subtleText)
            }
        }
        .padding(14)
        .appCardStyle()
    }

    private var logMetaCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Log Details")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .textCase(.uppercase)
                .foregroundStyle(AppStyle.subtleText)

            Picker("Category", selection: $mealType) {
                ForEach(MealType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Text("Timestamp")
                    .font(.subheadline)
                    .foregroundStyle(AppStyle.subtleText)
                Spacer()
                DatePicker(
                    "",
                    selection: $timestamp,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .appInputBackground(radius: 12)
        }
        .padding(14)
        .appCardStyle()
    }

    private var correctedFoodCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Corrected Food")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .textCase(.uppercase)
                .foregroundStyle(AppStyle.subtleText)

            Toggle("Save corrected item to Custom Foods", isOn: $saveEditedFoodToCustom)
                .toggleStyle(.switch)

            Text(saveEditedFoodToCustom
                 ? "This correction will be saved as a reusable custom food and future scans can prefer it."
                 : "Without saving, this correction is logged as a one-off override and stays out of your Custom Foods list.")
            .font(.caption)
            .foregroundStyle(AppStyle.subtleText)

            Button("Reset to Original") {
                draft = originalDraft
                showMicros = originalDraft.hasMicros
            }
            .font(.caption.weight(.semibold))
        }
        .padding(14)
        .appCardStyle()
    }

    private func adjustAmount(by delta: Double) {
        let current = enteredAmount
        let next = max(0, current + delta)
        if abs(next.rounded() - next) < 0.00001 {
            amountText = String(Int(next))
        } else {
            amountText = String(format: "%.1f", next)
        }
    }

    private func submit() {
        guard enteredAmount > 0 else {
            showError("Amount must be greater than 0.")
            return
        }

        guard draft.isValid else {
            showError("Nutrition details are incomplete. Update the corrected food before logging.")
            return
        }

        guard let servingsAmount, servingsAmount > 0 else {
            showError("Cannot convert \(quantityUnit.label) for this food's serving unit (\(draft.servingUnit)).")
            return
        }

        let didLog = onLog(
            LogSubmission(
                selection: selection,
                draft: draft,
                saveAsCustomFood: saveEditedFoodToCustom,
                hasNutritionChanges: hasDraftChanges,
                servings: servingsAmount,
                mealType: mealType,
                timestamp: resolvedTimestamp
            )
        )
        if didLog {
            dismiss()
        }
    }

    private func showError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
    }

    private static func defaultEntryTimestamp(for selectedDay: Date) -> Date {
        let now = Date()
        let calendar = Calendar.current
        let nowTime = calendar.dateComponents([.hour, .minute, .second], from: now)
        return calendar.date(
            bySettingHour: nowTime.hour ?? 12,
            minute: nowTime.minute ?? 0,
            second: nowTime.second ?? 0,
            of: selectedDay
        ) ?? selectedDay
    }
}

private struct FoodNutritionEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var draft: FoodDraft
    @Binding var showMicros: Bool

    var body: some View {
        NavigationStack {
            Form {
                FoodEditorSections(draft: $draft, showMicros: $showMicros)
            }
            .navigationTitle("Edit Nutrition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    AddLogEntryView(
        logVM: DailyLogViewModel(modelContext: try! ModelContainer(for: Food.self, OfficialFood.self, LogEntry.self).mainContext),
        mealType: .breakfast
    )
    .modelContainer(for: [Food.self, OfficialFood.self, LogEntry.self, UserGoals.self], inMemory: true)
}
