import SwiftUI

@main
struct ProudDailyApp: App {
    @StateObject private var healthKit = HealthKitManager.shared
    @AppStorage("healthKitEnabled") private var healthKitEnabled = true
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    if healthKitEnabled && healthKit.isAvailable {
                        await healthKit.requestAuthorization()
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .background || newPhase == .inactive {
                        healthKit.endSession()
                    }
                }
        }
    }
}
