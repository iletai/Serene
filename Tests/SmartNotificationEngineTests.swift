import XCTest
@testable import AnNien
import VNCalendarDomain
import VNCalendarLunar

final class SmartNotificationEngineTests: XCTestCase {
    private func makeCalendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? TimeZone(secondsFromGMT: 7 * 3600) ?? .current
        return cal
    }

    private func makeEngine() -> SmartNotificationEngine {
        SmartNotificationEngine()
    }

    // 1. Quota limit test: 80 events must not exceed usableSlotLimit (60)
    func testQuotaLimit64Slots() async throws {
        let engine = makeEngine()
        let calendar = makeCalendar()
        var baseComponents = DateComponents()
        baseComponents.year = 2026
        baseComponents.month = 5
        baseComponents.day = 1
        baseComponents.hour = 8
        baseComponents.minute = 0
        guard let now = calendar.date(from: baseComponents) else {
            XCTFail("Failed to create base date")
            return
        }

        var reminders: [ReminderEvent] = []
        for i in 1...80 {
            let day = (i % 28) + 1
            let month = ((i / 28) % 12) + 1
            let reminder = ReminderEvent(
                id: UUID(),
                title: "Nhắc nhở sự kiện \(i)",
                category: .deathAnniversary,
                dateType: .solar,
                day: day,
                month: month,
                alertOffsets: [0, -1, -3]
            )
            reminders.append(reminder)
        }

        let candidates = await engine.generateCandidates(for: reminders, now: now, calendar: calendar)

        XCTAssertLessThanOrEqual(
            candidates.count,
            SmartNotificationEngine.usableSlotLimit,
            "Candidates count must not exceed usableSlotLimit (\(SmartNotificationEngine.usableSlotLimit))"
        )
        XCTAssertEqual(
            candidates.count,
            SmartNotificationEngine.usableSlotLimit,
            "With 80 events and multiple offsets, candidates should fill all \(SmartNotificationEngine.usableSlotLimit) slots"
        )
    }

    // 2. Hyperbolic time-decay score test: nearer event has higher score than farther event
    func testHyperbolicTimeDecayScore() async throws {
        let engine = makeEngine()
        let calendar = makeCalendar()
        var baseComponents = DateComponents()
        baseComponents.year = 2026
        baseComponents.month = 5
        baseComponents.day = 1
        baseComponents.hour = 8
        baseComponents.minute = 0
        guard let now = calendar.date(from: baseComponents) else {
            XCTFail("Failed to create base date")
            return
        }

        // Event near: 2 days later (May 3, 2026)
        let nearEvent = ReminderEvent(
            title: "Sự kiện gần",
            category: .deathAnniversary,
            dateType: .solar,
            day: 3,
            month: 5,
            alertOffsets: [0]
        )

        // Event far: 40 days later (June 10, 2026)
        let farEvent = ReminderEvent(
            title: "Sự kiện xa",
            category: .deathAnniversary,
            dateType: .solar,
            day: 10,
            month: 6,
            alertOffsets: [0]
        )

        let candidates = await engine.generateCandidates(for: [nearEvent, farEvent], now: now, calendar: calendar)

        guard let nearCandidate = candidates.first(where: { $0.eventId == nearEvent.id }),
              let farCandidate = candidates.first(where: { $0.eventId == farEvent.id }) else {
            XCTFail("Could not find both near and far event candidates")
            return
        }

        XCTAssertEqual(nearCandidate.priority, farCandidate.priority, "Both events should have same priority")
        XCTAssertGreaterThan(
            nearCandidate.score,
            farCandidate.score,
            "Closer event must have a higher decay score than farther event"
        )
    }

    // 3. Lunar Month 30 clamping test: Day 30 in a 29-day month clamps to 29 and subtitle has info
    func testLunarMonth30ClampingTo29() async throws {
        let engine = makeEngine()
        let calendar = makeCalendar()
        // Find a lunar month with 29 days in 2026
        let lunarEngine = LunarAstronomicalEngine.shared
        var targetMonth = 12
        for month in 1...12 {
            let reqLunar = LunarDate(day: 30, month: month, year: 2026, isLeapMonth: false)
            let solar = lunarEngine.convertToSolar(from: reqLunar)
            let verifiedLunar = lunarEngine.convertToLunar(from: solar)
            if verifiedLunar.day == 29 {
                targetMonth = month
                break
            }
        }

        let memorial = MemorialEvent(
            title: "Giỗ Kỵ Ngày 30",
            body: "Cúng giỗ họ",
            isLunar: true,
            day: 30,
            month: targetMonth,
            isLeapMonth: false,
            priority: .critical,
            advanceOffsets: [0]
        )

        let occurrences = await engine.resolveTriggerDates(event: memorial, targetYear: 2026, calendar: calendar)
        XCTAssertFalse(occurrences.isEmpty, "Occurrences should not be empty")

        guard let occ = occurrences.first else { return }
        XCTAssertTrue(occ.isClamped, "Day 30 in a 29-day lunar month must be marked as clamped")
        XCTAssertEqual(occ.lunarDate.day, 29, "Clamped lunar day must be 29")

        // Now test via reminder event & candidate generation
        let reminder = ReminderEvent(
            title: "Giỗ Kỵ Ngày 30",
            category: .deathAnniversary,
            dateType: .lunar,
            day: 30,
            month: targetMonth,
            alertOffsets: [0],
            note: "Cúng giỗ họ"
        )

        // Set `now` to before the event
        guard let now = calendar.date(byAdding: .day, value: -10, to: occ.date) else {
            XCTFail("Failed to compute now date")
            return
        }

        let candidates = await engine.generateCandidates(for: [reminder], now: now, calendar: calendar)
        guard let candidate = candidates.first(where: { $0.eventId == reminder.id }) else {
            XCTFail("Candidate not found for clamped reminder")
            return
        }

        XCTAssertTrue(
            candidate.body.contains("Tháng thiếu 29 ngày"),
            "Subtitle body must contain 'Tháng thiếu 29 ngày' when clamped. Got: \(candidate.body)"
        )
        XCTAssertTrue(
            candidate.body.contains("Ngày 29/\(targetMonth) ÂL"),
            "Subtitle body must contain 'Ngày 29/\(targetMonth) ÂL'. Got: \(candidate.body)"
        )
    }

    // 4. Advance offsets candidate generation test: [0, -1, -3, -7]
    func testAdvanceOffsetsCandidateGeneration() async throws {
        let engine = makeEngine()
        let calendar = makeCalendar()
        var eventComponents = DateComponents()
        eventComponents.year = 2026
        eventComponents.month = 10
        eventComponents.day = 15
        eventComponents.hour = 8
        eventComponents.minute = 0
        guard let targetDate = calendar.date(from: eventComponents) else {
            XCTFail("Failed to create target date")
            return
        }

        // Set now to 20 days prior
        guard let now = calendar.date(byAdding: .day, value: -20, to: targetDate) else {
            XCTFail("Failed to compute now date")
            return
        }

        let offsets = [0, -1, -3, -7]
        let reminder = ReminderEvent(
            title: "Kỷ Niệm Ngày Cưới",
            category: .wedding,
            dateType: .solar,
            day: 15,
            month: 10,
            alertOffsets: offsets,
            note: "Chuẩn bị hoa và quà"
        )

        let candidates = await engine.generateCandidates(for: [reminder], now: now, calendar: calendar)

        let year2026Candidates = candidates.filter {
            $0.eventId == reminder.id && $0.identifier.contains("_2026_")
        }
        XCTAssertEqual(year2026Candidates.count, offsets.count, "Must generate candidates for all 4 offsets in year 2026")

        for offset in offsets {
            guard let expectedFireDate = calendar.date(byAdding: .day, value: offset, to: targetDate) else {
                XCTFail("Failed to calculate expected fire date for offset \(offset)")
                continue
            }

            guard let matched = year2026Candidates.first(where: { candidate in
                candidate.userInfo["offset"] == "\(offset)"
            }) else {
                XCTFail("Candidate for offset \(offset) was not found")
                continue
            }

            XCTAssertEqual(
                calendar.dateComponents([.year, .month, .day, .hour, .minute], from: matched.triggerDate),
                calendar.dateComponents([.year, .month, .day, .hour, .minute], from: expectedFireDate),
                "Fire date for offset \(offset) must match calculated trigger date"
            )
        }
    }
}
