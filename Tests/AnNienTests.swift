import XCTest
@testable import AnNien
import VNCalendarDomain
import VNCalendarData
import VNCalendarLunar
import VNCalendarDesignSystem
import VNCalendarKit

final class AnNienIntegrationTests: XCTestCase {
    @MainActor
    func testAppContainerInitialization() {
        let container = AppContainer(inMemory: true)
        XCTAssertNotNil(container.modelContainer)
        XCTAssertNotNil(container.reminderRepository)
        XCTAssertNotNil(container.holidayRepository)
        XCTAssertNotNil(container.subscriptionManager)
        XCTAssertNotNil(container.notificationEngine)
    }

    @MainActor
    func testFullCalendarFlow() async throws {
        let container = AppContainer(inMemory: true)

        // 1. Create a memorial event
        let reminder = ReminderEvent(
            title: "Giỗ Cụ Cố",
            category: .deathAnniversary,
            dateType: .lunar,
            day: 18,
            month: 8,
            year: nil,
            alertOffsets: [0, -1, -3, -7]
        )
        try await container.scheduleReminderUseCase.execute(save: reminder)

        // 2. Fetch for date 29/09/2026 (19/08 ÂL)
        let solarDate = SolarDate(day: 29, month: 9, year: 2026)
        let details = try await container.getMonthCalendarUseCase.execute(solarDate: solarDate)

        XCTAssertEqual(details.lunarDate.day, 19)
        XCTAssertEqual(details.lunarDate.month, 8)
        XCTAssertEqual(details.canChi.year.description, "Bính Ngọ")
    }

    func testFeatureGateFreeTierLimit() async throws {
        let container = await AppContainer(inMemory: true)

        let initialCanAdd = try await container.evaluateFeatureGateUseCase.canAddReminder()
        XCTAssertTrue(initialCanAdd)

        for i in 1...5 {
            let event = ReminderEvent(title: "Event \(i)", day: i, month: 1)
            try await container.scheduleReminderUseCase.execute(save: event)
        }

        let canAddAfter5 = try await container.evaluateFeatureGateUseCase.canAddReminder()
        XCTAssertFalse(canAddAfter5, "Free tier must be limited to 5 events")
    }

    func testDeterministicDateParser() {
        let r1 = DeterministicDateParser.parse(query: "Rằm tháng 7")
        XCTAssertNotNil(r1)
        XCTAssertEqual(r1?.lunarDate?.day, 15)
        XCTAssertEqual(r1?.lunarDate?.month, 7)

        let r2 = DeterministicDateParser.parse(query: "Mùng 1 Tết")
        XCTAssertNotNil(r2)
        XCTAssertEqual(r2?.lunarDate?.day, 1)
        XCTAssertEqual(r2?.lunarDate?.month, 1)

        let r3 = DeterministicDateParser.parse(query: "18/8 am")
        XCTAssertNotNil(r3)
        XCTAssertEqual(r3?.lunarDate?.day, 18)
        XCTAssertEqual(r3?.lunarDate?.month, 8)

        let r4 = DeterministicDateParser.parse(query: "02/09/2026")
        XCTAssertNotNil(r4)
        XCTAssertEqual(r4?.solarDate?.day, 2)
        XCTAssertEqual(r4?.solarDate?.month, 9)
        XCTAssertEqual(r4?.solarDate?.year, 2026)
    }

    func testDataBackupEngineJSON() throws {
        let events = [
            ReminderEvent(title: "Giỗ Ông", day: 10, month: 3),
            ReminderEvent(title: "Sinh nhật Mẹ", day: 15, month: 5)
        ]

        let data = try DataBackupEngine.exportJSON(reminders: events)
        let restored = try DataBackupEngine.importJSON(from: data)

        XCTAssertEqual(restored.count, 2)
        XCTAssertEqual(restored.first?.title, "Giỗ Ông")
    }

    func testDataBackupEngineICS() async {
        let events = [
            ReminderEvent(title: "Giỗ Cụ Cố", day: 18, month: 8)
        ]

        let ics = await DataBackupEngine.generateICS(reminders: events, years: [2026])
        XCTAssertTrue(ics.contains("BEGIN:VCALENDAR"))
        XCTAssertTrue(ics.contains("SUMMARY:Giỗ Cụ Cố"))
        XCTAssertTrue(ics.contains("END:VCALENDAR"))
    }
}
