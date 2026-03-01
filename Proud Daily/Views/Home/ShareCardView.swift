import SwiftUI

/// Rendered off-screen to produce a share image.
struct ShareCardView: View {
    let text: String
    let colors: [Color]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 40) {
                Spacer()

                Text(text)
                    .font(.system(size: 54, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                    .padding(.horizontal, 80)

                Spacer()

                Text("Proud Daily")
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.bottom, 60)
            }
        }
    }
}
