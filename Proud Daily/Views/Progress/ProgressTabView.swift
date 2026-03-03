import SwiftUI
import SwiftData
import Charts

// MARK: - ProgressTabView

struct ProgressTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @StateObject private var healthKit = HealthKitManager.shared
    @AppStorage("healthKitEnabled") private var healthKitEnabled = true

    @State private var currentStreak = 0
    @State private var longestStreak = 0
    @State private var selectedDate: Date?
    @State private var showingDayDetail = false
    @State private var showingReflection = false

    private var dataManager: DataManager {
        DataManager(modelContext: modelContext)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    streakHeader
                    StreakCalendarView(
                        accentColor: themeManager.activeAccentColor,
                        modelContext: modelContext,
                        selectedDate: $selectedDate,
                        showingDetail: $showingDayDetail
                    )
                    MoodTrendView(
                        modelContext: modelContext,
                        accentColor: themeManager.activeAccentColor,
                        gradientColors: themeManager.activeGradientColors
                    )
                    PracticeStatsView(
                        modelContext: modelContext,
                        healthKit: healthKit,
                        healthKitEnabled: healthKitEnabled,
                        accentColor: themeManager.activeAccentColor
                    )
                    WeeklySummaryView(
                        modelContext: modelContext,
                        accentColor: themeManager.activeAccentColor,
                        gradientColors: themeManager.activeGradientColors
                    )
                    monthlyReflectionPrompt
                }
                .padding()
            }
            .navigationTitle("Progress")
            .task {
                let dm = dataManager
                currentStreak = dm.calculateCurrentStreak()
                longestStreak = dm.calculateLongestStreak()
                if healthKitEnabled && healthKit.isAvailable {
                    await healthKit.fetchMindfulMinutes()
                }
            }
            .sheet(isPresented: $showingDayDetail) {
                if let date = selectedDate {
                    DayDetailSheet(date: date, modelContext: modelContext, accentColor: themeManager.activeAccentColor)
                        .presentationDetents([.medium, .large])
                }
            }
            .sheet(isPresented: $showingReflection) {
                MonthlyReflectionSheet(modelContext: modelContext, accentColor: themeManager.activeAccentColor)
            }
        }
    }

    // MARK: - Streak Header

    private var streakHeader: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(currentStreak)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(themeManager.activeAccentColor)
                Text(currentStreak == 1 ? "day" : "days")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            Text("Current Streak 🔥")
                .font(.headline)
            Text("Longest: \(longestStreak) days")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: - Monthly Reflection

    @ViewBuilder
    private var monthlyReflectionPrompt: some View {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: .now)
        if day <= 3 {
            Button {
                showingReflection = true
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Monthly Reflection")
                            .font(.headline)
                        Text("What are you most proud of this month?")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(themeManager.activeAccentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Streak Calendar

struct StreakCalendarView: View {
    let accentColor: Color
    let modelContext: ModelContext
    @Binding var selectedDate: Date?
    @Binding var showingDetail: Bool

    @State private var displayMonth = Date()
    @State private var practicedDates: Set<String> = []

    private var calendar: Calendar { Calendar.current }

    var body: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "Streak Calendar", icon: "calendar")

            HStack {
                Button { changeMonth(-1) } label: {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(displayMonth, format: .dateTime.month(.wide).year())
                    .font(.headline)
                Spacer()
                Button { changeMonth(1) } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(calendar.isDate(displayMonth, equalTo: .now, toGranularity: .month))
            }
            .padding(.horizontal, 4)

            let weekdays = calendar.shortWeekdaySymbols
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day.prefix(2))
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            let days = daysInMonth()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, date in
                    if let date {
                        let key = dateKey(date)
                        let practiced = practicedDates.contains(key)
                        let isToday = calendar.isDateInToday(date)

                        Button {
                            selectedDate = date
                            showingDetail = true
                        } label: {
                            Text("\(calendar.component(.day, from: date))")
                                .font(.caption)
                                .fontWeight(isToday ? .bold : .regular)
                                .frame(width: 32, height: 32)
                                .background {
                                    if practiced {
                                        Circle().fill(accentColor)
                                    } else if isToday {
                                        Circle().strokeBorder(accentColor, lineWidth: 2)
                                    }
                                }
                                .foregroundStyle(practiced ? .white : isToday ? accentColor : .primary)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear.frame(width: 32, height: 32)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .task { loadPracticedDates() }
        .onChange(of: displayMonth) { _, _ in loadPracticedDates() }
    }

    private func changeMonth(_ delta: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: delta, to: displayMonth) {
            displayMonth = newMonth
        }
    }

    private func daysInMonth() -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayMonth))
        else { return [] }

        let weekday = calendar.component(.weekday, from: firstDay)
        let leadingBlanks = (weekday - calendar.firstWeekday + 7) % 7

        var result: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                result.append(date)
            }
        }
        return result
    }

    private func loadPracticedDates() {
        let comps = calendar.dateComponents([.year, .month], from: displayMonth)
        guard let start = calendar.date(from: comps),
              let end = calendar.date(byAdding: .month, value: 1, to: start) else { return }

        let descriptor = FetchDescriptor<DailyRecord>(
            predicate: #Predicate<DailyRecord> { $0.date >= start && $0.date < end },
            sortBy: [SortDescriptor(\.date)]
        )
        let records = (try? modelContext.fetch(descriptor)) ?? []
        practicedDates = Set(records.map { dateKey($0.date) })
    }

    private func dateKey(_ date: Date) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(comps.year!)-\(comps.month!)-\(comps.day!)"
    }
}

// MARK: - Mood Trend View

struct MoodTrendView: View {
    let modelContext: ModelContext
    let accentColor: Color
    let gradientColors: [Color]

    @State private var weeklyMoods: [(date: Date, before: Double?, after: Double?)] = []
    @State private var averageMood: Double = 0
    @State private var moodImprovement: Double?

    var body: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "Mood Trends", icon: "heart.text.square")

            if weeklyMoods.isEmpty {
                emptyState("Record your mood to see trends here")
            } else {
                moodChart
                legendRow

                if let improvement = moodImprovement, improvement > 0 {
                    insightCard(improvement: improvement)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .task { loadMoodData() }
    }

    private var moodChart: some View {
        Chart {
            ForEach(weeklyMoods, id: \.date) { point in
                if let after = point.after {
                    LineMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Mood", after)
                    )
                    .foregroundStyle(accentColor)
                    .symbol(Circle())
                }
                if let before = point.before {
                    LineMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Before", before)
                    )
                    .foregroundStyle(accentColor.opacity(0.4))
                    .lineStyle(StrokeStyle(dash: [5, 3]))
                    .symbol(Triangle())
                }
            }
        }
        .chartYScale(domain: 1...5)
        .chartYAxis {
            AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                AxisValueLabel {
                    if let v = value.as(Int.self), let mood = Mood(rawValue: v) {
                        Text(mood.emoji)
                    }
                }
            }
        }
        .frame(height: 180)
    }

    private var legendRow: some View {
        HStack {
            Label("After", systemImage: "circle.fill")
                .font(.caption2)
                .foregroundStyle(accentColor)
            Label("Before", systemImage: "triangle.fill")
                .font(.caption2)
                .foregroundStyle(accentColor.opacity(0.4))
            Spacer()
            Text("Avg: \(String(format: "%.1f", averageMood))")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
    }

    private func insightCard(improvement: Double) -> some View {
        HStack {
            Image(systemName: "arrow.up.right")
                .foregroundStyle(.green)
            Text("Your mood improved \(String(format: "%.0f", improvement))% on days you practiced")
                .font(.subheadline)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    private func loadMoodData() {
        let calendar = Calendar.current
        let now = Date()
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return }
        let startOfWeek = calendar.startOfDay(for: weekAgo)

        let descriptor = FetchDescriptor<DailyRecord>(
            predicate: #Predicate<DailyRecord> { $0.date >= startOfWeek },
            sortBy: [SortDescriptor(\.date)]
        )
        let records = (try? modelContext.fetch(descriptor)) ?? []

        weeklyMoods = records.compactMap { record in
            let before = record.moodBeforeRaw.map(Double.init)
            let after = record.moodAfterRaw.map(Double.init)
            guard before != nil || after != nil else { return nil }
            return (date: record.date, before: before, after: after)
        }

        let afterMoods = records.compactMap(\.moodAfterRaw)
        averageMood = afterMoods.isEmpty ? 0 : Double(afterMoods.reduce(0, +)) / Double(afterMoods.count)

        // Mood improvement on practice vs non-practice days
        let allDescriptor = FetchDescriptor<DailyRecord>(sortBy: [SortDescriptor(\.date)])
        let allRecords = (try? modelContext.fetch(allDescriptor)) ?? []

        let practiceDayMoods = allRecords.filter { ($0.affirmationsViewed?.count ?? 0) > 0 }.compactMap(\.moodAfterRaw)
        let nonPracticeMoods = allRecords.filter { ($0.affirmationsViewed?.count ?? 0) == 0 }.compactMap(\.moodAfterRaw)

        if !practiceDayMoods.isEmpty && !nonPracticeMoods.isEmpty {
            let practiceAvg = Double(practiceDayMoods.reduce(0, +)) / Double(practiceDayMoods.count)
            let nonPracticeAvg = Double(nonPracticeMoods.reduce(0, +)) / Double(nonPracticeMoods.count)
            if nonPracticeAvg > 0 {
                moodImprovement = ((practiceAvg - nonPracticeAvg) / nonPracticeAvg) * 100
            }
        }
    }
}

// MARK: - Practice Stats

struct PracticeStatsView: View {
    let modelContext: ModelContext
    @ObservedObject var healthKit: HealthKitManager
    let healthKitEnabled: Bool
    let accentColor: Color

    @State private var totalAffirmations = 0
    @State private var totalJournals = 0
    @State private var totalFavorites = 0
    @State private var favoriteCategory: AffirmationCategory?

    var body: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "Practice Stats", icon: "chart.bar.fill")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(title: "Affirmations Viewed", value: "\(totalAffirmations)", unit: "total", color: accentColor)
                if healthKitEnabled && healthKit.isAvailable {
                    StatCard(title: "Mindful Minutes", value: String(format: "%.0f", healthKit.totalMindfulMinutesThisWeek), unit: "this week", color: .purple)
                }
                StatCard(title: "Journal Entries", value: "\(totalJournals)", unit: "written", color: .orange)
                StatCard(title: "Favorites Saved", value: "\(totalFavorites)", unit: "saved", color: .pink)
            }

            if let cat = favoriteCategory {
                HStack {
                    Text(cat.emoji)
                    Text("Most viewed: \(cat.displayName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(12)
                .background(accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .task { loadStats() }
    }

    private func loadStats() {
        let allRecords = (try? modelContext.fetch(FetchDescriptor<DailyRecord>())) ?? []
        totalAffirmations = allRecords.reduce(0) { $0 + ($1.affirmationsViewed?.count ?? 0) }
        totalJournals = (try? modelContext.fetchCount(FetchDescriptor<JournalEntry>())) ?? 0
        totalFavorites = (try? modelContext.fetchCount(FetchDescriptor<FavoriteAffirmation>())) ?? 0

        var categoryCounts: [AffirmationCategory: Int] = [:]
        for record in allRecords {
            for aff in record.affirmationsViewed ?? [] {
                categoryCounts[aff.category, default: 0] += 1
            }
        }
        favoriteCategory = categoryCounts.max(by: { $0.value < $1.value })?.key
    }
}

// MARK: - Weekly Summary

struct WeeklySummaryView: View {
    let modelContext: ModelContext
    let accentColor: Color
    let gradientColors: [Color]

    @State private var daysPracticed = 0
    @State private var streakStatus = ""
    @State private var moodTrendText = ""
    @State private var topCategory: AffirmationCategory?
    @State private var favoriteAffirmation: String?
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                sectionHeader(title: "Weekly Summary", icon: "rectangle.stack")
                Spacer()
                if daysPracticed > 0 {
                    Button {
                        generateShareImage()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.body)
                    }
                }
            }

            if daysPracticed == 0 {
                emptyState("Complete a week to see your summary")
            } else {
                VStack(spacing: 8) {
                    summaryRow(emoji: "📅", text: "\(daysPracticed)/7 days practiced")
                    summaryRow(emoji: "🔥", text: streakStatus)
                    if !moodTrendText.isEmpty {
                        summaryRow(emoji: "📈", text: moodTrendText)
                    }
                    if let cat = topCategory {
                        summaryRow(emoji: cat.emoji, text: "Most viewed: \(cat.displayName)")
                    }
                    if let aff = favoriteAffirmation {
                        summaryRow(emoji: "⭐", text: "\"\(aff)\"")
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .task { loadWeeklySummary() }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheetView(image: image)
            }
        }
    }

    private func summaryRow(emoji: String, text: String) -> some View {
        HStack(alignment: .top) {
            Text(emoji)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
        .padding(.vertical, 2)
    }

    private func loadWeeklySummary() {
        let calendar = Calendar.current
        let now = Date()
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return }
        let start = calendar.startOfDay(for: weekAgo)

        let descriptor = FetchDescriptor<DailyRecord>(
            predicate: #Predicate<DailyRecord> { $0.date >= start },
            sortBy: [SortDescriptor(\.date)]
        )
        let records = (try? modelContext.fetch(descriptor)) ?? []
        daysPracticed = records.count

        let dm = DataManager(modelContext: modelContext)
        let streak = dm.calculateCurrentStreak()
        streakStatus = streak > 0 ? "\(streak)-day streak going strong!" : "Start a new streak today"

        let moods = records.compactMap(\.moodAfterRaw)
        if moods.count >= 2 {
            let firstHalf = moods.prefix(moods.count / 2)
            let secondHalf = moods.suffix(moods.count / 2)
            let firstAvg = Double(firstHalf.reduce(0, +)) / Double(firstHalf.count)
            let secondAvg = Double(secondHalf.reduce(0, +)) / Double(secondHalf.count)
            if secondAvg > firstAvg {
                moodTrendText = "Mood trending up ↑"
            } else if secondAvg < firstAvg {
                moodTrendText = "Mood trending down ↓"
            } else {
                moodTrendText = "Mood holding steady →"
            }
        }

        var categoryCounts: [AffirmationCategory: Int] = [:]
        for record in records {
            for aff in record.affirmationsViewed ?? [] {
                categoryCounts[aff.category, default: 0] += 1
            }
        }
        topCategory = categoryCounts.max(by: { $0.value < $1.value })?.key

        var affCounts: [String: Int] = [:]
        for record in records {
            for aff in record.affirmationsViewed ?? [] {
                affCounts[aff.text, default: 0] += 1
            }
        }
        favoriteAffirmation = affCounts.max(by: { $0.value < $1.value })?.key
    }

    @MainActor
    private func generateShareImage() {
        let renderer = ImageRenderer(content:
            WeeklySummaryShareCard(
                daysPracticed: daysPracticed,
                streakStatus: streakStatus,
                moodTrendText: moodTrendText,
                topCategory: topCategory,
                favoriteAffirmation: favoriteAffirmation,
                gradientColors: gradientColors
            )
            .frame(width: 400)
        )
        renderer.scale = 3
        if let uiImage = renderer.uiImage {
            shareImage = uiImage
            showShareSheet = true
        }
    }
}

// MARK: - Share Card

struct WeeklySummaryShareCard: View {
    let daysPracticed: Int
    let streakStatus: String
    let moodTrendText: String
    let topCategory: AffirmationCategory?
    let favoriteAffirmation: String?
    let gradientColors: [Color]

    var body: some View {
        VStack(spacing: 16) {
            Text("My Week with Proud Daily")
                .font(.title2.bold())
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 8) {
                Text("📅 \(daysPracticed)/7 days practiced")
                Text("🔥 \(streakStatus)")
                if !moodTrendText.isEmpty { Text("📈 \(moodTrendText)") }
                if let cat = topCategory { Text("\(cat.emoji) Most viewed: \(cat.displayName)") }
                if let aff = favoriteAffirmation { Text("⭐ \"\(aff)\"").lineLimit(2) }
            }
            .font(.body)
            .foregroundStyle(.white.opacity(0.9))
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("🏳️‍🌈")
                .font(.largeTitle)
        }
        .padding(32)
        .background(
            LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

// MARK: - Share Sheet

struct ShareSheetView: UIViewControllerRepresentable {
    let image: UIImage

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [image], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Day Detail Sheet

struct DayDetailSheet: View {
    let date: Date
    let modelContext: ModelContext
    let accentColor: Color

    @State private var record: DailyRecord?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let record {
                        if let moodBefore = record.moodBefore {
                            infoRow(label: "Mood Before", value: "\(moodBefore.emoji) \(moodBefore.displayName)")
                        }
                        if let moodAfter = record.moodAfter {
                            infoRow(label: "Mood After", value: "\(moodAfter.emoji) \(moodAfter.displayName)")
                        }

                        let viewed = record.affirmationsViewed ?? []
                        if !viewed.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Affirmations Viewed (\(viewed.count))")
                                    .font(.headline)
                                ForEach(viewed) { aff in
                                    Text("• \(aff.text)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if let journal = record.journalEntry {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Journal Entry")
                                    .font(.headline)
                                Text(journal.text)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if record.minutesPracticed > 0 {
                            infoRow(label: "Practice Time", value: "\(String(format: "%.0f", record.minutesPracticed)) min")
                        }
                    } else {
                        ContentUnavailableView("No Activity", systemImage: "moon.zzz", description: Text("Nothing recorded on this day"))
                    }
                }
                .padding()
            }
            .navigationTitle(date.formatted(date: .abbreviated, time: .omitted))
            .navigationBarTitleDisplayMode(.inline)
        }
        .task { loadRecord() }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }

    private func loadRecord() {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return }

        let descriptor = FetchDescriptor<DailyRecord>(
            predicate: #Predicate<DailyRecord> { $0.date >= start && $0.date < end }
        )
        record = try? modelContext.fetch(descriptor).first
    }
}

// MARK: - Monthly Reflection Sheet

struct MonthlyReflectionSheet: View {
    let modelContext: ModelContext
    let accentColor: Color

    @Environment(\.dismiss) private var dismiss
    @State private var reflectionText = ""
    @State private var selectedPrompt = ""

    private let prompts = [
        "What has changed in how you see yourself?",
        "What are you most proud of this month?",
        "What moment of joy stands out?",
        "How has your relationship with yourself grown?",
        "What affirmation resonated most deeply?"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(selectedPrompt)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                TextEditor(text: $reflectionText)
                    .frame(minHeight: 200)
                    .padding(8)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Monthly Reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveReflection()
                        dismiss()
                    }
                    .disabled(reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                let month = Calendar.current.component(.month, from: .now)
                selectedPrompt = prompts[month % prompts.count]
            }
        }
    }

    private func saveReflection() {
        let dm = DataManager(modelContext: modelContext)
        let prefix = "📝 Monthly Reflection: \(selectedPrompt)\n\n"
        _ = dm.createJournalEntry(text: prefix + reflectionText)
    }
}

// MARK: - Reusable Components

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
                .lineLimit(1)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)                    .font(.title.bold())
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

// MARK: - View Helpers

private func sectionHeader(title: String, icon: String) -> some View {
    HStack {
        Image(systemName: icon)
            .font(.title3)
        Text(title)
            .font(.title3.bold())
        Spacer()
    }
}

private func emptyState(_ text: String) -> some View {
    Text(text)
        .font(.subheadline)
        .foregroundStyle(.tertiary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
}

#Preview {
    ProgressTabView()
        .environment(ThemeManager())
        .modelContainer(for: [DailyRecord.self, Affirmation.self, JournalEntry.self, FavoriteAffirmation.self])
}
