import Foundation

struct AudioFileManager {
    static var recordingsDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Recordings", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private static let metadataURL: URL = {
        recordingsDirectory.appendingPathComponent("recordings_metadata.json")
    }()

    // MARK: - Metadata persistence

    static func loadRecordings() -> [VoiceRecording] {
        guard let data = try? Data(contentsOf: metadataURL),
              let recordings = try? JSONDecoder().decode([VoiceRecording].self, from: data) else {
            return []
        }
        return recordings
    }

    static func saveRecordings(_ recordings: [VoiceRecording]) {
        guard let data = try? JSONEncoder().encode(recordings) else { return }
        try? data.write(to: metadataURL, options: .atomic)
    }

    // MARK: - Queries

    static func recordings(for affirmationId: UUID) -> [VoiceRecording] {
        loadRecordings().filter { $0.affirmationId == affirmationId }
    }

    // MARK: - Delete

    static func deleteRecording(_ recording: VoiceRecording) {
        try? FileManager.default.removeItem(at: recording.fileURL)
        var all = loadRecordings()
        all.removeAll { $0.id == recording.id }
        saveRecordings(all)
    }

    // MARK: - Storage

    static func totalStorageUsed() -> Int64 {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: recordingsDirectory, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var total: Int64 = 0
        for case let url as URL in enumerator {
            if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += Int64(size)
            }
        }
        return total
    }

    static func formattedStorageUsed() -> String {
        ByteCountFormatter.string(fromByteCount: totalStorageUsed(), countStyle: .file)
    }

    // MARK: - New recording file path

    static func newRecordingURL(for affirmationId: UUID) -> (url: URL, fileName: String) {
        let fileName = "\(affirmationId.uuidString)_\(Int(Date().timeIntervalSince1970)).m4a"
        return (recordingsDirectory.appendingPathComponent(fileName), fileName)
    }
}
