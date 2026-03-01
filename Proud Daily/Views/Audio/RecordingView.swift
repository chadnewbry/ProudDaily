import SwiftUI

struct RecordingView: View {
    let affirmation: Affirmation
    @State private var audioManager = AudioManager.shared
    @State private var hasPermission = false
    @State private var showPermissionAlert = false
    @State private var justRecorded: VoiceRecording?
    @State private var recordingElapsed: TimeInterval = 0
    @State private var recordingTimer: Timer?

    @Environment(\.dismiss) private var dismiss

    private var affirmationRecordings: [VoiceRecording] {
        audioManager.recordings(for: affirmation.id)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Affirmation display
                        affirmationHeader

                        // Recording area
                        if audioManager.isRecording {
                            activeRecordingView
                        } else if let recording = justRecorded {
                            previewView(recording: recording)
                        } else {
                            idleRecordView
                        }

                        // Saved recordings
                        if !affirmationRecordings.isEmpty {
                            savedRecordingsSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Microphone Access", isPresented: $showPermissionAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Proud Daily needs microphone access to record your affirmations. Please enable it in Settings.")
            }
            .task {
                hasPermission = await audioManager.requestMicrophonePermission()
            }
        }
    }

    // MARK: - Affirmation Header

    private var affirmationHeader: some View {
        VStack(spacing: 8) {
            Text(affirmation.category.emoji)
                .font(.largeTitle)
            Text(affirmation.text)
                .font(.system(.title3, design: .serif))
                .italic()
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
            Text(affirmation.category.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Affirmation: \(affirmation.text)")
    }

    // MARK: - Idle Record

    private var idleRecordView: some View {
        VStack(spacing: 20) {
            Text("Tap to record yourself reading this affirmation")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                startRecording()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.prideRed.opacity(0.15))
                        .frame(width: 100, height: 100)
                    Circle()
                        .fill(Color.prideRed)
                        .frame(width: 72, height: 72)
                    Image(systemName: "mic.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                }
            }
            .accessibilityLabel("Start recording")
        }
        .padding(.vertical, 24)
    }

    // MARK: - Active Recording

    private var activeRecordingView: some View {
        VStack(spacing: 20) {
            Text(formatTime(recordingElapsed))
                .font(.system(size: 42, weight: .light, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.prideRed)
                .accessibilityLabel("Recording time: \(formatTime(recordingElapsed))")

            LiveWaveformView(isActive: true, color: Color.prideRed)
                .frame(height: 64)
                .padding(.horizontal)

            Button {
                stopRecording()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.prideRed.opacity(0.15))
                        .frame(width: 100, height: 100)
                    Circle()
                        .fill(Color.prideRed)
                        .frame(width: 72, height: 72)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.white)
                        .frame(width: 24, height: 24)
                }
            }
            .accessibilityLabel("Stop recording")

            Text("Tap to stop")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 24)
    }

    // MARK: - Preview

    private func previewView(recording: VoiceRecording) -> some View {
        VStack(spacing: 20) {
            Text("Preview")
                .font(.headline)

            WaveformView(
                levels: generateStaticWaveform(seed: recording.id.hashValue),
                progress: audioManager.isPlayingVoice ? 0.5 : 0,
                activeColor: Color.prideViolet,
                inactiveColor: Color.prideViolet.opacity(0.2)
            )
            .frame(height: 48)
            .padding(.horizontal)

            HStack(spacing: 24) {
                // Play preview
                Button {
                    audioManager.toggleVoicePlayback(recording)
                } label: {
                    Label(
                        audioManager.isPlayingVoice ? "Pause" : "Play",
                        systemImage: audioManager.isPlayingVoice ? "pause.circle.fill" : "play.circle.fill"
                    )
                    .font(.title3)
                }

                // Re-record
                Button {
                    audioManager.deleteRecording(recording)
                    justRecorded = nil
                } label: {
                    Label("Re-record", systemImage: "arrow.counterclockwise")
                        .font(.title3)
                }

                // Save (dismiss)
                Button {
                    audioManager.stopVoicePlayback()
                    justRecorded = nil
                } label: {
                    Label("Save", systemImage: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.prideGreen)
                }
            }
            .accessibilityElement(children: .contain)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Saved Recordings

    private var savedRecordingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Recordings")
                    .font(.headline)
                Spacer()
                Toggle("Loop", isOn: $audioManager.loopVoicePlayback)
                    .fixedSize()
                    .font(.caption)
            }

            ForEach(affirmationRecordings) { recording in
                RecordingRow(recording: recording)
            }
        }
    }

    // MARK: - Actions

    private func startRecording() {
        guard hasPermission else {
            showPermissionAlert = true
            return
        }
        audioManager.startRecording(for: affirmation.id)
        recordingElapsed = 0
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                recordingElapsed += 0.1
            }
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func stopRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        audioManager.stopRecording()
        justRecorded = affirmationRecordings.last
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let m = Int(time) / 60
        let s = Int(time) % 60
        let ms = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%d:%02d.%d", m, s, ms)
    }

    private func generateStaticWaveform(seed: Int) -> [CGFloat] {
        var rng = seed
        return (0..<40).map { _ in
            rng = rng &* 1103515245 &+ 12345
            return CGFloat(abs(rng % 100)) / 100.0 * 0.7 + 0.15
        }
    }
}

// MARK: - Recording Row

struct RecordingRow: View {
    let recording: VoiceRecording
    @State private var audioManager = AudioManager.shared

    var body: some View {
        HStack(spacing: 12) {
            Button {
                audioManager.toggleVoicePlayback(recording)
            } label: {
                Image(systemName: audioManager.isPlayingVoice ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.prideViolet)
            }
            .accessibilityLabel(audioManager.isPlayingVoice ? "Pause" : "Play recording")

            VStack(alignment: .leading, spacing: 2) {
                Text(recording.createdAt, style: .date)
                    .font(.subheadline)
                Text(formatDuration(recording.duration))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(role: .destructive) {
                audioManager.deleteRecording(recording)
            } label: {
                Image(systemName: "trash")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Delete recording")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let m = Int(duration) / 60
        let s = Int(duration) % 60
        return String(format: "%d:%02d", m, s)
    }
}

#Preview {
    RecordingView(
        affirmation: Affirmation(
            text: "I am worthy of love and belonging",
            category: .selfAcceptance
        )
    )
}
