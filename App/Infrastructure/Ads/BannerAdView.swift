import GoogleMobileAds
import SwiftUI

/// Fixed 320x50 banner; height is exposed so callers can reserve layout space.
struct BannerAdView: UIViewRepresentable {
    static let height: CGFloat = 50

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = AdUnitIDs.banner
        banner.rootViewController = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }.first
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}
