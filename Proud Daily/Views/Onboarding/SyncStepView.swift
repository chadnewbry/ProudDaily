import SwiftUI

struct SyncStepView: View {
    @Bindable var preferences: UserPreferences
    var onNext: () -> Void
    var onSkip: () -> Void

    @State private var syncEnabled = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "icloud.fill")
                .font(.system(size: 48))
                .foregroundStyle(.white)

            Text("Keep your affirmations everywhere")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Toggle(isOn: $syncEnabled) {
                Text("iCloud Sync")
                    .foregroundStyle(.white)
                    .fontWeight(.medium)
            }
            .tint(.white)
            .padding(.horizontal, 40)

            VStack(alignment: .leading, spacing: 8) {
                SyncInfoRow(icon: "heart.fill", text: "Favorites & collections")
                SyncInfoRow(icon: "book.closed.fill", text: "Journal entries")
                SyncInfoRow(icon: "gearshape.fill", text: "Preferences & themes")
            }
            .padding(.horizontal, 40)

            Spacer()

            VStack(spacing: 12) {
                Button(action: {
                    preferences.iCloudSyncEnabled = syncEnabled
                    if syncEnabled {
                        CloudSyncManager.shared.enableSync()
                    }
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
}

private struct SyncInfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}
