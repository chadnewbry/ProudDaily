import SwiftUI

enum PrideTheme: String, CaseIterable, Codable, Identifiable {
    case rainbow
    case trans
    case bisexual
    case pansexual
    case nonBinary
    case lesbian
    case asexual
    case sunset
    case pastelRainbow
    case ocean

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rainbow: return "Rainbow"
        case .trans: return "Trans"
        case .bisexual: return "Bisexual"
        case .pansexual: return "Pansexual"
        case .nonBinary: return "Non-Binary"
        case .lesbian: return "Lesbian"
        case .asexual: return "Asexual"
        case .sunset: return "Sunset"
        case .pastelRainbow: return "Pastel Rainbow"
        case .ocean: return "Ocean"
        }
    }

    var emoji: String {
        switch self {
        case .rainbow: return "🏳️‍🌈"
        case .trans: return "🏳️‍⚧️"
        case .bisexual: return "💗"
        case .pansexual: return "💛"
        case .nonBinary: return "💜"
        case .lesbian: return "🧡"
        case .asexual: return "🖤"
        case .sunset: return "🌅"
        case .pastelRainbow: return "🌸"
        case .ocean: return "🌊"
        }
    }

    func gradientColors(isDark: Bool) -> [Color] {
        let colors = rawGradientColors
        if isDark {
            return colors.map { $0.opacity(0.75) }
        }
        return colors
    }

    private var rawGradientColors: [Color] {
        switch self {
        case .rainbow:
            return [.prideRed, .prideOrange, .prideYellow, .prideGreen, .prideBlue, .prideViolet]
        case .trans:
            return [.transPink, .white, .transBlue]
        case .bisexual:
            return [.biPink, .biPurple, .biBlue]
        case .pansexual:
            return [.panPink, .panYellow, .panCyan]
        case .nonBinary:
            return [.nbYellow, .white, .nbPurple, .black]
        case .lesbian:
            return [.lesbianDarkOrange, .lesbianOrange, .white, .lesbianPink, .lesbianDarkPink]
        case .asexual:
            return [.black, .gray, .white, .acePurple]
        case .sunset:
            return [
                Color(red: 0.98, green: 0.40, blue: 0.20),
                Color(red: 0.95, green: 0.55, blue: 0.35),
                Color(red: 0.90, green: 0.45, blue: 0.55),
                Color(red: 0.65, green: 0.30, blue: 0.65)
            ]
        case .pastelRainbow:
            return [
                Color(red: 1.0, green: 0.70, blue: 0.70),
                Color(red: 1.0, green: 0.85, blue: 0.65),
                Color(red: 1.0, green: 1.0, blue: 0.70),
                Color(red: 0.70, green: 1.0, blue: 0.70),
                Color(red: 0.70, green: 0.80, blue: 1.0),
                Color(red: 0.85, green: 0.70, blue: 1.0)
            ]
        case .ocean:
            return [
                Color(red: 0.10, green: 0.70, blue: 0.65),
                Color(red: 0.15, green: 0.55, blue: 0.80),
                Color(red: 0.25, green: 0.45, blue: 0.70),
                Color(red: 0.35, green: 0.75, blue: 0.65)
            ]
        }
    }

    var accentColor: Color {
        switch self {
        case .rainbow: return .prideRed
        case .trans: return .transPink
        case .bisexual: return .biPink
        case .pansexual: return .panPink
        case .nonBinary: return .nbPurple
        case .lesbian: return .lesbianOrange
        case .asexual: return .acePurple
        case .sunset: return Color(red: 0.98, green: 0.40, blue: 0.20)
        case .pastelRainbow: return Color(red: 0.85, green: 0.70, blue: 1.0)
        case .ocean: return Color(red: 0.10, green: 0.70, blue: 0.65)
        }
    }

    var textColor: Color { .white }

    var widgetTintColor: Color { accentColor.opacity(0.3) }

    func gradient(isDark: Bool) -> LinearGradient {
        LinearGradient(
            colors: gradientColors(isDark: isDark),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Hex Colors (for widget sync)

extension PrideTheme {
    var gradientHexColors: [String] {
        switch self {
        case .rainbow: return ["#E40303", "#FF8C00", "#FFED00", "#008026", "#004DFF", "#750787"]
        case .trans: return ["#5BCEFA", "#F5A9B8", "#FFFFFF", "#F5A9B8", "#5BCEFA"]
        case .bisexual: return ["#D60270", "#9B4F96", "#0038A8"]
        case .pansexual: return ["#FF218C", "#FFD800", "#21B1FF"]
        case .nonBinary: return ["#FCF434", "#FFFFFF", "#9C59D1", "#2C2C2C"]
        case .lesbian: return ["#D52D00", "#FF9A56", "#FFFFFF", "#D462A6", "#A30262"]
        case .asexual: return ["#000000", "#A3A3A3", "#FFFFFF", "#800080"]
        case .sunset: return ["#FF6B35", "#F7931E", "#FFD700", "#FF4500"]
        case .pastelRainbow: return ["#FFB3BA", "#FFDFBA", "#FFFFBA", "#BAFFC9", "#BAE1FF", "#D4BAFF"]
        case .ocean: return ["#1AB3A5", "#268CCC", "#4073B3", "#59BFA5"]
        }
    }

    var accentHex: String {
        switch self {
        case .rainbow: return "#750787"
        case .trans: return "#5BCEFA"
        case .bisexual: return "#9B4F96"
        case .pansexual: return "#FF218C"
        case .nonBinary: return "#9C59D1"
        case .lesbian: return "#D462A6"
        case .asexual: return "#800080"
        case .sunset: return "#FF6B35"
        case .pastelRainbow: return "#D4BAFF"
        case .ocean: return "#1AB3A5"
        }
    }
}
