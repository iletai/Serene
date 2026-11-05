import XCTest
@testable import AnNien

final class DeepLinkHandlerTests: XCTestCase {
    private let handler = DeepLinkHandler()

    private func action(_ string: String) -> DeepLinkHandler.Action? {
        guard let url = URL(string: string) else { return nil }
        return handler.action(for: url)
    }

    func testDeepLinkSelectsTabAndPresentsSheet() {
        XCTAssertEqual(action("annien://settings"), .present(tab: .calendar, sheet: .settings))
        XCTAssertNil(action("annien://nope"))
    }

    func testTabHostsSelectTab() {
        XCTAssertEqual(action("annien://calendar"), .select(.calendar))
        XCTAssertEqual(action("annien://memorial"), .select(.memorial))
        XCTAssertEqual(action("annien://rituals"), .select(.calendar))  // legacy link
        XCTAssertEqual(action("annien://family"), .select(.family))
    }

    func testSheetHostsPresentOnCalendarTab() {
        XCTAssertEqual(action("annien://paywall"), .present(tab: .calendar, sheet: .paywall))
        XCTAssertEqual(action("annien://search"), .present(tab: .calendar, sheet: .search))
    }

    /// Notification payloads carry `annien://reminder/<uuid>`; route them to the memorial tab.
    func testReminderLinkSelectsMemorialTab() {
        XCTAssertEqual(action("annien://reminder/\(UUID().uuidString)"), .select(.memorial))
    }

    func testSchemeAndHostAreCaseInsensitive() {
        XCTAssertEqual(action("annien://Settings"), .present(tab: .calendar, sheet: .settings))
        XCTAssertEqual(action("ANNIEN://calendar"), .select(.calendar))
    }

    func testForeignSchemeIsIgnored() {
        XCTAssertNil(action("https://settings"))
    }
}
