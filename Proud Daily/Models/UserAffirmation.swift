import Foundation
import SwiftData

@Model
final class UserAffirmation {
    @Attribute(.unique) var id: UUID
    var text: String
    var collection: UserCollection?
    var createdAt: Date

    init(id: UUID = UUID(), text: String, collection: UserCollection? = nil, createdAt: Date = .now) {
        self.id = id
        self.text = text
        self.collection = collection
        self.createdAt = createdAt
    }
}
