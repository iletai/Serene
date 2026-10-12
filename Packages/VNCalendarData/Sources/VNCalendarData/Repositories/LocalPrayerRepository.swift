import Foundation
import VNCalendarDomain
import OSLog

private let logger = Logger(subsystem: "com.iletai.annien", category: "LocalPrayerRepository")

public actor LocalPrayerRepository: PrayerRepositoryProtocol {
    private var cachedPrayers: [Prayer] = []
    private var isLoaded = false
    private let bundle: Bundle?

    public init(bundle: Bundle? = nil) {
        self.bundle = bundle
    }

    public func fetchAllPrayers() async throws -> [Prayer] {
        try await loadIfNeeded()
        return cachedPrayers
    }

    public func fetchPrayers(in category: PrayerCategory) async throws -> [Prayer] {
        try await loadIfNeeded()
        return cachedPrayers.filter { $0.category == category }
    }

    public func searchPrayers(query: String) async throws -> [Prayer] {
        try await loadIfNeeded()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return cachedPrayers }

        let matches = cachedPrayers.filter { prayer in
            prayer.title.localizedCaseInsensitiveContains(trimmed) ||
            prayer.occasion.localizedCaseInsensitiveContains(trimmed) ||
            prayer.prayerText.localizedCaseInsensitiveContains(trimmed) ||
            prayer.tags.contains(where: { $0.localizedCaseInsensitiveContains(trimmed) })
        }

        // Sort: title matches first
        return matches.sorted { p1, p2 in
            let p1Title = p1.title.localizedCaseInsensitiveContains(trimmed)
            let p2Title = p2.title.localizedCaseInsensitiveContains(trimmed)
            if p1Title && !p2Title { return true }
            if !p1Title && p2Title { return false }
            return false
        }
    }

    public func fetchPrayer(by id: String) async throws -> Prayer? {
        try await loadIfNeeded()
        return cachedPrayers.first { $0.id == id }
    }

    // MARK: - Private Loader

    private func loadIfNeeded() async throws {
        if isLoaded { return }

        #if SWIFT_PACKAGE
        let targetBundle = bundle ?? Bundle.module
        #else
        let targetBundle = bundle ?? Bundle.main
        #endif

        guard let fileURL = targetBundle.url(forResource: "bundled_prayers", withExtension: "json") else {
            logger.warning("bundled_prayers.json not found in bundle resources.")
            self.cachedPrayers = []
            self.isLoaded = true
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            self.cachedPrayers = try decoder.decode([Prayer].self, from: data)
            self.isLoaded = true
            logger.info("Successfully loaded \(self.cachedPrayers.count) traditional prayers.")
        } catch {
            logger.error("Failed to decode bundled_prayers.json: \(error.localizedDescription)")
            self.cachedPrayers = []
            self.isLoaded = true
        }
    }
}
