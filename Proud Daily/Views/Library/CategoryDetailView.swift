import SwiftUI
import SwiftData

struct CategoryDetailView: View {
    let category: AffirmationCategory

    @Environment(\.modelContext) private var modelContext
    @State private var affirmations: [Affirmation] = []
    @State private var filter: AffirmationFilter = .all
    @State private var selectedAffirmation: Affirmation?

    enum AffirmationFilter: String, CaseIterable {
        case all = "All"
        case favorites = "Favorites"
        case custom = "Custom"
    }

    var body: some View {
        List {
            Picker("Filter", selection: $filter) {
                ForEach(AffirmationFilter.allCases, id: \.self) { f in
                    Text(f.rawValue).tag(f)
                }
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            if filteredAffirmations.isEmpty {
                ContentUnavailableView(
                    "No Affirmations",
                    systemImage: "text.quote",
                    description: Text("No \(filter.rawValue.lowercased()) affirmations in this category yet.")
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(filteredAffirmations) { affirmation in
                    Button {
                        selectedAffirmation = affirmation
                    } label: {
                        AffirmationRow(affirmation: affirmation)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(category.displayName)
        .onAppear { loadAffirmations() }
        .onChange(of: filter) { _, _ in loadAffirmations() }
        .fullScreenCover(item: $selectedAffirmation) { affirmation in
            FullScreenAffirmationView(affirmation: affirmation)
        }
    }

    private var filteredAffirmations: [Affirmation] {
        switch filter {
        case .all:
            return affirmations
        case .favorites:
            return affirmations.filter { !($0.favorites?.isEmpty ?? true) }
        case .custom:
            return affirmations.filter { $0.isCustom }
        }
    }

    private func loadAffirmations() {
        let raw = category.rawValue
        let descriptor = FetchDescriptor<Affirmation>(
            predicate: #Predicate<Affirmation> { $0.categoryRaw == raw },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        affirmations = (try? modelContext.fetch(descriptor)) ?? []
    }
}

struct AffirmationRow: View {
    let affirmation: Affirmation

    private var isFavorited: Bool {
        !(affirmation.favorites?.isEmpty ?? true)
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(affirmation.text)
                    .font(.body)
                    .lineLimit(2)

                if affirmation.isCustom {
                    Text("Custom")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }

            Spacer()

            if isFavorited {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.pink)
                    .font(.caption)
            }
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        CategoryDetailView(category: .queerJoy)
    }
    .environment(ThemeManager())
}
