import SwiftUI

struct PrideGradientView: View {
    var body: some View {
        LinearGradient(
            colors: [.prideRed, .prideOrange, .prideYellow, .prideGreen, .prideBlue, .prideViolet],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

#Preview { PrideGradientView() }
