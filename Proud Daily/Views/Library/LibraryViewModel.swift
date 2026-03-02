import Foundation
import SwiftData
import SwiftUI

@Observable
final class LibraryViewModel {
    var searchText: String = ""
    var favorites: [FavoriteAffirmation] = []
    var categoryCounts: [AffirmationCategory: Int] = [:]
    var searchResults: [Affirmation] = []

    private var modelContext: ModelContext?
    private var dataManager: DataManager?

    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.dataManager = DataManager(modelContext: modelContext)
        refresh()
    }

    func refresh() {
        loadFavorites()
        loadCategoryCounts()
        if !searchText.isEmpty {
            performSearch()
        }
    }

    private func loadFavorites() {
        guard let dataManager else { return }
        favorites = dataManager.fetchFavorites()
    }

    private func loadCategoryCounts() {
        guard let modelContext else { return }
        var counts: [AffirmationCategory: Int] = [:]
        for category in AffirmationCategory.allCases {
            let raw = category.rawValue
            let descriptor = FetchDescriptor<Affirmation>(
                predicate: #Predicate<Affirmation> { $0.categoryRaw == raw }
            )
            counts[category] = (try? modelContext.fetchCount(descriptor)) ?? 0
        }
        categoryCounts = counts
    }

    func performSearch() {
        guard let modelContext, !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }
        let query = searchText.lowercased()
        let descriptor = FetchDescriptor<Affirmation>()
        let all = (try? modelContext.fetch(descriptor)) ?? []
        searchResults = all.filter { $0.text.lowercased().contains(query) }
    }

    func isFavorite(_ affirmation: Affirmation) -> Bool {
        dataManager?.isFavorite(affirmation) ?? false
    }

    func toggleFavorite(_ affirmation: Affirmation) {
        dataManager?.toggleFavorite(affirmation: affirmation)
        refresh()
    }

    func unfavorite(_ fav: FavoriteAffirmation) {
        if let affirmation = fav.affirmation {
            dataManager?.toggleFavorite(affirmation: affirmation)
        }
        refresh()
    }
}
