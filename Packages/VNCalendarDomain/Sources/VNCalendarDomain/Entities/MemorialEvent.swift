import Foundation
import VNCalendarLunar // Types: SolarDate, LunarDate, CanChiPair; remove if engine types change

public enum MemorialPriority: Int, Comparable, Sendable, Codable {
    case low = 100         // Nhắc nhở thường
    case medium = 300      // Sinh nhật, kỷ niệm cưới
    case high = 700        // Mùng 1, Ngày Rằm (15 ÂL)
    case critical = 1000   // Giỗ gia tiên, tổ tiên

    public static func < (lhs: MemorialPriority, rhs: MemorialPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public enum LeapMonthPolicy: String, Sendable, Codable {
    case adaptiveFallback // Nếu có tháng nhuận, nhắc tháng nhuận; không có thì nhắc tháng chính
    case regularOnly      // Chỉ nhắc tháng chính
    case leapOnly         // Chỉ nhắc nếu rơi vào năm có tháng nhuận
    case both             // Nhắc cả tháng chính và tháng nhuận
}

public struct MemorialEvent: Identifiable, Equatable, Sendable, Codable {
    public let id: UUID
    public var title: String
    public var body: String
    public var isLunar: Bool
    public var day: Int
    public var month: Int
    public var isLeapMonth: Bool
    public var leapPolicy: LeapMonthPolicy
    public var priority: MemorialPriority
    public var advanceOffsets: [Int] // [0, -1, -3, -7]
    public var hour: Int
    public var minute: Int

    public init(
        id: UUID = UUID(),
        title: String,
        body: String = "",
        isLunar: Bool = true,
        day: Int,
        month: Int,
        isLeapMonth: Bool = false,
        leapPolicy: LeapMonthPolicy = .adaptiveFallback,
        priority: MemorialPriority = .critical,
        advanceOffsets: [Int] = [0, -1, -3, -7],
        hour: Int = 8,
        minute: Int = 0
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.isLunar = isLunar
        self.day = day
        self.month = month
        self.isLeapMonth = isLeapMonth
        self.leapPolicy = leapPolicy
        self.priority = priority
        self.advanceOffsets = advanceOffsets
        self.hour = hour
        self.minute = minute
    }

    public init(from reminder: ReminderEvent) {
        self.id = reminder.id
        self.title = reminder.title
        let relationshipText = reminder.relationship.map { "Kỳ giỗ: \($0)" } ?? ""
        self.body = reminder.note ?? relationshipText
        self.isLunar = (reminder.dateType == .lunar)
        self.day = reminder.day
        self.month = reminder.month
        self.isLeapMonth = reminder.isLeapMonth
        self.leapPolicy = reminder.leapPolicy
        switch reminder.category {
        case .deathAnniversary, .ancestral:
            self.priority = .critical
        case .worship:
            self.priority = .high
        case .birthday, .wedding:
            self.priority = .medium
        case .other:
            self.priority = .low
        }
        self.advanceOffsets = reminder.alertOffsets
        // Respect the user-set reminder time instead of forcing 08:00.
        self.hour = reminder.hour
        self.minute = reminder.minute
    }
}
