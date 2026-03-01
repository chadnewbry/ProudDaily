import WidgetKit
import SwiftUI

struct ProudDailyWidgetEntry: TimelineEntry {
    let date: Date
    let affirmation: String
}

struct ProudDailyWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ProudDailyWidgetEntry {
        ProudDailyWidgetEntry(date: .now, affirmation: "You are worthy of love.")
    }

    func getSnapshot(in context: Context, completion: @escaping (ProudDailyWidgetEntry) -> Void) {
        completion(ProudDailyWidgetEntry(date: .now, affirmation: "You are worthy of love and belonging."))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ProudDailyWidgetEntry>) -> Void) {
        let entry = ProudDailyWidgetEntry(date: .now, affirmation: "You are worthy of love and belonging, exactly as you are.")
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 6, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct ProudDailyWidgetView: View {
    var entry: ProudDailyWidgetEntry

    private var widgetGradientColors: [Color] {
        let themeRaw = UserDefaults.standard.string(forKey: "theme.pride") ?? "rainbow"
        return Self.colorsForTheme(themeRaw)
    }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.title2)
            Text(entry.affirmation)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .padding()
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: widgetGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private static func colorsForTheme(_ name: String) -> [Color] {
        switch name {
        case "rainbow":
            return [.red.opacity(0.3), .orange.opacity(0.3), .yellow.opacity(0.3), .green.opacity(0.3), .blue.opacity(0.3), .purple.opacity(0.3)]
        case "trans":
            return [Color(red: 0.96, green: 0.66, blue: 0.72).opacity(0.3), .white.opacity(0.3), Color(red: 0.36, green: 0.81, blue: 0.98).opacity(0.3)]
        case "bisexual":
            return [Color(red: 0.84, green: 0.0, blue: 0.44).opacity(0.3), Color(red: 0.61, green: 0.31, blue: 0.64).opacity(0.3), Color(red: 0.0, green: 0.22, blue: 0.66).opacity(0.3)]
        case "ocean":
            return [Color(red: 0.10, green: 0.70, blue: 0.65).opacity(0.3), Color(red: 0.15, green: 0.55, blue: 0.80).opacity(0.3)]
        default:
            return [.purple.opacity(0.3), .pink.opacity(0.3)]
        }
    }
}

@main
struct ProudDailyWidget: Widget {
    let kind = "ProudDailyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ProudDailyWidgetProvider()) { entry in
            ProudDailyWidgetView(entry: entry)
        }
        .configurationDisplayName("Daily Affirmation")
        .description("See your daily affirmation at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}
