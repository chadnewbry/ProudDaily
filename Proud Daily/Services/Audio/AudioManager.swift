import AVFoundation
import Foundation
import Observation

@Observable
final class AudioManager {
    // MARK: - Singleton
    static let shared = AudioManager()

    // MARK: - Recording state
    private(set) var isRecording = false
    private(set) var currentRecordingAffirmationId: UUID?
    private var audioRecorder: AVAudioRecorder?
    private var recordingStartTime: Date?

    // MARK: - Voice playback state
    private(set) var isPlayingVoice = false
    var loopVoicePlayback = false {
        didSet { voicePlayer?.numberOfLoops = loopVoicePlayback ? -1 : 0 }
    }
    private var voicePlayer: AVAudioPlayer?

    // MARK: - Ambient sound state
    private(set) var currentAmbientSound: AmbientSound?
    private(set) var isPlayingAmbient = false
    var ambientVolume: Float = 0.5 {
        didSet { ambientPlayer?.volume = ambientVolume }
    }
    private var ambientPlayer: AVAudioPlayer?

    // MARK: - Sleep mode state
    private(set) var isSleepModeActive = false
    private(set) var sleepTimeRemaining: TimeInterval = 0
    private(set) var sleepTotalDuration: TimeInterval = 0
    private var sleepTimer: Timer?
    private var fadeTimer: Timer?
    private var sleepStartVolume: Float = 1.0

    // MARK: - Recordings cache
    private(set) var recordings: [VoiceRecording] = []

    // MARK: - Init

    private init() {
        recordings = AudioFileManager.loadRecordings()
        configureAudioSession()
        setupInterruptionHandling()
    }

    // MARK: - Audio Session

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP, .mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Audio session configuration error: \(error)")
        }
    }

    private func setupInterruptionHandling() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let info = notification.userInfo,
                  let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

            switch type {
            case .began:
                self?.handleInterruptionBegan()
            case .ended:
                if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    if options.contains(.shouldResume) {
                        self?.handleInterruptionEnded()
                    }
                }
            @unknown default:
                break
            }
        }
    }

    private func handleInterruptionBegan() {
        if isRecording { stopRecording() }
        if isPlayingVoice { voicePlayer?.pause(); isPlayingVoice = false }
        if isPlayingAmbient { ambientPlayer?.pause(); isPlayingAmbient = false }
    }

    private func handleInterruptionEnded() {
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    // MARK: - Microphone Permission

    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    // MARK: - Voice Recording

    func startRecording(for affirmationId: UUID) {
        let (url, _) = AudioFileManager.newRecordingURL(for: affirmationId)
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try AVAudioSession.sharedInstance().setActive(true)
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
            isRecording = true
            currentRecordingAffirmationId = affirmationId
            recordingStartTime = Date()
        } catch {
            print("Recording error: \(error)")
        }
    }

    func stopRecording() {
        guard let recorder = audioRecorder, isRecording else { return }
        recorder.stop()
        isRecording = false

        let duration = recordingStartTime.map { Date().timeIntervalSince($0) } ?? 0
        let fileName = recorder.url.lastPathComponent
        let affirmationId = currentRecordingAffirmationId ?? UUID()

        let recording = VoiceRecording(
            affirmationId: affirmationId,
            fileName: fileName,
            duration: duration
        )

        recordings.append(recording)
        AudioFileManager.saveRecordings(recordings)
        currentRecordingAffirmationId = nil
        recordingStartTime = nil
        audioRecorder = nil
    }

    // MARK: - Voice Playback

    func playRecording(_ recording: VoiceRecording) {
        stopVoicePlayback()
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            voicePlayer = try AVAudioPlayer(contentsOf: recording.fileURL)
            voicePlayer?.numberOfLoops = loopVoicePlayback ? -1 : 0
            voicePlayer?.play()
            isPlayingVoice = true
        } catch {
            print("Playback error: \(error)")
        }
    }

    func stopVoicePlayback() {
        voicePlayer?.stop()
        voicePlayer = nil
        isPlayingVoice = false
    }

    func toggleVoicePlayback(_ recording: VoiceRecording) {
        if isPlayingVoice {
            stopVoicePlayback()
        } else {
            playRecording(recording)
        }
    }

    // MARK: - Delete Recording

    func deleteRecording(_ recording: VoiceRecording) {
        if voicePlayer?.url == recording.fileURL { stopVoicePlayback() }
        AudioFileManager.deleteRecording(recording)
        recordings.removeAll { $0.id == recording.id }
    }

    func recordings(for affirmationId: UUID) -> [VoiceRecording] {
        recordings.filter { $0.affirmationId == affirmationId }
    }

    // MARK: - Ambient Sounds

    func playAmbientSound(_ sound: AmbientSound) {
        stopAmbientSound()
        guard let url = Bundle.main.url(forResource: sound.fileName, withExtension: "m4a") else {
            print("Ambient sound file not found: \(sound.fileName)")
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            ambientPlayer = try AVAudioPlayer(contentsOf: url)
            ambientPlayer?.numberOfLoops = -1
            ambientPlayer?.volume = ambientVolume
            ambientPlayer?.play()
            currentAmbientSound = sound
            isPlayingAmbient = true
        } catch {
            print("Ambient playback error: \(error)")
        }
    }

    func stopAmbientSound() {
        ambientPlayer?.stop()
        ambientPlayer = nil
        currentAmbientSound = nil
        isPlayingAmbient = false
    }

    func toggleAmbientSound(_ sound: AmbientSound) {
        if currentAmbientSound == sound && isPlayingAmbient {
            stopAmbientSound()
        } else {
            playAmbientSound(sound)
        }
    }

    // MARK: - Sleep Mode

    func startSleepMode(duration: SleepTimerDuration, recordings sleepRecordings: [VoiceRecording]) {
        guard !sleepRecordings.isEmpty else { return }

        stopSleepMode()

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Sleep mode audio session error: \(error)")
        }

        isSleepModeActive = true
        sleepTotalDuration = duration.timeInterval
        sleepTimeRemaining = duration.timeInterval
        sleepStartVolume = 1.0

        // Play first recording, loop through all
        playSleepRecordings(sleepRecordings)

        // Countdown timer
        sleepTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.sleepTimeRemaining -= 1
                if self.sleepTimeRemaining <= 0 {
                    self.stopSleepMode()
                }
            }
        }

        // Volume fade timer
        let fadeInterval: TimeInterval = 5 // fade every 5 seconds
        let totalFadeSteps = duration.timeInterval / fadeInterval
        let volumeDecrement = sleepStartVolume / Float(totalFadeSteps)

        fadeTimer = Timer.scheduledTimer(withTimeInterval: fadeInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                let newVolume = max((self.voicePlayer?.volume ?? 0) - volumeDecrement, 0)
                self.voicePlayer?.volume = newVolume
                if let ambient = self.ambientPlayer {
                    ambient.volume = max(ambient.volume - volumeDecrement * 0.5, 0)
                }
            }
        }
    }

    private func playSleepRecordings(_ sleepRecordings: [VoiceRecording]) {
        guard let first = sleepRecordings.first else { return }
        do {
            voicePlayer = try AVAudioPlayer(contentsOf: first.fileURL)
            voicePlayer?.numberOfLoops = -1 // loop for sleep mode
            voicePlayer?.volume = sleepStartVolume
            voicePlayer?.play()
            isPlayingVoice = true
        } catch {
            print("Sleep playback error: \(error)")
        }
    }

    func stopSleepMode() {
        sleepTimer?.invalidate()
        sleepTimer = nil
        fadeTimer?.invalidate()
        fadeTimer = nil
        stopVoicePlayback()
        isSleepModeActive = false
        sleepTimeRemaining = 0
        sleepTotalDuration = 0

        // Restore ambient volume
        ambientPlayer?.volume = ambientVolume
    }

    var sleepTimeRemainingFormatted: String {
        let minutes = Int(sleepTimeRemaining) / 60
        let seconds = Int(sleepTimeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Storage

    var totalStorageUsed: String {
        AudioFileManager.formattedStorageUsed()
    }

    func refreshRecordings() {
        recordings = AudioFileManager.loadRecordings()
    }
}

// MARK: - Playback Speed

extension AudioManager {
    func setPlaybackSpeed(_ speed: Float) {
        voicePlayer?.rate = speed
        voicePlayer?.enableRate = true
    }
}

// MARK: - Now Playing Info Center

import MediaPlayer

extension AudioManager {
    func updateNowPlayingInfo(title: String, duration: TimeInterval) {
        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = title
        info[MPMediaItemPropertyArtist] = "Proud Daily"
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPNowPlayingInfoPropertyPlaybackRate] = voicePlayer?.rate ?? 1.0
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = voicePlayer?.currentTime ?? 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func setupRemoteCommandCenter() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in
            guard let self, let player = self.voicePlayer else { return .commandFailed }
            player.play()
            self.isPlayingVoice = true
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            self?.voicePlayer?.pause()
            self?.isPlayingVoice = false
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            if self.isPlayingVoice {
                self.voicePlayer?.pause()
                self.isPlayingVoice = false
            } else {
                self.voicePlayer?.play()
                self.isPlayingVoice = true
            }
            return .success
        }
    }

    func clearNowPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
}
