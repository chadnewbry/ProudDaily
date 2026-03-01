import SwiftUI

struct ContentView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var selectedTab: Tab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "sparkles")
                }
                .tag(Tab.home)

            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "books.vertical")
                }
                .tag(Tab.library)

            JournalView()
                .tabItem {
                    Label("Journal", systemImage: "book.closed")
                }
                .tag(Tab.journal)

            ProgressTabView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar")
                }
                .tag(Tab.progress)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(Tab.settings)
        }
        .tint(themeManager.activeAccentColor)
    }
}

enum Tab: String, CaseIterable {
    case home, library, journal, progress, settings
}

#Preview {
    ContentView()
        .environment(ThemeManager())
}
