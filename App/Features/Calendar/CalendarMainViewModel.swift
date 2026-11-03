import SwiftUI
import Observation
import VNCalendarDomain
import VNCalendarKit
import VNCalendarLunar

@Observable
@MainActor
final class CalendarMainViewModel {
    let adapterViewModel: VNCalendarAdapterViewModel
    var todayDetails: DayCalendarDetails?

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
            adapterViewModel.updateReminders(reminders)
        }
    }

    /// Long-running: keeps the grid in sync after sheet-driven saves. Ends when the calling task is cancelled.
    func observeReminders() async {
        for await reminders in reminderRepository.observeReminders() {
            adapterViewModel.updateReminders(reminders)
        }
    }

    func createReminderGate() async -> CreateReminderGate {
        do {
            return try await evaluateFeatureGateUseCase.canAddReminder() ? .allowed : .requiresPro
        } catch {
            return .requiresPro
        }
    }
}
