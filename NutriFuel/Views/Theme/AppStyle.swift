import SwiftUI

enum AppStyle {
    static let accent = Color(red: 0.07, green: 0.62, blue: 0.47)
    static let accentStrong = Color(red: 0.03, green: 0.48, blue: 0.36)
    static let secondaryAccent = Color(red: 0.15, green: 0.39, blue: 0.84)
    static let protein = Color(red: 0.15, green: 0.39, blue: 0.92)
    static let carbs = Color(red: 0.96, green: 0.62, blue: 0.04)
    static let fat = Color(red: 0.93, green: 0.28, blue: 0.60)

    static let pageBackgroundTop = Color(
        uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.07, green: 0.09, blue: 0.12, alpha: 1)
            : UIColor(red: 0.96, green: 0.98, blue: 0.99, alpha: 1)
        }
    )

    static let pageBackgroundBottom = Color(
        uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.05, green: 0.07, blue: 0.10, alpha: 1)
            : UIColor(red: 0.92, green: 0.96, blue: 0.94, alpha: 1)
        }
    )

    static let cardTop = Color(
        uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.13, blue: 0.17, alpha: 1)
            : UIColor(red: 0.99, green: 1.00, blue: 1.00, alpha: 1)
        }
    )

    static let cardBottom = Color(
        uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.10, green: 0.12, blue: 0.16, alpha: 1)
            : UIColor(red: 0.97, green: 0.99, blue: 1.00, alpha: 1)
        }
    )

    static let fieldBackground = Color(
        uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.16, green: 0.20, blue: 0.26, alpha: 1)
            : UIColor(red: 0.96, green: 0.98, blue: 0.99, alpha: 1)
        }
    )

    static let chipBackground = Color(
        uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.13, green: 0.18, blue: 0.23, alpha: 1)
            : UIColor(red: 0.95, green: 0.97, blue: 0.99, alpha: 1)
        }
    )

    static let pillBackground = Color(
        uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.13, green: 0.18, blue: 0.23, alpha: 0.96)
            : UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 0.94)
        }
    )

    static let cardBackground = Color(
        uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.10, green: 0.13, blue: 0.17, alpha: 0.95)
            : UIColor(red: 0.98, green: 0.99, blue: 1.00, alpha: 0.94)
        }
    )

    static let border = Color(
        uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.17, green: 0.22, blue: 0.28, alpha: 0.82)
            : UIColor(red: 0.86, green: 0.90, blue: 0.93, alpha: 1.00)
        }
    )

    static let subtleText = Color(uiColor: .secondaryLabel)
    static let shadow = Color.black.opacity(0.10)
    static let radiusXL: CGFloat = 24
    static let radiusL: CGFloat = 20
    static let radiusM: CGFloat = 14
    static let radiusS: CGFloat = 10
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

extension View {
    func appCardStyle() -> some View {
        self
            .background(
                LinearGradient(
                    colors: [AppStyle.cardTop, AppStyle.cardBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: AppStyle.radiusL, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.radiusL, style: .continuous)
                    .stroke(AppStyle.border, lineWidth: 1)
            )
            .shadow(color: AppStyle.shadow, radius: 16, x: 0, y: 9)
    }

    func appPageBackground() -> some View {
        self.background(
            LinearGradient(
                colors: [AppStyle.pageBackgroundTop, AppStyle.pageBackgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    func appInputBackground(radius: CGFloat = 12) -> some View {
        self
            .background(AppStyle.fieldBackground, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(AppStyle.border, lineWidth: 1)
            )
    }

    func appPillBackground(radius: CGFloat = 999) -> some View {
        self
            .background(AppStyle.pillBackground, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(AppStyle.border, lineWidth: 1)
            )
    }
}

struct AppChip: View {
    let text: String
    var isActive: Bool = false
    var activeTint: Color = AppStyle.accent

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(isActive ? activeTint : AppStyle.subtleText)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(isActive ? activeTint.opacity(0.13) : AppStyle.chipBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .stroke(isActive ? activeTint.opacity(0.35) : AppStyle.border, lineWidth: 1)
            )
    }
}
