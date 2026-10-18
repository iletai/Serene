import Foundation
import Observation
import VNCalendarData
import VNCalendarDomain

/// MicroCMS `app-config` object API response. All fields optional so an empty
/// CMS object (or partial fill) decodes without throwing.
private struct LegalLinksPayload: Decodable, Sendable {
    let privacyPolicyURL: String?
    let termsOfUseURL: String?
    let supportURL: String?

    enum CodingKeys: String, CodingKey {
        case privacyPolicyURL = "privacy_policy_url"
        case termsOfUseURL = "terms_of_use_url"
        case supportURL = "support_url"
    }
}

/// Remote legal URLs from the microCMS `app-config` object API so links can be
/// updated (privacy text, new host, ToS) without shipping an App Store release.
/// Falls back to the built-in URLs below whenever the CMS is unreachable,
/// misconfigured, or the content has not been filled in yet.
@MainActor
@Observable
public final class LegalLinksService {
    public static let shared = LegalLinksService()

    // Always-live fallbacks bundled with the build (Guideline 3.1.2 minimum).
    public private(set) var privacyPolicyURL = URL(string: "https://github.com/iletai/Serene/blob/develop/PRIVACY.md")
    public private(set) var termsOfUseURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")
    public private(set) var supportURL = URL(string: "https://github.com/iletai/Serene/issues")

    /// Fetch once per session; call from `.task` on screens that show legal links.
    public func refresh() async {
        let config = AppConfiguration.current
        guard !config.microCMSServiceDomain.isEmpty, !config.microCMSApiKey.isEmpty else { return }

        let client = MicroCMSClient(
            serviceDomain: config.microCMSServiceDomain,
            apiKey: config.microCMSApiKey
        )

        let response: MicroCMSResponse<LegalLinksPayload>?
        do {
            response = try await client.fetchList(endpoint: "app-config", limit: 1)
        } catch {
            response = nil
        }

        guard case .success(let payload, _)? = response else { return }
        // Sanitize CMS strings: trim leading/trailing whitespace and require https/http scheme.
        if let value = payload.privacyPolicyURL?.trimmingCharacters(in: .whitespacesAndNewlines),
           let url = URL(string: value), url.scheme?.hasPrefix("http") == true {
            privacyPolicyURL = url
        }
        if let value = payload.termsOfUseURL?.trimmingCharacters(in: .whitespacesAndNewlines),
           let url = URL(string: value), url.scheme?.hasPrefix("http") == true {
            termsOfUseURL = url
        }
        if let value = payload.supportURL?.trimmingCharacters(in: .whitespacesAndNewlines),
           let url = URL(string: value), url.scheme?.hasPrefix("http") == true {
            supportURL = url
        }
    }
}
