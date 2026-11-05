import Foundation

/// Extra free reminder slots earned by watching rewarded ads, on top of `FeatureGateRule.freeMaxReminders`.
/// Capped so ads cannot replace the Pro upgrade.
enum RewardedSlotStore {
    static let maxBonus = 5
    private static let key = "rewardedBonusSlots"

    static var count: Int { min(UserDefaults.standard.integer(forKey: key), maxBonus) }
    static var isAtCap: Bool { count >= maxBonus }

    static func add() {
        UserDefaults.standard.set(min(count + 1, maxBonus), forKey: key)
    }
}
