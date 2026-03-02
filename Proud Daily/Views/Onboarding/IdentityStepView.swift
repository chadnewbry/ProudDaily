import SwiftUI

struct IdentityStepView: View {
    @Bindable var preferences: UserPreferences
    var onNext: () -> Void
    var onSkip: () -> Void

    @State private var selectedPronounOption: PronounOption = .theyThem
    @State private var customPronounText: String = ""
    @State private var selectedLabels: Set<IdentityLabel> = []

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Tell us about you")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.top, 40)

                Text("(all optional)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))

                // Display name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Display Name")
                        .font(.headline)
                        .foregroundStyle(.white)

                    TextField("What should we call you?", text: $preferences.displayName)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 4)
                }
                .padding(.horizontal, 32)

                // Pronouns
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pronouns")
                        .font(.headline)
                        .foregroundStyle(.white)

                    HStack(spacing: 8) {
                        ForEach(PronounOption.allCases) { option in
                            Button {
                                selectedPronounOption = option
                                if option != .custom {
                                    preferences.pronouns = option.displayName
                                }
                            } label: {
                                Text(option.displayName)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedPronounOption == option
                                            ? Color.white
                                            : Color.white.opacity(0.2)
                                    )
                                    .foregroundStyle(
                                        selectedPronounOption == option
                                            ? Color.purple
                                            : Color.white
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                    }

                    if selectedPronounOption == .custom {
                        TextField("Enter your pronouns", text: $customPronounText)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal, 4)
                            .onChange(of: customPronounText) { _, newValue in
                                preferences.pronouns = newValue
                            }
                    }
                }
                .padding(.horizontal, 32)

                // Identity labels
                VStack(alignment: .leading, spacing: 8) {
                    Text("Identity")
                        .font(.headline)
                        .foregroundStyle(.white)

                    OnboardingFlowLayout(spacing: 8) {
                        ForEach(IdentityLabel.allCases) { label in
                            Button {
                                if selectedLabels.contains(label) {
                                    selectedLabels.remove(label)
                                } else {
                                    selectedLabels.insert(label)
                                }
                                preferences.identityLabels = Array(selectedLabels)
                            } label: {
                                Text(label.displayName)
                                    .font(.subheadline)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedLabels.contains(label)
                                            ? Color.white
                                            : Color.white.opacity(0.2)
                                    )
                                    .foregroundStyle(
                                        selectedLabels.contains(label)
                                            ? Color.purple
                                            : Color.white
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)

                // Privacy note
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(.white.opacity(0.7))
                    Text("This stays on your device. We never share your identity data.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)

                // Buttons
                VStack(spacing: 12) {
                    Button(action: onNext) {
                        Text("Continue")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white)
                    .foregroundStyle(.purple)

                    Button(action: onSkip) {
                        Text("Skip")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - OnboardingFlowLayout

struct OnboardingFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalHeight = y + rowHeight
        }

        return (positions, CGSize(width: maxWidth, height: totalHeight))
    }
}
