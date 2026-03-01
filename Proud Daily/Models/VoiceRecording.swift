import Foundation

struct VoiceRecording: Identifiable, Codable {
    let id: UUID
    let affirmationId: UUID
    let fileName: String
    let createdAt: Date
    let duration: TimeInterval

    init(id: UUID = UUID(), affirmationId: UUID, fileName: String, createdAt: Date = .now, duration: TimeInterval = 0) {
        self.id = id
        self.affirmationId = affirmationId
        self.fileName = fileName
        self.createdAt = createdAt
        self.duration = duration
    }

    var fileURL: URL {
        AudioFileManager.recordingsDirectory.appendingPathComponent(fileName)
    }
}
