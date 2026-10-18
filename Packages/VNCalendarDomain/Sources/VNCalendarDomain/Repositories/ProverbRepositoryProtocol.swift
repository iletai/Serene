import Foundation

public protocol ProverbRepositoryProtocol: Sendable {
    /// Returns cached proverbs, falling back to bundled seed data. Never returns [] unless both are empty.
    func fetchProverbs() async throws -> [Proverb]
    /// Fetches from microCMS and refreshes the local cache. Keeps existing cache on any failure.
    func synchronizeRemoteContent() async throws
}
