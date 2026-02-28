import SwiftUI

struct LibraryView: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(AffirmationCategory.allCases, id: \.self) { category in
                    NavigationLink(value: category) {
                        Label(category.rawValue, systemImage: category.icon)
                    }
                }
            }
            .navigationTitle("Library")
            .navigationDestination(for: AffirmationCategory.self) { category in
                Text(category.rawValue)
                    .navigationTitle(category.rawValue)
            }
        }
    }
}

#Preview { LibraryView() }
