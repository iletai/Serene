import Foundation

public protocol ProverbRepositoryProtocol: Sendable {
    /// Returns cached proverbs; falls back to the bundled seed when the cache
    /// is missing or corrupt. Returns [] only when both cache and bundle are
    /// unavailable or undecodable (implementation logs the cause).
    func fetchProverbs() async throws -> [Proverb]
    /// Fetches from microCMS and refreshes the local cache. Keeps existing cache on any failure.
    func synchronizeRemoteContent() async throws
}
