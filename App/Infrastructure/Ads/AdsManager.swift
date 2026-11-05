import AppTrackingTransparency
import GoogleMobileAds
import Observation
import UIKit
import UserMessagingPlatform
import VNCalendarData

/// Owns the ad lifecycle: UMP consent -> ATT -> SDK start, plus interstitial pacing.
/// Ads are never shown to Pro users.
@Observable
@MainActor
final class AdsManager {
    private(set) var isStarted = false

    @ObservationIgnored private let subscriptionManager: SubscriptionManager
    @ObservationIgnored private var isStarting = false
    @ObservationIgnored private var interstitial: InterstitialAd?
    @ObservationIgnored private var rewarded: RewardedAd?
    @ObservationIgnored private var saveCount = 0
    @ObservationIgnored private var lastInterstitialAt = Date.distantPast

    private static let interstitialEverySaves = 3
    private static let interstitialMinInterval: TimeInterval = 180

    init(subscriptionManager: SubscriptionManager) {
        self.subscriptionManager = subscriptionManager
    }

    var canShowAds: Bool { isStarted && !subscriptionManager.entitlement.isPro }

    /// Safe to call repeatedly (e.g. on every scene activation); ATT only prompts while the app is active.
    func start() async {
        guard !isStarted, !isStarting, !subscriptionManager.entitlement.isPro else { return }
        isStarting = true
        defer { isStarting = false }

        try? await ConsentInformation.shared.requestConsentInfoUpdate(with: RequestParameters())
        try? await ConsentForm.loadAndPresentIfRequired(from: nil)
        guard ConsentInformation.shared.canRequestAds else { return }

        _ = await ATTrackingManager.requestTrackingAuthorization()
        _ = await MobileAds.shared.start()
        isStarted = true
        await loadInterstitial()
        await loadRewarded()
    }

    /// Call after a user-initiated success moment (e.g. a saved reminder); paced so it never feels spammy.
    func noteSaveAndShowInterstitialIfDue() async {
        saveCount += 1
        // Let the dismissing sheet finish so the ad has a free presenter.
        try? await Task.sleep(for: .seconds(1))
        guard canShowAds, let ad = interstitial,
              saveCount % Self.interstitialEverySaves == 0,
              Date().timeIntervalSince(lastInterstitialAt) > Self.interstitialMinInterval else { return }
        lastInterstitialAt = Date()
        interstitial = nil
        ad.present(from: UIApplication.shared.topViewController)
        Task { await loadInterstitial() }
    }

    /// Shows a rewarded ad; on completion grants one bonus reminder slot. Returns whether the reward was earned.
    func showRewardedForBonusSlot() async -> Bool {
        guard canShowAds, !RewardedSlotStore.isAtCap else { return false }
        if rewarded == nil { await loadRewarded() }
        guard let ad = rewarded else { return false }
        rewarded = nil
        let earned = await RewardedFlow().run(ad)
        if earned { RewardedSlotStore.add() }
        await loadRewarded()
        return earned
    }

    private func loadInterstitial() async {
        interstitial = try? await InterstitialAd.load(with: AdUnitIDs.interstitial, request: Request())
    }

    private func loadRewarded() async {
        rewarded = try? await RewardedAd.load(with: AdUnitIDs.rewarded, request: Request())
    }
}

/// Bridges the rewarded ad's delegate callbacks to async/await; resolves when the ad is closed.
@MainActor
private final class RewardedFlow: NSObject, FullScreenContentDelegate {
    private var continuation: CheckedContinuation<Bool, Never>?
    private var earned = false

    func run(_ ad: RewardedAd) async -> Bool {
        ad.fullScreenContentDelegate = self
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            ad.present(from: UIApplication.shared.topViewController) { [weak self] in self?.earned = true }
        }
    }

    func adDidDismissFullScreenContent(_ ad: any FullScreenPresentingAd) { finish() }

    func ad(_ ad: any FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: any Error) { finish() }

    private func finish() {
        continuation?.resume(returning: earned)
        continuation = nil
    }
}

extension UIApplication {
    /// Topmost presented view controller, so ads can present over an open sheet.
    var topViewController: UIViewController? {
        var top = connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }.first
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}
