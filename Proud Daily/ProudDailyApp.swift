import SwiftUI

@main
struct ProudDailyApp: App {
    @State private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(themeManager)
                .tint(themeManager.activeAccentColor)
        }
    }
}
