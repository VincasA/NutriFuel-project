//
//  NutriFuelApp.swift
//  NutriFuel
//
//  Created by Vincas on 05/03/2026.
//

import SwiftUI      // Visual GUI
import SwiftData    // Database

@main
struct NutriFuelApp: App {
    @AppStorage("appAppearance") private var appAppearanceRaw = AppAppearance.system.rawValue

    private let appContainer: AppContainer = {
        let schema = Schema([
            Food.self,
            OfficialFood.self,
            LogEntry.self,
            UserGoals.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            return AppContainer(modelContainer: modelContainer)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        let resetService = OfficialDataResetService(modelContext: appContainer.modelContainer.mainContext)
        resetService.performIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .tint(AppStyle.accent)
                .fontDesign(.rounded)
                .preferredColorScheme(currentAppearance.preferredColorScheme)
                .environment(\.appEnvironment, appContainer.environment)
        }
        .modelContainer(appContainer.modelContainer)
    }

    private var currentAppearance: AppAppearance {
        AppAppearance(rawValue: appAppearanceRaw) ?? .system
    }
}
