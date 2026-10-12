import Foundation

public protocol PrayerRepositoryProtocol: Sendable {
    func fetchAllPrayers() async throws -> [Prayer]
    func fetchPrayers(in category: PrayerCategory) async throws -> [Prayer]
    func searchPrayers(query: String) async throws -> [Prayer]
    func fetchPrayer(by id: String) async throws -> Prayer?
}
