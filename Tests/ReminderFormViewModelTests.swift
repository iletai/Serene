import XCTest
import VNCalendarDomain
import VNCalendarLunar
@testable import AnNien

@MainActor
final class ReminderFormViewModelTests: XCTestCase {
    func testIsDirtyFalseInitially() {
        XCTAssertFalse(ReminderFormViewModel().isDirty)
        XCTAssertFalse(ReminderFormViewModel(initialDate: Date()).isDirty)
    }

    func testIsDirtyTrueAfterTitleEdit() {
        let vm = ReminderFormViewModel()
        vm.title = "Giỗ Ông"
        XCTAssertTrue(vm.isDirty)
    }

    func testIsDirtyFalseAfterSave() {
        let vm = ReminderFormViewModel()
        vm.title = "Giỗ Ông"
        XCTAssertNotNil(vm.save())
        XCTAssertFalse(vm.isDirty)
    }

    func testSaveWithEmptyTitleShowsErrorAndReturnsNil() {
        let vm = ReminderFormViewModel()
        XCTAssertFalse(vm.showsTitleError)
        XCTAssertNil(vm.save())
        XCTAssertTrue(vm.showsTitleError)
        vm.title = "Giỗ Bà"
        XCTAssertFalse(vm.showsTitleError)
    }

    func testInitialDateSeedsLunarDayAndMonth() throws {
        // 2026-09-25 (solar) is Mid-Autumn: lunar 15/8.
        let solar = SolarDate(day: 25, month: 9, year: 2026)
        let date = try XCTUnwrap(solar.date)
        let expected = LunarAstronomicalEngine.shared.convertToLunar(from: solar)
        XCTAssertEqual(expected.day, 15)
        XCTAssertEqual(expected.month, 8)

        let vm = ReminderFormViewModel(initialDate: date)
        XCTAssertEqual(vm.dateType, .lunar)
        XCTAssertEqual(vm.day, expected.day)
        XCTAssertEqual(vm.month, expected.month)
        XCTAssertEqual(vm.isLeapMonth, expected.isLeapMonth)
    }

    func testEditModeIsNotDirtyAndSaveKeepsId() throws {
        let existing = ReminderEvent(title: "Giỗ Ông", day: 10, month: 3, note: "Mâm cỗ", relationship: "Ông")
        let vm = ReminderFormViewModel(existingReminder: existing)
        XCTAssertFalse(vm.isDirty)

        let saved = try XCTUnwrap(vm.save())
        XCTAssertEqual(saved.id, existing.id)
        XCTAssertEqual(saved.title, "Giỗ Ông")
    }
}
