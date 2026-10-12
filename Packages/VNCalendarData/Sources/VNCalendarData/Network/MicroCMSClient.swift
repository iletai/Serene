import Foundation
import OSLog

private let logger = Logger(subsystem: "com.iletai.annien", category: "MicroCMSClient")

public enum MicroCMSResponse<T: Decodable & Sendable>: Sendable {
    case success(data: T, eTag: String?)
    case notModified
}

public enum MicroCMSError: Error, Sendable {
    /// Thrown when serviceDomain/apiKey are missing so callers never mistake
    /// a misconfigured client for "no remote changes".
    case configurationMissing
}

public actor MicroCMSClient {
    private let serviceDomain: String
    private let apiKey: String
    private let session: URLSession
    private let defaults: UserDefaults

    public init(
        serviceDomain: String,
        apiKey: String,
        session: URLSession = .shared,
        /// Resolved inside the actor because `UserDefaults` is not `Sendable`.
        defaultsSuiteName: String? = nil
    ) {
        self.serviceDomain = serviceDomain
        self.apiKey = apiKey
        self.session = session
        if let suite = defaultsSuiteName {
            self.defaults = UserDefaults(suiteName: suite) ?? .standard
        } else {
            self.defaults = .standard
        }
    }

    public func fetchList<T: Decodable & Sendable>(
        endpoint: String,
        limit: Int = 100
    ) async throws -> MicroCMSResponse<T> {
        guard !serviceDomain.isEmpty, !apiKey.isEmpty else {
            throw MicroCMSError.configurationMissing
        }

        guard var components = URLComponents(string: "https://\(serviceDomain).microcms.io/api/v1/\(endpoint)") else {
            throw URLError(.badURL)
        }
        components.queryItems = [URLQueryItem(name: "limit", value: "\(limit)")]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-MICROCMS-API-KEY")
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let eTagKey = "microcms_etag_\(endpoint)"
        if let savedETag = defaults.string(forKey: eTagKey) {
            request.setValue(savedETag, forHTTPHeaderField: "If-None-Match")
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode == 304 {
            logger.info("Endpoint \(endpoint) returned 304 Not Modified.")
            return .notModified
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            logger.error("Endpoint \(endpoint) failed with status \(httpResponse.statusCode)")
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(T.self, from: data)

        let newETag = httpResponse.value(forHTTPHeaderField: "Etag")
        if let newETag {
            defaults.set(newETag, forKey: eTagKey)
        }

        return .success(data: decoded, eTag: newETag)
    }
}
