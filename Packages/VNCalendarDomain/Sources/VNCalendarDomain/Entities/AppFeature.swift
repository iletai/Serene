import Foundation

public enum AppFeature: String, Sendable, Codable, CaseIterable {
    case unlimitedReminders
    case mediumAndLockWidgets
    case cloudKitSync
    case genealogyMode
    case customAlertSounds
    case batchExportICS
}

public struct FeatureGateRule: Sendable {
    public static let freeMaxReminders = 5

    public static func canCreateReminder(currentCount: Int, isPro: Bool) -> Bool {
        if isPro { return true }
        return currentCount < freeMaxReminders
    }

    /// All current features are Pro-only per the paywall copy.
    public static func isFeatureAvailable(_ feature: AppFeature, isPro: Bool) -> Bool {
        if isPro { return true }
        switch feature {
        case .unlimitedReminders, .mediumAndLockWidgets, .cloudKitSync,
             .genealogyMode, .customAlertSounds, .batchExportICS:
            return false
        }
    }
}
