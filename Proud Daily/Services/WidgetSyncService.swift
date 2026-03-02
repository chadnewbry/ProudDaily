import Foundation
import SwiftData
import WidgetKit

/// Syncs app state to the shared App Group UserDefaults for widget consumption.
final class WidgetSyncService {
    static let shared = WidgetSyncService()

    private let defaults: UserDefaults?

    private init() {
        defaults = UserDefaults(suiteName: "group.com.openclaw.prouddaily")
    }

    // MARK: - Sync All

    func syncAll(modelContext: ModelContext) {
        syncAffirmations(modelContext: modelContext)
        syncTheme()
        syncStreak(modelContext: modelContext)
        syncDiscreetMode(modelContext: modelContext)
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Individual Syncs

    func syncAffirmations(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Affirmation>(
            predicate: #Predicate<Affirmation> { $0.isCustom == false }
        )
        guard let affirmations = try? modelContext.fetch(descriptor), !affirmations.isEmpty else { return }

        // Current daily affirmation
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 0
        let index = dayOfYear % affirmations.count
        let current = affirmations[index]

        defaults?.set(current.text, forKey: "widget.affirmation.text")
        defaults?.set(current.category.displayName, forKey: "widget.affirmation.category")

        // Build a pool of ~24 affirmations for timeline rotation
        var pool: [[String: String]] = []
        let shuffled = affirmations.shuffled()
        for aff in shuffled.prefix(24) {
            pool.append([
                "text": aff.text,
                "category": aff.category.displayName,
                "categoryEmoji": aff.category.emoji,
            ])
        }

        if let data = try? JSONEncoder().encode(
            pool.map { WidgetAffirmationDTO(text: $0["text"]!, category: $0["category"]!, categoryEmoji: $0["categoryEmoji"]!) }
        ) {
            defaults?.set(data, forKey: "widget.affirmationPool")
        }

        defaults?.set(Date().timeIntervalSince1970, forKey: "widget.lastUpdated")
    }

    func syncTheme() {
        let themeRaw = UserDefaults.standard.string(forKey: "theme.pride") ?? "rainbow"
        defaults?.set(themeRaw, forKey: "widget.theme")
    }

    func syncStreak(modelContext: ModelContext) {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        // Walk backwards counting consecutive days with records
        while true {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: checkDate)!
            let descriptor = FetchDescriptor<DailyRecord>(
                predicate: #Predicate<DailyRecord> { record in
                    record.date >= checkDate && record.date < nextDay
                }
            )
            guard let records = try? modelContext.fetch(descriptor), !records.isEmpty else { break }
            streak += 1
            guard let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prevDay
        }

        defaults?.set(streak, forKey: "widget.streak")
    }

    func syncDiscreetMode(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<UserPreferences>()
        let prefs = try? modelContext.fetch(descriptor).first
        defaults?.set(prefs?.discreetModeEnabled ?? false, forKey: "widget.discreetMode")
    }
}

// MARK: - DTO for encoding

private struct WidgetAffirmationDTO: Codable {
    let text: String
    let category: String
    let categoryEmoji: String
}
