import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Timeline Entry

struct ProudDailyEntry: TimelineEntry {
    let date: Date
    let affirmation: WidgetAffirmation
    let themeRaw: String
    let streak: Int
    let isDiscreet: Bool
}

// MARK: - Timeline Provider

struct ProudDailyTimelineProvider: AppIntentTimelineProvider {
    private let store = WidgetDataStore.shared

    func placeholder(in context: Context) -> ProudDailyEntry {
        ProudDailyEntry(
            date: .now,
            affirmation: WidgetAffirmation(text: "You are worthy of love and belonging.", category: "General Wellness", categoryEmoji: "🌿"),
            themeRaw: "rainbow",
            streak: 7,
            isDiscreet: false
        )
    }

    func snapshot(for configuration: CategorySelectionIntent, in context: Context) async -> ProudDailyEntry {
        makeEntry(at: .now, configuration: configuration)
    }

    func timeline(for configuration: CategorySelectionIntent, in context: Context) async -> Timeline<ProudDailyEntry> {
        let now = Date()
        let calendar = Calendar.current

        // Generate 6 entries (every 4 hours)
        var entries: [ProudDailyEntry] = []
        let pool = filteredPool(for: configuration)

        for i in 0..<6 {
            guard let entryDate = calendar.date(byAdding: .hour, value: i * 4, to: startOfCurrentPeriod(from: now)) else { continue }
            let index = i % max(pool.count, 1)
            let affirmation = pool.isEmpty
                ? WidgetAffirmation(text: "You are worthy of love.", category: "Wellness", categoryEmoji: "🌿")
                : pool[index]

            entries.append(ProudDailyEntry(
                date: entryDate,
                affirmation: store.isDiscreetMode ? discreetAffirmation(index: index) : affirmation,
                themeRaw: store.themeRaw,
                streak: store.streakCount,
                isDiscreet: store.isDiscreetMode
            ))
        }

        // Refresh at midnight
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now)!)
        return Timeline(entries: entries, policy: .after(tomorrow))
    }

    // MARK: - Helpers

    private func makeEntry(at date: Date, configuration: CategorySelectionIntent) -> ProudDailyEntry {
        let pool = filteredPool(for: configuration)
        let affirmation = pool.first ?? store.currentAffirmation
        return ProudDailyEntry(
            date: date,
            affirmation: store.isDiscreetMode ? discreetAffirmation(index: 0) : affirmation,
            themeRaw: store.themeRaw,
            streak: store.streakCount,
            isDiscreet: store.isDiscreetMode
        )
    }

    private func filteredPool(for configuration: CategorySelectionIntent) -> [WidgetAffirmation] {
        let pool = store.affirmationPool
        guard configuration.category != .all else { return pool }
        let categoryName = displayName(for: configuration.category)
        let filtered = pool.filter { $0.category == categoryName }
        return filtered.isEmpty ? pool : filtered
    }

    private func discreetAffirmation(index: Int) -> WidgetAffirmation {
        let fallbacks = WidgetAffirmation.discreetFallbacks
        return fallbacks[index % fallbacks.count]
    }

    private func startOfCurrentPeriod(from date: Date) -> Date {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let periodStart = (hour / 4) * 4
        return calendar.date(bySettingHour: periodStart, minute: 0, second: 0, of: date) ?? date
    }

    private func displayName(for option: WidgetCategoryOption) -> String {
        switch option {
        case .all: return "All"
        case .comingOut: return "Coming Out"
        case .selfAcceptance: return "Self-Acceptance"
        case .chosenFamily: return "Chosen Family"
        case .queerJoy: return "Queer Joy"
        case .resilience: return "Resilience"
        case .queerLove: return "Queer Love"
        case .bodyPositivity: return "Body Positivity"
        case .transNonBinary: return "Trans & Non-Binary"
        case .generalWellness: return "General Wellness"
        }
    }
}

// MARK: - Home Screen Views

struct SmallWidgetView: View {
    let entry: ProudDailyEntry

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.9))

            Text(entry.affirmation.text)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(4)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            WidgetTheme.gradient(for: entry.themeRaw)
        }
        .widgetURL(URL(string: "prouddaily://home"))
    }
}

struct MediumWidgetView: View {
    let entry: ProudDailyEntry

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text(entry.affirmation.categoryEmoji)
                        .font(.caption2)
                    Text(entry.affirmation.category)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Text(entry.affirmation.text)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Image(systemName: "sparkles")
                .font(.title)
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            WidgetTheme.gradient(for: entry.themeRaw)
        }
        .widgetURL(URL(string: "prouddaily://home"))
    }
}

struct LargeWidgetView: View {
    let entry: ProudDailyEntry

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Top decorative bar
                HStack {
                    ForEach(Array(WidgetTheme.gradientColors(for: entry.themeRaw).enumerated()), id: \.offset) { _, color in
                        Rectangle()
                            .fill(color)
                            .frame(height: 4)
                    }
                }

                Spacer()
            }

            VStack(spacing: 12) {
                Spacer()

                HStack(spacing: 4) {
                    Text(entry.affirmation.categoryEmoji)
                        .font(.footnote)
                    Text(entry.affirmation.category)
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Text(entry.affirmation.text)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                Spacer()

                if entry.streak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text("\(entry.streak) day streak")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.bottom, 8)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            WidgetTheme.gradient(for: entry.themeRaw)
        }
        .widgetURL(URL(string: "prouddaily://home"))
    }
}

// MARK: - Lock Screen Views

struct CircularLockScreenView: View {
    let entry: ProudDailyEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 1) {
                Image(systemName: "sparkles")
                    .font(.caption)
                if entry.streak > 0 {
                    Text("\(entry.streak)")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
            }
        }
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(URL(string: "prouddaily://home"))
    }
}

struct RectangularLockScreenView: View {
    let entry: ProudDailyEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.caption2)
                Text("Proud Daily")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            Text(entry.affirmation.text)
                .font(.caption)
                .lineLimit(2)
        }
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(URL(string: "prouddaily://home"))
    }
}

struct InlineLockScreenView: View {
    let entry: ProudDailyEntry

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
            Text(entry.affirmation.text)
                .lineLimit(1)
        }
        .containerBackground(for: .widget) { Color.clear }
    }
}

// MARK: - Widget Entry View (dispatches by family)

struct ProudDailyWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: ProudDailyEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge, .systemExtraLarge:
            LargeWidgetView(entry: entry)
        case .accessoryCircular:
            CircularLockScreenView(entry: entry)
        case .accessoryRectangular:
            RectangularLockScreenView(entry: entry)
        case .accessoryInline:
            InlineLockScreenView(entry: entry)
        @unknown default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Bundle

@main
struct ProudDailyWidgetBundle: WidgetBundle {
    var body: some Widget {
        ProudDailyAffirmationWidget()
        ProudDailyStandByWidget()
    }
}

// MARK: - Main Affirmation Widget

struct ProudDailyAffirmationWidget: Widget {
    let kind = "ProudDailyWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: CategorySelectionIntent.self,
            provider: ProudDailyTimelineProvider()
        ) { entry in
            ProudDailyWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Affirmation")
        .description("See your daily pride affirmation at a glance.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
        ])
    }
}

// MARK: - StandBy Widget

struct StandByWidgetView: View {
    let entry: ProudDailyEntry

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.8))

                Text(entry.affirmation.text)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .minimumScaleFactor(0.6)

                HStack(spacing: 4) {
                    Text(entry.affirmation.categoryEmoji)
                        .font(.footnote)
                    Text(entry.affirmation.category)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            WidgetTheme.gradient(for: entry.themeRaw)
        }
    }
}

struct ProudDailyStandByWidget: Widget {
    let kind = "ProudDailyStandByWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: CategorySelectionIntent.self,
            provider: ProudDailyTimelineProvider()
        ) { entry in
            StandByWidgetView(entry: entry)
        }
        .configurationDisplayName("StandBy Affirmation")
        .description("Full-screen pride affirmation for StandBy mode.")
        .supportedFamilies([.systemLarge, .systemExtraLarge])
    }
}
