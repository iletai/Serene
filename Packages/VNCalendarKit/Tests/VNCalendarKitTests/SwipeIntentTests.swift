import Testing
import CoreGraphics
@testable import VNCalendarKit

struct SwipeIntentTests {
    @Test func horizontalSwipeNavigates() {
        #expect(SwipeIntent.classify(translation: CGSize(width: -80, height: 10)) == .next)
        #expect(SwipeIntent.classify(translation: CGSize(width: 80, height: 10)) == .previous)
    }

    @Test func mostlyVerticalDragIsIgnored() {
        #expect(SwipeIntent.classify(translation: CGSize(width: -80, height: 120)) == .none)
        #expect(SwipeIntent.classify(translation: CGSize(width: 70, height: 60)) == .none)
    }

    @Test func shortDragUsesPredictedEnd() {
        #expect(SwipeIntent.classify(translation: CGSize(width: -30, height: 0)) == .none)
        #expect(
            SwipeIntent.classify(translation: CGSize(width: -30, height: 0), predictedEnd: CGSize(width: -200, height: 0)) == .next
        )
    }
}
