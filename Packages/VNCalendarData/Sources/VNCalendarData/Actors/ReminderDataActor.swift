import Foundation
import SwiftData
import VNCalendarDomain

@ModelActor
public actor ReminderDataActor {
    public func fetchAllReminders() throws -> [ReminderEvent] {
        let descriptor = FetchDescriptor<ReminderItemEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    public func fetchReminders(forMonth month: Int, isLunar: Bool) throws -> [ReminderEvent] {
        let dateType = isLunar ? "lunar" : "solar"
        let descriptor = FetchDescriptor<ReminderItemEntity>(
            predicate: #Predicate<ReminderItemEntity> {
                $0.month == month && $0.dateTypeRawValue == dateType
            },
            sortBy: [SortDescriptor(\.day)]
        )
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    public func getReminder(by id: UUID) throws -> ReminderEvent? {
        let descriptor = FetchDescriptor<ReminderItemEntity>(
            predicate: #Predicate<ReminderItemEntity> { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    public func saveReminder(_ reminder: ReminderEvent) throws {
        let targetId = reminder.id
        let descriptor = FetchDescriptor<ReminderItemEntity>(
            predicate: #Predicate<ReminderItemEntity> { $0.id == targetId }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            existing.update(from: reminder)
        } else {
            let newEntity = ReminderItemEntity(from: reminder)
            modelContext.insert(newEntity)
        }
        try modelContext.save()
    }

    public func deleteReminder(by id: UUID) throws {
        let targetId = id
        let descriptor = FetchDescriptor<ReminderItemEntity>(
            predicate: #Predicate<ReminderItemEntity> { $0.id == targetId }
        )
        if let existing = try modelContext.fetch(descriptor).first {
            modelContext.delete(existing)
            try modelContext.save()
        }
    }
}
