import Foundation
import SwiftData

// MARK: - Mood

enum Mood: Int, Codable, CaseIterable, Identifiable {
    case veryLow = 1
    case low = 2
    case neutral = 3
    case good = 4
    case great = 5

    var id: Int { rawValue }

    var emoji: String {
        switch self {
        case .veryLow: return "😢"
        case .low: return "😔"
        case .neutral: return "😐"
        case .good: return "😊"
        case .great: return "🤩"
        }
    }

    var displayName: String {
        switch self {
        case .veryLow: return "Very Low"
        case .low: return "Low"
        case .neutral: return "Neutral"
        case .good: return "Good"
        case .great: return "Great"
        }
    }
}

// MARK: - JournalEntry (SwiftData Model)

@Model
final class JournalEntry {
    @Attribute(.unique) var id: UUID
    var text: String
    var date: Date
    var moodBeforeRaw: Int?
    var moodAfterRaw: Int?

    var moodBefore: Mood? {
        get { moodBeforeRaw.flatMap { Mood(rawValue: $0) } }
        set { moodBeforeRaw = newValue?.rawValue }
    }

    var moodAfter: Mood? {
        get { moodAfterRaw.flatMap { Mood(rawValue: $0) } }
        set { moodAfterRaw = newValue?.rawValue }
    }

    init(
        id: UUID = UUID(),
        text: String,
        date: Date = .now,
        moodBefore: Mood? = nil,
        moodAfter: Mood? = nil
    ) {
        self.id = id
        self.text = text
        self.date = date
        self.moodBeforeRaw = moodBefore?.rawValue
        self.moodAfterRaw = moodAfter?.rawValue
    }
}
