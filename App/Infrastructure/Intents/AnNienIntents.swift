import AppIntents
import Foundation
import VNCalendarLunar
import VNCalendarDomain

public struct CheckLunarDateIntent: AppIntent {
    public static let title: LocalizedStringResource = "Hôm nay ngày mấy âm?"
    public static let description = IntentDescription("Đọc ngày âm lịch hiện tại kèm Can Chi và Tiết khí.")

    public init() {}

    public func perform() async throws -> some ProvidesDialog & ReturnsValue<String> {
        let now = Date()
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = VNTime.vietnam

        let solar = SolarDate(from: now, calendar: cal)
        let engine = LunarAstronomicalEngine.shared
        let lunar = engine.convertToLunar(from: solar)
        let canChi = engine.computeCanChi(for: solar)
        let jd = AstronomicalMath.julianDay(from: solar)
        let term = AstronomicalMath.solarTerm(at: jd)

        let response = "Hôm nay là ngày \(lunar.day) tháng \(lunar.month) Âm lịch, " +
            "năm \(canChi.year.description). Ngày \(canChi.day.description), tiết \(term.vietnameseName)."
        return .result(value: response, dialog: IntentDialog(stringLiteral: response))
    }
}

public struct CheckNextMemorialIntent: AppIntent {
    public static let title: LocalizedStringResource = "Kỳ giỗ tiếp theo là khi nào?"
    public static let description = IntentDescription("Kiểm tra ngày giỗ hoặc kỷ niệm gia đình gần nhất sắp tới.")

    public init() {}

    public func perform() async throws -> some ProvidesDialog & ReturnsValue<String> {
        // Reuse the app container so the intent does not open a second CloudKit/SQLite
        // store handle on the same file.
        let repo = await AppContainer.shared.reminderRepository
        let reminders = (try? await repo.fetchAllReminders()) ?? []

        guard !reminders.isEmpty else {
            let msg = "Bạn chưa có ngày giỗ nào được lên lịch trong An Niên."
            return .result(value: msg, dialog: IntentDialog(stringLiteral: msg))
        }

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = VNTime.vietnam
        let today = cal.startOfDay(for: Date())
        let solarNow = SolarDate(from: today, calendar: cal)

        let sorted = reminders.sorted { lhs, rhs in
            let lhsDate = Self.nextOccurrenceDate(for: lhs, today: today, solarNow: solarNow, calendar: cal)
            let rhsDate = Self.nextOccurrenceDate(for: rhs, today: today, solarNow: solarNow, calendar: cal)
            return lhsDate < rhsDate
        }

        guard let firstEvent = sorted.first else {
            let msg = "Bạn chưa có ngày giỗ nào được lên lịch trong An Niên."
            return .result(value: msg, dialog: IntentDialog(stringLiteral: msg))
        }

        let dateTypeStr = firstEvent.dateType == .lunar ? "Âm lịch" : "Dương lịch"
        let msg = "Kỳ giỗ sắp tới là \(firstEvent.title), diễn ra vào ngày \(firstEvent.day)/\(firstEvent.month) \(dateTypeStr)."
        return .result(value: msg, dialog: IntentDialog(stringLiteral: msg))
    }

    private static func nextOccurrenceDate(
        for reminder: ReminderEvent,
        today: Date,
        solarNow: SolarDate,
        calendar: Calendar
    ) -> Date {
        if reminder.dateType == .lunar {
            let currentLunar = LunarAstronomicalEngine.shared.convertToLunar(from: solarNow)
            var targetLunarYear = currentLunar.year
            if currentLunar.month > reminder.month || (currentLunar.month == reminder.month && currentLunar.day > reminder.day) {
                targetLunarYear += 1
            }
            let targetLunar = LunarDate(day: reminder.day, month: reminder.month, year: targetLunarYear)
            let targetSolar = LunarAstronomicalEngine.shared.convertToSolar(from: targetLunar)
            return targetSolar.date ?? today
        } else {
            var comps = DateComponents(year: solarNow.year, month: reminder.month, day: reminder.day)
            if let date = calendar.date(from: comps) {
                if date < today {
                    comps.year = solarNow.year + 1
                    return calendar.date(from: comps) ?? date
                }
                return date
            }
            return today
        }
    }
}

public struct AnNienShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CheckLunarDateIntent(),
            phrases: [
                "Hôm nay ngày mấy âm trong \(.applicationName)",
                "Xem lịch âm \(.applicationName)",
                "Ngày âm hôm nay \(.applicationName)",
                "What is the lunar date in \(.applicationName)"
            ],
            shortTitle: "Ngày Âm Hôm Nay",
            systemImageName: "moon.stars"
        )
        AppShortcut(
            intent: CheckNextMemorialIntent(),
            phrases: [
                "Kỳ giỗ tiếp theo trong \(.applicationName)",
                "Khi nào đến ngày giỗ \(.applicationName)",
                "Next memorial in \(.applicationName)"
            ],
            shortTitle: "Giỗ Tiếp Theo",
            systemImageName: "bell.badge"
        )
    }
}
