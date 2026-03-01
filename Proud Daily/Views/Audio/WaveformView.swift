import SwiftUI

/// Animated waveform visualization for recording and playback.
struct WaveformView: View {
    let levels: [CGFloat]
    var progress: CGFloat = 1.0
    var activeColor: Color = .white
    var inactiveColor: Color = .white.opacity(0.3)
    var barWidth: CGFloat = 3
    var spacing: CGFloat = 2

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .center, spacing: spacing) {
                ForEach(Array(displayLevels(for: geo.size.width).enumerated()), id: \.offset) { index, level in
                    let barProgress = CGFloat(index) / CGFloat(max(displayLevels(for: geo.size.width).count - 1, 1))
                    RoundedRectangle(cornerRadius: barWidth / 2)
                        .fill(barProgress <= progress ? activeColor : inactiveColor)
                        .frame(width: barWidth, height: max(4, level * geo.size.height))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityHidden(true)
    }

    private func displayLevels(for width: CGFloat) -> [CGFloat] {
        let barCount = Int(width / (barWidth + spacing))
        guard barCount > 0 else { return [] }
        guard !levels.isEmpty else {
            return Array(repeating: CGFloat(0.1), count: barCount)
        }
        return (0..<barCount).map { i in
            let sourceIndex = Double(i) / Double(barCount) * Double(levels.count)
            let idx = min(Int(sourceIndex), levels.count - 1)
            return levels[idx]
        }
    }
}

/// Animating waveform that pulses during recording.
struct LiveWaveformView: View {
    var isActive: Bool
    var color: Color = .white
    var barCount: Int = 30

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            WaveformView(
                levels: generateLevels(time: time),
                activeColor: color,
                inactiveColor: color.opacity(0.2)
            )
        }
        .opacity(isActive ? 1 : 0.4)
        .animation(.easeInOut(duration: 0.3), value: isActive)
    }

    private func generateLevels(time: TimeInterval) -> [CGFloat] {
        guard isActive else {
            return (0..<barCount).map { _ in CGFloat.random(in: 0.05...0.15) }
        }
        return (0..<barCount).map { i in
            let base = sin(time * 3 + Double(i) * 0.3) * 0.3 + 0.5
            let noise = sin(time * 7 + Double(i) * 1.7) * 0.2
            return CGFloat(max(0.1, min(1.0, base + noise)))
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        WaveformView(
            levels: (0..<40).map { _ in CGFloat.random(in: 0.1...1.0) },
            progress: 0.6,
            activeColor: Color.prideViolet,
            inactiveColor: Color.prideViolet.opacity(0.2)
        )
        .frame(height: 60)

        LiveWaveformView(isActive: true, color: Color.prideRed)
            .frame(height: 60)
    }
    .padding()
    .background(.black)
}
