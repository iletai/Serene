import XCTest
@testable import VNCalendarLunar

final class LunarEngineTests: XCTestCase {
    var engine: LunarAstronomicalEngine!

    override func setUp() async throws {
        engine = LunarAstronomicalEngine()
    }

    func testJulianDayRoundtrip() {
        let dates = [
            SolarDate(day: 1, month: 1, year: 2000),
            SolarDate(day: 29, month: 9, year: 2026),
            SolarDate(day: 28, month: 2, year: 2024),
            SolarDate(day: 29, month: 2, year: 2024),
            SolarDate(day: 15, month: 8, year: 1985)
        ]

        for date in dates {
            let jd = AstronomicalMath.julianDay(from: date)
            let roundtrip = AstronomicalMath.solarDate(from: jd)
            XCTAssertEqual(date.day, roundtrip.day, "Day mismatch for \(date)")
            XCTAssertEqual(date.month, roundtrip.month, "Month mismatch for \(date)")
            XCTAssertEqual(date.year, roundtrip.year, "Year mismatch for \(date)")
        }
    }

    func testTetAtSuu1985() async {
        // Mùng 1 Tết Ất Sửu 1985 tại Việt Nam rơi vào 21/01/1985
        let solarJan21 = SolarDate(day: 21, month: 1, year: 1985)
        let lunar = await engine.convertToLunar(from: solarJan21)
        XCTAssertEqual(lunar.day, 1)
        XCTAssertEqual(lunar.month, 1)
        XCTAssertEqual(lunar.year, 1985)
    }

    func testLeapMonth2023() async {
        // Năm Quý Mão 2023 có Tháng 2 Nhuận
        // 22/03/2023 Dương lịch là 02/02 Nhuận Âm lịch
        let solarLeap = SolarDate(day: 22, month: 3, year: 2023)
        let lunar = await engine.convertToLunar(from: solarLeap)
        XCTAssertEqual(lunar.day, 2)
        XCTAssertEqual(lunar.month, 2)
        XCTAssertTrue(lunar.isLeapMonth)
    }

    func testSolarToLunarAndBackRoundtrip() async {
        // Kiểm tra roundtrip cho tháng 9 năm 2026
        for day in 1...28 {
            let solar = SolarDate(day: day, month: 9, year: 2026)
            let lunar = await engine.convertToLunar(from: solar)
            let backToSolar = await engine.convertToSolar(from: lunar)
            XCTAssertEqual(solar.day, backToSolar.day, "Roundtrip failed for day \(day)")
            XCTAssertEqual(solar.month, backToSolar.month)
            XCTAssertEqual(solar.year, backToSolar.year)
        }
    }

    func testCanChiCalculations() async {
        // Ngày 29/09/2026 (Năm Bính Ngọ, Tháng Đinh Dậu, Ngày Bính Ngọ)
        let solar = SolarDate(day: 29, month: 9, year: 2026)
        let canChi = await engine.computeCanChi(for: solar)
        XCTAssertEqual(canChi.year.stem, .binh)
        XCTAssertEqual(canChi.year.branch, .ngo)
    }

    func testSolarTerms() {
        // 24/09/2026 là Thu Phân (Kinh độ Mặt Trời = 180° tại GMT+7)
        let jdThuPhan = AstronomicalMath.julianDay(from: SolarDate(day: 24, month: 9, year: 2026))
        let term = AstronomicalMath.solarTerm(at: jdThuPhan)
        XCTAssertEqual(term, .thuPhan)
        XCTAssertTrue(term.isMajorTerm)

        // 23/09/2026 là Bạch Lộ
        let jdBachLo = AstronomicalMath.julianDay(from: SolarDate(day: 23, month: 9, year: 2026))
        let termBachLo = AstronomicalMath.solarTerm(at: jdBachLo)
        XCTAssertEqual(termBachLo, .bachLo)
    }
}
