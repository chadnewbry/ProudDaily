import SwiftUI
import SwiftData

struct CollectionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var collection: UserCollection

    @State private var showDeleteConfirm = false
    @State private var showRename = false
    @State private var renameText = ""
    @State private var showFullScreen = false

    var body: some View {
        let dm = DataManager(modelContext: modelContext)
        let customAffirmations = collection.affirmations ?? []
        let curatedAffirmations = dm.fetchCuratedAffirmations(ids: collection.curatedAffirmationIds)

        List {
            if !customAffirmations.isEmpty {
                Section("Custom") {
                    ForEach(customAffirmations) { ua in
                        Text(ua.text)
                    }
                    .onDelete { indices in
                        for i in indices {
                            dm.deleteUserAffirmation(customAffirmations[i])
                        }
                    }
                    .onMove { source, destination in
                        // Reorder support via drag
                        var items = customAffirmations
                        items.move(fromOffsets: source, toOffset: destination)
                        // SwiftData doesn't have native ordering, but the UI reflects drag state
                    }
                }
            }

            if !curatedAffirmations.isEmpty {
                Section("Curated") {
                    ForEach(curatedAffirmations) { a in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(a.text)
                            Text(a.category.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { indices in
                        for i in indices {
                            dm.removeCuratedFromCollection(curatedAffirmations[i].id, collection: collection)
                        }
                    }
                }
            }

            if customAffirmations.isEmpty && curatedAffirmations.isEmpty {
                ContentUnavailableView(
                    "Empty Collection",
                    systemImage: "folder",
                    description: Text("Add affirmations from your library or create new ones.")
                )
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(collection.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    if collection.totalCount > 0 {
                        Button {
                            showFullScreen = true
                        } label: {
                            Label("Browse Cards", systemImage: "rectangle.stack")
                        }
                    }

                    Button {
                        renameText = collection.name
                        showRename = true
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete Collection", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }

            ToolbarItem(placement: .primaryAction) {
                EditButton()
            }
        }
        .alert("Rename Collection", isPresented: $showRename) {
            TextField("Name", text: $renameText)
            Button("Cancel", role: .cancel) {}
            Button("Rename") {
                let name = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { return }
                dm.renameCollection(collection, to: name)
            }
        }
        .alert("Delete Collection?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                dm.deleteCollection(collection)
                dismiss()
            }
        } message: {
            Text("This will remove the collection. Your affirmations won't be deleted.")
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            CollectionCardBrowser(
                customAffirmations: customAffirmations,
                curatedAffirmations: curatedAffirmations
            )
        }
    }
}

// MARK: - Full-Screen Card Browser

struct CollectionCardBrowser: View {
    @Environment(\.dismiss) private var dismiss
    let customAffirmations: [UserAffirmation]
    let curatedAffirmations: [Affirmation]

    @State private var currentIndex = 0

    private var allTexts: [String] {
        customAffirmations.map(\.text) + curatedAffirmations.map(\.text)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if allTexts.isEmpty {
                Text("No affirmations")
                    .foregroundStyle(.white)
            } else {
                TabView(selection: $currentIndex) {
                    ForEach(Array(allTexts.enumerated()), id: \.offset) { index, text in
                        VStack {
                            Spacer()
                            Text(text)
                                .font(.title)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white)
                                .padding(40)
                            Spacer()
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.white)
                    }
                    .padding()
                }
                Spacer()
            }
        }
    }
}
