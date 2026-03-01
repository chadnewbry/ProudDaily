import SwiftUI

struct HomeView: View {
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        NavigationStack {
            ZStack {
                PrideGradientView()

                VStack(spacing: 24) {
                    Spacer()

                    Text("Today's Affirmation")
                        .font(themeManager.scaledFont(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))

                    Text("You are worthy of love and belonging, exactly as you are.")
                        .font(themeManager.scaledFont(size: 24, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)

                    Spacer()

                    Button {
                        // TODO: Share action
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(themeManager.scaledFont(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white.opacity(0.25))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Proud Daily")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview {
    HomeView()
        .environment(ThemeManager())
}
