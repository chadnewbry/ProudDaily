import Foundation

@Observable
class AffirmationService {
    private(set) var affirmations: [Affirmation] = []
    private(set) var todaysAffirmation: Affirmation?

    init() {
        loadAffirmations()
        selectTodaysAffirmation()
    }

    private func loadAffirmations() {
        guard let url = Bundle.main.url(forResource: "sample-affirmations", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Affirmation].self, from: data) else {
            affirmations = []
            return
        }
        affirmations = decoded
    }

    private func selectTodaysAffirmation() {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 0
        let index = dayOfYear % max(affirmations.count, 1)
        todaysAffirmation = affirmations.isEmpty ? nil : affirmations[index]
    }
}
