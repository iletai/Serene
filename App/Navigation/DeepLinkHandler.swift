import Foundation
import Observation
import UserNotifications

/// Maps `annien://<host>` URLs to a tab switch or a sheet on a tab router.
struct DeepLinkHandler: Sendable {
    enum Action: Equatable, Sendable {
        case select(MainTab)
        case present(tab: MainTab, sheet: AppSheet)
    }

    static let scheme = "annien"

    func action(for url: URL) -> Action? {
        // Schemes and hosts are case-insensitive (RFC 3986).
        guard url.scheme?.lowercased() == Self.scheme, let host = url.host()?.lowercased() else { return nil }
        switch host {
        case "calendar": return .select(.calendar)
        // Notification payloads use `annien://reminder/<uuid>`; minimal routing is the memorial tab.
        case "memorial", "reminder": return .select(.memorial)
        // Legacy link: the rituals tab was removed; fall back to the calendar tab.
        case "rituals": return .select(.calendar)
        case "family": return .select(.family)
        case "settings": return .present(tab: .calendar, sheet: .settings)
        case "paywall": return .present(tab: .calendar, sheet: .paywall)
        case "search": return .present(tab: .calendar, sheet: .search)
        default: return nil
        }
    }
}

/// Single inbox for deep links from `onOpenURL` and notification taps; `MainTabView` consumes it.
@MainActor
@Observable
final class DeepLinkCenter: NSObject, UNUserNotificationCenterDelegate {
    /// Shared so it can be the notification delegate from `App.init` (the delegate is held weakly).
    static let shared = DeepLinkCenter()

    var pendingAction: DeepLinkHandler.Action?

    func open(_ url: URL) {
        pendingAction = DeepLinkHandler().action(for: url)
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        // "Prepared" and dismiss actions must not navigate.
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier
            || response.actionIdentifier == SmartNotificationEngine.actionViewDetail else { return }
        let link = response.notification.request.content.userInfo["deep_link"] as? String
        await MainActor.run {
            pendingAction = link.flatMap(URL.init(string:)).flatMap(DeepLinkHandler().action(for:)) ?? .select(.memorial)
        }
    }
}
