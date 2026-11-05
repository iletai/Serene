import Testing
import CoreGraphics
@testable import VNCalendarKit

struct TapIntentTests {
    @Test func stationaryTouchIsTap() {
        #expect(TapIntent.isTap(.zero))
        #expect(TapIntent.isTap(CGSize(width: 4, height: 6)))
    }

    @Test func scrollOrSwipeIsNotTap() {
        #expect(!TapIntent.isTap(CGSize(width: 0, height: 24)))
        #expect(!TapIntent.isTap(CGSize(width: 30, height: 2)))
    }
}
