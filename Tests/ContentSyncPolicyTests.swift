import XCTest
@testable import AnNien

final class ContentSyncPolicyTests: XCTestCase {
    func testAutoSyncOffBlocksEverything() {
        XCTAssertFalse(ContentSyncPolicy.allowsAutoSync(autoSyncEnabled: false, wifiOnly: false, isMeteredNetwork: false))
    }

    func testWifiOnlyBlocksOnMeteredNetworkOnly() {
        XCTAssertFalse(ContentSyncPolicy.allowsAutoSync(autoSyncEnabled: true, wifiOnly: true, isMeteredNetwork: true))
        XCTAssertTrue(ContentSyncPolicy.allowsAutoSync(autoSyncEnabled: true, wifiOnly: true, isMeteredNetwork: false))
    }

    func testMeteredNetworkIsIgnoredWhenWifiOnlyIsOff() {
        XCTAssertTrue(ContentSyncPolicy.allowsAutoSync(autoSyncEnabled: true, wifiOnly: false, isMeteredNetwork: true))
    }

    func testUnsetDefaultsMatchSettingsDefaults() async {
        let suite = "ContentSyncPolicyTests"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        let allowed = await ContentSyncPolicy.autoSyncAllowed(defaults: defaults)
        XCTAssertTrue(allowed, "Auto-sync is on and Wi-Fi-only is off until the user changes them")
    }

    func testDisabledAutoSyncInDefaultsIsHonoured() async {
        let suite = "ContentSyncPolicyTests.off"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        defaults.set(false, forKey: ContentSyncPolicy.autoSyncKey)
        let allowed = await ContentSyncPolicy.autoSyncAllowed(defaults: defaults)
        XCTAssertFalse(allowed)
    }
}
