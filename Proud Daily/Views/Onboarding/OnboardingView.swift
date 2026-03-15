import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @Bindable var preferences: UserPreferences
    var onComplete: () -> Void

    @State private var currentStep: Int

    private let totalSteps = 7

    init(preferences: UserPreferences, onComplete: @escaping () -> Void) {
        self.preferences = preferences
        self.onComplete = onComplete
        self._currentStep = State(initialValue: preferences.onboardingStep)
    }

    var body: some View {
        ZStack {
            PrideGradientView()

            VStack(spacing: 0) {
                // Top bar with progress dots and skip button
                if currentStep > 0 && currentStep < totalSteps - 1 {
                    HStack {
                        Spacer()
                        OnboardingProgressDots(current: currentStep, total: totalSteps)
                        Spacer()
                    }
                    .overlay(alignment: .trailing) {
                        Button(action: completeOnboarding) {
                            Text("Skip")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding(.trailing, 20)
                        .accessibilityIdentifier("onboarding-skip-all")
                    }
                    .padding(.top, 16)
                }

                TabView(selection: $currentStep) {
                    WelcomeStepView(onNext: advance)
                        .tag(0)

                    IdentityStepView(preferences: preferences, onNext: advance, onSkip: completeOnboarding)
                        .tag(1)

                    CategoryStepView(preferences: preferences, onNext: advance)
                        .tag(2)

                    ThemeStepView(preferences: preferences, themeManager: themeManager, onNext: advance)
                        .tag(3)

                    NotificationStepView(preferences: preferences, onNext: advance, onSkip: completeOnboarding)
                        .tag(4)

                    SyncStepView(preferences: preferences, onNext: advance, onSkip: completeOnboarding)
                        .tag(5)

                    ReadyStepView(onComplete: completeOnboarding)
                        .tag(6)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .onChange(of: currentStep) { _, newValue in
            preferences.onboardingStep = newValue
            try? modelContext.save()
        }
    }

    private func advance() {
        if currentStep < totalSteps - 1 {
            withAnimation {
                currentStep += 1
            }
        }
    }

    private func completeOnboarding() {
        preferences.hasCompletedOnboarding = true
        preferences.onboardingStep = totalSteps
        try? modelContext.save()
        onComplete()
    }
}

// MARK: - Progress Dots

struct OnboardingProgressDots: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index <= current ? Color.white : Color.white.opacity(0.3))
                    .frame(width: index == current ? 10 : 7, height: index == current ? 10 : 7)
                    .animation(.easeInOut(duration: 0.2), value: current)
            }
        }
        .padding(.vertical, 8)
    }
}
