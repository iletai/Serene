import XCTest
@testable import VNCalendarData
import VNCalendarDomain
import SwiftData

final class DataTests: XCTestCase {
    var container: ModelContainer!

    override func setUp() async throws {
        container = try ModelContainerFactory.createContainer(inMemoryOnly: true, cloudKitContainerIdentifier: "iCloud.com.iletai.annien.test")
    }

    func testReminderCRUD() async throws {
        let repo = SwiftDataReminderRepository(modelContainer: container)

        let initial = try await repo.fetchAllReminders()
        XCTAssertEqual(initial.count, 0)

        let id = UUID()
        let event = ReminderEvent(
            id: id,
            title: "Giỗ Cụ Cố",
            category: .deathAnniversary,
            dateType: .lunar,
            day: 18,
            month: 8,
            year: nil
        )
        try await repo.saveReminder(event)

        let fetched = try await repo.getReminder(by: id)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.title, "Giỗ Cụ Cố")
        XCTAssertEqual(fetched?.day, 18)
        XCTAssertEqual(fetched?.month, 8)

        try await repo.deleteReminder(by: id)
        let afterDelete = try await repo.getReminder(by: id)
        XCTAssertNil(afterDelete)
    }

    func testHolidaySeeding() async throws {
        let client = MicroCMSClient(serviceDomain: "", apiKey: "")
        let repo = HybridHolidayRepository(modelContainer: container, client: client, bundle: Bundle.module)

        // Allow background seed task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        let holidays = try await repo.getHolidays()
        XCTAssertFalse(holidays.isEmpty, "Bundled holidays should be seeded")
        XCTAssertTrue(holidays.contains(where: { $0.id == "tet-nguyen-dan-1" }))
    }
}
