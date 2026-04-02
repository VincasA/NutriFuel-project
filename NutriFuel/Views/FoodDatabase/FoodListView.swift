import SwiftUI
import SwiftData

private enum FoodsSection: String, CaseIterable {
    case recentlyLogged = "Recently Logged Foods"
    case customFoods = "Custom Foods"
}

private struct RecentLoggedFoodItem: Identifiable {
    enum Kind {
        case custom(Food)
        case official(OfficialFood)
    }

    let id: String
    let kind: Kind
    let loggedAt: Date
}

struct FoodListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appEnvironment) private var appEnvironment
    @Query private var recentEntries: [LogEntry]
    @State private var viewModel: FoodDatabaseViewModel?
    @State private var selectedSection: FoodsSection = .recentlyLogged
    @State private var showAddFood = false
    @State private var showScanner = false
    @State private var editingFood: Food?
    @State private var scannedBarcode: String?
    @State private var barcodeMatches: [Food] = []
    @State private var selectedRecentCustomFood: Food?
    @State private var selectedRecentOfficialFood: OfficialFood?

    init() {
        var descriptor = FetchDescriptor<LogEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        descriptor.fetchLimit = 200
        _recentEntries = Query(descriptor)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    loadedContent(viewModel)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Foods")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Scan Food", systemImage: "barcode.viewfinder") {
                        showScanner = true
                    }
                    .labelStyle(.iconOnly)
                }
            }
            .task {
                if viewModel == nil {
                    viewModel = appEnvironment.makeFoodDatabaseViewModel()
                }
                viewModel?.fetchFoods()
            }
            .sheet(isPresented: $showAddFood, onDismiss: refreshFoods) {
                AddEditFoodView(
                    modelContext: modelContext,
                    prefilledBarcode: scannedBarcode
                )
            }
            .sheet(item: $editingFood, onDismiss: refreshFoods) { food in
                AddEditFoodView(modelContext: modelContext, food: food)
            }
            .sheet(item: $selectedRecentCustomFood) { food in
                NavigationStack {
                    FoodDetailView(food: food)
                }
            }
            .sheet(item: $selectedRecentOfficialFood) { food in
                OfficialFoodDetailView(officialFood: food)
            }
            .sheet(isPresented: $showScanner, onDismiss: handleScanResult) {
                BarcodeScannerSheet(scannedBarcode: $scannedBarcode)
            }
            .sheet(isPresented: barcodePickerIsPresented) {
                BarcodeFoodPickerView(
                    title: "Choose Custom Food",
                    subtitle: "Multiple saved custom foods use this barcode. Pick the one you want to edit.",
                    foods: barcodeMatches,
                    onSelect: { food in
                        editingFood = food
                    }
                )
                .presentationDetents([.medium, .large])
            }
        }
        .appPageBackground()
    }

    @ViewBuilder
    private func loadedContent(_ viewModel: FoodDatabaseViewModel) -> some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: 10) {
            Picker("Section", selection: $selectedSection) {
                ForEach(FoodsSection.allCases, id: \.self) { section in
                    Text(section.rawValue).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)

            List {
                switch selectedSection {
                case .recentlyLogged:
                    recentlyLoggedSection
                case .customFoods:
                    customFoodsSection(vm: viewModel)
                }
            }
            .listStyle(.plain)
            .listRowSpacing(8)
            .scrollContentBackground(.hidden)
            .environment(\.defaultMinListRowHeight, 0)
        }
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: selectedSection == .recentlyLogged
            ? "Search recently logged foods"
            : "Search custom foods or barcodes"
        )
    }

    private var uniqueRecentItems: [RecentLoggedFoodItem] {
        var seen = Set<String>()
        var items: [RecentLoggedFoodItem] = []
        items.reserveCapacity(40)

        for entry in recentEntries {
            if let food = entry.food {
                let key = "custom:\(food.id.uuidString)"
                if seen.insert(key).inserted {
                    items.append(RecentLoggedFoodItem(id: key, kind: .custom(food), loggedAt: entry.date))
                }
            } else if let officialFood = entry.officialFood {
                let key = "official:\(officialFood.id.uuidString)"
                if seen.insert(key).inserted {
                    items.append(RecentLoggedFoodItem(id: key, kind: .official(officialFood), loggedAt: entry.date))
                }
            }

            if items.count >= 40 {
                break
            }
        }

        return items
    }

    private var filteredRecentItems: [RecentLoggedFoodItem] {
        let query = viewModel?.searchText.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !query.isEmpty else { return uniqueRecentItems }

        return uniqueRecentItems.filter { item in
            switch item.kind {
            case .custom(let food):
                return matches(food.name, query: query) ||
                matches(food.brand, query: query) ||
                matches(food.barcode, query: query)
            case .official(let food):
                return matches(food.name, query: query) ||
                matches(food.brandOwner, query: query) ||
                matches(food.gtinUpc, query: query)
            }
        }
    }

    @ViewBuilder
    private var recentlyLoggedSection: some View {
        if filteredRecentItems.isEmpty {
            ContentUnavailableView(
                "No Recently Logged Foods",
                systemImage: "clock.arrow.circlepath",
                description: Text("Log foods from Today to populate recent items")
            )
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            .listRowBackground(Color.clear)
        } else {
            ForEach(filteredRecentItems) { item in
                Button {
                    switch item.kind {
                    case .custom(let food):
                        selectedRecentCustomFood = food
                    case .official(let food):
                        selectedRecentOfficialFood = food
                    }
                } label: {
                    RecentLoggedFoodRow(item: item)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .listRowBackground(Color.clear)
            }
        }
    }

    @ViewBuilder
    private func customFoodsSection(vm: FoodDatabaseViewModel) -> some View {
        if vm.foods.isEmpty {
            ContentUnavailableView(
                "No Custom Foods Yet",
                systemImage: "fork.knife",
                description: Text("Use the bottom-right quick log button or scan a barcode to create a custom food")
            )
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            .listRowBackground(Color.clear)
        } else {
            ForEach(vm.foods, id: \.id) { food in
                NavigationLink {
                    FoodDetailView(food: food)
                } label: {
                    FoodRow(food: food)
                }
                .contentShape(Rectangle())
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .listRowBackground(Color.clear)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        vm.deleteFood(food)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                    Button {
                        editingFood = food
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
        }
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

    private func handleScanResult() {
        guard let scannedBarcode else { return }

        let matches = viewModel?.findFoodsByBarcode(scannedBarcode) ?? []
        self.scannedBarcode = scannedBarcode

        switch matches.count {
        case 0:
            editingFood = nil
            showAddFood = true
        case 1:
            editingFood = matches[0]
        default:
            barcodeMatches = matches
        }
    }

    private func refreshFoods() {
        viewModel?.fetchFoods()
        scannedBarcode = nil
        barcodeMatches = []
    }

    private func matches(_ candidate: String?, query: String) -> Bool {
        guard let candidate else { return false }
        return candidate.localizedStandardContains(query)
    }
}

struct BarcodeScannerSheet: View {
    @Binding var scannedBarcode: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        BarcodeScannerView { barcode in
            scannedBarcode = barcode
            dismiss()
        }
    }
}

struct FoodRow: View {
    let food: Food

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(food.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))

                if let brand = food.brand, !brand.isEmpty {
                    Text("Custom • \(brand)")
                        .font(.caption)
                        .foregroundStyle(AppStyle.subtleText)
                }

                Text("\(food.servingSize, specifier: "%.0f")\(food.servingUnit) per serving")
                    .font(.caption2)
                    .foregroundStyle(AppStyle.subtleText.opacity(0.9))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(food.calories))")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(AppStyle.accentStrong)
                Text("kcal")
                    .font(.caption2)
                    .foregroundStyle(AppStyle.subtleText)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .appCardStyle()
    }
}

private struct RecentLoggedFoodRow: View {
    let item: RecentLoggedFoodItem

    private var title: String {
        switch item.kind {
        case .custom(let food): return food.name
        case .official(let food): return food.name
        }
    }

    private var subtitle: String {
        switch item.kind {
        case .custom(let food):
            return food.brand ?? "Custom"
        case .official(let food):
            return food.brandOwner ?? "Open Food Facts"
        }
    }

    private var sourceLabel: String {
        switch item.kind {
        case .custom:
            return "Custom"
        case .official:
            return "Open Food Facts"
        }
    }

    private var calories: Double {
        switch item.kind {
        case .custom(let food):
            return food.calories
        case .official(let food):
            return food.calories
        }
    }

    private var timestampString: String {
        item.loggedAt.formatted(date: .abbreviated, time: .shortened)
    }

    private var sourceTint: Color {
        sourceLabel == "Open Food Facts" ? AppStyle.secondaryAccent : AppStyle.accent
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppStyle.subtleText)
                Text(timestampString)
                    .font(.caption2)
                    .foregroundStyle(AppStyle.subtleText.opacity(0.88))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                AppChip(text: sourceLabel, isActive: sourceLabel == "Open Food Facts", activeTint: sourceTint)
                Text("\(Int(calories)) kcal")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppStyle.accentStrong)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .appCardStyle()
    }
}

#Preview {
    FoodListView()
        .modelContainer(for: [Food.self, OfficialFood.self, LogEntry.self, UserGoals.self], inMemory: true)
}
