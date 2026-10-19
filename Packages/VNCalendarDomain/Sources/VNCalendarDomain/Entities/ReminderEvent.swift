import Foundation

public enum CalendarDateType: String, Codable, Sendable, CaseIterable {
    case solar
    case lunar
}

public enum ReminderCategory: String, Codable, Sendable, CaseIterable {
    case deathAnniversary // Giỗ gia tiên
    case ancestral        // Kỵ / Chạp họ
    case birthday         // Sinh nhật
    case wedding          // Kỷ niệm cưới
    case worship          // Cúng lễ / Ngày vía
    case other

    public var title: String {
        switch self {
        case .deathAnniversary: return "Giỗ / Kỵ"
        case .ancestral: return "Chạp Họ / Kỵ Lớn"
        case .birthday: return "Sinh Nhật"
        case .wedding: return "Kỷ Niệm Cưới"
        case .worship: return "Cúng Lễ / Vía"
        case .other: return "Khác"
        }
    }
}

public enum RecurrenceRule: String, Codable, Sendable, CaseIterable {
    case none
    case yearly
    case monthly

    public var title: String {
        switch self {
        case .none: return "Không lặp lại"
        case .yearly: return "Lặp hàng năm"
        case .monthly: return "Lặp hàng tháng"
        }
    }
}

public struct ReminderEvent: Identifiable, Equatable, Sendable, Codable {
    public let id: UUID
    public var title: String
    public var category: ReminderCategory
    public var dateType: CalendarDateType
    public var day: Int
    public var month: Int
    public var year: Int? // nil = lặp lại không ràng buộc năm gốc
    public var isLeapMonth: Bool
    public var leapPolicy: LeapMonthPolicy
    public var recurrence: RecurrenceRule
    public var alertOffsets: [Int] // ví dụ: [0, -1, -3, -7, -14, -30]
    public var hour: Int
    public var minute: Int
    public var note: String?
    public var relationship: String?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        category: ReminderCategory = .deathAnniversary,
        dateType: CalendarDateType = .lunar,
        day: Int,
        month: Int,
        year: Int? = nil,
        isLeapMonth: Bool = false,
        leapPolicy: LeapMonthPolicy = .adaptiveFallback,
        recurrence: RecurrenceRule = .yearly,
        alertOffsets: [Int] = [0, -1, -3, -7],
        hour: Int = 8,
        minute: Int = 0,
        note: String? = nil,
        relationship: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.dateType = dateType
        self.day = day
        self.month = month
        self.year = year
        self.isLeapMonth = isLeapMonth
        self.leapPolicy = leapPolicy
        self.recurrence = recurrence
        self.alertOffsets = alertOffsets
        self.hour = hour
        self.minute = minute
        self.note = note
        self.relationship = relationship
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, category, dateType, day, month, year, isLeapMonth,
             leapPolicy, recurrence, alertOffsets, hour, minute, note,
             relationship, createdAt, updatedAt
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        category = try c.decode(ReminderCategory.self, forKey: .category)
        dateType = try c.decode(CalendarDateType.self, forKey: .dateType)
        day = try c.decode(Int.self, forKey: .day)
        month = try c.decode(Int.self, forKey: .month)
        year = try c.decodeIfPresent(Int.self, forKey: .year)
        isLeapMonth = try c.decode(Bool.self, forKey: .isLeapMonth)
        recurrence = try c.decode(RecurrenceRule.self, forKey: .recurrence)
        alertOffsets = try c.decode([Int].self, forKey: .alertOffsets)
        note = try c.decodeIfPresent(String.self, forKey: .note)
        relationship = try c.decodeIfPresent(String.self, forKey: .relationship)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        updatedAt = try c.decode(Date.self, forKey: .updatedAt)
        // Legacy backups predate these keys.
        hour = try c.decodeIfPresent(Int.self, forKey: .hour) ?? 8
        minute = try c.decodeIfPresent(Int.self, forKey: .minute) ?? 0
        leapPolicy = try c.decodeIfPresent(LeapMonthPolicy.self, forKey: .leapPolicy) ?? .adaptiveFallback
    }
}

// MARK: - Occurrence & Countdown Math
import VNCalendarLunar

extension ReminderEvent {
    public func nextOccurrence(after anchorDate: Date, calendar: Calendar) -> Date {
        let solarNow = SolarDate(from: anchorDate, calendar: calendar)
        if dateType == .lunar {
            let engine = LunarAstronomicalEngine.shared
            let currentLunar = engine.convertToLunar(from: solarNow)
            var targetLunarYear = currentLunar.year
            if currentLunar.month > month || (currentLunar.month == month && currentLunar.day > day) {
                targetLunarYear += 1
            }
            let targetLunar = LunarDate(day: day, month: month, year: targetLunarYear, isLeapMonth: isLeapMonth)
            let targetSolar = engine.convertToSolar(from: targetLunar)
            return targetSolar.date ?? anchorDate
        } else {
            var comps = DateComponents(year: solarNow.year, month: month, day: day)
            if let date = calendar.date(from: comps) {
                if date < anchorDate {
                    comps.year = solarNow.year + 1
                    return calendar.date(from: comps) ?? date
                }
                return date
            }
            // Clamp invalid solar day (e.g. 30/2) to the month's last day.
            let monthDate = calendar.date(from: DateComponents(year: solarNow.year, month: month, day: 1)) ?? anchorDate
            if let clampedDay = calendar.range(of: .day, in: .month, for: monthDate)?.count {
                comps.day = min(day, clampedDay)
                if let date = calendar.date(from: comps), date >= anchorDate {
                    return date
                }
            }
            return anchorDate
        }
    }

    public func countdownText(relativeTo anchorDate: Date, calendar: Calendar) -> String {
        let today = calendar.startOfDay(for: anchorDate)
        let target = nextOccurrence(after: today, calendar: calendar)
        let diff = calendar.dateComponents([.day], from: today, to: target).day ?? 0

        if diff == 0 {
            return "Hôm nay"
        } else if diff == 1 {
            return "Ngày mai"
        } else if diff > 1 {
            return "Còn \(diff) ngày"
        } else {
            return "Đã qua"
        }
    }
}
