import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HomeViewModel()
    @State private var storeManager = StoreManager.shared
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                PrideGradientView()

                VStack(spacing: 24) {
                    Spacer()

                    if isLocked {
                        lockedContent
                    } else {
                        affirmationContent
                    }

                    Spacer()

                    // Free uses counter (hidden after purchase)
                    if !isPremium {
                        freeUsesBar
                    }

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
                    .opacity(isLocked ? 0.4 : 1.0)
                    .disabled(isLocked)
                }
            }
            .navigationTitle("Proud Daily")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                viewModel.setup(modelContext: modelContext)
                syncPurchaseState()
            }
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView {
                    syncPurchaseState()
                }
                .environment(themeManager)
            }
        }
    }

    // MARK: - Computed

    private var isPremium: Bool {
        storeManager.isPurchased || viewModel.hasPurchasedPremium
    }

    private var isLocked: Bool {
        !isPremium && viewModel.freeUsesRemaining <= 0
    }

    // MARK: - Affirmation Content

    private var affirmationContent: some View {
        VStack(spacing: 24) {
            Text("Today's Affirmation")
                .font(themeManager.scaledFont(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))

            Text("You are worthy of love and belonging, exactly as you are.")
                .font(themeManager.scaledFont(size: 24, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
        }
    }

    // MARK: - Locked Content

    private var lockedContent: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.6))

            Text("Your free days have ended")
                .font(themeManager.scaledFont(size: 20, weight: .semibold))
                .foregroundStyle(.white)

            Button {
                showPaywall = true
            } label: {
                Text("Unlock Proud Daily")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        Capsule().fill(.white)
                    )
            }
        }
    }

    // MARK: - Free Uses Bar

    private var freeUsesBar: some View {
        HStack(spacing: 12) {
            Text("\(viewModel.freeUsesRemaining) free day\(viewModel.freeUsesRemaining == 1 ? "" : "s") remaining")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))

            Button {
                showPaywall = true
            } label: {
                Text("Unlock Proud Daily")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(.white)
                    )
            }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Helpers

    private func syncPurchaseState() {
        if storeManager.isPurchased {
            let descriptor = FetchDescriptor<UserPreferences>()
            if let prefs = try? modelContext.fetch(descriptor).first {
                storeManager.syncPurchaseState(to: prefs)
            }
        }
    }
}

#Preview {
    HomeView()
        .environment(ThemeManager())
}
