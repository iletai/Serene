import XCTest

@MainActor
final class SnapshotUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCaptureScreenshots() throws {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()

        // 1. Calendar main screen
        snapshot("01-calendar")

        // 2. Memorial / Ngày Giỗ tab
        let memorialTab = app.buttons["Ngày Giỗ"]
        if memorialTab.waitForExistence(timeout: 5) {
            memorialTab.tap()
            sleep(1)
            snapshot("02-memorial")
        }

        // 3. Gia Tộc tab
        let familyTab = app.buttons["Gia Tộc"]
        if familyTab.waitForExistence(timeout: 5) {
            familyTab.tap()
            sleep(1)
            snapshot("03-family")
        }
    }
}
