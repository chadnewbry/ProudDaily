import SwiftUI
import SwiftData

@main
struct ProudDailyApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                Affirmation.self,
                FavoriteAffirmation.self,
                UserAffirmation.self,
                UserCollection.self,
                JournalEntry.self,
                DailyRecord.self,
                UserPreferences.self,
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    let dataManager = DataManager(modelContext: modelContainer.mainContext)
                    dataManager.seedIfNeeded()
                }
        }
        .modelContainer(modelContainer)
    }
}
