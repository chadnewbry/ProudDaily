import Foundation
import SwiftData

@Model
final class UserCollection {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \UserAffirmation.collection)
    var affirmations: [UserAffirmation]?

    /// IDs of curated (non-custom) affirmations added to this collection
    var curatedAffirmationIds: [UUID]

    var totalCount: Int {
        (affirmations?.count ?? 0) + curatedAffirmationIds.count
    }

    init(id: UUID = UUID(), name: String, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.curatedAffirmationIds = []
    }
}
