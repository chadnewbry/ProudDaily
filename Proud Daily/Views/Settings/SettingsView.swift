import SwiftUI

struct SettingsView: View {
    private let baseURL = "https://chadnewbry.github.io/ProudDaily/"

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
                Section("Legal") {
                    Link(destination: URL(string: "\(baseURL)privacy-policy.html")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
                    }
                    Link(destination: URL(string: "\(baseURL)terms-of-service.html")!) {
                        HStack {
                            Text("Terms of Service")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
                    }
                    Link(destination: URL(string: "\(baseURL)support.html")!) {
                        HStack {
                            Text("Support")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
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
