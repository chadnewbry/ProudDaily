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

// MARK: - AppearanceMode

enum AppearanceMode: String, CaseIterable, Codable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: return "gear"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
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
    var defaultAmbientSoundRaw: String
    var sleepTimerDurationMinutes: Int
    var healthKitEnabled: Bool
    var appearanceModeRaw: String
    var notificationCategoryFiltersRaw: [String]

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

    var defaultAmbientSound: AmbientSound {
        get { AmbientSound(rawValue: defaultAmbientSoundRaw) ?? .rain }
        set { defaultAmbientSoundRaw = newValue.rawValue }
    }

    var sleepTimerDuration: SleepTimerDuration {
        get { SleepTimerDuration(rawValue: sleepTimerDurationMinutes) ?? .thirty }
        set { sleepTimerDurationMinutes = newValue.rawValue }
    }

    var appearanceMode: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceModeRaw) ?? .system }
        set { appearanceModeRaw = newValue.rawValue }
    }

    var notificationCategoryFilters: [AffirmationCategory] {
        get { notificationCategoryFiltersRaw.compactMap { AffirmationCategory(rawValue: $0) } }
        set { notificationCategoryFiltersRaw = newValue.map(\.rawValue) }
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
        hasPurchasedPremium: Bool = false,
        defaultAmbientSound: AmbientSound = .rain,
        sleepTimerDuration: SleepTimerDuration = .thirty,
        healthKitEnabled: Bool = false,
        appearanceMode: AppearanceMode = .system,
        notificationCategoryFilters: [AffirmationCategory] = AffirmationCategory.allCases
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
        self.defaultAmbientSoundRaw = defaultAmbientSound.rawValue
        self.sleepTimerDurationMinutes = sleepTimerDuration.rawValue
        self.healthKitEnabled = healthKitEnabled
        self.appearanceModeRaw = appearanceMode.rawValue
        self.notificationCategoryFiltersRaw = notificationCategoryFilters.map(\.rawValue)
    }
}
