import Foundation

enum AmbientSound: String, CaseIterable, Codable, Identifiable {
    case rain = "rain"
    case oceanWaves = "ocean_waves"
    case lofiBeats = "lofi_beats"
    case softPiano = "soft_piano"
    case natureBirds = "nature_birds"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rain: return "Rain"
        case .oceanWaves: return "Ocean Waves"
        case .lofiBeats: return "Lo-fi Beats"
        case .softPiano: return "Soft Piano"
        case .natureBirds: return "Nature & Birds"
        }
    }

    var icon: String {
        switch self {
        case .rain: return "cloud.rain.fill"
        case .oceanWaves: return "water.waves"
        case .lofiBeats: return "headphones"
        case .softPiano: return "pianokeys"
        case .natureBirds: return "bird.fill"
        }
    }

    var fileName: String { rawValue }
}
