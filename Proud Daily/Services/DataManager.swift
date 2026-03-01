import Foundation
import SwiftData
import Observation

@Observable
final class DataManager {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - User Preferences (singleton)

    func getOrCreatePreferences() -> UserPreferences {
        let descriptor = FetchDescriptor<UserPreferences>()
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let prefs = UserPreferences()
        modelContext.insert(prefs)
        try? modelContext.save()
        return prefs
    }

    // MARK: - Affirmations

    func fetchAffirmations(category: AffirmationCategory? = nil, customOnly: Bool = false) -> [Affirmation] {
        var descriptor = FetchDescriptor<Affirmation>(sortBy: [SortDescriptor(\.createdAt)])
        if let category {
            let raw = category.rawValue
            descriptor.predicate = #Predicate<Affirmation> { $0.categoryRaw == raw }
        }
        if customOnly {
            descriptor.predicate = #Predicate<Affirmation> { $0.isCustom == true }
        }
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func addCustomAffirmation(text: String, category: AffirmationCategory) -> Affirmation {
        let affirmation = Affirmation(text: text, category: category, isCustom: true)
        modelContext.insert(affirmation)
        try? modelContext.save()
        return affirmation
    }

    func deleteAffirmation(_ affirmation: Affirmation) {
        modelContext.delete(affirmation)
        try? modelContext.save()
    }

    // MARK: - Favorites

    func toggleFavorite(affirmation: Affirmation) {
        if let existing = affirmation.favorites?.first {
            modelContext.delete(existing)
        } else {
            let fav = FavoriteAffirmation(affirmation: affirmation)
            modelContext.insert(fav)
        }
        try? modelContext.save()
    }

    func isFavorite(_ affirmation: Affirmation) -> Bool {
        !(affirmation.favorites?.isEmpty ?? true)
    }

    func fetchFavorites() -> [FavoriteAffirmation] {
        let descriptor = FetchDescriptor<FavoriteAffirmation>(sortBy: [SortDescriptor(\.savedAt, order: .reverse)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - User Affirmations

    func addUserAffirmation(text: String, collection: UserCollection? = nil) -> UserAffirmation {
        let ua = UserAffirmation(text: text, collection: collection)
        modelContext.insert(ua)
        try? modelContext.save()
        return ua
    }

    func fetchUserAffirmations() -> [UserAffirmation] {
        let descriptor = FetchDescriptor<UserAffirmation>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func deleteUserAffirmation(_ ua: UserAffirmation) {
        modelContext.delete(ua)
        try? modelContext.save()
    }

    // MARK: - Collections

    func createCollection(name: String) -> UserCollection {
        let collection = UserCollection(name: name)
        modelContext.insert(collection)
        try? modelContext.save()
        return collection
    }

    func fetchCollections() -> [UserCollection] {
        let descriptor = FetchDescriptor<UserCollection>(sortBy: [SortDescriptor(\.createdAt)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func deleteCollection(_ collection: UserCollection) {
        modelContext.delete(collection)
        try? modelContext.save()
    }

    // MARK: - Journal Entries

    func createJournalEntry(text: String, date: Date = .now, moodBefore: Mood? = nil, moodAfter: Mood? = nil) -> JournalEntry {
        let entry = JournalEntry(text: text, date: date, moodBefore: moodBefore, moodAfter: moodAfter)
        modelContext.insert(entry)
        try? modelContext.save()
        return entry
    }

    func fetchJournalEntries() -> [JournalEntry] {
        let descriptor = FetchDescriptor<JournalEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func deleteJournalEntry(_ entry: JournalEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
    }

    // MARK: - Daily Records

    func getOrCreateTodayRecord() -> DailyRecord {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let descriptor = FetchDescriptor<DailyRecord>(
            predicate: #Predicate<DailyRecord> { $0.date >= startOfDay && $0.date < endOfDay }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let record = DailyRecord(date: .now)
        modelContext.insert(record)
        try? modelContext.save()
        return record
    }

    func recordAffirmationViewed(_ affirmation: Affirmation) {
        let record = getOrCreateTodayRecord()
        if record.affirmationsViewed == nil {
            record.affirmationsViewed = []
        }
        if !(record.affirmationsViewed?.contains(where: { $0.id == affirmation.id }) ?? false) {
            record.affirmationsViewed?.append(affirmation)
        }
        try? modelContext.save()
    }

    func addPracticeTime(_ minutes: Double) {
        let record = getOrCreateTodayRecord()
        record.minutesPracticed += minutes
        try? modelContext.save()
    }

    // MARK: - Streak Calculation

    func calculateCurrentStreak() -> Int {
        let descriptor = FetchDescriptor<DailyRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        guard let records = try? modelContext.fetch(descriptor), !records.isEmpty else { return 0 }

        let calendar = Calendar.current
        var streak = 0
        var expectedDate = calendar.startOfDay(for: .now)

        for record in records {
            let recordDate = calendar.startOfDay(for: record.date)
            if recordDate == expectedDate {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: expectedDate) else { break }
                expectedDate = previousDay
            } else if recordDate < expectedDate {
                break
            }
        }
        return streak
    }

    func calculateLongestStreak() -> Int {
        let descriptor = FetchDescriptor<DailyRecord>(sortBy: [SortDescriptor(\.date)])
        guard let records = try? modelContext.fetch(descriptor), !records.isEmpty else { return 0 }

        let calendar = Calendar.current
        var longest = 1
        var current = 1

        for i in 1..<records.count {
            let prev = calendar.startOfDay(for: records[i - 1].date)
            let curr = calendar.startOfDay(for: records[i].date)
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: prev), nextDay == curr {
                current += 1
                longest = max(longest, current)
            } else if prev != curr {
                current = 1
            }
        }
        return longest
    }

    func totalDaysActive() -> Int {
        let descriptor = FetchDescriptor<DailyRecord>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    // MARK: - Seed Data

    func seedIfNeeded() {
        let descriptor = FetchDescriptor<Affirmation>(predicate: #Predicate<Affirmation> { $0.isCustom == false })
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        guard let url = Bundle.main.url(forResource: "affirmations", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return }

        struct SeedAffirmation: Decodable {
            let text: String
            let category: String
        }

        guard let seeds = try? JSONDecoder().decode([SeedAffirmation].self, from: data) else { return }

        for seed in seeds {
            let category = AffirmationCategory(rawValue: seed.category) ?? .generalWellness
            let affirmation = Affirmation(text: seed.text, category: category, isCustom: false)
            modelContext.insert(affirmation)
        }
        try? modelContext.save()
    }
}
