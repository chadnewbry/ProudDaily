import SwiftUI

struct PrideGradientView: View {
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        ZStack {
            if let bgImage = themeManager.customBackgroundImage {
                Image(uiImage: bgImage)
                    .resizable()
                    .scaledToFill()
                    .overlay(themeManager.activeGradient.opacity(0.5))
            } else {
                themeManager.activeGradient
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    PrideGradientView()
        .environment(ThemeManager())
}
