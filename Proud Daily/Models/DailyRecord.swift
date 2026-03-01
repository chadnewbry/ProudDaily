import Foundation
import SwiftData

@Model
final class DailyRecord {
    @Attribute(.unique) var id: UUID
    var date: Date
    var moodBeforeRaw: Int?
    var moodAfterRaw: Int?
    var journalEntry: JournalEntry?
    var minutesPracticed: Double

    @Relationship var affirmationsViewed: [Affirmation]?

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
        date: Date = .now,
        moodBefore: Mood? = nil,
        moodAfter: Mood? = nil,
        journalEntry: JournalEntry? = nil,
        minutesPracticed: Double = 0
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.moodBeforeRaw = moodBefore?.rawValue
        self.moodAfterRaw = moodAfter?.rawValue
        self.journalEntry = journalEntry
        self.minutesPracticed = minutesPracticed
    }
}
