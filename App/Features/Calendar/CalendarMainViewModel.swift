import SwiftUI
import Observation
import VNCalendarDomain
import VNCalendarKit
import VNCalendarLunar

/// Nearest memorial (giỗ / kỵ) shown in the Home hero.
public struct UpcomingMemorial: Equatable {
    public let title: String
    public let countdown: String
}

@Observable
@MainActor
final class CalendarMainViewModel {
    let adapterViewModel: VNCalendarAdapterViewModel
    var todayDetails: DayCalendarDetails?
    var upcomingMemorial: UpcomingMemorial?

    private let getMonthCalendarUseCase: GetMonthCalendarUseCase
    private let reminderRepository: ReminderRepositoryProtocol
    private let evaluateFeatureGateUseCase: EvaluateFeatureGateUseCase

    init(
        adapterViewModel: VNCalendarAdapterViewModel = VNCalendarAdapterViewModel(),
        getMonthCalendarUseCase: GetMonthCalendarUseCase,
        reminderRepository: ReminderRepositoryProtocol,
        evaluateFeatureGateUseCase: EvaluateFeatureGateUseCase
    ) {
        self.adapterViewModel = adapterViewModel
        self.getMonthCalendarUseCase = getMonthCalendarUseCase
        self.reminderRepository = reminderRepository
        self.evaluateFeatureGateUseCase = evaluateFeatureGateUseCase
    }

    func loadData() async {
        let now = Date()
        let solar = SolarDate(from: now)
        todayDetails = try? await getMonthCalendarUseCase.execute(solarDate: solar)

        if let reminders = try? await reminderRepository.fetchAllReminders() {
            apply(reminders)
        }
    }

    /// Long-running: keeps the grid in sync after sheet-driven saves. Ends when the calling task is cancelled.
    func observeReminders() async {
        for await reminders in reminderRepository.observeReminders() {
            apply(reminders)
        }
    }

    private func apply(_ reminders: [ReminderEvent]) {
        adapterViewModel.updateReminders(reminders)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = VNTime.vietnam
        let now = Date()
        let today = calendar.startOfDay(for: now)
        upcomingMemorial = reminders
            .filter { $0.category == .deathAnniversary || $0.category == .ancestral }
            .min { $0.nextOccurrence(after: today, calendar: calendar) < $1.nextOccurrence(after: today, calendar: calendar) }
            .map { UpcomingMemorial(title: $0.title, countdown: $0.countdownText(relativeTo: now, calendar: calendar)) }
    }

    func createReminderGate() async -> CreateReminderGate {
        do {
            return try await evaluateFeatureGateUseCase.canAddReminder() ? .allowed : .requiresPro
        } catch {
            return .requiresPro
        }
    }
}
