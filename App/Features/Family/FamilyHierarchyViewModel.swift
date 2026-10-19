import SwiftUI
import Observation
import VNCalendarDomain
import VNCalendarData

@Observable
@MainActor
final class FamilyHierarchyViewModel {
    var reminders: [ReminderEvent] = []
    var pressedMemberID: UUID?
    var isShowingCreateReminder = false
    var isShowingPaywall = false
    var selectedReminder: ReminderEvent?

    private let reminderRepository: ReminderRepositoryProtocol
    private let subscriptionManager: SubscriptionManager
    private let scheduleReminderUseCase: ScheduleReminderUseCase
    private let evaluateFeatureGateUseCase: EvaluateFeatureGateUseCase

    init(
        reminderRepository: ReminderRepositoryProtocol,
        subscriptionManager: SubscriptionManager,
        scheduleReminderUseCase: ScheduleReminderUseCase,
        evaluateFeatureGateUseCase: EvaluateFeatureGateUseCase
    ) {
        self.reminderRepository = reminderRepository
        self.subscriptionManager = subscriptionManager
        self.scheduleReminderUseCase = scheduleReminderUseCase
        self.evaluateFeatureGateUseCase = evaluateFeatureGateUseCase
    }

    var isGenealogyUnlocked: Bool {
        FeatureGateRule.isFeatureAvailable(.genealogyMode, isPro: subscriptionManager.entitlement.isPro)
    }

    var groupedGenerations: [FamilyMemberGroup] {
        let gen1 = reminders.filter { $0.relationship?.contains("Cụ") == true }
        let gen1IDs = Set(gen1.map(\.id))

        let gen2 = reminders.filter { item in
            guard !gen1IDs.contains(item.id) else { return false }
            return item.relationship?.contains("Ông") == true || item.relationship?.contains("Bà") == true
        }
        let gen2IDs = Set(gen2.map(\.id))

        let gen3Keys = ["Cha", "Bố", "Mẹ", "Bác", "Chú", "Cô", "Dì"]
        let gen3 = reminders.filter { item in
            guard !gen1IDs.contains(item.id), !gen2IDs.contains(item.id) else { return false }
            guard let rel = item.relationship else { return false }
            return gen3Keys.contains(where: { rel.contains($0) })
        }
        let gen3IDs = Set(gen3.map(\.id))

        let others = reminders.filter { !gen1IDs.contains($0.id) && !gen2IDs.contains($0.id) && !gen3IDs.contains($0.id) }

        var groups: [FamilyMemberGroup] = []
        if !gen1.isEmpty {
            groups.append(FamilyMemberGroup(
                id: "gen1",
                generationTitle: "Thế Hệ Tiên Tổ",
                generationRank: "ĐỜI I",
                members: gen1
            ))
        }
        if !gen2.isEmpty {
            groups.append(FamilyMemberGroup(
                id: "gen2",
                generationTitle: "Thế Hệ Ông Bà",
                generationRank: "ĐỜI II",
                members: gen2
            ))
        }
        if !gen3.isEmpty {
            groups.append(FamilyMemberGroup(
                id: "gen3",
                generationTitle: "Thế Hệ Cha Mẹ & Cô Chú",
                generationRank: "ĐỜI III",
                members: gen3
            ))
        }
        if !others.isEmpty {
            groups.append(FamilyMemberGroup(
                id: "others",
                generationTitle: "Họ Hàng & Kỷ Niệm Khác",
                generationRank: "HẬU DUỆ",
                members: others
            ))
        }
        return groups
    }

    func load() async {
        if let items = try? await reminderRepository.fetchAllReminders() {
            self.reminders = items
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

    func saveMember(_ event: ReminderEvent) {
        Task {
            try? await scheduleReminderUseCase.execute(save: event)
            await load()
        }
    }
}
