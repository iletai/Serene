import XCTest
@testable import AnNien

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
        router.present(sheet: .search)
        router.dismissModals()
        router.present(sheet: .paywall)
        XCTAssertEqual(router.sheet, .paywall)
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
}
