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
        ad.present(from: nil)
        Task { await loadInterstitial() }
    }

    private func loadInterstitial() async {
        interstitial = try? await InterstitialAd.load(with: AdUnitIDs.interstitial, request: Request())
    }
}
