import Foundation
import VNCalendarDomain
import VNCalendarLunar

public struct BackupPayload: Codable, Sendable {
    public let appVersion: String
    public let exportedAt: Date
    public let reminders: [ReminderEvent]

    public init(reminders: [ReminderEvent]) {
        self.appVersion = "1.0.0"
        self.exportedAt = Date()
        self.reminders = reminders
    }
}

public enum DataBackupEngine {
    // MARK: - JSON Export & Import
    public static func exportJSON(reminders: [ReminderEvent]) throws -> Data {
        let payload = BackupPayload(reminders: reminders)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(payload)
    }

    public static func importJSON(from data: Data) throws -> [ReminderEvent] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(BackupPayload.self, from: data)
        return payload.reminders
    }

    // MARK: - RFC 5545 iCalendar (ICS) Generation
    /// Escapes TEXT values per RFC 5545: backslash, semicolon, comma, newline.
    static func escapeICS(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: "\r\n", with: "\\n")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\n")
    }

    public static func generateICS(
        reminders: [ReminderEvent],
        years: [Int]? = nil
    ) async -> String {
        let engine = LunarAstronomicalEngine.shared
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = VNTime.vietnam

        let currentYear = cal.component(.year, from: Date())
        let exportYears = years ?? [currentYear, currentYear + 1, currentYear + 2]

        var ics = "BEGIN:VCALENDAR\r\n"
        ics += "VERSION:2.0\r\n"
        ics += "PRODID:-//AnNien//LichViet Giatoc//VI\r\n"
        ics += "CALSCALE:GREGORIAN\r\n"
        ics += "METHOD:PUBLISH\r\n"
        ics += "X-WR-CALNAME:An Niên - Ngày Nhớ Gia Đình\r\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss"
        dateFormatter.timeZone = cal.timeZone

        let utcFormatter = DateFormatter()
        utcFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        utcFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        let dtstamp = utcFormatter.string(from: Date())

        for reminder in reminders {
            for year in exportYears {
                let solarDate: SolarDate
                if reminder.dateType == .lunar {
                    let reqLunar = LunarDate(day: reminder.day, month: reminder.month, year: year, isLeapMonth: reminder.isLeapMonth)
                    solarDate = await engine.convertToSolar(from: reqLunar)
                } else {
                    solarDate = SolarDate(day: reminder.day, month: reminder.month, year: year)
                }

                var comp = DateComponents()
                comp.year = solarDate.year
                comp.month = solarDate.month
                comp.day = solarDate.day
                comp.hour = reminder.hour
                comp.minute = reminder.minute
                comp.second = 0

                guard let start = cal.date(from: comp),
                      let end = cal.date(byAdding: .hour, value: 2, to: start) else {
                    continue
                }

                let startStr = dateFormatter.string(from: start)
                let endStr = dateFormatter.string(from: end)
                let uid = "\(reminder.id.uuidString)_\(year)@annien.app"

                ics += "BEGIN:VEVENT\r\n"
                ics += "UID:\(uid)\r\n"
                ics += "DTSTAMP:\(dtstamp)\r\n"
                ics += "DTSTART:\(startStr)\r\n"
                ics += "DTEND:\(endStr)\r\n"
                ics += "SUMMARY:\(Self.escapeICS(reminder.title))\r\n"
                let dateTypeStr = reminder.dateType == .lunar ? "Âm lịch" : "Dương lịch"
                let desc = "Kỳ giỗ: \(reminder.day)/\(reminder.month) \(dateTypeStr). \(reminder.note ?? "")"
                ics += "DESCRIPTION:\(Self.escapeICS(desc))\r\n"
                ics += "STATUS:CONFIRMED\r\n"
                ics += "END:VEVENT\r\n"
            }
        }

        ics += "END:VCALENDAR\r\n"
        return ics
    }
}
