import SwiftUI

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var animating = false

    private let prideColors: [Color] = [
        .prideRed, .prideOrange, .prideYellow,
        .prideGreen, .prideBlue, .prideViolet,
        .transPink, .transBlue, .panPink, .panCyan
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(particle.color)
                        .frame(width: particle.size.width, height: particle.size.height)
                        .rotationEffect(.degrees(animating ? particle.endRotation : 0))
                        .position(
                            x: animating ? particle.endX : particle.startX,
                            y: animating ? geo.size.height + 20 : particle.startY
                        )
                        .opacity(animating ? 0 : 1)
                }
            }
            .onAppear {
                particles = (0..<60).map { _ in
                    ConfettiParticle(
                        color: prideColors.randomElement()!,
                        size: CGSize(
                            width: CGFloat.random(in: 6...12),
                            height: CGFloat.random(in: 10...20)
                        ),
                        startX: CGFloat.random(in: 0...geo.size.width),
                        startY: CGFloat.random(in: -40...(-10)),
                        endX: CGFloat.random(in: -20...(geo.size.width + 20)),
                        endRotation: Double.random(in: 180...720)
                    )
                }
                withAnimation(.easeOut(duration: 3.0)) {
                    animating = true
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGSize
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endRotation: Double
}
