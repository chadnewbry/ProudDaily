import Foundation
import SwiftData

// MARK: - PrideTheme

enum PrideTheme: String, CaseIterable, Codable, Identifiable {
    case rainbow, trans, bi, pan, nonbinary, lesbian, asexual, sunset, nature, pastelRainbow

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rainbow: return "Rainbow"
        case .trans: return "Trans"
        case .bi: return "Bisexual"
        case .pan: return "Pansexual"
        case .nonbinary: return "Non-Binary"
        case .lesbian: return "Lesbian"
        case .asexual: return "Asexual"
        case .sunset: return "Sunset"
        case .nature: return "Nature"
        case .pastelRainbow: return "Pastel Rainbow"
        }
    }

    var gradientHexColors: [String] {
        switch self {
        case .rainbow: return ["#E40303", "#FF8C00", "#FFED00", "#008026", "#004DFF", "#750787"]
        case .trans: return ["#5BCEFA", "#F5A9B8", "#FFFFFF", "#F5A9B8", "#5BCEFA"]
        case .bi: return ["#D60270", "#9B4F96", "#0038A8"]
        case .pan: return ["#FF218C", "#FFD800", "#21B1FF"]
        case .nonbinary: return ["#FCF434", "#FFFFFF", "#9C59D1", "#2C2C2C"]
        case .lesbian: return ["#D52D00", "#FF9A56", "#FFFFFF", "#D462A6", "#A30262"]
        case .asexual: return ["#000000", "#A3A3A3", "#FFFFFF", "#800080"]
        case .sunset: return ["#FF6B35", "#F7931E", "#FFD700", "#FF4500"]
        case .nature: return ["#2D5016", "#4A7C2E", "#7CB342", "#AED581"]
        case .pastelRainbow: return ["#FFB3BA", "#FFDFBA", "#FFFFBA", "#BAFFC9", "#BAE1FF", "#D4BAFF"]
        }
    }

    var accentHex: String {
        switch self {
        case .rainbow: return "#750787"
        case .trans: return "#5BCEFA"
        case .bi: return "#9B4F96"
        case .pan: return "#FF218C"
        case .nonbinary: return "#9C59D1"
        case .lesbian: return "#D462A6"
        case .asexual: return "#800080"
        case .sunset: return "#FF6B35"
        case .nature: return "#4A7C2E"
        case .pastelRainbow: return "#D4BAFF"
        }
    }
}

// MARK: - FontSize

enum FontSize: String, CaseIterable, Codable {
    case small, medium, large

    var scaleFactor: CGFloat {
        switch self {
        case .small: return 0.85
        case .medium: return 1.0
        case .large: return 1.2
        }
    }
}

// MARK: - UserPreferences (SwiftData Model — single instance)

@Model
final class UserPreferences {
    @Attribute(.unique) var id: UUID
    var selectedCategoriesRaw: [String]
    var pronouns: String
    var displayName: String
    var selectedThemeRaw: String
    var fontSizeRaw: String
    var notificationTimes: [Date]
    var discreetModeEnabled: Bool
    var iCloudSyncEnabled: Bool
    var hasCompletedOnboarding: Bool
    var freeUsesRemaining: Int
    var hasPurchasedPremium: Bool

    var selectedCategories: [AffirmationCategory] {
        get { selectedCategoriesRaw.compactMap { AffirmationCategory(rawValue: $0) } }
        set { selectedCategoriesRaw = newValue.map(\.rawValue) }
    }

    var selectedTheme: PrideTheme {
        get { PrideTheme(rawValue: selectedThemeRaw) ?? .rainbow }
        set { selectedThemeRaw = newValue.rawValue }
    }

    var fontSize: FontSize {
        get { FontSize(rawValue: fontSizeRaw) ?? .medium }
        set { fontSizeRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        selectedCategories: [AffirmationCategory] = AffirmationCategory.allCases,
        pronouns: String = "",
        displayName: String = "",
        selectedTheme: PrideTheme = .rainbow,
        fontSize: FontSize = .medium,
        notificationTimes: [Date] = [],
        discreetModeEnabled: Bool = false,
        iCloudSyncEnabled: Bool = false,
        hasCompletedOnboarding: Bool = false,
        freeUsesRemaining: Int = 5,
        hasPurchasedPremium: Bool = false
    ) {
        self.id = id
        self.selectedCategoriesRaw = selectedCategories.map(\.rawValue)
        self.pronouns = pronouns
        self.displayName = displayName
        self.selectedThemeRaw = selectedTheme.rawValue
        self.fontSizeRaw = fontSize.rawValue
        self.notificationTimes = notificationTimes
        self.discreetModeEnabled = discreetModeEnabled
        self.iCloudSyncEnabled = iCloudSyncEnabled
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.freeUsesRemaining = freeUsesRemaining
        self.hasPurchasedPremium = hasPurchasedPremium
    }
}
