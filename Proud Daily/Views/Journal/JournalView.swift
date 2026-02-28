import SwiftUI

struct JournalView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No Entries Yet",
                systemImage: "book.closed",
                description: Text("Start journaling to reflect on your affirmations.")
            )
            .navigationTitle("Journal")
        }
    }
}

#Preview { JournalView() }
