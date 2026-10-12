import XCTest
@testable import VNCalendarKit
import VNCalendarDomain
import VNCalendarLunar
import VNCalendarDesignSystem

final class CalendarKitTests: XCTestCase {
    func testDateKeyConversions() {
        let key = DateKey(year: 2026, month: 9, day: 29)
        XCTAssertEqual(key.rawValue, 20260929)
        XCTAssertEqual(key.year, 2026)
        XCTAssertEqual(key.month, 9)
        XCTAssertEqual(key.day, 29)

        let solar = key.toSolarDate
        XCTAssertEqual(solar.year, 2026)
        XCTAssertEqual(solar.month, 9)
        XCTAssertEqual(solar.day, 29)
    }

    func testMonthCachePrecomputation() {
        let cache = VNMonthLunarCache.shared
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")!
        var comp = DateComponents()
        comp.year = 2026
        comp.month = 9
        comp.day = 1
        let sept1 = cal.date(from: comp)!

        cache.precomputeMonthWindow(around: sept1)

        let sept29Key = DateKey(year: 2026, month: 9, day: 29)
        let dayModel = cache.dayModel(for: sept29Key)
        XCTAssertNotNil(dayModel)
        XCTAssertEqual(dayModel?.solarDay, 29)
        XCTAssertEqual(dayModel?.lunarDay, 19)
    }

    @MainActor
    func testAdapterViewModelInitialization() {
        let viewModel = VNCalendarAdapterViewModel()
        XCTAssertNotNil(viewModel.selectedDate)
        XCTAssertNotNil(viewModel.selectedDateKey)
        XCTAssertEqual(viewModel.displayMode, .month)
    }

    @MainActor
    func testDisplayModeSwitching() {
        let viewModel = VNCalendarAdapterViewModel(initialMode: .month)
        XCTAssertEqual(viewModel.displayMode, .month)

        viewModel.setDisplayMode(.block)
        XCTAssertEqual(viewModel.displayMode, .block)

        viewModel.setDisplayMode(.week)
        XCTAssertEqual(viewModel.displayMode, .week)

        viewModel.setDisplayMode(.year)
        XCTAssertEqual(viewModel.displayMode, .year)
    }

    @MainActor
    func testDayNavigation() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")!
        var comp = DateComponents()
        comp.year = 2026
        comp.month = 10
        comp.day = 15
        let oct15 = cal.date(from: comp)!

        let viewModel = VNCalendarAdapterViewModel(initialDate: oct15, initialMode: .block)
        XCTAssertEqual(viewModel.selectedDateKey.day, 15)

        viewModel.nextDay()
        XCTAssertEqual(viewModel.selectedDateKey.day, 16)

        viewModel.previousDay()
        XCTAssertEqual(viewModel.selectedDateKey.day, 15)

        viewModel.next()
        XCTAssertEqual(viewModel.selectedDateKey.day, 16)

        viewModel.previous()
        XCTAssertEqual(viewModel.selectedDateKey.day, 15)
    }

    @MainActor
    func testWeekNavigationAndWeekDates() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")!
        var comp = DateComponents()
        comp.year = 2026
        comp.month = 10
        comp.day = 15 // Thứ Năm
        let oct15 = cal.date(from: comp)!

        let viewModel = VNCalendarAdapterViewModel(initialDate: oct15, initialMode: .week)
        let weekDays = viewModel.currentWeekDates()

        XCTAssertEqual(weekDays.count, 7)
        XCTAssertEqual(weekDays.first?.weekdayName, "Thứ Hai")
        XCTAssertEqual(weekDays.last?.weekdayName, "Chủ Nhật")

        viewModel.nextWeek()
        let nextWeekDays = viewModel.currentWeekDates()
        XCTAssertEqual(nextWeekDays.count, 7)
        XCTAssertEqual(nextWeekDays[3].dateKey.day, 22) // Thứ Năm tuần sau
    }

    @MainActor
    func testYearMonthsData() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")!
        var comp = DateComponents()
        comp.year = 2026
        comp.month = 1
        comp.day = 1
        let jan1 = cal.date(from: comp)!

        let viewModel = VNCalendarAdapterViewModel(initialDate: jan1, initialMode: .year)
        let yearMonths = viewModel.yearMonthsData()

        XCTAssertEqual(yearMonths.count, 12)
        XCTAssertEqual(yearMonths.first?.month, 1)
        XCTAssertEqual(yearMonths.last?.month, 12)

        for monthModel in yearMonths {
            XCTAssertEqual(monthModel.days.count, 42)
        }

        viewModel.selectMonth(8)
        XCTAssertEqual(viewModel.displayMode, .month)
    }

    @MainActor
    func testRichDayModelAstrologyAndFolkQuotes() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")!
        var comp = DateComponents()
        comp.year = 2026
        comp.month = 10
        comp.day = 3
        let targetDate = cal.date(from: comp)!

        let viewModel = VNCalendarAdapterViewModel(initialDate: targetDate)
        guard let model = viewModel.selectedDayModel else {
            XCTFail("Selected day model must not be nil")
            return
        }

        // Verify Can Chi
        XCTAssertFalse(model.lunarYearCanChi.isEmpty)
        XCTAssertFalse(model.lunarDayCanChi.isEmpty)
        XCTAssertFalse(model.lunarMonthCanChi.isEmpty)

        // Verify Giờ Hoàng Đạo
        XCTAssertEqual(model.auspiciousHours.count, 6)

        // Verify Hướng Hỷ Thần / Tài Thần
        XCTAssertFalse(model.joyGodDirection.isEmpty)
        XCTAssertFalse(model.wealthGodDirection.isEmpty)

        // Verify Trực & Việc nên / kiêng
        XCTAssertFalse(model.lunarOfficer.title.isEmpty)
        XCTAssertFalse(model.suitableActivities.isEmpty)
        XCTAssertFalse(model.tabooActivities.isEmpty)

        // Verify Folk Quote
        XCTAssertFalse(model.folkQuote.quote.isEmpty)
        XCTAssertFalse(model.folkQuote.authorOrOrigin.isEmpty)
    }

    func test42CellMatrixGeneration() {
        let cache = VNMonthLunarCache()
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")!
        var comp = DateComponents()
        comp.year = 2026
        comp.month = 10
        comp.day = 1
        let oct1 = cal.date(from: comp)!

        cache.computeMonth42Cells(for: oct1)

        // Verify key dates exist in cache
        let oct1Key = DateKey(year: 2026, month: 10, day: 1)
        let model = cache.dayModel(for: oct1Key)
        XCTAssertNotNil(model)
        XCTAssertEqual(model?.solarDay, 1)
        XCTAssertEqual(model?.solarMonth, 10)
    }
}
