import SwiftUI
import Observation
import VNCalendarDomain
import VNCalendarLunar

@Observable
@MainActor
final class ReminderFormViewModel {
    var title: String = ""
    var category: ReminderCategory = .deathAnniversary
    var dateType: CalendarDateType = .lunar
    var day: Int = 1
    var month: Int = 1
    var year: String = ""
    var isLeapMonth = false
    var recurrence: RecurrenceRule = .yearly
    var relationship: String = "Ông"
    var note: String = ""

    // Advance Offsets
    var notifyOnDay = true
    var notify1DayBefore = true
    var notify3DaysBefore = true
    var notify7DaysBefore = true
    var notify14DaysBefore = false
    var notify30DaysBefore = false

    let existingReminder: ReminderEvent?

    /// Set by a save attempt with an empty title; drives the inline error row.
    private(set) var saveAttempted = false
    /// Field values at load (or last save); `isDirty` compares against it.
    private var baseline: [AnyHashable] = []

    init(existingReminder: ReminderEvent? = nil, initialDate: Date? = nil) {
        self.existingReminder = existingReminder

        if let existing = existingReminder {
            title = existing.title
            category = existing.category
            dateType = existing.dateType
            day = existing.day
            month = existing.month
            year = existing.year.map(String.init) ?? ""
            isLeapMonth = existing.isLeapMonth
            recurrence = existing.recurrence
            relationship = existing.relationship ?? "Ông"
            note = existing.note ?? ""

            let offsets = Set(existing.alertOffsets)
            notifyOnDay = offsets.contains(0)
            notify1DayBefore = offsets.contains(-1)
            notify3DaysBefore = offsets.contains(-3)
            notify7DaysBefore = offsets.contains(-7)
            notify14DaysBefore = offsets.contains(-14)
            notify30DaysBefore = offsets.contains(-30)
        } else if let date = initialDate {
            // The form defaults to lunar, so seed it with the lunar equivalent of the solar date.
            let lunar = LunarAstronomicalEngine.shared.convertToLunar(from: SolarDate(from: date))
            day = lunar.day
            month = lunar.month
            isLeapMonth = lunar.isLeapMonth
        }
        baseline = fingerprint
    }

    private var fingerprint: [AnyHashable] {
        [title, category, dateType, day, month, year, isLeapMonth, recurrence, relationship, note,
         notifyOnDay, notify1DayBefore, notify3DaysBefore, notify7DaysBefore, notify14DaysBefore, notify30DaysBefore]
    }

    /// True once any field differs from its loaded value; guards against losing edits on dismiss.
    var isDirty: Bool { fingerprint != baseline }

    var showsTitleError: Bool { saveAttempted && !isValid }

    /// Returns the reminder to persist, or nil (and flags the title error) when the title is empty.
    func save() -> ReminderEvent? {
        guard isValid else {
            saveAttempted = true
            return nil
        }
        let reminder = buildReminder()
        baseline = fingerprint
        return reminder
    }

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func buildReminder() -> ReminderEvent {
        var offsets: [Int] = []
        if notifyOnDay { offsets.append(0) }
        if notify1DayBefore { offsets.append(-1) }
        if notify3DaysBefore { offsets.append(-3) }
        if notify7DaysBefore { offsets.append(-7) }
        if notify14DaysBefore { offsets.append(-14) }
        if notify30DaysBefore { offsets.append(-30) }
        if offsets.isEmpty { offsets.append(0) }

        let parsedYear = Int(year.trimmingCharacters(in: .whitespaces))
        return ReminderEvent(
            id: existingReminder?.id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespaces),
            category: category,
            dateType: dateType,
            day: day,
            month: month,
            year: parsedYear,
            isLeapMonth: isLeapMonth,
            recurrence: recurrence,
            alertOffsets: offsets,
            note: note.isEmpty ? nil : note,
            relationship: relationship,
            createdAt: existingReminder?.createdAt ?? Date(),
            updatedAt: Date()
        )
    }
}
