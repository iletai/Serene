import SwiftData
import XCTest
@testable import VNCalendarData

/// Serves canned responses so the client's HTTP contract is tested without the network.
private final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var handler: ((URLRequest) -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else { return }
        let (response, data) = handler(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

final class MicroCMSClientTests: XCTestCase {
    private let suite = "MicroCMSClientTests"

    // Real microCMS payload shape: select fields are arrays, timestamps carry milliseconds.
    private let holidayJSON = """
    {"contents":[{"id":"quoc-te-lao-dong","updatedAt":"2026-10-05T14:03:52.487Z","title":"Ngày Quốc Tế Lao Động",
    "calendarType":["solar"],"day":1,"month":5,"isNationalHoliday":true,"isTraditionHoliday":false,"summary":"s"}],
    "totalCount":1,"offset":0,"limit":100}
    """

    override func setUp() {
        UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
    }

    private func makeClient() -> MicroCMSClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return MicroCMSClient(
            serviceDomain: "annien",
            apiKey: "key",
            session: URLSession(configuration: config),
            defaultsSuiteName: suite
        )
    }

    private func reply(_ request: URLRequest, status: Int, headers: [String: String] = [:], body: String = "") -> (HTTPURLResponse, Data) {
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: headers)!
        return (response, Data(body.utf8))
    }

    func testDecodesMillisecondTimestampsFromMicroCMS() async throws {
        StubURLProtocol.handler = { self.reply($0, status: 200, headers: ["Etag": "W/\"1\""], body: self.holidayJSON) }

        let result: MicroCMSResponse<MicroCMSHolidayListResponse> = try await makeClient().fetchList(endpoint: "holidays")

        guard case .success(let payload, let eTag) = result else { return XCTFail("expected success") }
        let expected = try Date("2026-10-05T14:03:52.487Z", strategy: Date.ISO8601FormatStyle(includingFractionalSeconds: true))
        XCTAssertEqual(payload.contents.first?.updatedAt, expected)
        XCTAssertEqual(eTag, "W/\"1\"")
    }

    func testSendsSavedETagAndReturnsNotModifiedOn304() async throws {
        StubURLProtocol.handler = { self.reply($0, status: 200, headers: ["Etag": "W/\"1\""], body: self.holidayJSON) }
        let client = makeClient()
        let _: MicroCMSResponse<MicroCMSHolidayListResponse> = try await client.fetchList(endpoint: "holidays")

        nonisolated(unsafe) var sentETag: String?
        StubURLProtocol.handler = {
            sentETag = $0.value(forHTTPHeaderField: "If-None-Match")
            return self.reply($0, status: 304)
        }
        let second: MicroCMSResponse<MicroCMSHolidayListResponse> = try await client.fetchList(endpoint: "holidays")

        XCTAssertEqual(sentETag, "W/\"1\"")
        guard case .notModified = second else { return XCTFail("expected notModified") }
    }

    func testClearETagStopsConditionalRequests() async throws {
        StubURLProtocol.handler = { self.reply($0, status: 200, headers: ["Etag": "W/\"1\""], body: self.holidayJSON) }
        let client = makeClient()
        let _: MicroCMSResponse<MicroCMSHolidayListResponse> = try await client.fetchList(endpoint: "holidays")

        await client.clearETag(endpoint: "holidays")

        nonisolated(unsafe) var sentETag: String? = "unset"
        StubURLProtocol.handler = {
            sentETag = $0.value(forHTTPHeaderField: "If-None-Match")
            return self.reply($0, status: 200, body: self.holidayJSON)
        }
        let _: MicroCMSResponse<MicroCMSHolidayListResponse> = try await client.fetchList(endpoint: "holidays")

        XCTAssertNil(sentETag)
    }

    func testHolidaySyncFailureDropsETagSoNextSyncRefetches() async throws {
        StubURLProtocol.handler = { self.reply($0, status: 200, headers: ["Etag": "W/\"1\""], body: self.holidayJSON) }
        let client = makeClient()
        // Reopening an existing store read-only makes save() throw, so persisting the fetched holidays must fail.
        let storeURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: storeURL) }
        _ = try ModelContainer(for: HolidayEntity.self, configurations: ModelConfiguration(url: storeURL))
        let brokenContainer = try ModelContainer(
            for: HolidayEntity.self,
            configurations: ModelConfiguration(url: storeURL, allowsSave: false)
        )
        let repo = HybridHolidayRepository(modelContainer: brokenContainer, client: client)

        do {
            try await repo.synchronizeRemoteContent()
            XCTFail("expected persistence failure")
        } catch {}

        nonisolated(unsafe) var sentETag: String? = "unset"
        StubURLProtocol.handler = {
            sentETag = $0.value(forHTTPHeaderField: "If-None-Match")
            return self.reply($0, status: 200, body: self.holidayJSON)
        }
        let _: MicroCMSResponse<MicroCMSHolidayListResponse> = try await client.fetchList(endpoint: "holidays")

        XCTAssertNil(sentETag, "a stale ETag would turn the next sync into a permanent 304")
    }
}
