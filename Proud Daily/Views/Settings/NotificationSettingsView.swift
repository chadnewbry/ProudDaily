import SwiftUI
import SwiftData

struct NotificationSettingsView: View {
    var preferences: UserPreferences
    @State private var notificationManager = NotificationManager.shared
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            permissionSection
            if notificationManager.authorizationStatus == .authorized {
                timesSection
                categoriesSection
                discreetSection
            }
        }
        .navigationTitle("Notifications")
        .task {
            await notificationManager.refreshAuthorizationStatus()
        }
    }

    private var permissionSection: some View {
        Section {
            switch notificationManager.authorizationStatus {
            case .notDetermined:
                Button("Enable Notifications") {
                    Task {
                        await notificationManager.requestPermission()
                        await reschedule()
                    }
                }
            case .denied:
                VStack(alignment: .leading, spacing: 8) {
                    Label("Notifications are disabled", systemImage: "bell.slash")
                        .foregroundStyle(.secondary)
                    Button("Open Settings") {
                        notificationManager.openSettings()
                    }
                }
            case .authorized, .provisional, .ephemeral:
                Label("Notifications enabled", systemImage: "bell.badge.fill")
                    .foregroundStyle(.green)
            @unknown default:
                EmptyView()
            }
        }
    }

    private var timesSection: some View {
        Section {
            ForEach(0..<preferences.notificationTimes.count, id: \.self) { index in
                DatePicker(
                    slotLabel(for: preferences.notificationTimes[index], index: index),
                    selection: Binding(
                        get: { preferences.notificationTimes[index] },
                        set: {
                            preferences.notificationTimes[index] = $0
                            Task { await reschedule() }
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
            }
            .onDelete { offsets in
                preferences.notificationTimes.remove(atOffsets: offsets)
                Task { await reschedule() }
            }

            if preferences.notificationTimes.count < 5 {
                Button {
                    let t = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? .now
                    preferences.notificationTimes.append(t)
                    Task { await reschedule() }
                } label: {
                    Label("Add Notification Time", systemImage: "plus.circle")
                }
            }
        } header: {
            Text("Notification Times")
        } footer: {
            Text("Schedule up to 5 daily affirmation reminders.")
        }
    }

    private var categoriesSection: some View {
        Section {
            CategoryToggleList(preferences: preferences, onChanged: {
                Task { await reschedule() }
            })
        } header: {
            Text("Notification Categories")
        } footer: {
            Text("Choose which affirmation categories appear in notifications.")
        }
    }

    private var discreetSection: some View {
        Section {
            Toggle("Discreet Mode", isOn: Binding(
                get: { preferences.discreetModeEnabled },
                set: {
                    preferences.discreetModeEnabled = $0
                    Task { await reschedule() }
                }
            ))
        } footer: {
            Text("When enabled, notifications show \"Daily Reminder\" with generic text instead of affirmation content.")
        }
    }

    private func slotLabel(for time: Date, index: Int) -> String {
        let hour = Calendar.current.component(.hour, from: time)
        if hour >= 5 && hour < 10 { return "Morning ☀️" }
        if hour >= 21 || hour < 5 { return "Bedtime 🌙" }
        return "Reminder \(index + 1)"
    }

    private func reschedule() async {
        await notificationManager.rescheduleAll(preferences: preferences, modelContext: modelContext)
    }
}

// MARK: - Category Toggle List (extracted to help type checker)

private struct CategoryToggleList: View {
    var preferences: UserPreferences
    var onChanged: () -> Void

    var body: some View {
        ForEach(AffirmationCategory.allCases) { category in
            CategoryRow(
                category: category,
                isSelected: preferences.selectedCategoriesRaw.contains(category.rawValue),
                onTap: {
                    if preferences.selectedCategoriesRaw.contains(category.rawValue) {
                        preferences.selectedCategoriesRaw.removeAll { $0 == category.rawValue }
                    } else {
                        preferences.selectedCategoriesRaw.append(category.rawValue)
                    }
                    onChanged()
                }
            )
        }
    }
}

private struct CategoryRow: View {
    let category: AffirmationCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text("\(category.emoji) \(category.displayName)")
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
