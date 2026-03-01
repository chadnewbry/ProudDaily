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

    func selectTodaysAffirmation(from categories: [AffirmationCategory]? = nil) {
        var descriptor = FetchDescriptor<Affirmation>(
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

    func randomAffirmation(category: AffirmationCategory? = nil) -> Affirmation? {
        var descriptor = FetchDescriptor<Affirmation>()
        if let category {
            let raw = category.rawValue
            descriptor.predicate = #Predicate<Affirmation> { $0.categoryRaw == raw }
        }
        guard let all = try? modelContext.fetch(descriptor), !all.isEmpty else { return nil }
        return all.randomElement()
    }
}
