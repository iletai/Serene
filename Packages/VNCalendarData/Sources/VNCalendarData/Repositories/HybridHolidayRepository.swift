import Foundation
import SwiftData
import VNCalendarDomain

public struct MicroCMSHolidayDTO: Decodable, Sendable {
    public let id: String
    public let title: String
    /// microCMS select fields decode as an array (`["lunar"]`); text fields arrive as a bare string.
    public let calendarType: String
    public let day: Int
    public let month: Int
    public let isNationalHoliday: Bool
    public let isTraditionHoliday: Bool
    public let summary: String
    public let customs: String?
    public let taboos: String?
    public let rituals: String?
    public let updatedAt: Date?

    private enum CodingKeys: String, CodingKey {
        case id, title, calendarType, day, month, isNationalHoliday,
             isTraditionHoliday, summary, customs, taboos, rituals, updatedAt
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        if let single = try? c.decode(String.self, forKey: .calendarType) {
            calendarType = single
        } else {
            let many = try c.decode([String].self, forKey: .calendarType)
            calendarType = many.first ?? "lunar"
        }
        day = try c.decode(Int.self, forKey: .day)
        month = try c.decode(Int.self, forKey: .month)
        isNationalHoliday = try c.decodeIfPresent(Bool.self, forKey: .isNationalHoliday) ?? false
        isTraditionHoliday = try c.decodeIfPresent(Bool.self, forKey: .isTraditionHoliday) ?? false
        summary = try c.decode(String.self, forKey: .summary)
        customs = try c.decodeIfPresent(String.self, forKey: .customs)
        taboos = try c.decodeIfPresent(String.self, forKey: .taboos)
        rituals = try c.decodeIfPresent(String.self, forKey: .rituals)
        updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
}

public struct MicroCMSHolidayListResponse: Decodable, Sendable {
    public let contents: [MicroCMSHolidayDTO]
    public let totalCount: Int
}

public final class HybridHolidayRepository: HolidayRepositoryProtocol, Sendable {
    private let dataActor: HolidayDataActor
    private let client: MicroCMSClient
    private let bundle: Bundle?
    private let seedState = SeedState()

    public init(
        modelContainer: ModelContainer,
        client: MicroCMSClient,
        bundle: Bundle? = nil
    ) {
        self.dataActor = HolidayDataActor(modelContainer: modelContainer)
        self.client = client
        self.bundle = bundle
    }

    // Avoids racing seed against the first read; re-entrant safe via actor.
    private actor SeedState {
        private var seeded = false

        func run(_ work: @Sendable () async -> Void) async {
            guard !seeded else { return }
            await work()
            seeded = true
        }
    }

    private func seedIfNeeded() async {
        let actor = dataActor
        let bundle = bundle
        await seedState.run {
            await SeedDataLoader.seedInitialHolidaysIfNeeded(dataActor: actor, bundle: bundle)
        }
    }

    public func getHolidays() async throws -> [Holiday] {
        await seedIfNeeded()
        return try await dataActor.fetchAllHolidays()
    }

    public func getHolidays(month: Int, isLunar: Bool) async throws -> [Holiday] {
        try await dataActor.fetchHolidays(month: month, isLunar: isLunar)
    }

    public func getHoliday(by id: String) async throws -> Holiday? {
        try await dataActor.getHoliday(by: id)
    }

    public func synchronizeRemoteContent() async throws {
        await seedIfNeeded()
        let response: MicroCMSResponse<MicroCMSHolidayListResponse> = try await client.fetchList(endpoint: "holidays", limit: 100)
        if case .success(let payload, _) = response {
            let holidays = payload.contents.map { dto in
                Holiday(
                    id: dto.id,
                    title: dto.title,
                    calendarType: CalendarDateType(rawValue: dto.calendarType) ?? .lunar,
                    day: dto.day,
                    month: dto.month,
                    isNationalHoliday: dto.isNationalHoliday,
                    isTraditionHoliday: dto.isTraditionHoliday,
                    summary: dto.summary,
                    customs: dto.customs,
                    taboos: dto.taboos,
                    rituals: dto.rituals,
                    updatedAt: dto.updatedAt ?? Date()
                )
            }
            try await dataActor.upsertHolidays(holidays)
        }
    }
}
