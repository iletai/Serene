import XCTest
import VNCalendarDomain
@testable import AnNien

final class FamilyTreeLayoutTests: XCTestCase {
    private let node = FamilyTreeLayout.nodeSize
    private let gap = FamilyTreeLayout.columnGap
    private let pad = FamilyTreeLayout.padding

    func testEmptyLayoutHasNoNodesAndZeroSize() {
        let layout = FamilyTreeLayout(memberCounts: [])
        XCTAssertTrue(layout.nodes.isEmpty)
        XCTAssertTrue(layout.edges.isEmpty)
        XCTAssertEqual(layout.size, .zero)
        XCTAssertEqual(layout.fitScale(in: CGSize(width: 300, height: 500)), 1)
    }

    func testRowsAreCentredOnTheWidestRow() throws {
        let layout = FamilyTreeLayout(memberCounts: [1, 3, 2])
        let widest = 3 * node.width + 2 * gap
        XCTAssertEqual(layout.size.width, widest + pad.width * 2)

        let single = try XCTUnwrap(layout.node(generation: 0, index: 0))
        XCTAssertEqual(layout.center(of: single).x, layout.size.width / 2, accuracy: 0.001)

        let first = try XCTUnwrap(layout.node(generation: 1, index: 0))
        XCTAssertEqual(first.origin.x, pad.width, accuracy: 0.001)
        let second = try XCTUnwrap(layout.node(generation: 1, index: 1))
        XCTAssertEqual(second.origin.x - first.origin.x, node.width + gap, accuracy: 0.001)
    }

    func testNodesAreGenerationMajorAndRowsStackByPitch() throws {
        let layout = FamilyTreeLayout(memberCounts: [2, 1])
        XCTAssertEqual(layout.nodes.map(\.generation), [0, 0, 1])
        XCTAssertEqual(layout.nodes.map(\.index), [0, 1, 0])
        let top = try XCTUnwrap(layout.node(generation: 0, index: 0))
        let next = try XCTUnwrap(layout.node(generation: 1, index: 0))
        XCTAssertEqual(next.origin.y - top.origin.y, FamilyTreeLayout.rowPitch, accuracy: 0.001)
    }

    func testCanvasHeightEndsAtLastRowPlusPadding() {
        let layout = FamilyTreeLayout(memberCounts: [1, 1, 1])
        let lastRowBottom = FamilyTreeLayout.rowY(2) + node.height
        XCTAssertEqual(layout.size.height, lastRowBottom + pad.height, accuracy: 0.001)
    }

    func testOneTrunkEdgePerGenerationGap() throws {
        let layout = FamilyTreeLayout(memberCounts: [2, 1, 3])
        XCTAssertEqual(layout.edges.count, 2)
        let edge = try XCTUnwrap(layout.edges.first)
        XCTAssertEqual(edge.start.y, FamilyTreeLayout.rowY(0) + node.height, accuracy: 0.001)
        XCTAssertEqual(edge.end.y, FamilyTreeLayout.rowY(1), accuracy: 0.001)
        XCTAssertEqual(edge.start.x, layout.size.width / 2, accuracy: 0.001)
    }

    func testFitScaleNeverExceedsOneAndStaysInRange() {
        let small = FamilyTreeLayout(memberCounts: [1])
        XCTAssertLessThanOrEqual(small.fitScale(in: CGSize(width: 5000, height: 5000)), 1)

        let wide = FamilyTreeLayout(memberCounts: [40])
        XCTAssertEqual(wide.fitScale(in: CGSize(width: 300, height: 540)), FamilyTreeLayout.scaleRange.lowerBound)
    }

    func testClampKeepsScaleInsideRange() {
        XCTAssertEqual(FamilyTreeLayout.clamped(0.01), FamilyTreeLayout.scaleRange.lowerBound)
        XCTAssertEqual(FamilyTreeLayout.clamped(9), FamilyTreeLayout.scaleRange.upperBound)
        XCTAssertEqual(FamilyTreeLayout.clamped(1), 1)
    }

    func testRingHasTwelveMonthsAndOnlyLunarMemorialsSortedByDay() {
        let late = ReminderEvent(title: "Giỗ B", category: .deathAnniversary, day: 20, month: 9)
        let early = ReminderEvent(title: "Giỗ A", category: .deathAnniversary, day: 3, month: 9)
        let birthday = ReminderEvent(title: "Sinh nhật", category: .birthday, day: 1, month: 9)
        let solar = ReminderEvent(title: "Giỗ dương", category: .deathAnniversary, dateType: .solar, day: 1, month: 9)

        let months = FamilyRingMonth.months(from: [late, birthday, solar, early])
        XCTAssertEqual(months.count, 12)
        XCTAssertEqual(months[8].members.map(\.title), ["Giỗ A", "Giỗ B"])
        XCTAssertTrue(months[0].isEmpty)
    }

    func testInitialUsesLastWord() {
        XCTAssertEqual(FamilyMemberInfo.initial(of: "Giỗ Cụ Ông Nguyễn Văn Phúc"), "P")
        XCTAssertEqual(FamilyMemberInfo.initial(of: ""), "?")
    }
}
