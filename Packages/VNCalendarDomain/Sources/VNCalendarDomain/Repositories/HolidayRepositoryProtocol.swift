import Foundation

public protocol HolidayRepositoryProtocol: Sendable {
    func getHolidays() async throws -> [Holiday]
    func getHolidays(month: Int, isLunar: Bool) async throws -> [Holiday]
    func getHoliday(by id: String) async throws -> Holiday?
    func synchronizeRemoteContent() async throws
}
