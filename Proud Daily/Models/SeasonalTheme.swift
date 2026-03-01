import SwiftUI

struct SeasonalTheme: Identifiable {
    let id: String
    let displayName: String
    let emoji: String
    let gradientColors: [Color]
    let accentColor: Color
    let startMonth: Int
    let startDay: Int
    let endMonth: Int
    let endDay: Int

    var isCurrentlyActive: Bool {
        let cal = Calendar.current
        let now = Date()
        let month = cal.component(.month, from: now)
        let day = cal.component(.day, from: now)

        if startMonth == endMonth {
            return month == startMonth && day >= startDay && day <= endDay
        }
        if month == startMonth { return day >= startDay }
        if month == endMonth { return day <= endDay }
        return month > startMonth && month < endMonth
    }

    func gradient(isDark: Bool) -> LinearGradient {
        let colors = isDark ? gradientColors.map { $0.opacity(0.75) } : gradientColors
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static let all: [SeasonalTheme] = [
        SeasonalTheme(
            id: "prideMonth",
            displayName: "Pride Month",
            emoji: "✨",
            gradientColors: [
                Color(red: 1.0, green: 0.0, blue: 0.0),
                Color(red: 1.0, green: 0.5, blue: 0.0),
                Color(red: 1.0, green: 1.0, blue: 0.0),
                Color(red: 0.0, green: 0.8, blue: 0.0),
                Color(red: 0.0, green: 0.4, blue: 1.0),
                Color(red: 0.6, green: 0.0, blue: 0.8)
            ],
            accentColor: Color(red: 1.0, green: 0.85, blue: 0.0),
            startMonth: 6, startDay: 1,
            endMonth: 6, endDay: 30
        ),
        SeasonalTheme(
            id: "comingOutDay",
            displayName: "Coming Out Day",
            emoji: "🚪",
            gradientColors: [
                Color(red: 0.95, green: 0.75, blue: 0.20),
                Color(red: 0.90, green: 0.35, blue: 0.45),
                Color(red: 0.55, green: 0.20, blue: 0.70)
            ],
            accentColor: Color(red: 0.95, green: 0.75, blue: 0.20),
            startMonth: 10, startDay: 8,
            endMonth: 10, endDay: 14
        ),
        SeasonalTheme(
            id: "transVisibility",
            displayName: "Trans Day of Visibility",
            emoji: "🏳️‍⚧️",
            gradientColors: [
                Color(red: 0.96, green: 0.66, blue: 0.72),
                .white,
                Color(red: 0.36, green: 0.81, blue: 0.98),
                Color(red: 0.85, green: 0.75, blue: 0.10)
            ],
            accentColor: Color(red: 0.85, green: 0.75, blue: 0.10),
            startMonth: 3, startDay: 28,
            endMonth: 4, endDay: 3
        )
    ]

    static var currentlyActive: [SeasonalTheme] {
        all.filter { $0.isCurrentlyActive }
    }
}
