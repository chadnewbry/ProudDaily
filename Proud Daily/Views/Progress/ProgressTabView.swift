import SwiftUI

struct ProgressTabView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "chart.bar")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("Track your journey")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text("Your streaks and stats will appear here as you use the app.")
                    .font(.body)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
            }
            .navigationTitle("Progress")
        }
    }
}

#Preview { ProgressTabView() }
