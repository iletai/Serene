import Foundation
import VNCalendarDomain
import VNCalendarLunar

/// Display facts derived from one reminder; everything the tree node and profile sheet need
/// beyond the stored fields. Pure, so it is testable with a fixed `now`.
struct FamilyMemberInfo: Equatable, Sendable {
    /// A memorial days-away count at or under this highlights the countdown pill.
    static let soonThresholdDays = 30

    let isWorshipped: Bool
    let nextDate: Date
    let daysUntil: Int

    var isSoon: Bool { isWorshipped && daysUntil <= Self.soonThresholdDays }

    init(member: ReminderEvent, now: Date, calendar: Calendar) {
        let today = calendar.startOfDay(for: now)
        let next = member.nextOccurrence(after: today, calendar: calendar)
        isWorshipped = Self.isWorshipped(member)
        nextDate = next
        daysUntil = calendar.dateComponents([.day], from: today, to: next).day ?? 0
    }

    /// 1 = first death anniversary (giỗ đầu); nil when the base year or lunar date is unknown.
    /// Not stored: it needs a lunar conversion, and node infos are rebuilt on every reminder change.
    func memorialOrdinal(for member: ReminderEvent, calendar: Calendar) -> Int? {
        guard isWorshipped, member.dateType == .lunar, let baseYear = member.year else { return nil }
        let lunarYear = LunarAstronomicalEngine.shared.convertToLunar(from: SolarDate(from: nextDate, calendar: calendar)).year
        return lunarYear > baseYear ? lunarYear - baseYear : nil
    }

    static func isWorshipped(_ member: ReminderEvent) -> Bool {
        member.category == .deathAnniversary || member.category == .ancestral
    }

    /// "Còn N ngày" / "Hôm nay" / "Ngày mai", localized (Domain's `countdownText` is Vietnamese-only).
    var countdownText: String {
        switch daysUntil {
        case ...0: String(localized: "family.countdown.today")
        case 1: String(localized: "family.countdown.tomorrow")
        default: String(format: String(localized: "family.countdown.days"), daysUntil)
        }
    }

    /// "Giỗ 5/9 ÂL" style label of the stored date.
    static func anniversaryText(_ member: ReminderEvent) -> String {
        let suffix = member.dateType == .lunar ? String(localized: "family.abbrev_lunar") : String(localized: "family.abbrev_solar")
        return String(format: String(localized: "family.member_date"), member.day, member.month, suffix)
    }

    static func yearText(_ member: ReminderEvent) -> String? {
        member.year.map { String(format: String(localized: "family.member_year"), String($0)) }
    }

    /// First letter of the last word, as the prototype's `initial()` (given-name initial).
    static func initial(of title: String) -> String {
        title.split(separator: " ").last.map { String($0.prefix(1)).uppercased() } ?? "?"
    }
}

/// One slot of the 12-month lunar memorial ring (prototype "Vòng giỗ năm âm lịch").
struct FamilyRingMonth: Identifiable, Equatable, Sendable {
    let month: Int
    /// Lunar memorials in this month, ordered by day.
    let members: [ReminderEvent]

    var id: Int { month }
    var isEmpty: Bool { members.isEmpty }

    /// Always 12 entries; only worshipped lunar reminders are placed.
    static func months(from reminders: [ReminderEvent]) -> [FamilyRingMonth] {
        let memorials = reminders.filter { FamilyMemberInfo.isWorshipped($0) && $0.dateType == .lunar }
        return (1...12).map { month in
            FamilyRingMonth(month: month, members: memorials.filter { $0.month == month }.sorted { $0.day < $1.day })
        }
    }
}
