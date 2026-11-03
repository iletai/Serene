import XCTest
import VNCalendarDomain
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
}
