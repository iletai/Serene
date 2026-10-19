import Foundation
import SwiftData
import VNCalendarDomain

@Model
public final class ReminderItemEntity {
    public var id = UUID()
    public var title: String = ""
    public var categoryRawValue: String = "deathAnniversary"
    public var dateTypeRawValue: String = "lunar"
    public var day: Int = 1
    public var month: Int = 1
    public var year: Int?
    public var isLeapMonth = false
    public var recurrenceRawValue: String = "yearly"
    public var alertOffsetsData = Data()
    public var note: String?
    public var relationship: String?
    public var createdAt = Date()
    public var updatedAt = Date()
    // Spec 04-data-layer: soft delete for CloudKit tombstone propagation.
    // Hard delete loses the deletion on offline devices; they resurrect the
    // record on next sync.
    public var isDeleted = false

    public init(
        id: UUID = UUID(),
        title: String = "",
        categoryRawValue: String = "deathAnniversary",
        dateTypeRawValue: String = "lunar",
        day: Int = 1,
        month: Int = 1,
        year: Int? = nil,
        isLeapMonth: Bool = false,
        recurrenceRawValue: String = "yearly",
        alertOffsets: [Int] = [0, -1, -3, -7],
        note: String? = nil,
        relationship: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.categoryRawValue = categoryRawValue
        self.dateTypeRawValue = dateTypeRawValue
        self.day = day
        self.month = month
        self.year = year
        self.isLeapMonth = isLeapMonth
        self.recurrenceRawValue = recurrenceRawValue
        self.alertOffsetsData = (try? JSONEncoder().encode(alertOffsets)) ?? Data()
        self.note = note
        self.relationship = relationship
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public convenience init(from domain: ReminderEvent) {
        self.init(
            id: domain.id,
            title: domain.title,
            categoryRawValue: domain.category.rawValue,
            dateTypeRawValue: domain.dateType.rawValue,
            day: domain.day,
            month: domain.month,
            year: domain.year,
            isLeapMonth: domain.isLeapMonth,
            recurrenceRawValue: domain.recurrence.rawValue,
            alertOffsets: domain.alertOffsets,
            note: domain.note,
            relationship: domain.relationship,
            createdAt: domain.createdAt,
            updatedAt: domain.updatedAt
        )
    }

    public func toDomain() -> ReminderEvent {
        let offsets = (try? JSONDecoder().decode([Int].self, from: alertOffsetsData)) ?? [0]
        return ReminderEvent(
            id: self.id,
            title: self.title,
            category: ReminderCategory(rawValue: self.categoryRawValue) ?? .other,
            dateType: CalendarDateType(rawValue: self.dateTypeRawValue) ?? .lunar,
            day: self.day,
            month: self.month,
            year: self.year,
            isLeapMonth: self.isLeapMonth,
            recurrence: RecurrenceRule(rawValue: self.recurrenceRawValue) ?? .yearly,
            alertOffsets: offsets,
            note: self.note,
            relationship: self.relationship,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt
        )
    }

    public func update(from domain: ReminderEvent) {
        self.title = domain.title
        self.categoryRawValue = domain.category.rawValue
        self.dateTypeRawValue = domain.dateType.rawValue
        self.day = domain.day
        self.month = domain.month
        self.year = domain.year
        self.isLeapMonth = domain.isLeapMonth
        self.recurrenceRawValue = domain.recurrence.rawValue
        self.alertOffsetsData = (try? JSONEncoder().encode(domain.alertOffsets)) ?? Data()
        self.note = domain.note
        self.relationship = domain.relationship
        self.updatedAt = domain.updatedAt
    }
}
