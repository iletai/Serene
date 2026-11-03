import XCTest
import VNCalendarDesignSystem

final class VNHapticsTests: XCTestCase {
    func testShouldFireFollowsSetting() {
        XCTAssertFalse(VNHaptics.shouldFire(enabled: false))
        XCTAssertTrue(VNHaptics.shouldFire(enabled: true))
    }
}
