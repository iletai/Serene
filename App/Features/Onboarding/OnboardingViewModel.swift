import Foundation
import Observation

/// First-launch onboarding: page index, notification opt-in result and the leave transition.
/// Preference choices on the last page are written straight to the Settings `@AppStorage` keys by the View.
@Observable
@MainActor
final class OnboardingViewModel {
    static let pageCount = 4
    static let notificationPageIndex = 2
    static let leaveDuration: Duration = .milliseconds(300)

    var index = 0
    private(set) var notificationsEnabled = false
    private(set) var isLeaving = false

    @ObservationIgnored private let requestNotifications: @MainActor () async -> Bool
    @ObservationIgnored private let onFinish: @MainActor () -> Void

    init(
        requestNotifications: @escaping @MainActor () async -> Bool,
        onFinish: @escaping @MainActor () -> Void
    ) {
        self.requestNotifications = requestNotifications
        self.onFinish = onFinish
    }

    var isLastPage: Bool { index == Self.pageCount - 1 }

    func go(to page: Int) {
        index = max(0, min(Self.pageCount - 1, page))
    }

    func next() {
        go(to: index + 1)
    }

    /// Asks the system for notification permission (the same engine call the app already uses), then moves on.
    func enableNotifications() async {
        notificationsEnabled = await requestNotifications()
        go(to: Self.notificationPageIndex + 1)
    }

    /// Plays the leave fade (skipped for Reduce Motion), then hands control back so the cover can dismiss.
    func finish(animated: Bool) async {
        guard !isLeaving else { return }
        isLeaving = true
        if animated {
            try? await Task.sleep(for: Self.leaveDuration)
        }
        onFinish()
    }
}
