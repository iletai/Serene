import XCTest
@testable import AnNien
import VNCalendarDomain

@MainActor
final class AppNavigationTests: XCTestCase {
    func testDoubleTapPushIsIgnored() {
        let router = AppRouter()
        XCTAssertTrue(router.push(.about))
        XCTAssertFalse(router.push(.about))
        XCTAssertEqual(router.path, [.about])
    }

    func testSheetThenSecondSheetReplacesNotStacks() {
        let router = AppRouter()
        XCTAssertTrue(router.present(sheet: .search))
        XCTAssertTrue(router.present(sheet: .paywall))
        XCTAssertEqual(router.sheet, .paywall)
    }

    func testSheetAndCoverAreMutuallyExclusive() {
        let sheetRouter = AppRouter()
        sheetRouter.present(sheet: .search)
        XCTAssertFalse(sheetRouter.present(cover: .unused))
        XCTAssertNil(sheetRouter.cover)

        let coverRouter = AppRouter()
        XCTAssertTrue(coverRouter.present(cover: .unused))
        XCTAssertFalse(coverRouter.present(sheet: .paywall))
        XCTAssertNil(coverRouter.sheet)
    }

    func testPopToRootClearsModals() {
        let router = AppRouter()
        router.push(.dataBackup)
        router.present(sheet: .settings)
        router.popToRoot()
        XCTAssertTrue(router.path.isEmpty)
        XCTAssertNil(router.sheet)
    }

    func testSheetIdsAreStableAndDistinct() {
        XCTAssertEqual(AppSheet.paywall.id, AppSheet.paywall.id)
        XCTAssertNotEqual(AppSheet.search, AppSheet.settings)
        XCTAssertNotEqual(AppSheet.ritual(title: "A"), AppSheet.ritual(title: "B"))
    }

    func testReminderFormIdsDependOnEventAndDate() {
        let event = ReminderEvent(title: "Giỗ", day: 10, month: 3)
        let other = ReminderEvent(title: "Giỗ", day: 10, month: 3)
        let date = Date(timeIntervalSince1970: 1_000_000)
        let laterDate = Date(timeIntervalSince1970: 2_000_000)

        XCTAssertEqual(
            AppSheet.reminderForm(editing: event, initialDate: date),
            AppSheet.reminderForm(editing: event, initialDate: date)
        )
        XCTAssertNotEqual(
            AppSheet.reminderForm(editing: event, initialDate: date),
            AppSheet.reminderForm(editing: event, initialDate: laterDate)
        )
        XCTAssertNotEqual(
            AppSheet.reminderForm(editing: event, initialDate: date),
            AppSheet.reminderForm(editing: other, initialDate: date)
        )
        XCTAssertNotEqual(
            AppSheet.reminderForm(editing: nil, initialDate: date),
            AppSheet.reminderForm(editing: nil, initialDate: nil)
        )
    }
}
