import Foundation
import Network

/// Gates the launch-time background sync on the user's Settings; the manual "Sync now" button bypasses it.
enum ContentSyncPolicy {
    static let autoSyncKey = "autoSyncMicroCMS"
    static let wifiOnlyKey = "microCMSWifiOnly"
    static let lastSyncKey = "microCMSLastSyncAt"

    static func allowsAutoSync(autoSyncEnabled: Bool, wifiOnly: Bool, isMeteredNetwork: Bool) -> Bool {
        autoSyncEnabled && !(wifiOnly && isMeteredNetwork)
    }

    static func autoSyncAllowed(defaults: UserDefaults = .standard) async -> Bool {
        // Unset keys behave like the Settings toggles' defaults (auto-sync on, Wi-Fi-only off).
        let autoSync = defaults.object(forKey: autoSyncKey) as? Bool ?? true
        let wifiOnly = defaults.object(forKey: wifiOnlyKey) as? Bool ?? false
        let metered = wifiOnly ? await isMeteredNetwork() : false
        return allowsAutoSync(autoSyncEnabled: autoSync, wifiOnly: wifiOnly, isMeteredNetwork: metered)
    }

    /// Cellular, hotspot and Low Data Mode all count as metered.
    private static func isMeteredNetwork() async -> Bool {
        for await path in NWPathMonitor() {
            return path.isExpensive || path.isConstrained
        }
        return false
    }
}
