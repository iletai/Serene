import GoogleMobileAds
import SwiftUI

/// Loads one native ad and renders it as a compact card (icon, headline, body, call to action).
struct NativeAdCard: View {
    @State private var loader = NativeAdLoader()

    var body: some View {
        if let ad = loader.ad {
            NativeAdRepresentable(ad: ad)
                .frame(height: 96)
        } else {
            Color.clear.frame(height: 0).task { loader.load() }
        }
    }
}

@Observable
@MainActor
private final class NativeAdLoader: NSObject, NativeAdLoaderDelegate {
    private(set) var ad: NativeAd?
    @ObservationIgnored private var adLoader: AdLoader?

    func load() {
        guard adLoader == nil else { return }
        let rootVC = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }.first
        adLoader = AdLoader(adUnitID: AdUnitIDs.native, rootViewController: rootVC, adTypes: [.native], options: nil)
        adLoader?.delegate = self
        adLoader?.load(Request())
    }

    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) { ad = nativeAd }
    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: any Error) { adLoader.delegate = nil }
}

private struct NativeAdRepresentable: UIViewRepresentable {
    let ad: NativeAd

    func makeUIView(context: Context) -> NativeAdView {
        let view = NativeAdView()
        let icon = UIImageView()
        let headline = UILabel()
        let body = UILabel()
        let cta = UILabel()
        headline.font = .preferredFont(forTextStyle: .subheadline).withWeight(.semibold)
        body.font = .preferredFont(forTextStyle: .caption1)
        body.textColor = .secondaryLabel
        body.numberOfLines = 2
        cta.font = .preferredFont(forTextStyle: .caption1).withWeight(.semibold)
        cta.textColor = .tintColor
        icon.contentMode = .scaleAspectFit
        icon.widthAnchor.constraint(equalToConstant: 48).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 48).isActive = true

        let texts = UIStackView(arrangedSubviews: [headline, body, cta])
        texts.axis = .vertical
        texts.spacing = 2
        let row = UIStackView(arrangedSubviews: [icon, texts])
        row.spacing = 12
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            row.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            row.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        view.iconView = icon
        view.headlineView = headline
        view.bodyView = body
        view.callToActionView = cta
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        return view
    }

    func updateUIView(_ view: NativeAdView, context: Context) {
        (view.headlineView as? UILabel)?.text = ad.headline
        (view.bodyView as? UILabel)?.text = ad.body
        (view.callToActionView as? UILabel)?.text = ad.callToAction
        (view.iconView as? UIImageView)?.image = ad.icon?.image
        view.nativeAd = ad
    }
}

private extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        UIFont.systemFont(ofSize: pointSize, weight: weight)
    }
}
