import Foundation

struct JournalEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    var text: String
    let affirmationId: UUID?

    init(id: UUID = UUID(), date: Date = .now, text: String, affirmationId: UUID? = nil) {
        self.id = id
        self.date = date
        self.text = text
        self.affirmationId = affirmationId
    }
}
