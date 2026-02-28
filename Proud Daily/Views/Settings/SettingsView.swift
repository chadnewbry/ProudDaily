import SwiftUI

struct SettingsView: View {
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
