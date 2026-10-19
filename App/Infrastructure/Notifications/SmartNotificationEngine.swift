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

private struct MonthRequest {
    let day: Int
    let month: Int
    let isLeap: Bool
}

public actor SmartNotificationEngine {
    public static let shared = SmartNotificationEngine()

    public static let maxNotificationLimit = 64
    public static let reservedSlots = 4
    public static let usableSlotLimit = maxNotificationLimit - reservedSlots // 60 slots
    /// Hyperbolic time-decay coefficient α (spec 05 §2.1).
    public static let decayAlpha = 0.05

    /// Bundle whose .lproj matches the in-app language setting
    /// (`appLanguage`: "vi", "en", or "system").
    private static var activeBundle: Bundle {
        let setting = UserDefaults.standard.string(forKey: "appLanguage") ?? "system"
        let code: String?
        switch setting {
        case "vi": code = "vi"
        case "en": code = "en"
        default: code = nil // follow device preference
        }
        guard let code,
              let path = Bundle.main.path(forResource: code, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }

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
        calendar.timeZone = VNTime.vietnam

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
                let decayFactor = 1.0 / (1.0 + Self.decayAlpha * daysUntil)
                let score = Double(event.priority.rawValue) * offsetWeight * decayFactor

                // Leap-month occurrences need a distinct ID or `.both` collapses into one.
                let leapTag = occ.lunarDate.isLeapMonth ? "_leap" : ""
                let notifID = "\(Self.notificationPrefix)\(event.id.uuidString)_\(year)\(leapTag)_\(offset)"
                let texts = notificationTexts(for: event, occurrence: occ, offset: offset)

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
                        title: texts.title,
                        body: texts.body,
                        userInfo: payload
                    )
                )
            }
        }
        return result
    }

    private func notificationTexts(
        for event: MemorialEvent,
        occurrence: TriggerOccurrence,
        offset: Int
    ) -> (title: String, body: String) {
        let bundle = Self.activeBundle
        func copy(_ key: String, _ args: CVarArg...) -> String {
            let raw = bundle.localizedString(forKey: key, value: nil, table: nil)
            let fmt: String
            if raw == key {
                // Missing key fallback preserves spec format arguments
                switch key {
                case "notif.today_title": fmt = "Hôm nay là %@"
                case "notif.today_body_lunar": fmt = "Ngày %lld/%lld Âm lịch - %@"
                case "notif.today_body_lunar_clamped": fmt = "Ngày %lld/%lld ÂL (Tháng thiếu 29 ngày) - %@"
                case "notif.today_body_solar": fmt = "Ngày %lld/%lld Dương lịch - %@"
                case "notif.upcoming_title": fmt = "Sắp đến %@ (Còn %lld ngày)"
                case "notif.upcoming_body_lunar": fmt = "Sự kiện vào ngày %lld/%lld ÂL - %@"
                case "notif.upcoming_body_solar": fmt = "Sự kiện vào ngày %lld/%lld Dương lịch - %@"
                default: fmt = key
                }
            } else {
                fmt = raw
            }
            return String(format: fmt, arguments: args)
        }
        if offset == 0 {
            let title = copy("notif.today_title", event.title)
            let body: String
            if event.isLunar {
                body = occurrence.isClamped
                    ? copy(
                        "notif.today_body_lunar_clamped",
                        Int64(occurrence.lunarDate.day), Int64(occurrence.lunarDate.month), event.body
                    )
                    : copy(
                        "notif.today_body_lunar",
                        Int64(occurrence.lunarDate.day), Int64(occurrence.lunarDate.month), event.body
                    )
            } else {
                body = copy(
                    "notif.today_body_solar",
                    Int64(event.day), Int64(event.month), event.body
                )
            }
            return (title, body)
        } else {
            let positiveOffset = abs(offset)
            let title = copy("notif.upcoming_title", event.title, Int64(positiveOffset))
            let body: String
            if event.isLunar {
                body = copy(
                    "notif.upcoming_body_lunar",
                    Int64(occurrence.lunarDate.day), Int64(occurrence.lunarDate.month), event.body
                )
            } else {
                body = copy(
                    "notif.upcoming_body_solar",
                    Int64(event.day), Int64(event.month), event.body
                )
            }
            return (title, body)
        }
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
        // Spec 05 §7.2: skip identifiers already pending to avoid re-add churn
        // on every scenePhase .active / app launch.
        let existingIDs = Set(await center.pendingNotificationRequests().map(\.identifier))
        for item in candidates where !existingIDs.contains(item.identifier) {
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

        // Spec 05 §3.2: apply LeapMonthPolicy when the target lunar year may
        // contain a leap month matching the event's month.
        let hasLeapThisYear = lunarEngine.hasLeapMonth(
            ofLunarYear: targetYear,
            matching: event.month
        )

        let requestedMonths: [MonthRequest]
        switch event.leapPolicy {
        case .regularOnly:
            requestedMonths = [MonthRequest(day: event.day, month: event.month, isLeap: false)]
        case .leapOnly:
            requestedMonths = hasLeapThisYear
                ? [MonthRequest(day: event.day, month: event.month, isLeap: true)]
                : []
        case .adaptiveFallback:
            // Prefer the actual leap month in leap years; fall back to regular.
            requestedMonths = hasLeapThisYear
                ? [MonthRequest(day: event.day, month: event.month, isLeap: true)]
                : [MonthRequest(day: event.day, month: event.month, isLeap: false)]
        case .both:
            requestedMonths = hasLeapThisYear
                ? [
                    MonthRequest(day: event.day, month: event.month, isLeap: false),
                    MonthRequest(day: event.day, month: event.month, isLeap: true)
                ]
                : [MonthRequest(day: event.day, month: event.month, isLeap: false)]
        }

        var occurrences: [TriggerOccurrence] = []
        for request in requestedMonths {
            let reqLunar = LunarDate(
                day: request.day,
                month: request.month,
                year: targetYear,
                isLeapMonth: request.isLeap
            )
            let solar = await lunarEngine.convertToSolar(from: reqLunar)
            let verifiedLunar = await lunarEngine.convertToLunar(from: solar)
            let isClamped = (request.day == 30 && verifiedLunar.day == 29)

            var comp = DateComponents()
            comp.year = solar.year
            comp.month = solar.month
            comp.day = solar.day
            comp.hour = event.hour
            comp.minute = event.minute
            comp.second = 0

            guard let d = calendar.date(from: comp) else { continue }
            occurrences.append(TriggerOccurrence(date: d, isClamped: isClamped, lunarDate: verifiedLunar))
        }
        return occurrences
    }
}
