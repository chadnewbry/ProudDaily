import SwiftUI

struct SettingsView: View {
    @StateObject private var healthKit = HealthKitManager.shared
    @AppStorage("healthKitEnabled") private var healthKitEnabled = true

    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    NavigationLink("Theme") {
                        Text("Theme Settings")
                    }
                }
                Section("Notifications") {
                    NavigationLink("Reminder Time") {
                        Text("Notification Settings")
                    }
                }

                if healthKit.isAvailable {
                    Section {
                        Toggle("Track Mindful Minutes", isOn: $healthKitEnabled)
                            .onChange(of: healthKitEnabled) { _, newValue in
                                if newValue {
                                    Task { await healthKit.requestAuthorization() }
                                }
                            }
                    } header: {
                        Text("Apple Health")
                    } footer: {
                        Text("Log affirmation sessions as Mindful Minutes in Apple Health.")
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0").foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview { SettingsView() }
