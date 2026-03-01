import SwiftUI

struct SleepModeView: View {
    @State private var audioManager = AudioManager.shared
    @State private var selectedDuration: SleepTimerDuration = .thirty
    @State private var selectedCategories: Set<AffirmationCategory> = Set(AffirmationCategory.allCases)

    private var allRecordings: [VoiceRecording] { audioManager.recordings }

    private var filteredRecordings: [VoiceRecording] {
        // In a full implementation, filter by affirmation category
        // For now, use all recordings
        allRecordings
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if audioManager.isSleepModeActive {
                    activeSleepView
                } else {
                    setupView
                }
            }
            .padding()
        }
        .navigationTitle("Sleep Mode")
        .animation(.easeInOut(duration: 0.4), value: audioManager.isSleepModeActive)
    }

    // MARK: - Active Sleep

    private var activeSleepView: some View {
        VStack(spacing: 32) {
            // Moon animation
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 64))
                .foregroundStyle(.indigo)
                .symbolEffect(.pulse)

            // Timer
            Text(audioManager.sleepTimeRemainingFormatted)
                .font(.system(size: 56, weight: .ultraLight, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .accessibilityLabel("Time remaining: \(audioManager.sleepTimeRemainingFormatted)")

            Text("Sleep Mode Active")
                .font(.headline)
                .foregroundStyle(.secondary)

            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.indigo.opacity(0.15), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: audioManager.sleepTotalDuration > 0
                        ? audioManager.sleepTimeRemaining / audioManager.sleepTotalDuration
                        : 0)
                    .stroke(Color.indigo, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 120, height: 120)
            .accessibilityHidden(true)

            Button(role: .destructive) {
                audioManager.stopSleepMode()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                Label("Stop Sleep Mode", systemImage: "stop.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
        }
        .padding(.top, 32)
    }

    // MARK: - Setup

    private var setupView: some View {
        VStack(spacing: 24) {
            // Moon header
            VStack(spacing: 8) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.indigo)
                Text("Fall asleep to your affirmations")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 16)

            // Timer selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Timer")
                    .font(.headline)
                Picker("Duration", selection: $selectedDuration) {
                    ForEach(SleepTimerDuration.allCases) { d in
                        Text(d.displayName).tag(d)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

            // Category selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Categories")
                    .font(.headline)
                Text("Select which affirmation categories to play")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                FlowLayout(spacing: 8) {
                    ForEach(AffirmationCategory.allCases) { cat in
                        let isSelected = selectedCategories.contains(cat)
                        Button {
                            if isSelected {
                                selectedCategories.remove(cat)
                            } else {
                                selectedCategories.insert(cat)
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(cat.emoji)
                                Text(cat.displayName)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(isSelected ? cat.color.opacity(0.2) : Color(.tertiarySystemFill), in: Capsule())
                            .overlay(Capsule().stroke(isSelected ? cat.color : .clear, lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(cat.displayName)\(isSelected ? ", selected" : "")")
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

            // Start
            if allRecordings.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "mic.badge.plus")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text("Record some affirmations first")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 24)
            } else {
                Button {
                    audioManager.startSleepMode(
                        duration: selectedDuration,
                        recordings: filteredRecordings
                    )
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } label: {
                    Label("Start Sleep Mode", systemImage: "moon.zzz.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
                .disabled(selectedCategories.isEmpty)

                Text("Audio fades out over the last 2 minutes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
        }

        return (positions, CGSize(width: maxX, height: y + rowHeight))
    }
}

#Preview {
    NavigationStack {
        SleepModeView()
    }
}
