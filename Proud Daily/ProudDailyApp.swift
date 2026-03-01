import SwiftUI
import SwiftData

@main
struct ProudDailyApp: App {
    @StateObject private var healthKit = HealthKitManager.shared
    @AppStorage("healthKitEnabled") private var healthKitEnabled = true
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let center = UNUserNotificationCenter.current()
        center.delegate = NotificationManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    if healthKitEnabled && healthKit.isAvailable {
                        await healthKit.requestAuthorization()
                    }
                    // Refresh notification status & reschedule on launch (handles reboot/update)
                    await NotificationManager.shared.refreshAuthorizationStatus()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .background || newPhase == .inactive {
                        healthKit.endSession()
                    }
                }
        }
    }
}
