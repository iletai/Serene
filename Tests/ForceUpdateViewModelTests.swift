import XCTest
import AppUpdateKit
@testable import AnNien

@MainActor
final class ForceUpdateViewModelTests: XCTestCase {
    private let url = URL(string: "https://apps.apple.com/app/id1")!

    private func viewModel(_ action: AppUpdateAction) -> ForceUpdateViewModel {
        ForceUpdateViewModel(action: action, onDismiss: {})
    }

    func testForceUpdateIsNotDismissible() {
        XCTAssertFalse(viewModel(.forceUpdate(title: "t", message: "m", storeURL: url)).isDismissible)
    }

    func testMaintenanceIsNotDismissible() {
        XCTAssertFalse(viewModel(.maintenance(title: "t", message: "m")).isDismissible)
    }

    func testOptionalUpdateIsDismissible() {
        XCTAssertTrue(viewModel(.optionalUpdate(title: "t", message: "m", storeURL: url)).isDismissible)
    }
}
