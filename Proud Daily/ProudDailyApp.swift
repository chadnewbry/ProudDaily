import SwiftUI
import SwiftData

@main
struct ProudDailyApp: App {
    @State private var syncManager = CloudSyncManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(syncManager)
                .onAppear {
                    // Seed data on first launch using the default container
                }
        }
        .modelContainer(Self.createModelContainer())
    }

    static func createModelContainer() -> ModelContainer {
        let schema = Schema([
            Affirmation.self,
            FavoriteAffirmation.self,
            UserAffirmation.self,
            UserCollection.self,
            JournalEntry.self,
            DailyRecord.self,
            UserPreferences.self,
        ])

        // Check if user previously enabled iCloud sync via UserDefaults
        // (We store this separately because we need it before SwiftData loads)
        let iCloudEnabled = UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")

        let config: ModelConfiguration
        if iCloudEnabled {
            config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private("iCloud.com.openclaw.prouddaily")
            )
        } else {
            config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
        }

        do {
            let container = try ModelContainer(for: schema, configurations: [config])

            // Seed if needed
            let context = container.mainContext
            let descriptor = FetchDescriptor<Affirmation>(predicate: #Predicate<Affirmation> { $0.isCustom == false })
            let count = (try? context.fetchCount(descriptor)) ?? 0
            if count == 0 {
                let dataManager = DataManager(modelContext: context)
                dataManager.seedIfNeeded()
            }

            // Update sync manager status
            if iCloudEnabled {
                CloudSyncManager.shared.enableSync()
            }

            return container
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
