import SwiftUI

// MARK: - Widget Theme (standalone, no dependency on main app)

enum WidgetTheme {
    static func gradientColors(for themeRaw: String) -> [Color] {
        switch themeRaw {
        case "rainbow":
            return [
                Color(red: 0.89, green: 0.01, blue: 0.01),
                Color(red: 1.0, green: 0.55, blue: 0.0),
                Color(red: 1.0, green: 0.93, blue: 0.0),
                Color(red: 0.0, green: 0.50, blue: 0.15),
                Color(red: 0.0, green: 0.30, blue: 0.77),
                Color(red: 0.46, green: 0.03, blue: 0.53)
            ]
        case "trans":
            return [
                Color(red: 0.96, green: 0.66, blue: 0.72),
                .white,
                Color(red: 0.36, green: 0.81, blue: 0.98)
            ]
        case "bisexual", "bi":
            return [
                Color(red: 0.84, green: 0.0, blue: 0.44),
                Color(red: 0.61, green: 0.31, blue: 0.64),
                Color(red: 0.0, green: 0.22, blue: 0.66)
            ]
        case "pansexual", "pan":
            return [
                Color(red: 1.0, green: 0.09, blue: 0.55),
                Color(red: 1.0, green: 0.84, blue: 0.0),
                Color(red: 0.13, green: 0.69, blue: 0.93)
            ]
        case "nonBinary", "nonbinary":
            return [
                Color(red: 0.99, green: 0.95, blue: 0.20),
                .white,
                Color(red: 0.61, green: 0.35, blue: 0.82),
                .black
            ]
        case "lesbian":
            return [
                Color(red: 0.83, green: 0.18, blue: 0.0),
                Color(red: 0.99, green: 0.60, blue: 0.32),
                .white,
                Color(red: 0.84, green: 0.37, blue: 0.56),
                Color(red: 0.64, green: 0.03, blue: 0.33)
            ]
        case "asexual":
            return [.black, .gray, .white, Color(red: 0.50, green: 0.0, blue: 0.50)]
        case "sunset":
            return [
                Color(red: 0.98, green: 0.40, blue: 0.20),
                Color(red: 0.95, green: 0.55, blue: 0.35),
                Color(red: 0.90, green: 0.45, blue: 0.55),
                Color(red: 0.65, green: 0.30, blue: 0.65)
            ]
        case "pastelRainbow":
            return [
                Color(red: 1.0, green: 0.70, blue: 0.70),
                Color(red: 1.0, green: 0.85, blue: 0.65),
                Color(red: 1.0, green: 1.0, blue: 0.70),
                Color(red: 0.70, green: 1.0, blue: 0.70),
                Color(red: 0.70, green: 0.80, blue: 1.0),
                Color(red: 0.85, green: 0.70, blue: 1.0)
            ]
        case "ocean", "nature":
            return [
                Color(red: 0.10, green: 0.70, blue: 0.65),
                Color(red: 0.15, green: 0.55, blue: 0.80),
                Color(red: 0.25, green: 0.45, blue: 0.70),
                Color(red: 0.35, green: 0.75, blue: 0.65)
            ]
        default:
            return [.purple, .pink]
        }
    }

    static func gradient(for themeRaw: String) -> LinearGradient {
        LinearGradient(
            colors: gradientColors(for: themeRaw).map { $0.opacity(0.85) },
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func accentColor(for themeRaw: String) -> Color {
        switch themeRaw {
        case "rainbow": return Color(red: 0.89, green: 0.01, blue: 0.01)
        case "trans": return Color(red: 0.96, green: 0.66, blue: 0.72)
        case "bisexual", "bi": return Color(red: 0.84, green: 0.0, blue: 0.44)
        case "pansexual", "pan": return Color(red: 1.0, green: 0.09, blue: 0.55)
        case "nonBinary", "nonbinary": return Color(red: 0.61, green: 0.35, blue: 0.82)
        case "lesbian": return Color(red: 0.99, green: 0.60, blue: 0.32)
        case "asexual": return Color(red: 0.50, green: 0.0, blue: 0.50)
        case "sunset": return Color(red: 0.98, green: 0.40, blue: 0.20)
        case "pastelRainbow": return Color(red: 0.85, green: 0.70, blue: 1.0)
        case "ocean", "nature": return Color(red: 0.10, green: 0.70, blue: 0.65)
        default: return .purple
        }
    }
}
