import SwiftUI

struct AmbientSoundsView: View {
    @State private var audioManager = AudioManager.shared

    var body: some View {
        List {
            Section {
                ForEach(AmbientSound.allCases) { sound in
                    Button {
                        audioManager.toggleAmbientSound(sound)
                    } label: {
                        HStack {
                            Image(systemName: sound.icon)
                                .font(.title2)
                                .frame(width: 36)
                            Text(sound.displayName)
                                .font(.body)
                            Spacer()
                            if audioManager.currentAmbientSound == sound && audioManager.isPlayingAmbient {
                                Image(systemName: "speaker.wave.2.fill")
                                    .foregroundStyle(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Sounds")
            }

            if audioManager.isPlayingAmbient {
                Section {
                    VStack {
                        Text("Volume")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Slider(value: $audioManager.ambientVolume, in: 0...1)
                    }
                    Button("Stop", role: .destructive) {
                        audioManager.stopAmbientSound()
                    }
                } header: {
                    Text("Now Playing")
                }
            }
        }
        .navigationTitle("Ambient Sounds")
    }
}
