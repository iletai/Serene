import XCTest
import SwiftUI
@testable import VNCalendarDesignSystem

/// Reference values come from design.html `moonSVG` (24x24 box, r = 10): the first lit pixel columns per lunar day.
final class VNMoonPhaseShapeTests: XCTestCase {
    private let box = CGRect(x: 2, y: 2, width: 20, height: 20)

    private func bounds(_ day: Int) -> CGRect {
        VNMoonPhaseShape(lunarDay: day).path(in: box).boundingRect
    }

    func testNewMoonHasNoLitArea() {
        XCTAssertTrue(VNMoonPhaseShape(lunarDay: 1).path(in: box).isEmpty)
    }

    func testWaxingCrescentIsLitOnTheEast() {
        let rect = bounds(8)
        XCTAssertEqual(rect.minX, 12, accuracy: 0.05)
        XCTAssertEqual(rect.maxX, 22, accuracy: 0.05)
    }

    func testFullMoonSpansTheWholeDisc() {
        let rect = bounds(15)
        XCTAssertEqual(rect.width, 20, accuracy: 0.3)
        XCTAssertEqual(rect.height, 20, accuracy: 0.05)
    }

    func testWaningPhaseIsLitOnTheWest() {
        let rect = bounds(22)
        XCTAssertEqual(rect.minX, 2, accuracy: 0.05)
        XCTAssertEqual(rect.maxX, 14.4, accuracy: 0.1)
    }

    func testLeapMonthDay30StaysInsideTheDisc() {
        let rect = bounds(30)
        XCTAssertGreaterThanOrEqual(rect.minX, 2 - 0.01)
        XCTAssertLessThanOrEqual(rect.maxX, 22 + 0.01)
    }
}
