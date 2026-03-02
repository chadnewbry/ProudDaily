import SwiftUI
import SwiftData

struct FullScreenAffirmationView: View {
    let affirmation: Affirmation

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @State private var isFavorited: Bool = false
    @State private var showShareSheet = false
    @State private var showRecording = false
    @State private var shareImage: UIImage?

    var body: some View {
        ZStack {
            // Background gradient using category color
            LinearGradient(
                colors: [affirmation.category.color, affirmation.category.color.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Text(affirmation.category.emoji)
                        Text(affirmation.category.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding()

                Spacer()

                // Affirmation text
                Text(affirmation.text)
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
                    .padding(.horizontal, 32)

                Spacer()

                // Action buttons
                HStack(spacing: 32) {
                    actionButton(
                        icon: isFavorited ? "heart.fill" : "heart",
                        label: isFavorited ? "Favorited" : "Favorite",
                        tint: isFavorited ? .pink : .white
                    ) {
                        toggleFavorite()
                    }

                    actionButton(icon: "square.and.arrow.up", label: "Share", tint: .white) {
                        shareAffirmation()
                    }

                    actionButton(icon: "mic", label: "Record", tint: .white) {
                        showRecording = true
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear { isFavorited = !(affirmation.favorites?.isEmpty ?? true) }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheetView(items: [image])
            }
        }
        .sheet(isPresented: $showRecording) {
            RecordingView(affirmation: affirmation)
        }
    }

    private func actionButton(icon: String, label: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                Text(label)
                    .font(.caption2)
            }
            .foregroundStyle(tint)
        }
    }

    private func toggleFavorite() {
        let dm = DataManager(modelContext: modelContext)
        dm.toggleFavorite(affirmation: affirmation)
        isFavorited.toggle()
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    @MainActor
    private func shareAffirmation() {
        let theme = themeManager.selectedTheme
        let colors = theme.gradientHexColors.map { Color(hex: $0) }
        let view = ShareCardView(text: affirmation.text, colors: colors)
            .frame(width: 1080, height: 1920)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0
        shareImage = renderer.uiImage
        showShareSheet = true
    }
}

// MARK: - Share Sheet

struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    FullScreenAffirmationView(
        affirmation: Affirmation(text: "You are worthy of love and belonging.", category: .selfAcceptance)
    )
    .environment(ThemeManager())
}
