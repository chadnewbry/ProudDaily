import Foundation
import SwiftData

@Observable
final class AffirmationService {
    private let modelContext: ModelContext
    private(set) var todaysAffirmation: Affirmation?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        selectTodaysAffirmation()
    }

    // MARK: - Today's Affirmation (deterministic by day)

    func selectTodaysAffirmation(from categories: [AffirmationCategory]? = nil) {
        let descriptor = FetchDescriptor<Affirmation>(
            predicate: #Predicate<Affirmation> { $0.isCustom == false }
        )
        guard let affirmations = try? modelContext.fetch(descriptor), !affirmations.isEmpty else {
            todaysAffirmation = nil
            return
        }

        let filtered: [Affirmation]
        if let categories, !categories.isEmpty {
            let rawValues = Set(categories.map(\.rawValue))
            filtered = affirmations.filter { rawValues.contains($0.categoryRaw) }
        } else {
            filtered = affirmations
        }

        guard !filtered.isEmpty else {
            todaysAffirmation = filtered.first ?? affirmations.first
            return
        }

        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 0
        let index = dayOfYear % filtered.count
        todaysAffirmation = filtered[index]
    }

    // MARK: - Mood-Aware Selection

    /// Selects today's affirmation using mood-based category weighting.
    /// Falls back to equal-weight random from selected categories if mood is nil.
    func selectTodaysAffirmation(
        mood: Mood?,
        selectedCategories: [AffirmationCategory]
    ) {
        guard !selectedCategories.isEmpty else {
            selectTodaysAffirmation()
            return
        }

        guard let category = MoodSuggestionEngine.suggestCategory(
            for: mood,
            selectedCategories: selectedCategories
        ) else {
            selectTodaysAffirmation(from: selectedCategories)
            return
        }

        let raw = category.rawValue
        let descriptor = FetchDescriptor<Affirmation>(
            predicate: #Predicate<Affirmation> { $0.categoryRaw == raw && $0.isCustom == false }
        )

        guard let candidates = try? modelContext.fetch(descriptor), !candidates.isEmpty else {
            // Fall back to any affirmation in selected categories
            selectTodaysAffirmation(from: selectedCategories)
            return
        }

        // Use day-of-year for deterministic daily pick within the chosen category
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 0
        let index = dayOfYear % candidates.count
        todaysAffirmation = candidates[index]
    }

    /// Returns a set of mood-appropriate affirmations for browsing.
    func moodBasedAffirmations(
        mood: Mood?,
        selectedCategories: [AffirmationCategory],
        count: Int = 10
    ) -> [Affirmation] {
        guard !selectedCategories.isEmpty else { return [] }

        // Pick categories weighted by mood
        let categoryPicks = MoodSuggestionEngine.suggestCategories(
            count: min(count, selectedCategories.count),
            for: mood,
            selectedCategories: selectedCategories
        )

        var result: [Affirmation] = []
        let perCategory = max(count / max(categoryPicks.count, 1), 1)

        for category in categoryPicks {
            let raw = category.rawValue
            let descriptor = FetchDescriptor<Affirmation>(
                predicate: #Predicate<Affirmation> { $0.categoryRaw == raw && $0.isCustom == false }
            )
            if let candidates = try? modelContext.fetch(descriptor), !candidates.isEmpty {
                let shuffled = candidates.shuffled()
                result.append(contentsOf: shuffled.prefix(perCategory))
            }
        }

        // Fill remaining slots if needed
        if result.count < count {
            let existingIds = Set(result.map(\.id))
            let rawValues = selectedCategories.map(\.rawValue)
            let descriptor = FetchDescriptor<Affirmation>(
                predicate: #Predicate<Affirmation> { $0.isCustom == false }
            )
            if let all = try? modelContext.fetch(descriptor) {
                let extras = all
                    .filter { rawValues.contains($0.categoryRaw) && !existingIds.contains($0.id) }
                    .shuffled()
                    .prefix(count - result.count)
                result.append(contentsOf: extras)
            }
        }

        return Array(result.prefix(count))
    }

    // MARK: - Random Affirmation

    func randomAffirmation(category: AffirmationCategory? = nil) -> Affirmation? {
        var descriptor = FetchDescriptor<Affirmation>()
        if let category {
            let raw = category.rawValue
            descriptor.predicate = #Predicate<Affirmation> { $0.categoryRaw == raw }
        }
        guard let all = try? modelContext.fetch(descriptor), !all.isEmpty else { return nil }
        return all.randomElement()
    }

    /// Returns a mood-appropriate random affirmation for notifications.
    func randomAffirmation(
        mood: Mood?,
        selectedCategories: [AffirmationCategory]
    ) -> Affirmation? {
        guard !selectedCategories.isEmpty else { return randomAffirmation() }

        guard let category = MoodSuggestionEngine.suggestCategory(
            for: mood,
            selectedCategories: selectedCategories
        ) else {
            return randomAffirmation()
        }

        return randomAffirmation(category: category)
    }
}
