import SwiftUI

struct RecordingView: View {
    let affirmation: Affirmation
    @State private var audioManager = AudioManager.shared
    @State private var hasPermission = false
    @State private var showPermissionAlert = false

    private var affirmationRecordings: [VoiceRecording] {
        audioManager.recordings(for: affirmation.id)
    }

    var body: some View {
        List {
            Section {
                Text(affirmation.text)
                    .font(.title3)
                    .italic()
                    .padding(.vertical, 8)
            } header: {
                Text("Affirmation")
            }

            Section {
                recordButton
            } header: {
                Text("Record")
            }

            if !affirmationRecordings.isEmpty {
                Section {
                    ForEach(affirmationRecordings) { recording in
                        RecordingRow(recording: recording)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            audioManager.deleteRecording(affirmationRecordings[index])
                        }
                    }
                } header: {
                    Text("Your Recordings")
                }

                Section {
                    Toggle("Loop Playback", isOn: $audioManager.loopVoicePlayback)
                }
            }
        }
        .navigationTitle("Record")
        .alert("Microphone Access", isPresented: $showPermissionAlert) {
            Button("OK") {}
        } message: {
            Text("Please enable microphone access in Settings to record affirmations.")
        }
        .task {
            hasPermission = await audioManager.requestMicrophonePermission()
        }
    }

    @ViewBuilder
    private var recordButton: some View {
        Button {
            if audioManager.isRecording {
                audioManager.stopRecording()
            } else {
                if hasPermission {
                    audioManager.startRecording(for: affirmation.id)
                } else {
                    showPermissionAlert = true
                }
            }
        } label: {
            HStack {
                Image(systemName: audioManager.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.title)
                    .foregroundStyle(audioManager.isRecording ? .red : .accentColor)
                Text(audioManager.isRecording ? "Stop Recording" : "Start Recording")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

struct RecordingRow: View {
    let recording: VoiceRecording
    @State private var audioManager = AudioManager.shared

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(recording.createdAt, style: .date)
                    .font(.subheadline)
                Text(formatDuration(recording.duration))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                audioManager.toggleVoicePlayback(recording)
            } label: {
                Image(systemName: audioManager.isPlayingVoice ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
