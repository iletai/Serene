import XCTest
@testable import VNCalendarData
import VNCalendarDomain

final class ProverbDataTests: XCTestCase {
    private func makeDefaults() throws -> UserDefaults {
        let suiteName = "proverb-tests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        addTeardownBlock { UserDefaults().removePersistentDomain(forName: suiteName) }
        return defaults
    }

    func testDTODecodesBothCategoryShapes() throws {
        let single = #"{"text":"Có công mài sắt, có ngày nên kim.","origin":"Tục ngữ Việt Nam","category":"tuc_ngu"}"#
        let singleDTO = try JSONDecoder().decode(MicroCMSProverbDTO.self, from: Data(single.utf8))
        XCTAssertEqual(singleDTO.category, "tuc_ngu")

        let many = #"{"text":"Lời nói chẳng mất tiền mua.","origin":"Tục ngữ Việt Nam","category":["tuc_ngu"]}"#
        let manyDTO = try JSONDecoder().decode(MicroCMSProverbDTO.self, from: Data(many.utf8))
        XCTAssertEqual(manyDTO.category, "tuc_ngu")

        let empty = #"{"text":"X","origin":"Y","category":[]}"#
        let emptyDTO = try JSONDecoder().decode(MicroCMSProverbDTO.self, from: Data(empty.utf8))
        XCTAssertEqual(emptyDTO.category, "cham_ngon")
    }

    func testListResponseDecodesContents() throws {
        let json = #"{"contents":[{"text":"A","origin":"Ca dao Việt Nam","category":"ca_da"}],"totalCount":1}"#
        let response = try JSONDecoder().decode(MicroCMSProverbListResponse.self, from: Data(json.utf8))
        XCTAssertEqual(response.contents.count, 1)
        XCTAssertEqual(response.contents[0].text, "A")
    }

    func testFetchWithoutCacheUsesBundle() async throws {
        let repo = HybridProverbRepository(
            client: MicroCMSClient(serviceDomain: "", apiKey: ""),
            defaults: try makeDefaults()
        )
        let proverbs = try await repo.fetchProverbs()
        XCTAssertEqual(proverbs.count, 30, "bundled_proverbs.json must contain 30 entries")
        XCTAssertFalse(proverbs[0].text.isEmpty)
        XCTAssertFalse(proverbs[0].origin.isEmpty)
        XCTAssertFalse(proverbs[0].category.isEmpty)
    }

    func testCachedJSONWinsOverBundle() async throws {
        let defaults = try makeDefaults()
        let cached = [Proverb(text: "Cached proverb", origin: "Test", category: "cham_ngon")]
        defaults.set(try JSONEncoder().encode(cached), forKey: "proverbs_cache_json")

        let repo = HybridProverbRepository(
            client: MicroCMSClient(serviceDomain: "", apiKey: ""),
            defaults: defaults
        )
        let proverbs = try await repo.fetchProverbs()
        XCTAssertEqual(proverbs.count, 1)
        XCTAssertEqual(proverbs[0].text, "Cached proverb")
    }

    func testCorruptCacheFallsBackToBundled() async throws {
        let defaults = try makeDefaults()
        defaults.set(Data("not json".utf8), forKey: "proverbs_cache_json")

        let repo = HybridProverbRepository(
            client: MicroCMSClient(serviceDomain: "", apiKey: ""),
            defaults: defaults
        )
        let proverbs = try await repo.fetchProverbs()
        XCTAssertEqual(proverbs.count, 30, "corrupt cache must be discarded for bundled fallback")
        XCTAssertNil(defaults.data(forKey: "proverbs_cache_json"),
                     "corrupt cache key must be deleted so next sync rewrites it")
    }

    func testSyncFailureKeepsExistingCache() async throws {
        let defaults = try makeDefaults()
        let cached = [Proverb(text: "Keep me", origin: "Test", category: "cham_ngon")]
        defaults.set(try JSONEncoder().encode(cached), forKey: "proverbs_cache_json")
        // empty serviceDomain/apiKey → MicroCMSError.configurationMissing
        let repo = HybridProverbRepository(
            client: MicroCMSClient(serviceDomain: "", apiKey: ""),
            defaults: defaults
        )
        do {
            try await repo.synchronizeRemoteContent()
            XCTFail("Expected configurationMissing")
        } catch {
            // expected
        }
        let proverbs = try await repo.fetchProverbs()
        XCTAssertEqual(proverbs.first?.text, "Keep me", "failed sync must not wipe cache")
    }
}
