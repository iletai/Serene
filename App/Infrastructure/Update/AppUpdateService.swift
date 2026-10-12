import Foundation
import AppUpdateKit
import VNCalendarDomain

/// Wraps AppUpdateKit with the app's microCMS endpoint and fail-safe defaults.
///
/// Fail-safe: any fetch/decode error resolves to `.none` (AppUpdateKit guarantees this),
/// so a broken CMS never blocks launch.
@MainActor
@Observable
public final class AppUpdateService {
    public static let shared = AppUpdateService()

    /// `annien.microcms.io` object API consumed by `AppUpdateConfig`.
    private static let endpoint = "app-update"

    public private(set) var action: AppUpdateAction = .none

    private let storeURL: URL?

    private init() {
        // nil → AppUpdateKit skips force/optional update, so a placeholder never hard-blocks users.
        let configured = (Bundle.main.object(forInfoDictionaryKey: "APP_STORE_URL") as? String) ?? ""
        storeURL = configured.isEmpty ? nil : URL(string: configured)
    }

    /// Call on launch and foreground. `oncePerSession` throttles repeat foregrounds.
    public func check(policy: AppUpdateCheckPolicy = .oncePerSession) async {
        let config = AppConfiguration.current
        guard !config.microCMSServiceDomain.isEmpty, !config.microCMSApiKey.isEmpty else {
            // Misconfigured build: fail open, same as AppUpdateKit's own error path.
            return
        }

        let url = URL(string: "https://\(config.microCMSServiceDomain).microcms.io/api/v1/\(Self.endpoint)")
        guard let url else { return }

        action = await AppUpdateManager.shared.check(
            policy: policy,
            defaultStoreURL: storeURL,
            fetcher: AppUpdateFetcher.microCMS(
                endpoint: url,
                apiKey: config.microCMSApiKey
            )
        )
    }
}
