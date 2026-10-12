import Foundation
import VNCalendarDomain
import VNCalendarLunar

public struct AnniversaryDisplayItem: Identifiable, Equatable, Sendable, Codable {
    public let id: UUID
    public let title: String
    public let isLunar: Bool
    public let isAncestorDeath: Bool

    public init(id: UUID, title: String, isLunar: Bool, isAncestorDeath: Bool) {
        self.id = id
        self.title = title
        self.isLunar = isLunar
        self.isAncestorDeath = isAncestorDeath
    }
}

public struct VNCalendarDayModel: Identifiable, Equatable, Sendable {
    public var id: Int { dateKey.rawValue }

    public let dateKey: DateKey
    public let solarDate: Date
    public let solarDay: Int
    public let solarMonth: Int
    public let solarYear: Int
    public let weekdayName: String

    public let lunarDay: Int
    public let lunarMonth: Int
    public let lunarYear: Int
    public let isLeapMonth: Bool
    public let lunarDayText: String
    public let lunarMonthName: String
    public let lunarYearCanChi: String
    public let lunarDayCanChi: String
    public let lunarMonthCanChi: String
    public let lunarDayStem: HeavenlyStem
    public let lunarDayBranch: EarthlyBranch
    public let solarTermName: String?
    public let lunarOfficer: LunarOfficer
    public let zodiacStar: ZodiacStar
    public let auspiciousHours: [EarthlyBranch]

    public let joyGodDirection: String
    public let wealthGodDirection: String
    public let suitableActivities: [String]
    public let tabooActivities: [String]
    public let folkQuote: VNFolkQuote

    public let isFirstDayOfLunarMonth: Bool
    public let isFullMoonDay: Bool
    public let isAuspiciousDay: Bool
    public let isToday: Bool
    public let isCurrentMonth: Bool

    public let anniversaries: [AnniversaryDisplayItem]
    public let hasAncestorDeathAnniversary: Bool
    public let hasFestival: Bool

    public init(
        dateKey: DateKey,
        solarDate: Date,
        solarDay: Int,
        solarMonth: Int,
        solarYear: Int,
        weekdayName: String,
        lunarDay: Int,
        lunarMonth: Int,
        lunarYear: Int,
        isLeapMonth: Bool,
        lunarDayText: String,
        lunarMonthName: String,
        lunarYearCanChi: String,
        lunarDayCanChi: String,
        lunarMonthCanChi: String = "",
        lunarDayStem: HeavenlyStem = .giap,
        lunarDayBranch: EarthlyBranch = .ty,
        solarTermName: String?,
        lunarOfficer: LunarOfficer = .kien,
        zodiacStar: ZodiacStar = .thanhLong,
        auspiciousHours: [EarthlyBranch] = [],
        joyGodDirection: String = "Đông Bắc",
        wealthGodDirection: String = "Đông Nam",
        suitableActivities: [String] = [],
        tabooActivities: [String] = [],
        folkQuote: VNFolkQuote? = nil,
        isFirstDayOfLunarMonth: Bool,
        isFullMoonDay: Bool,
        isAuspiciousDay: Bool,
        isToday: Bool,
        isCurrentMonth: Bool,
        anniversaries: [AnniversaryDisplayItem],
        hasAncestorDeathAnniversary: Bool,
        hasFestival: Bool
    ) {
        self.dateKey = dateKey
        self.solarDate = solarDate
        self.solarDay = solarDay
        self.solarMonth = solarMonth
        self.solarYear = solarYear
        self.weekdayName = weekdayName
        self.lunarDay = lunarDay
        self.lunarMonth = lunarMonth
        self.lunarYear = lunarYear
        self.isLeapMonth = isLeapMonth
        self.lunarDayText = lunarDayText
        self.lunarMonthName = lunarMonthName
        self.lunarYearCanChi = lunarYearCanChi
        self.lunarDayCanChi = lunarDayCanChi
        self.lunarMonthCanChi = lunarMonthCanChi
        self.lunarDayStem = lunarDayStem
        self.lunarDayBranch = lunarDayBranch
        self.solarTermName = solarTermName
        self.lunarOfficer = lunarOfficer
        self.zodiacStar = zodiacStar
        self.auspiciousHours = auspiciousHours
        self.joyGodDirection = joyGodDirection
        self.wealthGodDirection = wealthGodDirection
        self.suitableActivities = suitableActivities.isEmpty ? lunarOfficer.suitableActivities : suitableActivities
        self.tabooActivities = tabooActivities.isEmpty ? lunarOfficer.tabooActivities : tabooActivities
        self.folkQuote = folkQuote ?? VNFolkQuotes.quote(for: dateKey)
        self.isFirstDayOfLunarMonth = isFirstDayOfLunarMonth
        self.isFullMoonDay = isFullMoonDay
        self.isAuspiciousDay = isAuspiciousDay
        self.isToday = isToday
        self.isCurrentMonth = isCurrentMonth
        self.anniversaries = anniversaries
        self.hasAncestorDeathAnniversary = hasAncestorDeathAnniversary
        self.hasFestival = hasFestival
    }
}
