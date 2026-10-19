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
    var isShowingCreateReminder = false
    var isShowingPaywall = false
    var editingReminder: ReminderEvent?
    var selectedRitualTitle: String?

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
        let today = calendar.startOfDay(for: Date())
        self.reminders = items.sorted {
            $0.nextOccurrence(after: today, calendar: calendar) < $1.nextOccurrence(after: today, calendar: calendar)
        }
    }

    func checkAndCreate() {
        Task {
            do {
                if try await evaluateFeatureGateUseCase.canAddReminder() {
                    isShowingCreateReminder = true
                } else {
                    isShowingPaywall = true
                }
            } catch {
                isShowingPaywall = true
            }
        }
    }

    func save(_ reminder: ReminderEvent) {
        Task {
            try? await scheduleReminderUseCase.execute(save: reminder)
            await load()
        }
    }

    func delete(_ reminder: ReminderEvent) {
        Task {
            try? await scheduleReminderUseCase.execute(delete: reminder.id)
            await load()
        }
    }
}
