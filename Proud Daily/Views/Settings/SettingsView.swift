import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(CloudSyncManager.self) private var syncManager
    @Environment(\.modelContext) private var modelContext
    @State private var iCloudSyncEnabled = UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")
    @State private var showSyncChangeAlert = false
    @State private var showDisableSyncInfo = false

    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    NavigationLink("Theme") {
                        Text("Theme Settings")
                    }
                    NavigationLink("App Icon") {
                        AppIconPickerView()
                    }
                }

                Section("Notifications") {
                    NavigationLink("Reminder Time") {
                        Text("Notification Settings")
                    }
                }

                Section {
                    Toggle("iCloud Sync", isOn: $iCloudSyncEnabled)
                        .onChange(of: iCloudSyncEnabled) { _, newValue in
                            if newValue {
                                showSyncChangeAlert = true
                            } else {
                                showDisableSyncInfo = true
                            }
                        }

                    if iCloudSyncEnabled {
                        HStack {
                            Image(systemName: syncManager.status.iconName)
                                .foregroundStyle(statusColor)
                                .symbolEffect(.pulse, isActive: syncManager.status == .syncing)
                            Text(syncManager.status.displayText)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("iCloud")
                } footer: {
                    Text("Sync your favorites, custom affirmations, journal entries, and preferences across your devices. Your data is stored privately in your personal iCloud account.")
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
            .alert("Enable iCloud Sync?", isPresented: $showSyncChangeAlert) {
                Button("Enable & Restart") {
                    enableSync()
                }
                Button("Cancel", role: .cancel) {
                    iCloudSyncEnabled = false
                }
            } message: {
                Text("This will sync your favorites, custom affirmations, journal entries, and preferences across all devices signed into your iCloud account.\n\nThe app will restart to apply this change.")
            }
            .alert("Sync Disabled", isPresented: $showDisableSyncInfo) {
                Button("OK") {
                    disableSync()
                }
                Button("Cancel", role: .cancel) {
                    iCloudSyncEnabled = true
                }
            } message: {
                Text("Syncing has been turned off. Your existing cloud data is preserved — you can delete it from Settings > Apple ID > iCloud > Manage Storage if needed.\n\nThe app will restart to apply this change.")
            }
        }
    }

    private var statusColor: Color {
        switch syncManager.status {
        case .synced: return .green
        case .syncing: return .blue
        case .error: return .red
        case .offline: return .orange
        case .disabled: return .secondary
        }
    }

    private func enableSync() {
        UserDefaults.standard.set(true, forKey: "iCloudSyncEnabled")
        // Update the SwiftData preference too
        updatePreferences(syncEnabled: true)
        triggerAppRestart()
    }

    private func disableSync() {
        UserDefaults.standard.set(false, forKey: "iCloudSyncEnabled")
        updatePreferences(syncEnabled: false)
        syncManager.disableSync()
        triggerAppRestart()
    }

    private func updatePreferences(syncEnabled: Bool) {
        let descriptor = FetchDescriptor<UserPreferences>()
        if let prefs = try? modelContext.fetch(descriptor).first {
            prefs.iCloudSyncEnabled = syncEnabled
            try? modelContext.save()
        }
    }

    private func triggerAppRestart() {
        // Post notification so the app can handle the restart gracefully
        // In practice, CloudKit container change requires app restart
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            exit(0)
        }
    }
}

#Preview {
    SettingsView()
        .environment(CloudSyncManager.shared)
}
