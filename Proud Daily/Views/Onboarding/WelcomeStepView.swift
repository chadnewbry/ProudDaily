import SwiftUI

struct WelcomeStepView: View {
    var onNext: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 72))
                .foregroundStyle(.white)
                .symbolEffect(.pulse, options: .repeating)

            Text("Proud Daily")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Welcome to Proud Daily")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            Text("Daily affirmations for the LGBTQ+ community")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button(action: onNext) {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(.white)
            .foregroundStyle(.purple)
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
    }
}
