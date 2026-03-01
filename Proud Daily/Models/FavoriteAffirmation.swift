import Foundation
import SwiftData

@Model
final class FavoriteAffirmation {
    @Attribute(.unique) var id: UUID
    var affirmation: Affirmation?
    var savedAt: Date

    init(id: UUID = UUID(), affirmation: Affirmation? = nil, savedAt: Date = .now) {
        self.id = id
        self.affirmation = affirmation
        self.savedAt = savedAt
    }
}
