import SwiftUI

struct AmbientSoundsView: View {
    @State private var audioManager = AudioManager.shared

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                Text("Set the mood with ambient sounds that play behind your affirmations.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Sound grid
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(AmbientSound.allCases) { sound in
                        AmbientSoundTile(
                            sound: sound,
                            isPlaying: audioManager.currentAmbientSound == sound && audioManager.isPlayingAmbient
                        ) {
                            audioManager.toggleAmbientSound(sound)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                }
                .padding(.horizontal)

                // Volume control
                if audioManager.isPlayingAmbient {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "speaker.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Slider(value: $audioManager.ambientVolume, in: 0...1)
                                .tint(Color.prideViolet)
                            Image(systemName: "speaker.wave.3.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Button(role: .destructive) {
                            audioManager.stopAmbientSound()
                        } label: {
                            Label("Stop", systemImage: "stop.fill")
                                .font(.subheadline.weight(.medium))
                        }
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Ambient Sounds")
        .animation(.easeInOut(duration: 0.3), value: audioManager.isPlayingAmbient)
    }
}

struct AmbientSoundTile: View {
    let sound: AmbientSound
    let isPlaying: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isPlaying ? Color.prideViolet.opacity(0.2) : Color(.tertiarySystemFill))
                        .frame(height: 80)

                    Image(systemName: sound.icon)
                        .font(.title)
                        .foregroundStyle(isPlaying ? Color.prideViolet : .primary)
                        .symbolEffect(.pulse, isActive: isPlaying)
                }

                Text(sound.displayName)
                    .font(.caption)
                    .foregroundStyle(isPlaying ? Color.prideViolet : .primary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isPlaying ? Color.prideViolet : .clear, lineWidth: 2)
                .frame(height: 80),
            alignment: .top
        )
        .accessibilityLabel("\(sound.displayName)\(isPlaying ? ", playing" : "")")
        .accessibilityAddTraits(isPlaying ? .isSelected : [])
    }
}

#Preview {
    NavigationStack {
        AmbientSoundsView()
    }
}
