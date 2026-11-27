import SwiftUI
import Observation
import VNCalendarDomain
import VNCalendarData
import VNCalendarLunar

@Observable
@MainActor
final class FamilyHierarchyViewModel {
    var reminders: [ReminderEvent] = [] {
        didSet {
            // Cached: the canvas re-renders on every pinch frame and each info needs a lunar conversion.
            let stamp = now()
            infoByID = Dictionary(
                reminders.map { ($0.id, FamilyMemberInfo(member: $0, now: stamp, calendar: calendar)) },
                uniquingKeysWith: { first, _ in first }
            )
        }
    }
    private var infoByID: [UUID: FamilyMemberInfo] = [:]
    /// Member whose profile sheet is open.
    var selectedMember: ReminderEvent?
    /// Lunar month (1...12) the ring currently spotlights; nil = none.
    private(set) var highlightedMonth: Int?
    /// Member the canvas should centre on (next memorial on load, earliest of the ring month on tap).
    private(set) var focusMemberID: UUID?

    private let reminderRepository: ReminderRepositoryProtocol
    private let subscriptionManager: SubscriptionManager
    private let evaluateFeatureGateUseCase: EvaluateFeatureGateUseCase
    private let now: @Sendable () -> Date
    private let calendar = VNTime.vietnamCalendar

    init(
        reminderRepository: ReminderRepositoryProtocol,
        subscriptionManager: SubscriptionManager,
        evaluateFeatureGateUseCase: EvaluateFeatureGateUseCase,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.reminderRepository = reminderRepository
        self.subscriptionManager = subscriptionManager
        self.evaluateFeatureGateUseCase = evaluateFeatureGateUseCase
        self.now = now
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
                generationTitle: String(localized: "family.gen1_title"),
                generationRank: String(localized: "family.gen1_rank"),
                members: gen1
            ))
        }
        if !gen2.isEmpty {
            groups.append(FamilyMemberGroup(
                id: "gen2",
                generationTitle: String(localized: "family.gen2_title"),
                generationRank: String(localized: "family.gen2_rank"),
                members: gen2
            ))
        }
        if !gen3.isEmpty {
            groups.append(FamilyMemberGroup(
                id: "gen3",
                generationTitle: String(localized: "family.gen3_title"),
                generationRank: String(localized: "family.gen3_rank"),
                members: gen3
            ))
        }
        if !others.isEmpty {
            groups.append(FamilyMemberGroup(
                id: "others",
                generationTitle: String(localized: "family.others_title"),
                generationRank: String(localized: "family.others_rank"),
                members: others
            ))
        }
        return groups
    }

    var ringMonths: [FamilyRingMonth] {
        FamilyRingMonth.months(from: reminders)
    }

    /// Lunar month of "today", for the ring's current-month marker.
    var currentLunarMonth: Int {
        LunarAstronomicalEngine.shared.convertToLunar(from: SolarDate(from: now(), calendar: calendar)).month
    }

    /// The worshipped member whose next memorial comes first.
    var nextMemorial: ReminderEvent? {
        reminders
            .filter(FamilyMemberInfo.isWorshipped)
            .min { info(for: $0).nextDate < info(for: $1).nextDate }
    }

    /// Ring slot of `nextMemorial`; nil when that memorial is on a solar date (not on the lunar ring).
    var nextRingMonth: Int? {
        nextMemorial.flatMap { $0.dateType == .lunar ? $0.month : nil }
    }

    func info(for member: ReminderEvent) -> FamilyMemberInfo {
        infoByID[member.id] ?? FamilyMemberInfo(member: member, now: now(), calendar: calendar)
    }

    func memorialOrdinal(for member: ReminderEvent) -> Int? {
        info(for: member).memorialOrdinal(for: member, calendar: calendar)
    }

    /// Spotlights a ring month (tap again to clear) and asks the canvas to centre on its earliest memorial.
    func toggleMonth(_ month: Int) {
        if highlightedMonth == month {
            highlightedMonth = nil
            return
        }
        highlightedMonth = month
        focusMemberID = ringMonths.first { $0.month == month }?.members.first?.id
    }

    /// nil = no spotlight active; otherwise whether `member` falls in the spotlighted lunar month.
    func isHighlighted(_ member: ReminderEvent) -> Bool? {
        guard let highlightedMonth else { return nil }
        return FamilyMemberInfo.isWorshipped(member) && member.dateType == .lunar && member.month == highlightedMonth
    }

    func load() async {
        if let items = try? await reminderRepository.fetchAllReminders() {
            self.reminders = items
            focusMemberID = nextMemorial?.id
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
