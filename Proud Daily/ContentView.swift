import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: Tab = .home
    @State private var showOnboarding = false
    @State private var preferences: UserPreferences?

    var body: some View {
        Group {
            if showOnboarding, let prefs = preferences {
                OnboardingView(preferences: prefs) {
                    withAnimation {
                        showOnboarding = false
                    }
                }
            } else {
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
        .onAppear {
            loadPreferences()
        }
    }

    private func loadPreferences() {
        let descriptor = FetchDescriptor<UserPreferences>()
        if let existing = try? modelContext.fetch(descriptor).first {
            preferences = existing
            showOnboarding = !existing.hasCompletedOnboarding
        } else {
            let prefs = UserPreferences()
            modelContext.insert(prefs)
            try? modelContext.save()
            preferences = prefs
            showOnboarding = true
        }
    }
}

enum Tab: String, CaseIterable {
    case home, library, journal, progress, settings
}

#Preview {
    ContentView()
        .environment(ThemeManager())
}
