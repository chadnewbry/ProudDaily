import Foundation

struct UserProgress: Codable {
    var currentStreak: Int
    var longestStreak: Int
    var totalDaysActive: Int
    var lastActiveDate: Date?
    var favoritedAffirmationIds: [UUID]

    init() {
        self.currentStreak = 0
        self.longestStreak = 0
        self.totalDaysActive = 0
        self.lastActiveDate = nil
        self.favoritedAffirmationIds = []
    }
}
