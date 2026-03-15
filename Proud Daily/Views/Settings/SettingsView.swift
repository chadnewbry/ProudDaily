import SwiftUI
import SwiftData
import StoreKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @Query private var allPreferences: [UserPreferences]
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var cloudSyncManager = CloudSyncManager.shared
    @State private var showDeleteConfirmation = false
    @State private var showExportSheet = false
    @State private var exportURL: URL?
    @State private var showShareSheet = false
    @State private var showRestorePurchasesAlert = false
    @State private var storeManager = StoreManager.shared
    @State private var showPaywall = false
    @State private var audioStorageSize: String = "Calculating…"

    private var preferences: UserPreferences {
        allPreferences.first ?? {
            let p = UserPreferences()
            modelContext.insert(p)
            return p
        }()
    }

    var body: some View {
        NavigationStack {
            List {
                accountPrivacySection
                notificationsSection
                appearanceSection
                audioSection
                affirmationPreferencesSection
                healthKitSection
                supportLegalSection
                aboutSection
                if !preferences.hasPurchasedPremium {
                    restorePurchasesSection
                }
            }
            .navigationTitle("Settings")
            .alert("Delete All Data", isPresented: $showDeleteConfirmation) {
                Button("Delete Everything", role: .destructive) { deleteAllData() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete all your journal entries, favorites, collections, and preferences. This cannot be undone.")
            }
            .sheet(isPresented: $showExportSheet) {
                if let url = exportURL {
                    ShareSheetView(items: [url])
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheetView(items: [URL(string: "https://apps.apple.com/app/proud-daily/id0000000000")!])
            }
            .alert("Restore Purchases", isPresented: $showRestorePurchasesAlert) {
                Button("OK") { }
            } message: {
                Text(storeManager.isPurchased ? "Premium features have been unlocked!" : "No previous purchase found.")
            }
            .task {
                calculateAudioStorage()
            }
        }
    }

    // MARK: - Account & Privacy

    private var accountPrivacySection: some View {
        Section {
            // iCloud Sync
            HStack {
                Toggle(isOn: Binding(
                    get: { preferences.iCloudSyncEnabled },
                    set: { newValue in
                        preferences.iCloudSyncEnabled = newValue
                        if newValue {
                            cloudSyncManager.enableSync()
                        } else {
                            cloudSyncManager.disableSync()
                        }
                    }
                )) {
                    HStack {
                        Label("iCloud Sync", systemImage: cloudSyncManager.status.iconName)
                        Spacer()
                        Text(cloudSyncManager.status.displayText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Discreet Mode
            Toggle(isOn: Binding(
                get: { preferences.discreetModeEnabled },
                set: { newValue in
                    preferences.discreetModeEnabled = newValue
                    if newValue {
                        UIApplication.shared.setAlternateIconName(AppIconVariant.subtle.iconName)
                    }
                }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Discreet Mode", systemImage: "eye.slash")
                    Text("Neutral icon, generic notifications & widget content")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Data Export
            Button {
                exportData()
            } label: {
                Label("Export My Data", systemImage: "square.and.arrow.up")
            }

            // Delete All Data
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete All Data", systemImage: "trash")
            }
        } header: {
            Text("Account & Privacy")
        }
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        Section {
            NavigationLink {
                NotificationSettingsView(preferences: preferences)
            } label: {
                Label("Notification Settings", systemImage: "bell.badge")
            }
        } header: {
            Text("Notifications")
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        Section {
            NavigationLink {
                ThemeSettingsView()
            } label: {
                HStack {
                    Label("Theme", systemImage: "paintpalette")
                    Spacer()
                    Text("\(themeManager.selectedTheme.emoji) \(themeManager.selectedTheme.displayName)")
                        .foregroundStyle(.secondary)
                }
            }

            NavigationLink {
                AppIconPickerView()
            } label: {
                Label("App Icon", systemImage: "app.badge")
            }

            // Dark Mode Override
            HStack {
                Label("Appearance", systemImage: "circle.lefthalf.filled")
                Spacer()
                Picker("", selection: Binding(
                    get: { preferences.appearanceMode },
                    set: { preferences.appearanceMode = $0 }
                )) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Label(mode.displayName, systemImage: mode.icon).tag(mode)
                    }
                }
                .pickerStyle(.menu)
            }
        } header: {
            Text("Appearance")
        }
    }

    // MARK: - Audio

    private var audioSection: some View {
        Section {
            // Default Ambient Sound
            Picker(selection: Binding(
                get: { preferences.defaultAmbientSound },
                set: { preferences.defaultAmbientSound = $0 }
            )) {
                ForEach(AmbientSound.allCases) { sound in
                    Label(sound.displayName, systemImage: sound.icon).tag(sound)
                }
            } label: {
                Label("Default Sound", systemImage: "speaker.wave.2")
            }

            // Sleep Timer
            Picker(selection: Binding(
                get: { preferences.sleepTimerDuration },
                set: { preferences.sleepTimerDuration = $0 }
            )) {
                ForEach(SleepTimerDuration.allCases) { duration in
                    Text(duration.displayName).tag(duration)
                }
            } label: {
                Label("Sleep Timer", systemImage: "moon.zzz")
            }

            // Audio Storage
            HStack {
                Label("Audio Cache", systemImage: "internaldrive")
                Spacer()
                Text(audioStorageSize)
                    .foregroundStyle(.secondary)
            }

            Button(role: .destructive) {
                clearAudioCache()
            } label: {
                Label("Clear Audio Cache", systemImage: "trash")
            }
        } header: {
            Text("Audio")
        }
    }

    // MARK: - Affirmation Preferences

    private var affirmationPreferencesSection: some View {
        Section {
            NavigationLink {
                CategorySelectionView(preferences: preferences)
            } label: {
                Label("Categories", systemImage: "tag")
            }

            NavigationLink {
                IdentityEditView(preferences: preferences)
            } label: {
                HStack {
                    Label("Pronouns & Name", systemImage: "person.text.rectangle")
                    Spacer()
                    if !preferences.pronouns.isEmpty {
                        Text(preferences.pronouns)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            NavigationLink {
                IdentityLabelsEditView(preferences: preferences)
            } label: {
                Label("Identity Labels", systemImage: "heart.text.square")
            }
        } header: {
            Text("Affirmation Preferences")
        }
    }

    // MARK: - HealthKit

    private var healthKitSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { preferences.healthKitEnabled },
                set: { newValue in
                    preferences.healthKitEnabled = newValue
                    if newValue {
                        Task { await healthKitManager.requestAuthorization() }
                    }
                }
            )) {
                Label("Mindful Minutes", systemImage: "heart.fill")
            }

            if preferences.healthKitEnabled {
                Button {
                    if let url = URL(string: "x-apple-health://") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Open Health App", systemImage: "heart.text.square")
                }
            }
        } header: {
            Text("HealthKit")
        } footer: {
            Text("Track affirmation sessions as mindful minutes in Apple Health.")
        }
    }

    // MARK: - Support & Legal

    private var supportLegalSection: some View {
        Section {
            Link(destination: URL(string: AppConfig.shared.urls.privacyPolicy)!) {
                Label("Privacy Policy", systemImage: "hand.raised")
            }

            Link(destination: URL(string: AppConfig.shared.urls.termsOfService)!) {
                Label("Terms of Use", systemImage: "doc.text")
            }

            Button {
                openSupportEmail()
            } label: {
                Label("Contact Support", systemImage: "envelope")
            }

            Button {
                sendFeedbackEmail()
            } label: {
                Label("Feedback / Product Suggestions", systemImage: "lightbulb")
            }

            Button {
                requestAppReview()
            } label: {
                Label("Rate the App", systemImage: "star")
            }

            Button {
                showShareSheet = true
            } label: {
                Label("Share the App", systemImage: "square.and.arrow.up")
            }
        } header: {
            Text("Support & Legal")
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Spacer()
                Text("Made with 🏳️‍🌈 by OpenClaw")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            NavigationLink {
                AcknowledgmentsView()
            } label: {
                Label("Acknowledgments", systemImage: "heart.circle")
            }
        } header: {
            Text("About")
        }
    }

    // MARK: - Restore Purchases

    private var restorePurchasesSection: some View {
        Section {
            Button {
                showPaywall = true
            } label: {
                Label("Upgrade to Premium", systemImage: "sparkles")
            }

            Button {
                Task {
                    let success = await storeManager.restore()
                    if success {
                        preferences.hasPurchasedPremium = true
                    }
                    showRestorePurchasesAlert = true
                }
            } label: {
                Label("Restore Purchases", systemImage: "arrow.clockwise")
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView {
                preferences.hasPurchasedPremium = true
            }
        }
    }

    // MARK: - Helpers

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func exportData() {
        Task {
            let descriptor = FetchDescriptor<JournalEntry>()
            let entries = (try? modelContext.fetch(descriptor)) ?? []
            let favDescriptor = FetchDescriptor<FavoriteAffirmation>()
            let favorites = (try? modelContext.fetch(favDescriptor)) ?? []

            var export: [String: Any] = [
                "exportDate": ISO8601DateFormatter().string(from: Date()),
                "journalEntries": entries.map { entry in
                    [
                        "id": entry.id.uuidString,
                        "text": entry.text,
                        "createdAt": ISO8601DateFormatter().string(from: entry.date),
                        "moodBefore": entry.moodBeforeRaw.map { String($0) } ?? "", "moodAfter": entry.moodAfterRaw.map { String($0) } ?? ""
                    ] as [String: Any]
                },
                "favoriteCount": favorites.count
            ]

            if let data = try? JSONSerialization.data(withJSONObject: export, options: .prettyPrinted) {
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("ProudDaily_Export_\(Date().timeIntervalSince1970).json")
                try? data.write(to: tempURL)
                exportURL = tempURL
                showExportSheet = true
            }
        }
    }

    private func deleteAllData() {
        try? modelContext.delete(model: JournalEntry.self)
        try? modelContext.delete(model: FavoriteAffirmation.self)
        try? modelContext.delete(model: UserAffirmation.self)
        try? modelContext.delete(model: UserCollection.self)
        try? modelContext.delete(model: DailyRecord.self)

        // Reset preferences
        let prefs = preferences
        prefs.selectedCategoriesRaw = AffirmationCategory.allCases.map(\.rawValue)
        prefs.pronouns = ""
        prefs.displayName = ""
        prefs.identityLabelsRaw = []
        prefs.notificationTimes = []
        prefs.discreetModeEnabled = false
        prefs.healthKitEnabled = false

        try? modelContext.save()
    }

    private func calculateAudioStorage() {
        let dir = AudioFileManager.recordingsDirectory
        let files = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.fileSizeKey])) ?? []
        let totalBytes = files.compactMap { try? $0.resourceValues(forKeys: [.fileSizeKey]).fileSize }.reduce(0, +)
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        audioStorageSize = formatter.string(fromByteCount: Int64(totalBytes))
    }

    private func clearAudioCache() {
        let dir = AudioFileManager.recordingsDirectory
        let files = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
        for file in files where file.pathExtension != "json" {
            try? FileManager.default.removeItem(at: file)
        }
        audioStorageSize = "0 bytes"
    }


    private func openSupportEmail() {
        let email = AppConfig.shared.review?.contactEmail ?? "chad.newbry@gmail.com"
        let subject = "Proud Daily Support"
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject
        if let url = URL(string: "mailto:\(email)?subject=\(encodedSubject)") {
            UIApplication.shared.open(url)
        }
    }

    private func sendFeedbackEmail() {
        let email = AppConfig.shared.review?.contactEmail ?? "chad.newbry@gmail.com"
        let subject = "Feedback: Proud Daily"
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject
        if let url = URL(string: "mailto:\(email)?subject=\(encodedSubject)") {
            UIApplication.shared.open(url)
        }
    }

    private func requestAppReview() {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            AppStore.requestReview(in: scene)
        }
    }
}

// MARK: - Share Sheet

struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Category Selection

struct CategorySelectionView: View {
    var preferences: UserPreferences

    var body: some View {
        List {
            ForEach(AffirmationCategory.allCases) { category in
                Button {
                    toggleCategory(category)
                } label: {
                    HStack {
                        Text("\(category.emoji) \(category.displayName)")
                        Spacer()
                        if preferences.selectedCategoriesRaw.contains(category.rawValue) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.accentColor)
                        } else {
                            Image(systemName: "circle")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("Categories")
    }

    private func toggleCategory(_ category: AffirmationCategory) {
        if preferences.selectedCategoriesRaw.contains(category.rawValue) {
            guard preferences.selectedCategoriesRaw.count > 1 else { return }
            preferences.selectedCategoriesRaw.removeAll { $0 == category.rawValue }
        } else {
            preferences.selectedCategoriesRaw.append(category.rawValue)
        }
    }
}

// MARK: - Identity Edit

struct IdentityEditView: View {
    var preferences: UserPreferences
    @State private var selectedPronoun: PronounOption = .heHim
    @State private var customPronoun: String = ""
    @State private var name: String = ""

    var body: some View {
        Form {
            Section("Display Name") {
                TextField("Your name", text: $name)
                    .onChange(of: name) { _, newValue in
                        preferences.displayName = newValue
                    }
            }

            Section("Pronouns") {
                ForEach(PronounOption.allCases) { option in
                    Button {
                        selectedPronoun = option
                        if option != .custom {
                            preferences.pronouns = option.displayName
                        }
                    } label: {
                        HStack {
                            Text(option.displayName)
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedPronoun == option {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                }

                if selectedPronoun == .custom {
                    TextField("Custom pronouns", text: $customPronoun)
                        .onChange(of: customPronoun) { _, newValue in
                            preferences.pronouns = newValue
                        }
                }
            }
        }
        .navigationTitle("Pronouns & Name")
        .onAppear {
            name = preferences.displayName
            if let matched = PronounOption.allCases.first(where: { $0.displayName == preferences.pronouns }) {
                selectedPronoun = matched
            } else if !preferences.pronouns.isEmpty {
                selectedPronoun = .custom
                customPronoun = preferences.pronouns
            }
        }
    }
}

// MARK: - Identity Labels Edit

struct IdentityLabelsEditView: View {
    var preferences: UserPreferences

    var body: some View {
        List {
            ForEach(IdentityLabel.allCases) { label in
                Button {
                    toggleLabel(label)
                } label: {
                    HStack {
                        Text(label.displayName)
                        Spacer()
                        if preferences.identityLabelsRaw.contains(label.rawValue) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.accentColor)
                        } else {
                            Image(systemName: "circle")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("Identity Labels")
    }

    private func toggleLabel(_ label: IdentityLabel) {
        if preferences.identityLabelsRaw.contains(label.rawValue) {
            preferences.identityLabelsRaw.removeAll { $0 == label.rawValue }
        } else {
            preferences.identityLabelsRaw.append(label.rawValue)
        }
    }
}

// MARK: - Acknowledgments

struct AcknowledgmentsView: View {
    var body: some View {
        List {
            Section {
                Text("Proud Daily is built with love for the LGBTQ+ community.")
                    .font(.body)
            }

            Section("Open Source") {
                Text("SwiftUI & SwiftData by Apple")
                Text("HealthKit by Apple")
            }

            Section("Special Thanks") {
                Text("The LGBTQ+ community for inspiring every affirmation")
                Text("Beta testers who provided invaluable feedback")
                Text("All the chosen families that make us stronger")
            }

            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Text("🏳️‍🌈")
                            .font(.largeTitle)
                        Text("Made with pride by OpenClaw")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
        }
        .navigationTitle("Acknowledgments")
    }
}

#Preview {
    SettingsView()
        .environment(ThemeManager())
        .modelContainer(for: [UserPreferences.self, JournalEntry.self, FavoriteAffirmation.self])
}
