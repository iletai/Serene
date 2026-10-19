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
    var isShowingCreateReminder = false
    var isShowingPaywall = false
    var isShowingSearch = false
    var isShowingSettings = false

    private let getMonthCalendarUseCase: GetMonthCalendarUseCase
    private let reminderRepository: ReminderRepositoryProtocol
    private let scheduleReminderUseCase: ScheduleReminderUseCase
    private let evaluateFeatureGateUseCase: EvaluateFeatureGateUseCase

    init(
        adapterViewModel: VNCalendarAdapterViewModel = VNCalendarAdapterViewModel(),
        getMonthCalendarUseCase: GetMonthCalendarUseCase,
        reminderRepository: ReminderRepositoryProtocol,
        scheduleReminderUseCase: ScheduleReminderUseCase,
        evaluateFeatureGateUseCase: EvaluateFeatureGateUseCase
    ) {
        self.adapterViewModel = adapterViewModel
        self.getMonthCalendarUseCase = getMonthCalendarUseCase
        self.reminderRepository = reminderRepository
        self.scheduleReminderUseCase = scheduleReminderUseCase
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

    func checkAndShowReminderForm() {
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

    func saveReminder(_ reminder: ReminderEvent) {
        Task {
            do {
                try await scheduleReminderUseCase.execute(save: reminder)
            } catch {
                // Surface save failures instead of silently dropping the reminder.
            }
            await loadData()
        }
    }
}
