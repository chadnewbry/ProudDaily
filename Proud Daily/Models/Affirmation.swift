import Foundation
import SwiftData
import SwiftUI

// MARK: - AffirmationCategory

enum AffirmationCategory: String, CaseIterable, Codable, Hashable, Identifiable {
    case comingOut
    case selfAcceptance
    case chosenFamily
    case queerJoy
    case resilience
    case queerLove
    case bodyPositivity
    case transNonBinary
    case generalWellness

    var id: String { rawValue }

    var displayName: String {
        switch self {
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

    var emoji: String {
        switch self {
        case .comingOut: return "🚪"
        case .selfAcceptance: return "🪞"
        case .chosenFamily: return "👨‍👩‍👧‍👦"
        case .queerJoy: return "🎉"
        case .resilience: return "💪"
        case .queerLove: return "💕"
        case .bodyPositivity: return "✨"
        case .transNonBinary: return "🏳️‍⚧️"
        case .generalWellness: return "🌿"
        }
    }

    var description: String {
        switch self {
        case .comingOut: return "Affirmations for the courage of living authentically"
        case .selfAcceptance: return "Embracing every part of who you are"
        case .chosenFamily: return "Celebrating the people who truly see you"
        case .queerJoy: return "Finding and amplifying moments of pride and happiness"
        case .resilience: return "Strength through adversity and growth"
        case .queerLove: return "Honoring love in all its beautiful forms"
        case .bodyPositivity: return "Loving and respecting your body as it is"
        case .transNonBinary: return "Affirming gender identity and expression"
        case .generalWellness: return "Mindfulness, peace, and daily well-being"
        }
    }

    var color: Color {
        switch self {
        case .comingOut: return .prideOrange
        case .selfAcceptance: return .prideViolet
        case .chosenFamily: return .prideGreen
        case .queerJoy: return .prideYellow
        case .resilience: return .prideRed
        case .queerLove: return .transPink
        case .bodyPositivity: return .panCyan
        case .transNonBinary: return .transBlue
        case .generalWellness: return .prideBlue
        }
    }
}

// MARK: - Affirmation (SwiftData Model)

@Model
final class Affirmation {
    @Attribute(.unique) var id: UUID
    var text: String
    var categoryRaw: String
    var isCustom: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \FavoriteAffirmation.affirmation)
    var favorites: [FavoriteAffirmation]?

    var category: AffirmationCategory {
        get { AffirmationCategory(rawValue: categoryRaw) ?? .generalWellness }
        set { categoryRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        text: String,
        category: AffirmationCategory,
        isCustom: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.text = text
        self.categoryRaw = category.rawValue
        self.isCustom = isCustom
        self.createdAt = createdAt
    }
}
