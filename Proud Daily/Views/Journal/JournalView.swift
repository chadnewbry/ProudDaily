import SwiftUI
import SwiftData

// MARK: - Journal Tab Segments

enum JournalSegment: String, CaseIterable {
    case myAffirmations = "My Affirmations"
    case collections = "Collections"
    case journal = "Journal"
}

struct JournalView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var segment: JournalSegment = .myAffirmations

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Section", selection: $segment) {
                    ForEach(JournalSegment.allCases, id: \.self) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                switch segment {
                case .myAffirmations:
                    MyAffirmationsView()
                case .collections:
                    CollectionsView()
                case .journal:
                    JournalTimelineView()
                }
            }
            .navigationTitle("Journal")
        }
    }
}

#Preview { JournalView() }
