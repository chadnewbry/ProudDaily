import SwiftUI

struct ProgressTabView: View {
    @StateObject private var healthKit = HealthKitManager.shared
    @AppStorage("healthKitEnabled") private var healthKitEnabled = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if healthKitEnabled && healthKit.isAvailable {
                        mindfulMinutesSection
                    }

                    placeholderSection
                }
                .padding()
            }
            .navigationTitle("Progress")
            .task {
                if healthKitEnabled && healthKit.isAvailable {
                    await healthKit.fetchMindfulMinutes()
                }
            }
        }
    }

    private var mindfulMinutesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundStyle(.purple)
                Text("Mindful Minutes")
                    .font(.title3.bold())
                Spacer()
            }

            HStack(spacing: 16) {
                StatCard(
                    title: "Today",
                    value: String(format: "%.0f", healthKit.totalMindfulMinutesToday),
                    unit: "min",
                    color: .purple
                )
                StatCard(
                    title: "This Week",
                    value: String(format: "%.0f", healthKit.totalMindfulMinutesThisWeek),
                    unit: "min",
                    color: .indigo
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var placeholderSection: some View {
        VStack(spacing: 12) {
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
        }
        .padding(.top, 24)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title.bold())
                    .foregroundStyle(color)
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview { ProgressTabView() }
