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
                colors: [.purple.opacity(0.3), .pink.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
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
