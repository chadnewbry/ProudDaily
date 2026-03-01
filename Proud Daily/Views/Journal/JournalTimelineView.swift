import SwiftUI
import SwiftData

struct JournalTimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]

    @State private var todayEntry: JournalEntry?
    @State private var todayText = ""
    @State private var moodBefore: Mood?
    @State private var moodAfter: Mood?
    @State private var autoSaveTimer: Timer?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Today's entry
                todaySection
                    .padding()

                Divider()
                    .padding(.horizontal)

                // Past entries
                if pastEntries.isEmpty {
                    Text("Your past journal entries will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 40)
                } else {
                    ForEach(groupedByDate, id: \.key) { dateString, dayEntries in
                        Section {
                            ForEach(dayEntries) { entry in
                                PastEntryRow(entry: entry)
                            }
                        } header: {
                            Text(dateString)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                                .padding(.top, 16)
                                .padding(.bottom, 4)
                        }
                    }
                }
            }
        }
        .onAppear { loadToday() }
        .onDisappear { autoSaveTimer?.invalidate() }
    }

    // MARK: - Today Section

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today")
                .font(.title3.weight(.bold))

            Text("How does this resonate with you today?")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Mood before
            VStack(alignment: .leading, spacing: 8) {
                Text("How are you feeling?")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                MoodPicker(selectedMood: $moodBefore)
                    .onChange(of: moodBefore) { _, newMood in
                        ensureTodayEntry()
                        if let entry = todayEntry {
                            let dm = DataManager(modelContext: modelContext)
                            dm.updateJournalMoodBefore(entry, mood: newMood)
                        }
                    }
            }

            // Text entry
            TextEditor(text: $todayText)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .onChange(of: todayText) { _, _ in
                    scheduleAutoSave()
                }

            // Mood after
            VStack(alignment: .leading, spacing: 8) {
                Text("How do you feel now?")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                MoodPicker(selectedMood: $moodAfter)
                    .onChange(of: moodAfter) { _, newMood in
                        ensureTodayEntry()
                        if let entry = todayEntry {
                            let dm = DataManager(modelContext: modelContext)
                            dm.updateJournalMoodAfter(entry, mood: newMood)
                        }
                    }
            }
        }
    }

    // MARK: - Helpers

    private var pastEntries: [JournalEntry] {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        return entries.filter { $0.date < startOfDay }
    }

    private var groupedByDate: [(key: String, value: [JournalEntry])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let grouped = Dictionary(grouping: pastEntries) { entry in
            formatter.string(from: entry.date)
        }
        return grouped.sorted { $0.value.first!.date > $1.value.first!.date }
    }

    private func loadToday() {
        let dm = DataManager(modelContext: modelContext)
        if let existing = dm.todayJournalEntry() {
            todayEntry = existing
            todayText = existing.text
            moodBefore = existing.moodBefore
            moodAfter = existing.moodAfter
        }
    }

    private func ensureTodayEntry() {
        guard todayEntry == nil else { return }
        let dm = DataManager(modelContext: modelContext)
        let entry = dm.createJournalEntry(text: todayText, moodBefore: moodBefore, moodAfter: moodAfter)
        todayEntry = entry
    }

    private func scheduleAutoSave() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            Task { @MainActor in
                ensureTodayEntry()
                if let entry = todayEntry {
                    let dm = DataManager(modelContext: modelContext)
                    dm.updateJournalEntry(entry, text: todayText)
                }
            }
        }
    }
}

// MARK: - Mood Picker

struct MoodPicker: View {
    @Binding var selectedMood: Mood?

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Mood.allCases) { mood in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedMood = selectedMood == mood ? nil : mood
                    }
                } label: {
                    VStack(spacing: 2) {
                        Text(mood.emoji)
                            .font(.title2)
                        Text(mood.displayName)
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 4)
                    .background(
                        selectedMood == mood
                            ? Color.accentColor.opacity(0.15)
                            : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .scaleEffect(selectedMood == mood ? 1.15 : 1.0)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Past Entry Row

struct PastEntryRow: View {
    let entry: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if let mood = entry.moodBefore {
                    Text(mood.emoji)
                }
                Text(entry.text)
                    .font(.body)
                    .lineLimit(3)
                Spacer()
                if let mood = entry.moodAfter {
                    Text(mood.emoji)
                }
            }

            Text(entry.date, style: .time)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

#Preview { JournalTimelineView() }
