import Foundation

/// AdMob ad unit IDs, injected per environment via Config/*.xcconfig -> Info.plist.
/// Dev builds receive Google sample units; Prod builds receive the real units.
enum AdUnitIDs {
    static let banner = value(for: "ADMOB_BANNER_UNIT_ID")
    static let interstitial = value(for: "ADMOB_INTERSTITIAL_UNIT_ID")
    static let rewarded = value(for: "ADMOB_REWARDED_UNIT_ID")
    static let native = value(for: "ADMOB_NATIVE_UNIT_ID")

    private static func value(for key: String) -> String {
        Bundle.main.object(forInfoDictionaryKey: key) as? String ?? ""
    }
}
