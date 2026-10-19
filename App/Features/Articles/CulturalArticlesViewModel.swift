import SwiftUI
import Observation
import VNCalendarDomain

@Observable
@MainActor
final class CulturalArticlesViewModel {
    var holidays: [Holiday] = []
    var selectedHoliday: Holiday?
    var searchQuery = ""
    var selectedCategory: String = "Tất cả"

    private let holidayRepository: HolidayRepositoryProtocol

    init(holidayRepository: HolidayRepositoryProtocol) {
        self.holidayRepository = holidayRepository
    }

    var filteredHolidays: [Holiday] {
        holidays.filter { holiday in
            let matchesSearch = searchQuery.isEmpty ||
                holiday.title.localizedCaseInsensitiveContains(searchQuery) ||
                holiday.summary.localizedCaseInsensitiveContains(searchQuery)

            let matchesCategory: Bool
            switch selectedCategory {
            case "Cúng Giỗ":
                matchesCategory = holiday.title.localizedCaseInsensitiveContains("Giỗ") ||
                    holiday.summary.localizedCaseInsensitiveContains("Giỗ") ||
                    (holiday.rituals?.localizedCaseInsensitiveContains("Giỗ") == true)
            case "Lễ Tiết & Tết":
                matchesCategory = holiday.title.localizedCaseInsensitiveContains("Tết") ||
                    holiday.title.localizedCaseInsensitiveContains("Tiết")
            case "Rằm & Mùng 1":
                matchesCategory = holiday.title.localizedCaseInsensitiveContains("Rằm") ||
                    holiday.title.localizedCaseInsensitiveContains("Mùng 1") ||
                    holiday.day == 1 || holiday.day == 15
            default:
                matchesCategory = true
            }

            return matchesSearch && matchesCategory
        }
    }

    func load() async {
        if let items = try? await holidayRepository.getHolidays() {
            self.holidays = items
        }
    }

    func resetFilters() {
        selectedCategory = "Tất cả"
        searchQuery = ""
    }
}
