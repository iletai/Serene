import SwiftUI
import Observation
import VNCalendarDomain
import VNCalendarLunar

@Observable
@MainActor
final class OmniSearchViewModel {
    var searchText: String = ""
    var searchResults: [SearchResultItem] = []
    var parsedDate: ParsedDateResult?
    var resolvedConvertedDateText: String?

    private let naturalSearchUseCase: NaturalSearchUseCase
    private var searchTask: Task<Void, Never>?

    init(naturalSearchUseCase: NaturalSearchUseCase) {
        self.naturalSearchUseCase = naturalSearchUseCase
    }

    func performSearch(query: String) {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            searchResults = []
            parsedDate = nil
            resolvedConvertedDateText = nil
            return
        }

        let parsed = DeterministicDateParser.parse(query: trimmed)
        self.parsedDate = parsed

        searchTask = Task {
            if let p = parsed {
                let engine = LunarAstronomicalEngine.shared
                if let lunar = p.lunarDate {
                    let solar = await engine.convertToSolar(from: lunar)
                    let canChi = await engine.computeCanChi(for: solar)
                    resolvedConvertedDateText = "Tương ứng Dương lịch: \(solar.day)/\(solar.month)/\(solar.year) " +
                        "(Năm \(canChi.year.description))"
                } else if let solar = p.solarDate {
                    let lunar = await engine.convertToLunar(from: solar)
                    let canChi = await engine.computeCanChi(for: solar)
                    resolvedConvertedDateText = "Tương ứng Âm lịch: \(lunar.day)/\(lunar.month)/\(lunar.year) ÂL " +
                        "(Năm \(canChi.year.description))"
                }
            } else {
                resolvedConvertedDateText = nil
            }

            if let results = try? await naturalSearchUseCase.execute(query: trimmed) {
                if !Task.isCancelled {
                    self.searchResults = results
                }
            }
        }
    }
}
