import XCTest
@testable import VNCalendarKit
import VNCalendarDesignSystem
import VNCalendarLunar

final class CalendarPreferenceTests: XCTestCase {
    /// Stored values from earlier installs keep working only while these literals stay unchanged.
    func testPreferenceKeysKeepPersistedNames() {
        XCTAssertEqual(VNCalendarPreferenceKey.defaultDisplayMode, "defaultCalendarDisplayMode")
        XCTAssertEqual(VNCalendarPreferenceKey.highlightFullAndNewMoon, "highlightFullAndNewMoon")
        XCTAssertEqual(VNCalendarPreferenceKey.showAuspiciousHours, "showAuspiciousHours")
        XCTAssertEqual(VNCalendarPreferenceKey.showSolarTermsAndTruc, "showSolarTermsAndTruc")
        XCTAssertEqual(VNCalendarPreferenceKey.showDailyQuote, "showDailyAuspiciousQuote")
    }

    /// The Settings picker tags are raw strings; each must map to a real mode.
    func testSettingsPickerTagsMapToDisplayModes() {
        XCTAssertEqual(VNCalendarDisplayMode(rawValue: "block"), .block)
        XCTAssertEqual(VNCalendarDisplayMode(rawValue: "month"), .month)
        XCTAssertEqual(VNCalendarDisplayMode(rawValue: "week"), .week)
        XCTAssertEqual(VNCalendarDisplayMode(rawValue: "year"), .year)
    }

    func testDayCellEqualityTracksMoonHighlight() {
        let on = VNDayCellView(dayModel: nil, isSelected: false, highlightMoon: true, onSelect: {})
        let off = VNDayCellView(dayModel: nil, isSelected: false, highlightMoon: false, onSelect: {})
        XCTAssertNotEqual(on, off, "Toggling the setting must invalidate cached .equatable() cells")
    }
}

final class WeekStartTests: XCTestCase {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = VNTime.vietnam
        return cal
    }

    // Wednesday 14 Oct 2026; the Monday-first week runs 12...18, the Sunday-first week 11...17.
    func testWeekStartsOnMondayByDefaultAndSundayWhenAsked() throws {
        let wed = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: 14)))
        let cache = VNMonthLunarCache()

        let monFirst = cache.computeWeekDays(around: wed)
        let sunFirst = cache.computeWeekDays(around: wed, startsOnSunday: true)

        XCTAssertEqual(monFirst.map(\.solarDay), Array(12...18))
        XCTAssertEqual(sunFirst.map(\.solarDay), Array(11...17))
    }

    func testSundayItselfStartsItsOwnWeekWhenSundayFirst() throws {
        let sun = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: 18)))
        let cache = VNMonthLunarCache()

        XCTAssertEqual(cache.computeWeekDays(around: sun, startsOnSunday: true).map(\.solarDay), Array(18...24))
        XCTAssertEqual(cache.computeWeekDays(around: sun).map(\.solarDay), Array(12...18))
    }
}
