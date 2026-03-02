import Foundation

// MARK: - App Group Constants

enum AppGroupConstants {
    static let suiteName = "group.com.openclaw.prouddaily"
}

// MARK: - Widget Data Keys

private enum WidgetDataKey {
    static let affirmationText = "widget.affirmation.text"
    static let affirmationCategory = "widget.affirmation.category"
    static let themeRaw = "widget.theme"
    static let streakCount = "widget.streak"
    static let discreetMode = "widget.discreetMode"
    static let lastUpdated = "widget.lastUpdated"
    static let affirmationPool = "widget.affirmationPool"
}

// MARK: - Lightweight Affirmation for Widget

struct WidgetAffirmation: Codable, Equatable {
    let text: String
    let category: String
    let categoryEmoji: String

    static let discreetFallbacks: [WidgetAffirmation] = [
        WidgetAffirmation(text: "You are enough, exactly as you are.", category: "Wellness", categoryEmoji: "🌿"),
        WidgetAffirmation(text: "Today is full of possibilities.", category: "Wellness", categoryEmoji: "🌿"),
        WidgetAffirmation(text: "You deserve peace and happiness.", category: "Wellness", categoryEmoji: "🌿"),
        WidgetAffirmation(text: "Be gentle with yourself today.", category: "Wellness", categoryEmoji: "🌿"),
        WidgetAffirmation(text: "Your feelings are valid.", category: "Wellness", categoryEmoji: "🌿"),
        WidgetAffirmation(text: "You are worthy of love.", category: "Wellness", categoryEmoji: "🌿"),
    ]
}

// MARK: - Widget Data Store

final class WidgetDataStore {
    static let shared = WidgetDataStore()

    private let defaults: UserDefaults?

    init() {
        defaults = UserDefaults(suiteName: AppGroupConstants.suiteName)
    }

    // MARK: - Read

    var currentAffirmation: WidgetAffirmation {
        let text = defaults?.string(forKey: WidgetDataKey.affirmationText) ?? "You are worthy of love and belonging."
        let category = defaults?.string(forKey: WidgetDataKey.affirmationCategory) ?? "General Wellness"
        return WidgetAffirmation(text: text, category: category, categoryEmoji: emojiForCategory(category))
    }

    var affirmationPool: [WidgetAffirmation] {
        guard let data = defaults?.data(forKey: WidgetDataKey.affirmationPool),
              let pool = try? JSONDecoder().decode([WidgetAffirmation].self, from: data) else {
            return [currentAffirmation]
        }
        return pool.isEmpty ? [currentAffirmation] : pool
    }

    var themeRaw: String {
        defaults?.string(forKey: WidgetDataKey.themeRaw) ?? "rainbow"
    }

    var streakCount: Int {
        defaults?.integer(forKey: WidgetDataKey.streakCount) ?? 0
    }

    var isDiscreetMode: Bool {
        defaults?.bool(forKey: WidgetDataKey.discreetMode) ?? false
    }

    // MARK: - Write (called from main app)

    func updateAffirmation(text: String, category: String) {
        defaults?.set(text, forKey: WidgetDataKey.affirmationText)
        defaults?.set(category, forKey: WidgetDataKey.affirmationCategory)
        defaults?.set(Date().timeIntervalSince1970, forKey: WidgetDataKey.lastUpdated)
    }

    func updatePool(_ pool: [WidgetAffirmation]) {
        if let data = try? JSONEncoder().encode(pool) {
            defaults?.set(data, forKey: WidgetDataKey.affirmationPool)
        }
    }

    func updateTheme(_ raw: String) {
        defaults?.set(raw, forKey: WidgetDataKey.themeRaw)
    }

    func updateStreak(_ count: Int) {
        defaults?.set(count, forKey: WidgetDataKey.streakCount)
    }

    func updateDiscreetMode(_ enabled: Bool) {
        defaults?.set(enabled, forKey: WidgetDataKey.discreetMode)
    }

    // MARK: - Helpers

    private func emojiForCategory(_ name: String) -> String {
        switch name {
        case "Coming Out": return "🚪"
        case "Self-Acceptance": return "🪞"
        case "Chosen Family": return "👨‍👩‍👧‍👦"
        case "Queer Joy": return "🎉"
        case "Resilience": return "💪"
        case "Queer Love": return "💕"
        case "Body Positivity": return "✨"
        case "Trans & Non-Binary": return "🏳️‍⚧️"
        default: return "🌿"
        }
    }
}
