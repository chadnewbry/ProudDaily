import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @State private var viewModel = LibraryViewModel()
    @State private var showAllFavorites = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    // MARK: - Search Results
                    if !viewModel.searchText.isEmpty {
                        searchResultsSection
                    } else {
                        // MARK: - Favorites
                        if !viewModel.favorites.isEmpty {
                            favoritesSection
                        }

                        // MARK: - Categories Grid
                        categoriesSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .navigationTitle("Library")
            .searchable(text: $viewModel.searchText, prompt: "Search affirmations...")
            .onChange(of: viewModel.searchText) { _, _ in
                viewModel.performSearch()
            }
            .onAppear {
                viewModel.setup(modelContext: modelContext)
            }
            .navigationDestination(for: AffirmationCategory.self) { category in
                CategoryDetailView(category: category)
            }
            .navigationDestination(isPresented: $showAllFavorites) {
                AllFavoritesView()
            }
        }
    }

    // MARK: - Favorites Section

    @ViewBuilder
    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Favorites")
                    .font(.title3)
                    .fontWeight(.bold)

                Spacer()

                Button("See All") {
                    showAllFavorites = true
                }
                .font(.subheadline)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(viewModel.favorites.prefix(10)) { fav in
                        if let affirmation = fav.affirmation {
                            NavigationLink {
                                FullScreenAffirmationView(affirmation: affirmation)
                            } label: {
                                FavoriteCardView(affirmation: affirmation)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Categories Section

    @ViewBuilder
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.title3)
                .fontWeight(.bold)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(AffirmationCategory.allCases) { category in
                    NavigationLink(value: category) {
                        CategoryCardView(
                            category: category,
                            count: viewModel.categoryCounts[category] ?? 0
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Search Results

    @ViewBuilder
    private var searchResultsSection: some View {
        if viewModel.searchResults.isEmpty {
            ContentUnavailableView.search(text: viewModel.searchText)
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(viewModel.searchResults.count) results")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                LazyVStack(spacing: 8) {
                    ForEach(viewModel.searchResults) { affirmation in
                        NavigationLink {
                            FullScreenAffirmationView(affirmation: affirmation)
                        } label: {
                            SearchResultRow(
                                affirmation: affirmation,
                                searchTerm: viewModel.searchText
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Category Card

struct CategoryCardView: View {
    let category: AffirmationCategory
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category.emoji)
                    .font(.title)
                Spacer()
            }

            Text(category.displayName)
                .font(.headline)
                .foregroundStyle(.primary)

            Text("\(count) affirmation\(count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Mini pride gradient accent
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [category.color, category.color.opacity(0.4)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 3)
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(category.color.opacity(0.3), lineWidth: 1)
        }
    }
}

// MARK: - Favorite Card

struct FavoriteCardView: View {
    let affirmation: Affirmation

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(affirmation.text)
                .font(.subheadline)
                .lineLimit(3)
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)

            Spacer()

            Text(affirmation.category.displayName)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(12)
        .frame(width: 160, height: 120, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [affirmation.category.color, affirmation.category.color.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let affirmation: Affirmation
    let searchTerm: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            highlightedText
                .font(.body)
                .lineLimit(2)

            HStack(spacing: 4) {
                Text(affirmation.category.emoji)
                    .font(.caption2)
                Text(affirmation.category.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if affirmation.isCustom {
                    Text("• Custom")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
        }
    }

    @ViewBuilder
    private var highlightedText: some View {
        let text = affirmation.text
        let lower = text.lowercased()
        let term = searchTerm.lowercased()

        if let range = lower.range(of: term) {
            let before = String(text[text.startIndex..<range.lowerBound])
            let match = String(text[range.lowerBound..<range.upperBound])
            let after = String(text[range.upperBound...])
            Text(before) + Text(match).bold().foregroundColor(.accentColor) + Text(after)
        } else {
            Text(text)
        }
    }
}

#Preview {
    LibraryView()
        .environment(ThemeManager())
}
