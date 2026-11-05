import SwiftUI
import Observation
import VNCalendarDomain
import VNCalendarData

@Observable
@MainActor
final class FamilyHierarchyViewModel {
    var reminders: [ReminderEvent] = []
    /// Generation ids the user has collapsed; all generations start expanded.
    private(set) var collapsedGenerations: Set<String> = []

    private let reminderRepository: ReminderRepositoryProtocol
    private let subscriptionManager: SubscriptionManager
    private let evaluateFeatureGateUseCase: EvaluateFeatureGateUseCase

    init(
        reminderRepository: ReminderRepositoryProtocol,
        subscriptionManager: SubscriptionManager,
        evaluateFeatureGateUseCase: EvaluateFeatureGateUseCase
    ) {
        self.reminderRepository = reminderRepository
        self.subscriptionManager = subscriptionManager
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

    func isExpanded(_ generationID: String) -> Bool {
        !collapsedGenerations.contains(generationID)
    }

    func toggleGeneration(_ generationID: String) {
        if collapsedGenerations.contains(generationID) {
            collapsedGenerations.remove(generationID)
        } else {
            collapsedGenerations.insert(generationID)
        }
    }

    func load() async {
        if let items = try? await reminderRepository.fetchAllReminders() {
            self.reminders = items
        }
    }

    /// Keeps the tree in sync with saves made from the router-presented reminder form.
    func observe() async {
        for await items in reminderRepository.observeReminders() {
            reminders = items
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
