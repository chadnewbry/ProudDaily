import Foundation

enum SleepTimerDuration: Int, CaseIterable, Identifiable {
    case fifteen = 15
    case thirty = 30
    case fortyFive = 45
    case sixty = 60

    var id: Int { rawValue }

    var displayName: String {
        "\(rawValue) min"
    }

    var timeInterval: TimeInterval {
        TimeInterval(rawValue * 60)
    }
}
