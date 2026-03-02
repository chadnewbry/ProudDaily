import Foundation
import SwiftData

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

// MARK: - IdentityLabel

enum IdentityLabel: String, CaseIterable, Codable, Identifiable {
    case gay, lesbian, bisexual, trans, nonBinary, queer, pansexual, asexual, questioning, ally, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gay: return "Gay"
        case .lesbian: return "Lesbian"
        case .bisexual: return "Bisexual"
        case .trans: return "Trans"
        case .nonBinary: return "Non-Binary"
        case .queer: return "Queer"
        case .pansexual: return "Pansexual"
        case .asexual: return "Asexual"
        case .questioning: return "Questioning"
        case .ally: return "Ally"
        case .other: return "Other"
        }
    }
}

// MARK: - PronounOption

enum PronounOption: String, CaseIterable, Identifiable {
    case heHim = "he/him"
    case sheHer = "she/her"
    case theyThem = "they/them"
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .heHim: return "he/him"
        case .sheHer: return "she/her"
        case .theyThem: return "they/them"
        case .custom: return "Custom"
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
    var onboardingStep: Int
    var identityLabelsRaw: [String]
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

    var identityLabels: [IdentityLabel] {
        get { identityLabelsRaw.compactMap { IdentityLabel(rawValue: $0) } }
        set { identityLabelsRaw = newValue.map(\.rawValue) }
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
        onboardingStep: Int = 0,
        identityLabels: [IdentityLabel] = [],
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
        self.onboardingStep = onboardingStep
        self.identityLabelsRaw = identityLabels.map(\.rawValue)
        self.freeUsesRemaining = freeUsesRemaining
        self.hasPurchasedPremium = hasPurchasedPremium
    }
}
