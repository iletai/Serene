import XCTest
@testable import AnNien

final class StoreKitSubscriptionTests: XCTestCase {
    // Product IDs must stay in sync with App Store Connect — a mismatch means
    // the paywall silently loads nothing (missing IDs are dropped by StoreKit).
    func testProductIDsMatchAppStoreConnect() {
        XCTAssertEqual(ProductID.monthly, "com.iletai.annien.sub.monthly")
        XCTAssertEqual(ProductID.yearly, "com.iletai.annien.sub.yearly")
        XCTAssertEqual(ProductID.lifetime, "com.iletai.annien.nonconsumable.lifetime")
        XCTAssertEqual(ProductID.all, [ProductID.monthly, ProductID.yearly, ProductID.lifetime])
    }

    // Free state gates everything.
    func testFreeTierUnlocksNothing() {
        let free = EntitlementStatus.free
        XCTAssertFalse(free.isPro)
    }

    // Every paid tier unlocks Pro features.
    func testAllPaidTiersUnlockPro() {
        XCTAssertTrue(EntitlementStatus.pro(.monthly).isPro)
        XCTAssertTrue(EntitlementStatus.pro(.yearly).isPro)
        XCTAssertTrue(EntitlementStatus.pro(.lifetime).isPro)
    }
}
