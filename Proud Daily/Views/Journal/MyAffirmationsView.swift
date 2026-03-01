import SwiftUI
import SwiftData

struct MyAffirmationsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<UserAffirmation> { _ in true },
           sort: \UserAffirmation.createdAt, order: .reverse)
    private var userAffirmations: [UserAffirmation]

    @State private var showNewSheet = false
    @State private var editingAffirmation: UserAffirmation?

    var body: some View {
        Group {
            if userAffirmations.isEmpty {
                ContentUnavailableView {
                    Label("No Custom Affirmations", systemImage: "text.quote")
                } description: {
                    Text("Write your own affirmations to include in your daily rotation.")
                } actions: {
                    Button("+ New Affirmation") { showNewSheet = true }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    ForEach(userAffirmations) { ua in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(ua.text)
                                .font(.body)
                            if let collection = ua.collection {
                                Text(collection.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                let dm = DataManager(modelContext: modelContext)
                                dm.deleteUserAffirmation(ua)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                editingAffirmation = ua
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showNewSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showNewSheet) {
            NewAffirmationSheet()
        }
        .sheet(item: $editingAffirmation) { ua in
            EditAffirmationSheet(affirmation: ua)
        }
    }
}

// MARK: - New Affirmation Sheet

struct NewAffirmationSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \UserCollection.createdAt) private var collections: [UserCollection]

    @State private var text = ""
    @State private var selectedCollection: UserCollection?

    private let maxChars = 280

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $text)
                        .frame(minHeight: 120)
                        .onChange(of: text) { _, newValue in
                            if newValue.count > maxChars {
                                text = String(newValue.prefix(maxChars))
                            }
                        }

                    HStack {
                        Spacer()
                        Text("\(text.count)/\(maxChars)")
                            .font(.caption)
                            .foregroundStyle(text.count >= maxChars ? .red : .secondary)
                    }
                }

                if !collections.isEmpty {
                    Section("Collection (Optional)") {
                        Picker("Collection", selection: $selectedCollection) {
                            Text("None").tag(nil as UserCollection?)
                            ForEach(collections) { c in
                                Text(c.name).tag(c as UserCollection?)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Affirmation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let dm = DataManager(modelContext: modelContext)
                        _ = dm.addUserAffirmation(text: text.trimmingCharacters(in: .whitespacesAndNewlines), collection: selectedCollection)
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Edit Affirmation Sheet

struct EditAffirmationSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let affirmation: UserAffirmation
    @State private var text: String = ""

    private let maxChars = 280

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $text)
                        .frame(minHeight: 120)
                        .onChange(of: text) { _, newValue in
                            if newValue.count > maxChars {
                                text = String(newValue.prefix(maxChars))
                            }
                        }

                    HStack {
                        Spacer()
                        Text("\(text.count)/\(maxChars)")
                            .font(.caption)
                            .foregroundStyle(text.count >= maxChars ? .red : .secondary)
                    }
                }
            }
            .navigationTitle("Edit Affirmation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let dm = DataManager(modelContext: modelContext)
                        dm.updateUserAffirmation(affirmation, text: text.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { text = affirmation.text }
        }
        .presentationDetents([.medium])
    }
}

#Preview { MyAffirmationsView() }
