import SwiftUI

struct ReadyStepView: View {
    var onComplete: () -> Void

    @State private var showConfetti = false
    @State private var particles: [OnboardingConfettiParticle] = []

    var body: some View {
        ZStack {
            VStack(spacing: 32) {
                Spacer()

                Text("🎉")
                    .font(.system(size: 80))
                    .scaleEffect(showConfetti ? 1.0 : 0.3)
                    .animation(.spring(response: 0.5, dampingFraction: 0.5), value: showConfetti)

                Text("You're all set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .opacity(showConfetti ? 1 : 0)
                    .animation(.easeIn(duration: 0.5).delay(0.3), value: showConfetti)

                Spacer()

                Button(action: onComplete) {
                    Text("Start Your First Affirmation")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(.purple)
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
                .opacity(showConfetti ? 1 : 0)
                .animation(.easeIn(duration: 0.4).delay(0.6), value: showConfetti)
            }

            // Confetti particles
            ForEach(particles) { particle in
                OnboardingConfettiPiece(particle: particle)
            }
        }
        .onAppear {
            showConfetti = true
            generateConfetti()
        }
    }

    private func generateConfetti() {
        let colors: [Color] = [.prideRed, .prideOrange, .prideYellow, .prideGreen, .prideBlue, .prideViolet, .transPink, .transBlue]
        particles = (0..<50).map { i in
            OnboardingConfettiParticle(
                id: i,
                color: colors[i % colors.count],
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                startY: -20,
                endY: UIScreen.main.bounds.height + 20,
                size: CGFloat.random(in: 6...12),
                duration: Double.random(in: 2.0...4.0),
                delay: Double.random(in: 0...1.0),
                rotation: Double.random(in: 0...360)
            )
        }
    }
}

// MARK: - Confetti

struct OnboardingConfettiParticle: Identifiable {
    let id: Int
    let color: Color
    let x: CGFloat
    let startY: CGFloat
    let endY: CGFloat
    let size: CGFloat
    let duration: Double
    let delay: Double
    let rotation: Double
}

struct OnboardingConfettiPiece: View {
    let particle: OnboardingConfettiParticle
    @State private var animate = false

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size * 1.5)
            .rotationEffect(.degrees(animate ? particle.rotation + 360 : particle.rotation))
            .position(
                x: particle.x + (animate ? CGFloat.random(in: -30...30) : 0),
                y: animate ? particle.endY : particle.startY
            )
            .opacity(animate ? 0 : 1)
            .onAppear {
                withAnimation(
                    .easeIn(duration: particle.duration)
                    .delay(particle.delay)
                ) {
                    animate = true
                }
            }
    }
}
