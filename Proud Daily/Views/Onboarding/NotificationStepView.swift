import SwiftUI

struct NotificationStepView: View {
    @Bindable var preferences: UserPreferences
    var onNext: () -> Void
    var onSkip: () -> Void

    @State private var notificationsEnabled = false
    @State private var morningTime = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? .now
    @State private var eveningTime = Calendar.current.date(from: DateComponents(hour: 21, minute: 0)) ?? .now
    @State private var additionalTimes: [Date] = []

    private let maxTimes = 5

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 40)

                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.white)

                Text("Stay affirmed throughout the day")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Toggle(isOn: $notificationsEnabled) {
                    Text("Enable notifications")
                        .foregroundStyle(.white)
                        .fontWeight(.medium)
                }
                .tint(.white)
                .padding(.horizontal, 40)

                if notificationsEnabled {
                    VStack(spacing: 16) {
                        timeRow(label: "Morning", time: $morningTime)
                        timeRow(label: "Evening", time: $eveningTime)

                        ForEach(additionalTimes.indices, id: \.self) { index in
                            HStack {
                                timeRow(label: "Reminder \(index + 3)", time: $additionalTimes[index])
                                Button {
                                    additionalTimes.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                            }
                        }

                        if totalTimeCount < maxTimes {
                            Button {
                                additionalTimes.append(
                                    Calendar.current.date(from: DateComponents(hour: 13, minute: 0)) ?? .now
                                )
                            } label: {
                                Label("Add another time", systemImage: "plus.circle")
                                    .foregroundStyle(.white.opacity(0.8))
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Text("You can always change this in Settings")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))

                VStack(spacing: 12) {
                    Button(action: {
                        saveNotificationPrefs()
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
        .scrollIndicators(.hidden)
        .animation(.easeInOut, value: notificationsEnabled)
    }

    private var totalTimeCount: Int {
        2 + additionalTimes.count
    }

    private func timeRow(label: String, time: Binding<Date>) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.white)
                .font(.subheadline)
            Spacer()
            DatePicker("", selection: time, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(.white)
                .colorScheme(.dark)
        }
    }

    private func saveNotificationPrefs() {
        guard notificationsEnabled else {
            preferences.notificationTimes = []
            return
        }
        var times = [morningTime, eveningTime]
        times.append(contentsOf: additionalTimes)
        preferences.notificationTimes = times

        Task {
            await NotificationManager.shared.requestPermission()
        }
    }
}
