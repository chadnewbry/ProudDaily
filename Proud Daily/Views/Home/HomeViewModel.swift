import Foundation
import SwiftUI
import SwiftData
import Observation

@Observable
final class HomeViewModel {
    // MARK: - State

    var dailyAffirmation: Affirmation?
    var browseAffirmations: [Affirmation] = []
    var currentIndex: Int = 0
    var revealProgress: CGFloat = 0.0
    var isRevealed: Bool = false
    var isHolding: Bool = false
    var showConfetti: Bool = false
    var currentStreak: Int = 0
    var isMilestone: Bool = false

    // MARK: - Dependencies

    private var modelContext: ModelContext?
    private var dataManager: DataManager?
    private var affirmationService: AffirmationService?

    // MARK: - Persistence Keys

    private let dailyAffirmationIdKey = "dailyAffirmationId"
    private let dailyAffirmationDateKey = "dailyAffirmationDate"
    private let dailyRevealedKey = "dailyRevealed"
    private let dailyRevealedDateKey = "dailyRevealedDate"

    // MARK: - Session Tracking

    private var sessionStartTime: Date?

    // MARK: - Milestone Days

    static let milestoneDays: Set<Int> = [7, 14, 30, 60, 90, 180, 365]

    // MARK: - Setup

    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.dataManager = DataManager(modelContext: modelContext)
        self.affirmationService = AffirmationService(modelContext: modelContext)
        loadDailyAffirmation()
        loadStreak()
    }

    // MARK: - Daily Affirmation

    private func loadDailyAffirmation() {
        guard let dataManager, let affirmationService, let modelContext else { return }

        let prefs = dataManager.getOrCreatePreferences()
        let today = Calendar.current.startOfDay(for: .now)

        // Check if we already have a persisted daily affirmation for today
        if let savedDateInterval = UserDefaults.standard.object(forKey: dailyAffirmationDateKey) as? TimeInterval,
           let savedId = UserDefaults.standard.string(forKey: dailyAffirmationIdKey) {
            let savedDate = Calendar.current.startOfDay(for: Date(timeIntervalSince1970: savedDateInterval))
            if savedDate == today, let uuid = UUID(uuidString: savedId) {
                let descriptor = FetchDescriptor<Affirmation>(
                    predicate: #Predicate<Affirmation> { $0.id == uuid }
                )
                if let found = try? modelContext.fetch(descriptor).first {
                    dailyAffirmation = found
                    loadRevealState(for: today)
                    loadBrowseAffirmations(prefs: prefs)
                    return
                }
            }
        }

        // Select a new daily affirmation
        affirmationService.selectTodaysAffirmation(
            mood: nil,
            selectedCategories: prefs.selectedCategories
        )

        if let selected = affirmationService.todaysAffirmation {
            dailyAffirmation = selected
            UserDefaults.standard.set(selected.id.uuidString, forKey: dailyAffirmationIdKey)
            UserDefaults.standard.set(today.timeIntervalSince1970, forKey: dailyAffirmationDateKey)
        }

        loadRevealState(for: today)
        loadBrowseAffirmations(prefs: prefs)
    }

    private func loadRevealState(for today: Date) {
        if let savedDateInterval = UserDefaults.standard.object(forKey: dailyRevealedDateKey) as? TimeInterval {
            let savedDate = Calendar.current.startOfDay(for: Date(timeIntervalSince1970: savedDateInterval))
            if savedDate == today {
                isRevealed = UserDefaults.standard.bool(forKey: dailyRevealedKey)
                revealProgress = isRevealed ? 1.0 : 0.0
            } else {
                isRevealed = false
                revealProgress = 0.0
            }
        }
    }

    private func loadBrowseAffirmations(prefs: UserPreferences) {
        guard let affirmationService else { return }
        let extras = affirmationService.moodBasedAffirmations(
            mood: nil,
            selectedCategories: prefs.selectedCategories,
            count: 20
        ).filter { $0.id != dailyAffirmation?.id }

        if let daily = dailyAffirmation {
            browseAffirmations = [daily] + extras
        } else {
            browseAffirmations = extras
        }
        currentIndex = 0
    }

    // MARK: - Reveal

    func completeReveal() {
        guard !isRevealed else { return }
        isRevealed = true
        revealProgress = 1.0

        let today = Calendar.current.startOfDay(for: .now)
        UserDefaults.standard.set(true, forKey: dailyRevealedKey)
        UserDefaults.standard.set(today.timeIntervalSince1970, forKey: dailyRevealedDateKey)

        // Record the view and decrement free uses
        if let affirmation = dailyAffirmation {
            dataManager?.recordAffirmationViewed(affirmation)
        }

        if let dataManager {
            let prefs = dataManager.getOrCreatePreferences()
            if !prefs.hasPurchasedPremium && prefs.freeUsesRemaining > 0 {
                prefs.freeUsesRemaining -= 1
            }
        }

        // Haptic
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Update streak
        _ = dataManager?.getOrCreateTodayRecord()
        loadStreak()

        // Check milestone
        if Self.milestoneDays.contains(currentStreak) {
            isMilestone = true
            showConfetti = true
        }
    }

    // MARK: - Streak

    private func loadStreak() {
        currentStreak = dataManager?.calculateCurrentStreak() ?? 0
    }

    // MARK: - Favorites

    func toggleFavorite(for affirmation: Affirmation) {
        dataManager?.toggleFavorite(affirmation: affirmation)
    }

    func isFavorite(_ affirmation: Affirmation) -> Bool {
        dataManager?.isFavorite(affirmation) ?? false
    }

    // MARK: - Session Tracking

    func startSession() {
        sessionStartTime = .now
    }

    func endSession() {
        guard let start = sessionStartTime else { return }
        let minutes = Date.now.timeIntervalSince(start) / 60.0
        if minutes > 0.05 { // at least 3 seconds
            dataManager?.addPracticeTime(minutes)
        }
        sessionStartTime = nil
    }

    // MARK: - Share Image

    @MainActor
    func generateShareImage(affirmation: Affirmation, theme: PrideTheme, size: CGSize = CGSize(width: 1080, height: 1920)) -> UIImage? {
        let colors = theme.gradientHexColors.map { Color(hex: $0) }
        let view = ShareCardView(text: affirmation.text, colors: colors)
            .frame(width: size.width, height: size.height)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0
        return renderer.uiImage
    }

    // MARK: - Computed Properties

    var currentAffirmation: Affirmation? {
        guard !browseAffirmations.isEmpty,
              currentIndex >= 0,
              currentIndex < browseAffirmations.count else {
            return dailyAffirmation
        }
        return browseAffirmations[currentIndex]
    }

    var canSwipe: Bool { isRevealed }

    var freeUsesRemaining: Int {
        dataManager?.getOrCreatePreferences().freeUsesRemaining ?? 0
    }

    var hasPurchasedPremium: Bool {
        dataManager?.getOrCreatePreferences().hasPurchasedPremium ?? false
    }

    var selectedTheme: PrideTheme {
        dataManager?.getOrCreatePreferences().selectedTheme ?? .rainbow
    }

    var fontScale: CGFloat {
        dataManager?.getOrCreatePreferences().fontSize.scaleFactor ?? 1.0
    }
}

// MARK: - Color hex init

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        default:
            r = 1; g = 1; b = 1
        }
        self.init(red: r, green: g, blue: b)
    }
}
