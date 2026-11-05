import XCTest
import VNCalendarDesignSystem

final class DesignTokensTests: XCTestCase {
    func testLayoutTokensMatchSpec() {
        XCTAssertEqual(VNSpacing.screenMargin, 20)
        XCTAssertEqual(VNSpacing.cardPadding, 16)
        XCTAssertEqual(VNSpacing.sectionGap, 24)
        XCTAssertEqual(VNSize.minTapTarget, 44)
        XCTAssertEqual(VNSize.iconButton, 40)
        XCTAssertEqual(VNSize.iconBadge, 24)
        XCTAssertEqual(VNLayout.tabBarMaxWidth, 520)
        XCTAssertEqual(VNLayout.tabBarBottomInset, 12)
        XCTAssertEqual(VNLayout.tabBarItemHeight, 44)
    }
}
