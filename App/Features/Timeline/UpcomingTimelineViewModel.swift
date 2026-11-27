import SwiftUI
import Observation
import VNCalendarDomain
import VNCalendarLunar

/// One reminder occurrence inside a month section of the memorial timeline.
struct TimelineRowModel: Identifiable {
    let reminder: ReminderEvent
    let solarDay: Int
    let solarMonth: Int
    let weekday: String
    let lunarLabel: String
    let countdown: String
    let isSoon: Bool

    var id: UUID { reminder.id }
}

/// Month grouping of the timeline, e.g. "Tháng 11, 2026 · tháng Mười âm lịch".
struct TimelineMonthSection: Identifiable {
    let id: String
    let title: String
    let lunarSubtitle: String?
    let rows: [TimelineRowModel]
}

@Observable
@MainActor
final class UpcomingTimelineViewModel {
    var reminders: [ReminderEvent] = []
    var searchQuery = ""
    var selectedFilter: MemorialFilterTab = .all

    private let reminderRepository: ReminderRepositoryProtocol
    private let scheduleReminderUseCase: ScheduleReminderUseCase
    private let evaluateFeatureGateUseCase: EvaluateFeatureGateUseCase
    private var calendar: Calendar
    private let engine = LunarAstronomicalEngine()

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = VNTime.vietnam
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        return formatter
    }()

    init(
        reminderRepository: ReminderRepositoryProtocol,
        scheduleReminderUseCase: ScheduleReminderUseCase,
        evaluateFeatureGateUseCase: EvaluateFeatureGateUseCase,
        calendar: Calendar = {
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = VNTime.vietnam
            return cal
        }()
    ) {
        self.reminderRepository = reminderRepository
        self.scheduleReminderUseCase = scheduleReminderUseCase
        self.evaluateFeatureGateUseCase = evaluateFeatureGateUseCase
        self.calendar = calendar
    }

    var filteredReminders: [ReminderEvent] {
        let base = reminders.filter { selectedFilter.matches(category: $0.category) }
        guard !searchQuery.isEmpty else { return base }
        return base.filter {
            $0.title.localizedCaseInsensitiveContains(searchQuery) ||
            ($0.note?.localizedCaseInsensitiveContains(searchQuery) == true) ||
            ($0.relationship?.localizedCaseInsensitiveContains(searchQuery) == true)
        }
    }

    /// Reminders grouped by the solar month of their next occurrence.
    var sections: [TimelineMonthSection] {
        let today = calendar.startOfDay(for: Date())
        var order: [String] = []
        var buckets: [String: [TimelineRowModel]] = [:]
        var lunarMonths: [String: Set<Int>] = [:]

        for reminder in filteredReminders {
            let occurrence = reminder.nextOccurrence(after: today, calendar: calendar)
            let components = calendar.dateComponents([.year, .month, .day], from: occurrence)
            let year = components.year ?? 0
            let month = components.month ?? 1
            let day = components.day ?? 1
            let key = "\(year)-\(month)"
            if buckets[key] == nil {
                order.append(key)
                buckets[key] = []
            }
            let lunar = engine.convertToLunar(from: SolarDate(day: day, month: month, year: year))
            lunarMonths[key, default: []].insert(lunar.month)
            let daysUntil = calendar.dateComponents([.day], from: today, to: occurrence).day ?? 0
            buckets[key]?.append(
                TimelineRowModel(
                    reminder: reminder,
                    solarDay: day,
                    solarMonth: month,
                    weekday: Self.weekdayFormatter.string(from: occurrence).uppercased(),
                    lunarLabel: lunarLabel(day: lunar.day, month: lunar.month),
                    countdown: countdownText(for: reminder),
                    isSoon: (0...7).contains(daysUntil)
                )
            )
        }

        return order.compactMap { key in
            guard let rows = buckets[key], let first = rows.first else { return nil }
            let month = first.solarMonth
            let year = Int(key.split(separator: "-").first ?? "") ?? 0
            let lunarNames = (lunarMonths[key] ?? []).sorted().map(lunarMonthName)
            return TimelineMonthSection(
                id: key,
                title: String(format: String(localized: "calendar.header.title.month"), month, year),
                lunarSubtitle: lunarNames.isEmpty
                    ? nil
                    : String(format: String(localized: "timeline.lunar_month_suffix"), lunarNames.joined(separator: " & ")),
                rows: rows
            )
        }
    }

    var urgentMemorial: ReminderEvent? {
        reminders.first { $0.category == .deathAnniversary || $0.category == .ancestral }
    }

    func countdownText(for reminder: ReminderEvent) -> String {
        reminder.countdownText(relativeTo: Date(), calendar: calendar)
    }

    func load() async {
        guard let items = try? await reminderRepository.fetchAllReminders() else { return }
        apply(items)
    }

    /// Long-running: refreshes after every save/delete (the reminder form saves outside this ViewModel).
    func observe() async {
        for await items in reminderRepository.observeReminders() {
            apply(items)
        }
    }

    func createReminderGate() async -> CreateReminderGate {
        do {
            return try await evaluateFeatureGateUseCase.canAddReminder() ? .allowed : .requiresPro
        } catch {
            return .requiresPro
        }
    }

    private func apply(_ items: [ReminderEvent]) {
        let today = calendar.startOfDay(for: Date())
        self.reminders = items.sorted {
            $0.nextOccurrence(after: today, calendar: calendar) < $1.nextOccurrence(after: today, calendar: calendar)
        }
    }

    func delete(_ reminder: ReminderEvent) {
        Task {
            try? await scheduleReminderUseCase.execute(delete: reminder.id)
            await load()
        }
    }

    // MARK: - Formatting

    private func lunarMonthName(_ month: Int) -> String {
        let names: [LocalizedStringResource] = [
            "today.lunar_month_1", "today.lunar_month_2", "today.lunar_month_3", "today.lunar_month_4",
            "today.lunar_month_5", "today.lunar_month_6", "today.lunar_month_7", "today.lunar_month_8",
            "today.lunar_month_9", "today.lunar_month_10", "today.lunar_month_11", "today.lunar_month_12"
        ]
        guard month >= 1, month <= 12 else {
            return String(format: String(localized: "calendar.month_name_number"), month)
        }
        return String(localized: names[month - 1]).lowercased()
    }

    private func lunarLabel(day: Int, month: Int) -> String {
        String(format: String(localized: "daydetail.header.lunar_day"), day, lunarMonthName(month))
    }
}
