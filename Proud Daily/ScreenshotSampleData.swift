#if DEBUG
import Foundation
import SwiftData

/// Populates the SwiftData store with curated sample content when the app
/// is launched with `--screenshot-mode`. Used by the Maestro screenshot
/// capture flow so every key screen shows realistic, polished data.
enum ScreenshotSampleData {

    static var isScreenshotMode: Bool {
        ProcessInfo.processInfo.arguments.contains("--screenshot-mode")
    }

    // MARK: - Populate

    static func populate(context: ModelContext) {
        clearAll(context: context)

        // 1. UserPreferences — mark onboarding complete
        let prefs = UserPreferences(hasCompletedOnboarding: true)
        context.insert(prefs)

        // 2. Affirmations (curated — one per category for variety)
        let affirmations = sampleAffirmations()
        for a in affirmations { context.insert(a) }

        // 3. Favorites
        for a in affirmations.prefix(4) {
            let fav = FavoriteAffirmation(affirmation: a, savedAt: Date().addingTimeInterval(-Double.random(in: 0...86400 * 7)))
            context.insert(fav)
        }

        // 4. Journal entries (last 7 days)
        let journalEntries = sampleJournalEntries()
        for j in journalEntries { context.insert(j) }

        // 5. Daily records (streak data)
        let records = sampleDailyRecords(affirmations: affirmations, journals: journalEntries)
        for r in records { context.insert(r) }

        // 6. User collections & custom affirmations
        let collection = UserCollection(name: "Morning Mantras")
        context.insert(collection)

        let customTexts = [
            "I am worthy of love exactly as I am.",
            "My identity is my superpower.",
            "Today I choose joy and authenticity."
        ]
        for text in customTexts {
            let ua = UserAffirmation(text: text, collection: collection)
            context.insert(ua)
        }

        try? context.save()
    }

    // MARK: - Clear

    private static func clearAll(context: ModelContext) {
        try? context.delete(model: FavoriteAffirmation.self)
        try? context.delete(model: DailyRecord.self)
        try? context.delete(model: JournalEntry.self)
        try? context.delete(model: UserAffirmation.self)
        try? context.delete(model: UserCollection.self)
        try? context.delete(model: Affirmation.self)
        try? context.delete(model: UserPreferences.self)
        try? context.save()
    }

    // MARK: - Sample Data Generators

    private static func sampleAffirmations() -> [Affirmation] {
        let pairs: [(AffirmationCategory, String)] = [
            (.selfAcceptance, "I embrace every part of who I am — my identity is beautiful and valid."),
            (.queerJoy, "My joy is radical, my pride is powerful, and my light inspires others."),
            (.resilience, "I have overcome so much, and I grow stronger with every step forward."),
            (.chosenFamily, "I am surrounded by people who see me, love me, and celebrate me."),
            (.comingOut, "Living my truth is the bravest and most rewarding choice I make each day."),
            (.queerLove, "Love flows freely through my life in all its beautiful, vibrant forms."),
            (.bodyPositivity, "My body is my home and I honor it with compassion and gratitude."),
            (.transNonBinary, "My gender expression is uniquely mine and it deserves to be celebrated."),
            (.generalWellness, "I am grounded in the present moment, and I choose peace today."),
        ]
        return pairs.map { Affirmation(text: $0.1, category: $0.0) }
    }

    private static func sampleJournalEntries() -> [JournalEntry] {
        let entries: [(String, Int, Mood, Mood)] = [
            ("Went to Pride brunch with friends. Feeling so grateful for my community.", -1, .good, .great),
            ("Had a tough conversation at work but stayed true to myself.", -2, .low, .good),
            ("Spent the evening journaling and listening to my favorite playlist.", -3, .neutral, .good),
            ("Volunteered at the LGBTQ+ youth center today — incredibly rewarding.", -4, .good, .great),
            ("Morning meditation followed by a long walk in the park.", -5, .neutral, .good),
            ("Video-called my chosen family across the country. Miss them so much.", -6, .low, .good),
            ("Tried a new recipe and danced around the kitchen. Pure queer joy.", -7, .good, .great),
        ]
        return entries.map { text, dayOffset, before, after in
            JournalEntry(
                text: text,
                date: Calendar.current.date(byAdding: .day, value: dayOffset, to: .now)!,
                moodBefore: before,
                moodAfter: after
            )
        }
    }

    private static func sampleDailyRecords(affirmations: [Affirmation], journals: [JournalEntry]) -> [DailyRecord] {
        (0..<14).map { dayOffset in
            let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: .now)!
            let journal = dayOffset < journals.count ? journals[dayOffset] : nil
            let record = DailyRecord(
                date: date,
                moodBefore: journal?.moodBefore ?? (dayOffset % 2 == 0 ? .good : .neutral),
                moodAfter: journal?.moodAfter ?? .good,
                journalEntry: journal,
                minutesPracticed: Double.random(in: 3...15)
            )
            let viewedCount = min(2, affirmations.count)
            let startIdx = dayOffset % affirmations.count
            record.affirmationsViewed = (0..<viewedCount).map { affirmations[(startIdx + $0) % affirmations.count] }
            return record
        }
    }
}
#endif
