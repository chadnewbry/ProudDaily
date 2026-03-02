import SwiftUI

struct CategoryStepView: View {
    @Bindable var preferences: UserPreferences
    var onNext: () -> Void

    @State private var enabledCategories: Set<AffirmationCategory>

    init(preferences: UserPreferences, onNext: @escaping () -> Void) {
        self.preferences = preferences
        self.onNext = onNext
        self._enabledCategories = State(initialValue: Set(preferences.selectedCategories.isEmpty ? AffirmationCategory.allCases : preferences.selectedCategories))
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("What resonates with you?")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.top, 40)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(AffirmationCategory.allCases) { category in
                        CategoryCard(
                            category: category,
                            isEnabled: enabledCategories.contains(category),
                            onTap: { toggleCategory(category) }
                        )
                    }
                }
                .padding(.horizontal, 20)

                if enabledCategories.isEmpty {
                    Text("Select at least 1 category")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Button(action: {
                    preferences.selectedCategories = Array(enabledCategories)
                    onNext()
                }) {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(.purple)
                .disabled(enabledCategories.isEmpty)
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
        }
        .scrollIndicators(.hidden)
    }

    private func toggleCategory(_ category: AffirmationCategory) {
        if enabledCategories.contains(category) {
            if enabledCategories.count > 1 {
                enabledCategories.remove(category)
            }
        } else {
            enabledCategories.insert(category)
        }
    }
}

// MARK: - Category Card

private struct CategoryCard: View {
    let category: AffirmationCategory
    let isEnabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text(category.emoji)
                    .font(.title)

                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 90)
            .background(
                isEnabled
                    ? Color.white
                    : Color.white.opacity(0.15)
            )
            .foregroundStyle(isEnabled ? .purple : .white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isEnabled ? Color.clear : Color.white.opacity(0.3), lineWidth: 1)
            )
        }
    }
}
