import Foundation

// MARK: - CategoryWeight

/// A weighted category recommendation from the mood suggestion engine.
struct CategoryWeight: Identifiable, Equatable {
    let category: AffirmationCategory
    let weight: Double

    var id: String { category.rawValue }
}

// MARK: - MoodSuggestionEngine

/// On-device rule-based engine that maps a user's mood to weighted affirmation
/// category recommendations. Pure local logic — no AI/LLM required.
struct MoodSuggestionEngine {

    // MARK: - Mood → Category Mapping

    /// Returns the full weighted category list for a given mood, ordered by weight descending.
    static func recommendations(for mood: Mood) -> [CategoryWeight] {
        let mapping: [(AffirmationCategory, Double)]

        switch mood {
        case .veryLow:
            mapping = [
                (.resilience, 0.3),
                (.selfAcceptance, 0.3),
                (.generalWellness, 0.2),
                (.chosenFamily, 0.2),
            ]
        case .low:
            mapping = [
                (.selfAcceptance, 0.25),
                (.resilience, 0.25),
                (.bodyPositivity, 0.2),
                (.generalWellness, 0.15),
                (.chosenFamily, 0.15),
            ]
        case .neutral:
            mapping = [
                (.generalWellness, 0.2),
                (.queerJoy, 0.2),
                (.selfAcceptance, 0.2),
                (.comingOut, 0.15),
                (.queerLove, 0.15),
                (.transNonBinary, 0.1),
            ]
        case .good:
            mapping = [
                (.queerJoy, 0.3),
                (.queerLove, 0.2),
                (.comingOut, 0.15),
                (.bodyPositivity, 0.15),
                (.chosenFamily, 0.1),
                (.transNonBinary, 0.1),
            ]
        case .great:
            mapping = [
                (.queerJoy, 0.35),
                (.queerLove, 0.25),
                (.comingOut, 0.2),
                (.bodyPositivity, 0.1),
                (.chosenFamily, 0.1),
            ]
        }

        return mapping.map { CategoryWeight(category: $0.0, weight: $0.1) }
    }

    // MARK: - Filtered Recommendations

    /// Returns recommendations filtered to only the user's selected categories,
    /// with weights re-normalized to sum to 1.0.
    static func filteredRecommendations(
        for mood: Mood,
        selectedCategories: [AffirmationCategory]
    ) -> [CategoryWeight] {
        guard !selectedCategories.isEmpty else { return [] }

        let selectedSet = Set(selectedCategories)
        let raw = recommendations(for: mood).filter { selectedSet.contains($0.category) }

        guard !raw.isEmpty else {
            // None of the mood-recommended categories are selected;
            // fall back to equal weights across selected categories.
            let equalWeight = 1.0 / Double(selectedCategories.count)
            return selectedCategories.map { CategoryWeight(category: $0, weight: equalWeight) }
        }

        let totalWeight = raw.reduce(0.0) { $0 + $1.weight }
        guard totalWeight > 0 else { return raw }

        return raw.map {
            CategoryWeight(category: $0.category, weight: $0.weight / totalWeight)
        }
    }

    // MARK: - Weighted Random Selection

    /// Picks a single category using weighted random selection from recommendations.
    static func suggestCategory(
        for mood: Mood?,
        selectedCategories: [AffirmationCategory]
    ) -> AffirmationCategory? {
        guard !selectedCategories.isEmpty else { return nil }

        let weights: [CategoryWeight]

        if let mood {
            weights = filteredRecommendations(for: mood, selectedCategories: selectedCategories)
        } else {
            // No mood data — equal weight across selected categories
            let equalWeight = 1.0 / Double(selectedCategories.count)
            weights = selectedCategories.map { CategoryWeight(category: $0, weight: equalWeight) }
        }

        guard !weights.isEmpty else { return selectedCategories.randomElement() }

        let random = Double.random(in: 0..<1)
        var cumulative = 0.0

        for cw in weights {
            cumulative += cw.weight
            if random < cumulative {
                return cw.category
            }
        }

        // Floating-point safety: return last category
        return weights.last?.category
    }

    /// Picks multiple unique categories using weighted selection (without replacement).
    static func suggestCategories(
        count: Int,
        for mood: Mood?,
        selectedCategories: [AffirmationCategory]
    ) -> [AffirmationCategory] {
        guard !selectedCategories.isEmpty else { return [] }
        let limit = min(count, selectedCategories.count)
        var remaining = selectedCategories
        var result: [AffirmationCategory] = []

        for _ in 0..<limit {
            guard let pick = suggestCategory(for: mood, selectedCategories: remaining) else { break }
            result.append(pick)
            remaining.removeAll { $0 == pick }
        }

        return result
    }
}
