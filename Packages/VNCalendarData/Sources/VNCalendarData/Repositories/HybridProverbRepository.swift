import Foundation
import OSLog
import VNCalendarDomain

private let logger = Logger(subsystem: "com.iletai.annien", category: "ProverbRepository")

public final class HybridProverbRepository: ProverbRepositoryProtocol, Sendable {
    public static let cacheKey = "proverbs_cache_json"
    private static let endpoint = "proverbs"

    private let client: MicroCMSClient
    /// `UserDefaults` is documented thread-safe but not marked `Sendable`.
    nonisolated(unsafe) private let defaults: UserDefaults
    private let bundle: Bundle?

    public init(client: MicroCMSClient, defaults: UserDefaults = .standard, bundle: Bundle? = nil) {
        self.client = client
        self.defaults = defaults
        self.bundle = bundle
    }

    public func fetchProverbs() async throws -> [Proverb] {
        if let data = defaults.data(forKey: Self.cacheKey) {
            do {
                return try JSONDecoder().decode([Proverb].self, from: data)
            } catch {
                logger.error("Corrupt proverbs cache discarded: \(error.localizedDescription)")
                defaults.removeObject(forKey: Self.cacheKey)
            }
        }
        return loadBundled()
    }

    public func synchronizeRemoteContent() async throws {
        let response: MicroCMSResponse<MicroCMSProverbListResponse> = try await client.fetchList(
            endpoint: Self.endpoint,
            limit: 100
        )
        if case .success(let payload, _) = response {
            let proverbs = payload.contents.map {
                Proverb(text: $0.text, origin: $0.origin, category: $0.category)
            }
            guard !proverbs.isEmpty else {
                logger.warning("microCMS returned 0 proverbs; keeping existing cache.")
                return
            }
            do {
                defaults.set(try JSONEncoder().encode(proverbs), forKey: Self.cacheKey)
            } catch {
                logger.error("Failed to encode proverbs cache: \(error.localizedDescription)")
            }
        }
    }

    private func loadBundled() -> [Proverb] {
        #if SWIFT_PACKAGE
        let targetBundle = bundle ?? Bundle.module
        #else
        let targetBundle = bundle ?? Bundle.main
        #endif
        guard let fileURL = targetBundle.url(forResource: "bundled_proverbs", withExtension: "json") else {
            logger.warning("bundled_proverbs.json not found in resources bundle.")
            return []
        }
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([BundledProverbDTO].self, from: data).map {
                Proverb(text: $0.text, origin: $0.origin, category: $0.category)
            }
        } catch {
            logger.error("Failed to decode bundled_proverbs.json: \(error.localizedDescription)")
            return []
        }
    }
}

/// Shape of bundled_proverbs.json entries.
private struct BundledProverbDTO: Decodable {
    let text: String
    let origin: String
    let category: String
}
