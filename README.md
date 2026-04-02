# NutriFuel

A local-first iOS nutrition tracker built with SwiftUI and SwiftData. No accounts, no backend — just fast daily food logging on your device.

## What it does

- Log meals by day (breakfast, lunch, dinner, snacks) with calorie and macro tracking
- Build a personal food database you can search and reuse
- Scan barcodes to pull nutrition data from Open Food Facts, with the option to correct and save your own version
- Track progress toward calorie, macro, and micronutrient goals
- Review history with daily totals and a rolling 7-day average

## Tech stack

- SwiftUI + SwiftData
- `@Observable` / `@Bindable`
- AVFoundation (barcode scanning)
- Open Food Facts API via URLSession

## Getting started

```bash
git clone <your-repository-url>
cd NutriFuel
open NutriFuel.xcodeproj
```

Select the `NutriFuel` scheme, pick a simulator or device, and hit `Cmd+R`.

Barcode scanning requires a physical device with camera access.

## Project layout

```
NutriFuel/
├── App/              # Composition root, dependency injection
├── Models/           # SwiftData entities (Food, LogEntry, OfficialFood, UserGoals)
├── Repositories/     # Data access layer
├── Services/         # Open Food Facts client, data reset
├── Shared/           # Parsing, unit conversion, domain helpers
├── Utilities/        # Nutrition calculations
├── ViewModels/       # Screen-level state
└── Views/            # UI grouped by feature area
    ├── Dashboard/
    ├── FoodDatabase/
    ├── History/
    ├── Log/
    ├── Scanner/
    └── Settings/
```

The app follows MVVM with a composition root (`AppContainer`) that wires up repositories and view model factories, injected into SwiftUI via `AppEnvironment`.

## How data flows

- Custom foods live in `Food` (SwiftData). Barcode lookups check custom foods first, then fall back to Open Food Facts.
- Open Food Facts results get cached locally in `OfficialFood`.
- When you correct nutrition data during logging, you can save it as a reusable custom food or a one-off override attached to that log entry.

## Building from CLI

```bash
xcodebuild -project "NutriFuel.xcodeproj" -scheme "NutriFuel" -destination "generic/platform=iOS" build
```

Run tests:

```bash
xcodebuild test -project "NutriFuel.xcodeproj" -scheme "NutriFuel"
```

## Contributing

- Follow the existing MVVM + repository pattern
- Keep changes focused
- Test calculation/parsing/model changes; manually test scanner flows on a real device
- Make sure it builds clean before opening a PR
