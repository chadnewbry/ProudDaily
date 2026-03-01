import UIKit
import Foundation
import SwiftData
import UserNotifications

@Observable
final class NotificationManager: NSObject {
    static let shared = NotificationManager()

    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var isPermissionDenied: Bool { authorizationStatus == .denied }

    private static let notificationIdPrefix = "prouddaily.affirmation."
    private static let maxSlots = 5

    @ObservationIgnored
    private var recentAffirmationIds: [UUID] {
        get { (UserDefaults.standard.array(forKey: "recentNotificationAffirmationIds") as? [String])?.compactMap { UUID(uuidString: $0) } ?? [] }
        set { UserDefaults.standard.set(newValue.map(\.uuidString), forKey: "recentNotificationAffirmationIds") }
    }

    private override init() {
        super.init()
    }

    // MARK: - Authorization

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run { authorizationStatus = settings.authorizationStatus }
    }

    @discardableResult
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            await refreshAuthorizationStatus()
            return granted
        } catch {
            await refreshAuthorizationStatus()
            return false
        }
    }

    // MARK: - Scheduling

    func rescheduleAll(preferences: UserPreferences, modelContext: ModelContext) async {
        let ids = (0..<Self.maxSlots).map { "\(Self.notificationIdPrefix)\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)

        await refreshAuthorizationStatus()
        guard authorizationStatus == .authorized else { return }

        let times = Array(preferences.notificationTimes.prefix(Self.maxSlots))
        guard !times.isEmpty else { return }

        let categories = preferences.selectedCategories
        let discreet = preferences.discreetModeEnabled

        for (index, time) in times.enumerated() {
            let affirmation = pickAffirmation(categories: categories, modelContext: modelContext)
            let content = buildContent(
                for: affirmation,
                time: time,
                discreet: discreet
            )

            let components = Calendar.current.dateComponents([.hour, .minute], from: time)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

            let request = UNNotificationRequest(
                identifier: "\(Self.notificationIdPrefix)\(index)",
                content: content,
                trigger: trigger
            )

            try? await UNUserNotificationCenter.current().add(request)
        }
    }

    // MARK: - Badge

    func updateBadgeCount(modelContext: ModelContext) async {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        let descriptor = FetchDescriptor<DailyRecord>(
            predicate: #Predicate<DailyRecord> { $0.date >= startOfDay }
        )
        let todayRecord = (try? modelContext.fetch(descriptor))?.first
        let viewedCount = todayRecord?.affirmationsViewed?.count ?? 0

        let pendingRequests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let scheduledCount = pendingRequests.filter { $0.identifier.hasPrefix(Self.notificationIdPrefix) }.count
        let unviewed = max(scheduledCount - viewedCount, 0)

        try? await UNUserNotificationCenter.current().setBadgeCount(unviewed)
    }

    // MARK: - Settings Deep Link

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Private Helpers

    private func pickAffirmation(categories: [AffirmationCategory], modelContext: ModelContext) -> Affirmation? {
        let descriptor = FetchDescriptor<Affirmation>(
            predicate: #Predicate<Affirmation> { $0.isCustom == false }
        )
        guard let all = try? modelContext.fetch(descriptor), !all.isEmpty else { return nil }

        let filtered: [Affirmation]
        if !categories.isEmpty {
            let rawValues = Set(categories.map(\.rawValue))
            filtered = all.filter { rawValues.contains($0.categoryRaw) }
        } else {
            filtered = all
        }

        guard !filtered.isEmpty else { return all.randomElement() }

        let recentIds = Set(recentAffirmationIds)
        let fresh = filtered.filter { !recentIds.contains($0.id) }
        let pick = (fresh.isEmpty ? filtered : fresh).randomElement()

        if let pick {
            var recent = recentAffirmationIds
            recent.append(pick.id)
            if recent.count > min(filtered.count / 2, 20) {
                recent.removeFirst()
            }
            recentAffirmationIds = recent
        }

        return pick
    }

    private func buildContent(
        for affirmation: Affirmation?,
        time: Date,
        discreet: Bool
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.sound = .default

        let hour = Calendar.current.component(.hour, from: time)
        let isMorning = hour >= 5 && hour < 10
        let isBedtime = hour >= 21 || hour < 5

        if discreet {
            content.title = "Daily Reminder"
            content.body = "Take a moment for yourself"
        } else if isMorning {
            content.title = "Morning Affirmation ☀️"
            content.body = affirmation?.text ?? "You are worthy of a beautiful day."
        } else if isBedtime {
            content.title = "Bedtime Wind-Down 🌙"
            content.body = affirmation?.text ?? "You are safe, you are loved, you are enough."
        } else {
            content.title = "Proud Daily 🏳️‍🌈"
            content.body = affirmation?.text ?? "You are valid and worthy of love."
        }

        if let affirmation {
            content.userInfo = ["affirmationId": affirmation.id.uuidString]
        }

        return content
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        if let idString = userInfo["affirmationId"] as? String {
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .didTapAffirmationNotification,
                    object: nil,
                    userInfo: ["affirmationId": idString]
                )
            }
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }
}

extension Notification.Name {
    static let didTapAffirmationNotification = Notification.Name("didTapAffirmationNotification")
}
