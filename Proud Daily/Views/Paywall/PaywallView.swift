import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.dismiss) private var dismiss
    @State private var storeManager = StoreManager.shared
    @State private var showSuccessAnimation = false
    @State private var restoreMessage: String?

    var onPurchaseComplete: (() -> Void)?

    var body: some View {
        ZStack {
            PrideGradientView()

            if showSuccessAnimation {
                successView
            } else {
                paywallContent
            }
        }
    }

    // MARK: - Paywall Content

    private var paywallContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 40)

                // Header
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48))
                        .foregroundStyle(.white)

                    Text("Unlock Proud Daily Forever")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                }

                // Price badge
                priceBadge

                // Features
                featureList

                // Comparison
                comparisonCallout

                // Buttons
                VStack(spacing: 16) {
                    purchaseButton

                    restoreButton

                    dismissButton
                }
                .padding(.horizontal, 32)

                if let error = storeManager.purchaseError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                if let message = restoreMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer(minLength: 40)
            }
        }
    }

    // MARK: - Price Badge

    private var priceBadge: some View {
        Text(priceText)
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(.white.opacity(0.2))
                    .overlay(
                        Capsule()
                            .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                    )
            )
    }

    private var priceText: String {
        if let product = storeManager.premiumProduct {
            return "\(product.displayPrice) — One Time"
        }
        return "$4.99 — One Time"
    }

    // MARK: - Feature List

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 14) {
            featureRow("Unlimited daily affirmations")
            featureRow("All 9 LGBTQ+ categories")
            featureRow("All pride themes & customization")
            featureRow("Widgets, audio, journaling")
            featureRow("All future updates included")
            featureRow("No subscriptions ever")
        }
        .padding(.horizontal, 40)
    }

    private func featureRow(_ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.white)
                .font(.system(size: 20))
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Comparison

    private var comparisonCallout: some View {
        Text("Other apps charge $30-50/year.\nProud Daily is yours forever.")
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(.white.opacity(0.8))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(0.1))
            )
            .padding(.horizontal, 32)
    }

    // MARK: - Buttons

    private var purchaseButton: some View {
        Button {
            Task {
                let success = await storeManager.purchase()
                if success {
                    withAnimation(.spring(duration: 0.5)) {
                        showSuccessAnimation = true
                    }
                    try? await Task.sleep(for: .seconds(3))
                    onPurchaseComplete?()
                    dismiss()
                }
            }
        } label: {
            Group {
                if storeManager.isLoading {
                    ProgressView()
                        .tint(.black)
                } else {
                    Text("Purchase")
                        .font(.system(size: 18, weight: .bold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
        )
        .foregroundStyle(.black)
        .disabled(storeManager.isLoading)
    }

    private var restoreButton: some View {
        Button {
            Task {
                restoreMessage = nil
                let success = await storeManager.restore()
                if success {
                    withAnimation(.spring(duration: 0.5)) {
                        showSuccessAnimation = true
                    }
                    try? await Task.sleep(for: .seconds(3))
                    onPurchaseComplete?()
                    dismiss()
                } else {
                    restoreMessage = "No previous purchase found."
                }
            }
        } label: {
            Text("Restore Purchase")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    private var dismissButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Not now")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    // MARK: - Success View

    private var successView: some View {
        ZStack {
            ConfettiView()
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white)

                Text("Welcome to\nProud Daily Premium!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

#Preview {
    PaywallView()
        .environment(ThemeManager())
}
