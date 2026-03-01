import SwiftUI
import SwiftData

struct CollectionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserCollection.createdAt) private var collections: [UserCollection]

    @State private var showNewCollection = false
    @State private var newCollectionName = ""

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        Group {
            if collections.isEmpty {
                ContentUnavailableView {
                    Label("No Collections", systemImage: "folder")
                } description: {
                    Text("Organize your affirmations into personal collections.")
                } actions: {
                    Button("Create Collection") { showNewCollection = true }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(collections) { collection in
                            NavigationLink(value: collection.id) {
                                CollectionCard(collection: collection)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showNewCollection = true
                } label: {
                    Image(systemName: "folder.badge.plus")
                }
            }
        }
        .navigationDestination(for: UUID.self) { collectionId in
            if let collection = collections.first(where: { $0.id == collectionId }) {
                CollectionDetailView(collection: collection)
            }
        }
        .alert("New Collection", isPresented: $showNewCollection) {
            TextField("Collection name", text: $newCollectionName)
            Button("Cancel", role: .cancel) { newCollectionName = "" }
            Button("Create") {
                let name = newCollectionName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { return }
                let dm = DataManager(modelContext: modelContext)
                _ = dm.createCollection(name: name)
                newCollectionName = ""
            }
        }
    }
}

// MARK: - Collection Card

struct CollectionCard: View {
    let collection: UserCollection

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "folder.fill")
                .font(.title2)
                .foregroundStyle(Color.rainbowGradient)

            Text(collection.name)
                .font(.headline)
                .lineLimit(2)

            Text("\(collection.totalCount) affirmation\(collection.totalCount == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview { CollectionsView() }
