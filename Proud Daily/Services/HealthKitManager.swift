import Foundation
import HealthKit

@MainActor
final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()
    private let mindfulType = HKCategoryType(.mindfulSession)

    @Published var isAuthorized = false
    @Published var totalMindfulMinutesToday: Double = 0
    @Published var totalMindfulMinutesThisWeek: Double = 0

    private var sessionStartDate: Date?

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        guard isAvailable else { return }

        let typesToShare: Set<HKSampleType> = [mindfulType]
        let typesToRead: Set<HKObjectType> = [mindfulType]

        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            isAuthorized = true
            await fetchMindfulMinutes()
        } catch {
            print("HealthKit authorization failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Session Tracking

    func startSession() {
        sessionStartDate = Date()
    }

    func endSession() {
        guard let start = sessionStartDate else { return }
        let duration = Date().timeIntervalSince(start)
        sessionStartDate = nil

        guard duration >= 30 else { return }
        guard isAuthorized, UserDefaults.standard.bool(forKey: "healthKitEnabled") else { return }

        let end = Date()
        let sample = HKCategorySample(
            type: mindfulType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: start,
            end: end
        )

        Task {
            do {
                try await healthStore.save(sample)
                await fetchMindfulMinutes()
            } catch {
                print("Failed to save mindful session: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Reading Data

    func fetchMindfulMinutes() async {
        guard isAvailable, isAuthorized else { return }

        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)

        totalMindfulMinutesToday = await queryMindfulMinutes(from: startOfDay, to: now)

        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? startOfDay
        totalMindfulMinutesThisWeek = await queryMindfulMinutes(from: startOfWeek, to: now)
    }

    private func queryMindfulMinutes(from start: Date, to end: Date) async -> Double {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: mindfulType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                guard let samples = samples as? [HKCategorySample], error == nil else {
                    continuation.resume(returning: 0)
                    return
                }

                let totalSeconds = samples.reduce(0.0) { sum, sample in
                    sum + sample.endDate.timeIntervalSince(sample.startDate)
                }
                continuation.resume(returning: totalSeconds / 60.0)
            }
            healthStore.execute(query)
        }
    }
}
