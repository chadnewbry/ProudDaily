import SwiftUI
import SwiftData

struct AllFavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var favorites: [FavoriteAffirmation] = []
    @State private var selectedAffirmation: Affirmation?

    var body: some View {
        List {
            if favorites.isEmpty {
                ContentUnavailableView(
                    "No Favorites Yet",
                    systemImage: "heart",
                    description: Text("Tap the heart on any affirmation to add it here.")
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(favorites) { fav in
                    if let affirmation = fav.affirmation {
                        Button {
                            selectedAffirmation = affirmation
                        } label: {
                            AffirmationRow(affirmation: affirmation)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .onDelete(perform: unfavorite)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Favorites")
        .onAppear { loadFavorites() }
        .fullScreenCover(item: $selectedAffirmation) { affirmation in
            FullScreenAffirmationView(affirmation: affirmation)
        }
    }

    private func loadFavorites() {
        let descriptor = FetchDescriptor<FavoriteAffirmation>(
            sortBy: [SortDescriptor(\.savedAt, order: .reverse)]
        )
        favorites = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func unfavorite(at offsets: IndexSet) {
        for index in offsets {
            let fav = favorites[index]
            if let affirmation = fav.affirmation {
                let dm = DataManager(modelContext: modelContext)
                dm.toggleFavorite(affirmation: affirmation)
            }
        }
        loadFavorites()
    }
}

#Preview {
    NavigationStack {
        AllFavoritesView()
    }
    .environment(ThemeManager())
}
