import SwiftUI
import SwiftData

private enum MainTab: CaseIterable {
    case today
    case foods
    case history
    case settings

    var title: String {
        switch self {
        case .today: return "Today"
        case .foods: return "Foods"
        case .history: return "History"
        case .settings: return "Settings"
        }
    }

}

private enum QuickAddRoute {
    case search
    case scan
}

private struct QuickAddEntryConfiguration: Identifiable {
    let id = UUID()
    let startsInOfficialLookup: Bool
    let prefilledBarcode: String?
}

struct MainTabView: View {
    @Environment(\.appEnvironment) private var appEnvironment
    @State private var selectedTab: MainTab = .today
    @State private var showAddFoodMenu = false
    @State private var showScannerForQuickAdd = false
    @State private var activeQuickAddEntry: QuickAddEntryConfiguration?
    @State private var pendingQuickAddRoute: QuickAddRoute?
    @State private var pendingScannedBarcode: String?
    @State private var sharedLogVM: DailyLogViewModel?

    var body: some View {
        ZStack {
            DashboardView(externalLogVM: sharedLogVM)
                .opacity(selectedTab == .today ? 1 : 0)
                .allowsHitTesting(selectedTab == .today)

            FoodListView()
                .opacity(selectedTab == .foods ? 1 : 0)
                .allowsHitTesting(selectedTab == .foods)

            HistoryView()
                .opacity(selectedTab == .history ? 1 : 0)
                .allowsHitTesting(selectedTab == .history)

            SettingsView()
                .opacity(selectedTab == .settings ? 1 : 0)
                .allowsHitTesting(selectedTab == .settings)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Color.clear, AppStyle.pageBackgroundBottom.opacity(0.92)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 24)

                bottomNavigation
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
            }
        }
        .sheet(item: $activeQuickAddEntry) { configuration in
            if let sharedLogVM {
                AddLogEntryView(
                    logVM: sharedLogVM,
                    mealType: .snack,
                    startsInOfficialLookup: configuration.startsInOfficialLookup,
                    prefilledBarcode: configuration.prefilledBarcode
                )
            }
        }
        .sheet(
            isPresented: $showScannerForQuickAdd,
            onDismiss: handleQuickAddScannerDismiss
        ) {
            BarcodeScannerView { barcode in
                pendingScannedBarcode = barcode
                showScannerForQuickAdd = false
            }
        }
        .sheet(
            isPresented: $showAddFoodMenu,
            onDismiss: handleQuickAddMenuDismiss
        ) {
            AddFoodMenuSheet(
                onSearchFood: openSearchFlow,
                onScanFood: openScanFlow
            )
            .presentationDetents([.height(250)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
        .task {
            if sharedLogVM == nil {
                sharedLogVM = appEnvironment.makeDailyLogViewModel()
            }
        }
        .appPageBackground()
    }

    private var bottomNavigation: some View {
        HStack(spacing: 12) {
            HStack(spacing: 0) {
                ForEach(Array(MainTab.allCases.enumerated()), id: \.element) { index, tab in
                    if index > 0 {
                        Divider()
                            .frame(height: 20)
                    }
                    tabBarItem(for: tab)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .appPillBackground(radius: 24)

            quickLogButton
        }
    }

    private var quickLogButton: some View {
        Button {
            showAddFoodMenu = true
        } label: {
            Label("Quick Log Food", systemImage: "plus")
                .labelStyle(.iconOnly)
                .font(.title2.weight(.semibold))
                .foregroundStyle(AppStyle.accentStrong)
                .frame(width: 60, height: 60)
                .background(Circle().fill(AppStyle.cardTop))
                .overlay {
                    Circle()
                        .stroke(AppStyle.border, lineWidth: 1)
                }
                .shadow(color: AppStyle.shadow, radius: 12, x: 0, y: 7)
        }
        .contentShape(Circle())
        .accessibilityLabel("Quick log food")
    }

    private func tabBarItem(for tab: MainTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            Text(tab.title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(selectedTab == tab ? AppStyle.accentStrong : AppStyle.subtleText)
                .frame(maxWidth: .infinity, minHeight: 48)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    private func openSearchFlow() {
        pendingQuickAddRoute = .search
        showAddFoodMenu = false
    }

    private func openScanFlow() {
        pendingQuickAddRoute = .scan
        showAddFoodMenu = false
    }

    private func handleQuickAddMenuDismiss() {
        guard let pendingQuickAddRoute else { return }

        switch pendingQuickAddRoute {
        case .search:
            activeQuickAddEntry = QuickAddEntryConfiguration(
                startsInOfficialLookup: false,
                prefilledBarcode: nil
            )
        case .scan:
            showScannerForQuickAdd = true
        }

        self.pendingQuickAddRoute = nil
    }

    private func handleQuickAddScannerDismiss() {
        guard let pendingScannedBarcode else { return }

        activeQuickAddEntry = QuickAddEntryConfiguration(
            startsInOfficialLookup: true,
            prefilledBarcode: pendingScannedBarcode
        )
        self.pendingScannedBarcode = nil
    }
}

private struct AddFoodMenuSheet: View {
    let onSearchFood: () -> Void
    let onScanFood: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Capsule()
                .fill(AppStyle.border)
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            Text("Add Food")
                .font(.title3.bold())

            Text("Choose how you want to identify food first.")
                .font(.subheadline)
                .foregroundStyle(AppStyle.subtleText)

            HStack(spacing: 10) {
                actionButton(
                    title: "Search Food",
                    subtitle: "Find by name or brand",
                    systemImage: "magnifyingglass",
                    tint: AppStyle.accent,
                    action: onSearchFood
                )

                actionButton(
                    title: "Scan Food",
                    subtitle: "Use barcode camera",
                    systemImage: "barcode.viewfinder",
                    tint: AppStyle.secondaryAccent,
                    action: onScanFood
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .appPageBackground()
    }

    private func actionButton(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(tint)

                Text(title)
                    .font(.headline.bold())
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppStyle.subtleText)
            }
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
            .padding(12)
            .appCardStyle()
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: AppStyle.radiusL, style: .continuous))
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Food.self, OfficialFood.self, LogEntry.self, UserGoals.self], inMemory: true)
}
