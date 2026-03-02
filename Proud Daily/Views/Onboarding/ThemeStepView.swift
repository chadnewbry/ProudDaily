import SwiftUI

struct ThemeStepView: View {
    @Bindable var preferences: UserPreferences
    var themeManager: ThemeManager
    var onNext: () -> Void

    @State private var selectedTheme: PrideTheme = .rainbow

    init(preferences: UserPreferences, themeManager: ThemeManager, onNext: @escaping () -> Void) {
        self.preferences = preferences
        self.themeManager = themeManager
        self.onNext = onNext
        self._selectedTheme = State(initialValue: preferences.selectedTheme)
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Pick your pride")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(PrideTheme.allCases) { theme in
                        ThemeCard(
                            theme: theme,
                            isSelected: selectedTheme == theme,
                            onTap: {
                                selectedTheme = theme
                                preferences.selectedTheme = theme
                                themeManager.selectedTheme = theme
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            Button(action: onNext) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.white)
            .foregroundStyle(.purple)
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
    }
}

// MARK: - Theme Card

private struct ThemeCard: View {
    let theme: PrideTheme
    let isSelected: Bool
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: theme.gradientColors(isDark: colorScheme == .dark),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 160)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.white : Color.clear, lineWidth: 3)
                    )
                    .shadow(color: isSelected ? .white.opacity(0.4) : .clear, radius: 8)

                Text(theme.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                        .font(.title3)
                } else {
                    Circle()
                        .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                }
            }
        }
    }
}
