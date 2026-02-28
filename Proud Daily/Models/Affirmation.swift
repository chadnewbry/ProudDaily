import Foundation

struct Affirmation: Identifiable, Codable {
    let id: UUID
    let text: String
    let category: AffirmationCategory
    let author: String?

    init(id: UUID = UUID(), text: String, category: AffirmationCategory, author: String? = nil) {
        self.id = id
        self.text = text
        self.category = category
        self.author = author
    }
}

enum AffirmationCategory: String, CaseIterable, Codable, Hashable {
    case selfLove = "Self Love"
    case identity = "Identity"
    case community = "Community"
    case resilience = "Resilience"
    case joy = "Joy"
    case relationships = "Relationships"

    var icon: String {
        switch self {
        case .selfLove: return "heart.fill"
        case .identity: return "person.fill"
        case .community: return "person.3.fill"
        case .resilience: return "flame.fill"
        case .joy: return "sun.max.fill"
        case .relationships: return "heart.circle.fill"
        }
    }
}
