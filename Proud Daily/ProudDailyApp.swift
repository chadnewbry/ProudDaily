import SwiftUI
import SwiftData
import WidgetKit

@main
struct ProudDailyApp: App {
    @State private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(themeManager)
                .tint(themeManager.activeAccentColor)
                .task {
                    syncWidgetData()
                }
                .onChange(of: themeManager.selectedTheme) { _, _ in
                    WidgetSyncService.shared.syncTheme()
                    WidgetCenter.shared.reloadAllTimelines()
                }
        }
        .modelContainer(for: [
            Affirmation.self,
            DailyRecord.self,
            UserPreferences.self,
            FavoriteAffirmation.self,
            JournalEntry.self,
            UserAffirmation.self,
            UserCollection.self
        ])
    }

    private func syncWidgetData() {
        Task.detached {
            do {
                let container = try ModelContainer(for: Affirmation.self, DailyRecord.self, UserPreferences.self)
                let context = ModelContext(container)
                await MainActor.run {
                    WidgetSyncService.shared.syncAll(modelContext: context)
                }
            } catch {
                // Widget sync is best-effort
            }
        }
    }
}
