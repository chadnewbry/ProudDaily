import SwiftUI

struct SleepModeView: View {
    @State private var audioManager = AudioManager.shared
    @State private var selectedDuration: SleepTimerDuration = .thirty

    private var allRecordings: [VoiceRecording] {
        audioManager.recordings
    }

    var body: some View {
        List {
            if audioManager.isSleepModeActive {
                activeTimerSection
            } else {
                setupSection
            }
        }
        .navigationTitle("Sleep Mode")
    }

    @ViewBuilder
    private var activeTimerSection: some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "moon.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.indigo)

                Text(audioManager.sleepTimeRemainingFormatted)
                    .font(.system(size: 48, weight: .light, design: .rounded))
                    .monospacedDigit()

                Text("remaining")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }

        Section {
            Button("Stop Sleep Mode", role: .destructive) {
                audioManager.stopSleepMode()
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var setupSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("Timer Duration")
                    .font(.headline)
                Picker("Duration", selection: $selectedDuration) {
                    ForEach(SleepTimerDuration.allCases) { duration in
                        Text(duration.displayName).tag(duration)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Settings")
        }

        Section {
            if allRecordings.isEmpty {
                Text("Record some affirmations first to use sleep mode.")
                    .foregroundStyle(.secondary)
            } else {
                Button {
                    audioManager.startSleepMode(
                        duration: selectedDuration,
                        recordings: allRecordings
                    )
                } label: {
                    HStack {
                        Image(systemName: "moon.zzz.fill")
                        Text("Start Sleep Mode")
                    }
                    .frame(maxWidth: .infinity)
                    .font(.headline)
                }
            }
        } header: {
            Text("Start")
        } footer: {
            Text("Audio will gradually fade over \(selectedDuration.displayName) and stop automatically.")
        }
    }
}
