import Foundation
import VNCalendarLunar
import VNCalendarDomain

public struct ParsedDateResult: Sendable {
    public let originalQuery: String
    public let solarDate: SolarDate?
    public let lunarDate: LunarDate?
    public let label: String
}

public enum DeterministicDateParser {
    public static func parse(query: String, referenceYear: Int = 2026) -> ParsedDateResult? {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // 1. Keyword shortcuts: "mùng 1 tết", "rằm tháng giêng", "rằm tháng 7", "rằm tháng 8", "tết đoan ngọ"
        if q.contains("mùng 1 tết") || q.contains("mung 1 tet") || q == "tết" || q == "tet" {
            let lunar = LunarDate(day: 1, month: 1, year: referenceYear)
            return ParsedDateResult(originalQuery: query, solarDate: nil, lunarDate: lunar, label: "Mùng 1 Tết Nguyên Đán")
        }

        if q.contains("rằm tháng giêng") || q.contains("ram thang gieng") || q == "15/1 am" {
            let lunar = LunarDate(day: 15, month: 1, year: referenceYear)
            return ParsedDateResult(originalQuery: query, solarDate: nil, lunarDate: lunar, label: "Rằm Tháng Giêng (Tết Nguyên Tiêu)")
        }

        if q.contains("rằm tháng 7") || q.contains("ram thang 7") || q.contains("vu lan") {
            let lunar = LunarDate(day: 15, month: 7, year: referenceYear)
            return ParsedDateResult(originalQuery: query, solarDate: nil, lunarDate: lunar, label: "Rằm Tháng 7 (Lễ Vu Lan Báo Hiếu)")
        }

        if q.contains("trung thu") || q.contains("rằm tháng 8") || q.contains("ram thang 8") {
            let lunar = LunarDate(day: 15, month: 8, year: referenceYear)
            return ParsedDateResult(originalQuery: query, solarDate: nil, lunarDate: lunar, label: "Rằm Tháng 8 (Tết Trung Thu)")
        }

        if q.contains("ông táo") || q.contains("ong tao") || q.contains("23 tháng chạp") {
            let lunar = LunarDate(day: 23, month: 12, year: referenceYear)
            return ParsedDateResult(originalQuery: query, solarDate: nil, lunarDate: lunar, label: "23 Tháng Chạp (Tết Ông Công Ông Táo)")
        }

        // 2. Regex: "DD/MM am" or "DD/MM al" (Lunar)
        let lunarRegex = try? NSRegularExpression(pattern: #"^(\d{1,2})[/.-](\d{1,2})\s*(am|al|âm)$"#, options: .caseInsensitive)
        if let match = lunarRegex?.firstMatch(in: q, options: [], range: NSRange(location: 0, length: q.utf16.count)) {
            if let dayRange = Range(match.range(at: 1), in: q),
               let monthRange = Range(match.range(at: 2), in: q),
               let d = Int(q[dayRange]), let m = Int(q[monthRange]),
               (1...31).contains(d), (1...12).contains(m) {
                let lunar = LunarDate(day: d, month: m, year: referenceYear)
                return ParsedDateResult(originalQuery: query, solarDate: nil, lunarDate: lunar, label: "Ngày \(d) Tháng \(m) Âm Lịch")
            }
        }

        // 3. Regex: "DD/MM" or "DD/MM/YYYY" (Solar)
        let solarRegex = try? NSRegularExpression(pattern: #"^(\d{1,2})[/.-](\d{1,2})(?:[/.-](\d{4}))?$"#, options: .caseInsensitive)
        if let match = solarRegex?.firstMatch(in: q, options: [], range: NSRange(location: 0, length: q.utf16.count)) {
            if let dayRange = Range(match.range(at: 1), in: q),
               let monthRange = Range(match.range(at: 2), in: q),
               let d = Int(q[dayRange]), let m = Int(q[monthRange]),
               (1...31).contains(d), (1...12).contains(m) {
                var y = referenceYear
                if match.numberOfRanges > 3, match.range(at: 3).location != NSNotFound,
                   let yearRange = Range(match.range(at: 3), in: q),
                   let customY = Int(q[yearRange]) {
                    y = customY
                }
                let solar = SolarDate(day: d, month: m, year: y)
                let label = "Ngày \(d) Tháng \(m) Năm \(y) Dương Lịch"
                return ParsedDateResult(originalQuery: query, solarDate: solar, lunarDate: nil, label: label)
            }
        }

        return nil
    }
}
