import Foundation
import VNCalendarLunar

public enum SearchResultItem: Identifiable, Sendable {
    case reminder(ReminderEvent)
    case holiday(Holiday)

    public var id: String {
        switch self {
        case .reminder(let r): return "rem_\(r.id.uuidString)"
        case .holiday(let h): return "hol_\(h.id)"
        }
    }

    public var title: String {
        switch self {
        case .reminder(let r): return r.title
        case .holiday(let h): return h.title
        }
    }
}

public final class NaturalSearchUseCase: Sendable {
    private let reminderRepository: ReminderRepositoryProtocol
    private let holidayRepository: HolidayRepositoryProtocol

    public init(
        reminderRepository: ReminderRepositoryProtocol,
        holidayRepository: HolidayRepositoryProtocol
    ) {
        self.reminderRepository = reminderRepository
        self.holidayRepository = holidayRepository
    }

    public func execute(query: String) async throws -> [SearchResultItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return [] }

        async let allReminders = reminderRepository.fetchAllReminders()
        async let allHolidays = holidayRepository.getHolidays()

        let (reminders, holidays) = try await (allReminders, allHolidays)

        var results: [SearchResultItem] = []

        for r in reminders {
            if r.title.lowercased().contains(trimmed) ||
                (r.note?.lowercased().contains(trimmed) == true) ||
                (r.relationship?.lowercased().contains(trimmed) == true) {
                results.append(.reminder(r))
            }
        }

        for h in holidays {
            if h.title.lowercased().contains(trimmed) || h.summary.lowercased().contains(trimmed) {
                results.append(.holiday(h))
            }
        }

        return results
    }
}
