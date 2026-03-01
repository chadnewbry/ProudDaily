import SwiftUI

struct AudioPlaybackView: View {
    let recording: VoiceRecording
    let affirmationText: String
    @State private var audioManager = AudioManager.shared
    @State private var playbackSpeed: Float = 1.0

    @Environment(\.dismiss) private var dismiss

    private let speeds: [Float] = [0.75, 1.0, 1.25]

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Affirmation text
                Text(affirmationText)
                    .font(.system(.title2, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 24)
                    .accessibilityLabel("Affirmation: \(affirmationText)")

                // Waveform
                WaveformView(
                    levels: generateStaticWaveform(seed: recording.id.hashValue),
                    progress: 0.5,
                    activeColor: Color.prideViolet,
                    inactiveColor: Color.prideViolet.opacity(0.2)
                )
                .frame(height: 64)
                .padding(.horizontal, 32)

                // Duration
                HStack {
                    Text(formatDuration(0))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(formatDuration(recording.duration))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 32)

                // Controls
                HStack(spacing: 40) {
                    // Speed
                    Button {
                        cycleSpeed()
                    } label: {
                        Text(String(format: "%.2gx", playbackSpeed))
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    .accessibilityLabel("Playback speed \(String(format: "%.2g", playbackSpeed))x")

                    // Play/Pause
                    Button {
                        audioManager.toggleVoicePlayback(recording)
                    } label: {
                        Image(systemName: audioManager.isPlayingVoice ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(Color.prideViolet)
                    }
                    .accessibilityLabel(audioManager.isPlayingVoice ? "Pause" : "Play")

                    // Loop
                    Button {
                        audioManager.loopVoicePlayback.toggle()
                    } label: {
                        Image(systemName: "repeat")
                            .font(.title3)
                            .foregroundStyle(audioManager.loopVoicePlayback ? Color.prideViolet : .secondary)
                            .padding(8)
                            .background(
                                audioManager.loopVoicePlayback ? Color.prideViolet.opacity(0.15) : .clear,
                                in: Circle()
                            )
                    }
                    .accessibilityLabel(audioManager.loopVoicePlayback ? "Loop on" : "Loop off")
                }

                Spacer()
            }
            .navigationTitle("Playback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        audioManager.stopVoicePlayback()
                        dismiss()
                    }
                }
            }
        }
    }

    private func cycleSpeed() {
        guard let idx = speeds.firstIndex(of: playbackSpeed) else {
            playbackSpeed = 1.0
            return
        }
        playbackSpeed = speeds[(idx + 1) % speeds.count]
        audioManager.setPlaybackSpeed(playbackSpeed)
    }

    private func formatDuration(_ d: TimeInterval) -> String {
        let m = Int(d) / 60
        let s = Int(d) % 60
        return String(format: "%d:%02d", m, s)
    }

    private func generateStaticWaveform(seed: Int) -> [CGFloat] {
        var rng = seed
        return (0..<50).map { _ in
            rng = rng &* 1103515245 &+ 12345
            return CGFloat(abs(rng % 100)) / 100.0 * 0.7 + 0.15
        }
    }
}
