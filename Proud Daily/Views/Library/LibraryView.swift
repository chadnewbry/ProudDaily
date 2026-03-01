import SwiftUI

struct LibraryView: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(AffirmationCategory.allCases) { category in
                    NavigationLink(value: category) {
                        HStack(spacing: 10) {
                            Text(category.emoji)
                            Text(category.displayName)
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .navigationDestination(for: AffirmationCategory.self) { category in
                Text(category.displayName)
                    .navigationTitle(category.displayName)
            }
        }
    }
}

#Preview { LibraryView() }
