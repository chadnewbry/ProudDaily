import SwiftUI

enum FontTheme: String, CaseIterable, Codable, Identifiable {
    case system
    case rounded
    case serif
    case handwritten
    case boldDisplay

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System Default"
        case .rounded: return "Rounded"
        case .serif: return "Serif"
        case .handwritten: return "Handwritten"
        case .boldDisplay: return "Bold Display"
        }
    }

    var previewText: String { "Proud Daily ✨" }

    func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch self {
        case .system:
            return .system(size: size, weight: weight)
        case .rounded:
            return .system(size: size, weight: weight, design: .rounded)
        case .serif:
            return .system(size: size, weight: weight, design: .serif)
        case .handwritten:
            return .custom("Snell Roundhand", size: size)
        case .boldDisplay:
            return .system(size: size, weight: .heavy, design: .rounded)
        }
    }
}

enum TextSizePreference: String, CaseIterable, Codable, Identifiable {
    case compact
    case standard
    case large

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .compact: return "Compact"
        case .standard: return "Default"
        case .large: return "Large"
        }
    }

    var scaleFactor: CGFloat {
        switch self {
        case .compact: return 0.85
        case .standard: return 1.0
        case .large: return 1.2
        }
    }
}
