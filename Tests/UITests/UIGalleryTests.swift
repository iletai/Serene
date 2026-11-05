import XCTest

/// Captures every screen in light / dark / accessibility-XXXL as `XCTAttachment`s named
/// `<screen>--<variant>`; `scripts/ui-gallery/build-gallery.sh` turns them into `index.html`.
/// Each shot is a fresh launch with `-UITestSeed` (in-memory seeded store, Pro pinned; see
/// `App/Infrastructure/UITestSupport.swift`), so tests never depend on simulator state.
/// A missing anchor is recorded as a failure but the screenshot is still taken (it shows the bug).
@MainActor
final class UIGalleryTests: XCTestCase {
    enum Variant: String, CaseIterable {
        case light, dark, xxxl
    }

    private static var didCheckSystemAlert = false

    func testCalendar() {
        gallery("calendar", route: "calendar", anchor: "Lịch Ngày", scrollsToBottom: true)
    }

    func testTodayCard() {
        for variant in Variant.allCases {
            let app = launch(variant, route: "calendar")
            let card = app.descendants(matching: .any)["today.card"]
            check(card.waitForExistence(timeout: 15), "today.card", variant)
            settle()
            attach(card.exists ? card.screenshot() : XCUIScreen.main.screenshot(), "today-card", variant)
        }
    }

    func testTimeline() {
        gallery("timeline", route: "memorial", anchor: "Nguyễn", scrollsToBottom: true)
    }

    func testFamilyTree() {
        gallery("family", route: "family", anchor: "Nguyễn Văn Phúc", scrollsToBottom: true)
    }

    func testHolidaySheet() {
        gallery("holiday", route: "holiday", anchor: "Tết Nguyên Đán")
    }

    func testRitualSheet() {
        gallery("ritual", route: "ritual", anchor: "VĂN KHẤN TRUYỀN THỐNG")
    }

    func testReminderFormError() {
        gallery("reminder-form", route: "reminderForm", anchor: "Nhập tên người được tưởng nhớ trước") { app in
            // Saving with an empty title shows the inline title error.
            let save = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Lưu Ngày Lễ")).firstMatch
            if save.waitForExistence(timeout: 15) { save.tap() }
        }
    }

    func testSettings() {
        gallery("settings", route: "settings", anchor: "settings.calendarSettings", scrollsToBottom: true)
    }

    func testCalendarSettings() {
        gallery("calendar-settings", route: "settings", anchor: "GMT+7") { app in
            let row = app.buttons["settings.calendarSettings"]
            if row.waitForExistence(timeout: 15) { row.tap() }
        }
    }

    func testPaywall() {
        gallery("paywall", route: "paywall", anchor: nil)
    }

    func testSearch() {
        gallery("search", route: "search", anchor: nil) { app in
            _ = app.textFields.firstMatch.waitForExistence(timeout: 15)
        }
    }

    // MARK: - Helpers

    /// Shoots one screen in every variant; list screens add a scrolled-to-bottom XXXL shot.
    private func gallery(
        _ screen: String,
        route: String,
        anchor: String?,
        scrollsToBottom: Bool = false,
        prepare: ((XCUIApplication) -> Void)? = nil
    ) {
        for variant in Variant.allCases {
            let app = launch(variant, route: route)
            prepare?(app)
            if let anchor {
                check(element(app, anchor).waitForExistence(timeout: 15), anchor, variant)
            }
            settle()
            attach(XCUIScreen.main.screenshot(), screen, variant)

            if scrollsToBottom, variant == .xxxl {
                let scrollView = app.scrollViews.firstMatch
                for _ in 0..<6 where scrollView.exists {
                    scrollView.swipeUp(velocity: .fast)
                }
                settle()
                attach(XCUIScreen.main.screenshot(), screen, "xxxl-bottom")
            }
        }
    }

    private func launch(_ variant: Variant, route: String) -> XCUIApplication {
        let app = XCUIApplication()
        // Argument-domain defaults: they override UserDefaults for this launch only and are never saved.
        var arguments = [
            "-UITestSeed", "1",
            "-UITestRoute", route,
            "-AppleLanguages", "(vi)",
            "-AppleLocale", "vi_VN",
            "-appLanguage", "vi",
            "-appThemeAppearance", variant == .dark ? "2" : "1"
        ]
        if variant == .xxxl {
            arguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launchArguments = arguments
        app.launch()
        dismissNotificationPermissionAlertOnce()
        return app
    }

    /// The app asks for notification permission on first launch; answer it once per run.
    private func dismissNotificationPermissionAlertOnce() {
        guard !Self.didCheckSystemAlert else { return }
        Self.didCheckSystemAlert = true
        let alert = XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts.firstMatch
        guard alert.waitForExistence(timeout: 5) else { return }
        let buttons = alert.buttons
        (buttons.count > 1 ? buttons.element(boundBy: 1) : buttons.firstMatch).tap()  // "Allow"
    }

    /// Matches an accessibility identifier or any element whose label contains `text`.
    private func element(_ app: XCUIApplication, _ text: String) -> XCUIElement {
        let predicate = NSPredicate(format: "identifier == %@ OR label CONTAINS %@", text, text)
        return app.descendants(matching: .any).matching(predicate).firstMatch
    }

    private func check(_ found: Bool, _ anchor: String, _ variant: Variant) {
        if !found { XCTFail("Anchor '\(anchor)' not found (\(variant.rawValue))") }
    }

    /// Lets transitions and async loads finish; bounded, not a polling sleep.
    private func settle() {
        _ = XCTWaiter.wait(for: [XCTestExpectation(description: "settle")], timeout: 1.0)
    }

    private func attach(_ screenshot: XCUIScreenshot, _ screen: String, _ variant: Variant) {
        attach(screenshot, screen, variant.rawValue)
    }

    private func attach(_ screenshot: XCUIScreenshot, _ screen: String, _ variant: String) {
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "\(screen)--\(variant)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
