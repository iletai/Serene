import Foundation
import UserNotifications
import OSLog
import VNCalendarDomain
import VNCalendarLunar

private let logger = Logger(subsystem: "com.iletai.annien", category: "SmartNotificationEngine")

public struct NotificationCandidate: Sendable, Comparable {
    public let identifier: String
    public let eventId: UUID
    public let triggerDate: Date
    public let priority: MemorialPriority
    public let score: Double
    public let title: String
    public let body: String
    public let userInfo: [String: String]

    public init(
        identifier: String,
        eventId: UUID,
        triggerDate: Date,
        priority: MemorialPriority,
        score: Double,
        title: String,
        body: String,
        userInfo: [String: String]
    ) {
        self.identifier = identifier
        self.eventId = eventId
        self.triggerDate = triggerDate
        self.priority = priority
        self.score = score
        self.title = title
        self.body = body
        self.userInfo = userInfo
    }

    public static func < (lhs: NotificationCandidate, rhs: NotificationCandidate) -> Bool {
        if lhs.score != rhs.score {
            return lhs.score < rhs.score
        }
        if lhs.triggerDate != rhs.triggerDate {
            return lhs.triggerDate > rhs.triggerDate
        }
        // Final tie-break keeps prefix(usableSlotLimit) stable across runs.
        return lhs.identifier < rhs.identifier
    }
}

public struct TriggerOccurrence: Sendable {
    public let date: Date
    public let isClamped: Bool
    public let lunarDate: LunarDate

    public init(date: Date, isClamped: Bool, lunarDate: LunarDate) {
        self.date = date
        self.isClamped = isClamped
        self.lunarDate = lunarDate
    }
}

public actor SmartNotificationEngine {
    public static let shared = SmartNotificationEngine()

    public static let maxNotificationLimit = 64
    public static let reservedSlots = 4
    public static let usableSlotLimit = maxNotificationLimit - reservedSlots // 60 slots

    public static let categoryIdentifier = "AN_LUNAR_REMINDER"
    public static let actionViewDetail = "ACTION_VIEW_DETAIL"
    public static let actionPrepared = "ACTION_PREPARED"
    public static let notificationPrefix = "annien.event."

    private let center: UNUserNotificationCenter
    private let lunarEngine: LunarAstronomicalEngine

    public init(
        center: UNUserNotificationCenter = .current(),
        lunarEngine: LunarAstronomicalEngine = .shared
    ) {
        self.center = center
        self.lunarEngine = lunarEngine
    }

    public func registerCategories() {
        let viewAction = UNNotificationAction(
            identifier: Self.actionViewDetail,
            title: "Xem chi tiết",
            options: [.foreground]
        )

        let preparedAction = UNNotificationAction(
            identifier: Self.actionPrepared,
            title: "Đã chuẩn bị lễ",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: Self.categoryIdentifier,
            actions: [viewAction, preparedAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        center.setNotificationCategories([category])
    }

    public func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .badge, .sound])
    }

    public func generateCandidates(
        for reminders: [ReminderEvent],
        now: Date,
        calendar: Calendar
    ) async -> [NotificationCandidate] {
        let currentYear = calendar.component(.year, from: now)
        let targetYears = [currentYear, currentYear + 1]

        var candidates: [NotificationCandidate] = []
        for reminder in reminders {
            let event = MemorialEvent(from: reminder)
            let years = reminder.recurrence == .none ? [currentYear] : targetYears
            for year in years {
                let yearCandidates = await collectCandidates(for: event, year: year, now: now, calendar: calendar)
                candidates.append(contentsOf: yearCandidates)
            }
        }
        candidates.sort(by: >)
        return Array(candidates.prefix(Self.usableSlotLimit))
    }

    public func pruneAndSchedule(reminders: [ReminderEvent]) async throws {
        // N5: never schedule into a denied/restricted permission state.
        guard let settings = try? await center.notificationSettings(),
              settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            logger.warning("Notification permission not granted; skipping pruneAndSchedule.")
            return
        }

        let now = Date()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? TimeZone(secondsFromGMT: 7 * 3600) ?? .current

        let selectedCandidates = await generateCandidates(for: reminders, now: now, calendar: calendar)

        await reconcilePendingNotifications(selectedCandidates: selectedCandidates)
        try await scheduleRequests(candidates: selectedCandidates, calendar: calendar)

        logger.info("Successfully pruned and scheduled \(selectedCandidates.count) local notifications.")
    }

    private func collectCandidates(
        for event: MemorialEvent,
        year: Int,
        now: Date,
        calendar: Calendar
    ) async -> [NotificationCandidate] {
        var result: [NotificationCandidate] = []
        let occurrences = await resolveTriggerDates(event: event, targetYear: year, calendar: calendar)
        for occ in occurrences {
            for offset in event.advanceOffsets {
                guard let fireDate = calendar.date(byAdding: .day, value: offset, to: occ.date),
                      fireDate > now else {
                    continue
                }

                let daysUntil = max(0.1, fireDate.timeIntervalSince(now) / 86400.0)
                let offsetWeight = (offset == 0) ? 1.0 : (1.0 / Double(abs(offset) + 1))
                let decayFactor = 1.0 / (1.0 + 0.05 * daysUntil)
                let score = Double(event.priority.rawValue) * offsetWeight * decayFactor

                    let notifID = "\(Self.notificationPrefix)\(event.id.uuidString)_\(year)_\(offset)"
                    let titleText: String
                    let subtitleText: String
                    if offset == 0 {
                        titleText = "🔔 Hôm nay là \(event.title)"
                        if event.isLunar {
                            subtitleText = occ.isClamped
                                ? "Ngày \(occ.lunarDate.day)/\(occ.lunarDate.month) ÂL (Tháng thiếu 29 ngày) - \(event.body)"
                                : "Ngày \(occ.lunarDate.day)/\(occ.lunarDate.month) Âm lịch - \(event.body)"
                        } else {
                            subtitleText = "Ngày \(event.day)/\(event.month) Dương lịch - \(event.body)"
                        }
                    } else {
                        let positiveOffset = abs(offset)
                        titleText = "⏳ Sắp đến \(event.title) (Còn \(positiveOffset) ngày)"
                        if event.isLunar {
                            subtitleText = "Sự kiện vào ngày \(occ.lunarDate.day)/\(occ.lunarDate.month) ÂL - \(event.body)"
                        } else {
                            subtitleText = "Sự kiện vào ngày \(event.day)/\(event.month) Dương lịch - \(event.body)"
                        }
                    }

                    let payload: [String: String] = [
                        "reminder_id": event.id.uuidString,
                        "offset": "\(offset)",
                        "deep_link": "annien://reminder/\(event.id.uuidString)"
                    ]

                    result.append(
                        NotificationCandidate(
                            identifier: notifID,
                            eventId: event.id,
                            triggerDate: fireDate,
                            priority: event.priority,
                            score: score,
                            title: titleText,
                            body: subtitleText,
                            userInfo: payload
                        )
                    )
                }
            }
        return result
    }

    private func reconcilePendingNotifications(selectedCandidates: [NotificationCandidate]) async {

        let targetIDs = Set(selectedCandidates.map(\.identifier))
        let pending = await center.pendingNotificationRequests()
        let existingIDs = Set(pending.map(\.identifier))
        let engineExistingIDs = existingIDs.filter { $0.hasPrefix(Self.notificationPrefix) }
        let idsToRemove = engineExistingIDs.subtracting(targetIDs)

        if !idsToRemove.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: Array(idsToRemove))
        }
    }

    private func scheduleRequests(candidates: [NotificationCandidate], calendar: Calendar) async {
        for item in candidates {
            let content = UNMutableNotificationContent()
            content.title = item.title
            content.body = item.body
            content.sound = .default
            content.categoryIdentifier = Self.categoryIdentifier
            content.userInfo = item.userInfo

            var comps = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: item.triggerDate)
            // Device timezone must not reinterpret GMT+7 wall-clock components.
            comps.timeZone = calendar.timeZone
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(identifier: item.identifier, content: content, trigger: trigger)

            do {
                try await center.add(request)
            } catch {
                // One failed add must not drop the remaining candidates.
                logger.error("Failed to schedule notification \(item.identifier, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    public func resolveTriggerDates(
        event: MemorialEvent,
        targetYear: Int,
        calendar: Calendar
    ) async -> [TriggerOccurrence] {
        guard event.isLunar else {
            var components = DateComponents()
            components.year = targetYear
            components.month = event.month
            components.day = event.day
            components.hour = event.hour
            components.minute = event.minute
            components.second = 0
            guard let d = calendar.date(from: components) else { return [] }
            let solar = SolarDate(day: event.day, month: event.month, year: targetYear)
            let lunar = await lunarEngine.convertToLunar(from: solar)
            let occ = TriggerOccurrence(date: d, isClamped: false, lunarDate: lunar)
            return [occ]
        }

        let reqLunar = LunarDate(day: event.day, month: event.month, year: targetYear, isLeapMonth: event.isLeapMonth)
        let solar = await lunarEngine.convertToSolar(from: reqLunar)
        let verifiedLunar = await lunarEngine.convertToLunar(from: solar)
        let isClamped = (event.day == 30 && verifiedLunar.day == 29)

        var comp = DateComponents()
        comp.year = solar.year
        comp.month = solar.month
        comp.day = solar.day
        comp.hour = event.hour
        comp.minute = event.minute
        comp.second = 0

        guard let d = calendar.date(from: comp) else { return [] }
        return [TriggerOccurrence(date: d, isClamped: isClamped, lunarDate: verifiedLunar)]
    }
}
