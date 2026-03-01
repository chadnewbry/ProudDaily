import SwiftUI

struct HomeView: View {
    @StateObject private var healthKit = HealthKitManager.shared
    @AppStorage("healthKitEnabled") private var healthKitEnabled = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Text("Today's Affirmation")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("You are worthy of love and belonging, exactly as you are.")
                    .font(.title2)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                Button {
                    // TODO: Share action
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .navigationTitle("Proud Daily")
            .onAppear {
                if healthKitEnabled {
                    healthKit.startSession()
                }
            }
            .onDisappear {
                if healthKitEnabled {
                    healthKit.endSession()
                }
            }
        }
    }
}

#Preview { HomeView() }
