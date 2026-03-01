import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = HomeViewModel()
    @State private var holdTimer: Timer?
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?

    var body: some View {
        let theme = vm.selectedTheme
        let colors = theme.gradientHexColors.map { Color(hex: $0) }

        ZStack {
            // MARK: - Background
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Streak Header
                streakHeader
                    .padding(.top, 8)

                Spacer()

                // MARK: - Affirmation Card Area
                if vm.canSwipe {
                    TabView(selection: $vm.currentIndex) {
                        ForEach(Array(vm.browseAffirmations.enumerated()), id: \.element.id) { index, affirmation in
                            affirmationCard(affirmation: affirmation, isDaily: index == 0)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                    .frame(maxHeight: .infinity)
                } else {
                    affirmationCard(
                        affirmation: vm.dailyAffirmation,
                        isDaily: true
                    )
                    .frame(maxHeight: .infinity)
                }

                // MARK: - Action Buttons (visible after reveal)
                if vm.isRevealed, let affirmation = vm.currentAffirmation {
                    actionButtons(affirmation: affirmation)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 8)
                }

                // MARK: - Free Uses Counter
                if !vm.hasPurchasedPremium {
                    freeUsesBar
                        .padding(.bottom, 16)
                }
            }
            .padding(.horizontal, 24)

            // MARK: - Confetti Overlay
            if vm.showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            vm.setup(modelContext: modelContext)
            vm.startSession()
        }
        .onDisappear {
            vm.endSession()
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(items: [image])
            }
        }
        .animation(.easeInOut(duration: 0.3), value: vm.isRevealed)
    }

    // MARK: - Streak Header

    private var streakHeader: some View {
        HStack {
            if vm.currentStreak > 0 {
                Label {
                    Text("\(vm.currentStreak) day streak")
                        .font(.subheadline.weight(.semibold))
                } icon: {
                    Text("🔥")
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
                .accessibilityLabel("\(vm.currentStreak) day streak")
            }

            Spacer()
        }
    }

    // MARK: - Affirmation Card

    @ViewBuilder
    private func affirmationCard(affirmation: Affirmation?, isDaily: Bool) -> some View {
        VStack(spacing: 16) {
            if isDaily && !vm.isRevealed {
                // Hold-to-reveal prompt
                VStack(spacing: 24) {
                    Text(affirmation?.text ?? "Your affirmation awaits")
                        .font(.system(.title, design: .serif, weight: .semibold))
                        .scaleEffect(vm.fontScale)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .blur(radius: (1.0 - vm.revealProgress) * 20)
                        .opacity(0.3 + vm.revealProgress * 0.7)
                        .accessibilityLabel(vm.isRevealed ? (affirmation?.text ?? "") : "Hold to reveal your daily affirmation")

                    if !vm.isHolding && vm.revealProgress == 0 {
                        Text("Hold to reveal")
                            .font(.callout)
                            .foregroundStyle(.white.opacity(0.7))
                            .transition(.opacity)
                    }

                    // Progress ring
                    if vm.isHolding || (vm.revealProgress > 0 && !vm.isRevealed) {
                        Circle()
                            .trim(from: 0, to: vm.revealProgress)
                            .stroke(.white.opacity(0.8), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 44, height: 44)
                            .rotationEffect(.degrees(-90))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            guard !vm.isRevealed, !vm.isHolding else { return }
                            startHold()
                        }
                        .onEnded { _ in
                            cancelHold()
                        }
                )
            } else {
                // Revealed affirmation
                Text(affirmation?.text ?? "")
                    .font(.system(.title, design: .serif, weight: .semibold))
                    .scaleEffect(vm.fontScale)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                    .accessibilityLabel(affirmation?.text ?? "")

                if let category = affirmation?.category {
                    Text(category.displayName)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.top, 4)
                }
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Hold Gesture

    private func startHold() {
        vm.isHolding = true
        // Light haptic on start
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Animate reveal over 2 seconds using a timer
        let steps = 60 // ~30fps over 2s
        let interval = 2.0 / Double(steps)
        let increment = 1.0 / CGFloat(steps)

        holdTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            if vm.revealProgress >= 1.0 {
                timer.invalidate()
                holdTimer = nil
                vm.completeReveal()
                return
            }
            withAnimation(.linear(duration: interval)) {
                vm.revealProgress = min(vm.revealProgress + increment, 1.0)
            }
        }
    }

    private func cancelHold() {
        holdTimer?.invalidate()
        holdTimer = nil

        if vm.revealProgress < 1.0 {
            vm.isHolding = false
            withAnimation(.easeOut(duration: 0.3)) {
                vm.revealProgress = 0
            }
        }
    }

    // MARK: - Action Buttons

    private func actionButtons(affirmation: Affirmation) -> some View {
        HStack(spacing: 32) {
            // Favorite
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    vm.toggleFavorite(for: affirmation)
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: vm.isFavorite(affirmation) ? "heart.fill" : "heart")
                    .font(.title2)
                    .foregroundStyle(vm.isFavorite(affirmation) ? .red : .white)
                    .symbolEffect(.bounce, value: vm.isFavorite(affirmation))
            }
            .accessibilityLabel(vm.isFavorite(affirmation) ? "Remove from favorites" : "Add to favorites")

            // Share
            Button {
                Task {
                    shareImage = await vm.generateShareImage(
                        affirmation: affirmation,
                        theme: vm.selectedTheme
                    )
                    showShareSheet = true
                }
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            .accessibilityLabel("Share affirmation")

            // Audio
            Button {
                // TODO: Play recorded audio or prompt to record
            } label: {
                Image(systemName: "speaker.wave.2")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            .accessibilityLabel("Play audio")
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 32)
        .background(.ultraThinMaterial, in: Capsule())
    }

    // MARK: - Free Uses

    private var freeUsesBar: some View {
        HStack(spacing: 12) {
            Text("\(vm.freeUsesRemaining) free days remaining")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.8))

            Button {
                // TODO: Trigger paywall
            } label: {
                Text("Unlock")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.2), in: Capsule())
            }
            .accessibilityLabel("Unlock Proud Daily premium")
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    HomeView()
        .modelContainer(for: [
            Affirmation.self, FavoriteAffirmation.self,
            UserPreferences.self, DailyRecord.self,
            JournalEntry.self, UserAffirmation.self, UserCollection.self
        ], inMemory: true)
}
