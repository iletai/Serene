import SwiftUI
import Observation
import VNCalendarDomain
import VNCalendarLunar

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
}
