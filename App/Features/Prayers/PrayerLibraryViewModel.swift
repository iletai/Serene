import SwiftUI
import Observation
import VNCalendarDomain

@Observable
@MainActor
final class PrayerLibraryViewModel {
    var prayers: [Prayer] = []
    var searchQuery: String = ""
    var selectedCategory: PrayerCategory?
    var selectedPrayer: Prayer?

    private let prayerRepository: PrayerRepositoryProtocol

    init(prayerRepository: PrayerRepositoryProtocol) {
        self.prayerRepository = prayerRepository
    }

    var filteredPrayers: [Prayer] {
        var list = prayers
        if let cat = selectedCategory {
            list = list.filter { $0.category == cat }
        }
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            list = list.filter { prayer in
                prayer.title.localizedCaseInsensitiveContains(query) ||
                prayer.occasion.localizedCaseInsensitiveContains(query) ||
                prayer.tags.contains(where: { $0.localizedCaseInsensitiveContains(query) })
            }
        }
        return list
    }

    func load() async {
        if let items = try? await prayerRepository.fetchAllPrayers() {
            self.prayers = items
        }
    }
}
