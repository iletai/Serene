import XCTest
import VNCalendarLunar
@testable import VNCalendarDomain

final class ReminderEventOccurrenceTests: XCTestCase {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = VNTime.vietnam
        return cal
    }

    func testNextOccurrence_SolarFutureThisYear() {
        let reminder = ReminderEvent(title: "Sinh nhật", dateType: .solar, day: 25, month: 12)
        let anchor = calendar.date(from: DateComponents(year: 2026, month: 10, day: 19))!
        let next = reminder.nextOccurrence(after: anchor, calendar: calendar)
        let comps = calendar.dateComponents([.year, .month, .day], from: next)
        XCTAssertEqual(comps.year, 2026)
        XCTAssertEqual(comps.month, 12)
        XCTAssertEqual(comps.day, 25)
    }

    func testNextOccurrence_SolarPastMovesToNextYear() {
        let reminder = ReminderEvent(title: "Tết", dateType: .solar, day: 1, month: 1)
        let anchor = calendar.date(from: DateComponents(year: 2026, month: 10, day: 19))!
        let next = reminder.nextOccurrence(after: anchor, calendar: calendar)
        let comps = calendar.dateComponents([.year, .month, .day], from: next)
        XCTAssertEqual(comps.year, 2027)
        XCTAssertEqual(comps.month, 1)
        XCTAssertEqual(comps.day, 1)
    }

    func testCountdownText_Today() {
        let reminder = ReminderEvent(title: "Today", dateType: .solar, day: 19, month: 10)
        let anchor = calendar.date(from: DateComponents(year: 2026, month: 10, day: 19, hour: 10))!
        XCTAssertEqual(reminder.countdownText(relativeTo: anchor, calendar: calendar), "Hôm nay")
    }

    func testCountdownText_Tomorrow() {
        let reminder = ReminderEvent(title: "Tomorrow", dateType: .solar, day: 20, month: 10)
        let anchor = calendar.date(from: DateComponents(year: 2026, month: 10, day: 19, hour: 10))!
        XCTAssertEqual(reminder.countdownText(relativeTo: anchor, calendar: calendar), "Ngày mai")
    }

    func testCountdownText_DaysLeft() {
        let reminder = ReminderEvent(title: "Future", dateType: .solar, day: 25, month: 10)
        let anchor = calendar.date(from: DateComponents(year: 2026, month: 10, day: 19, hour: 10))!
        XCTAssertEqual(reminder.countdownText(relativeTo: anchor, calendar: calendar), "Còn 6 ngày")
    }
}
