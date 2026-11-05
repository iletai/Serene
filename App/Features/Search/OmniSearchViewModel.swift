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
    /// Solar date of the parsed query; seeds the reminder form.
    private(set) var resolvedSolarDate: Date?
    /// In-flight guard so repeated taps run one gate check.
    private(set) var isCheckingGate = false

    private let naturalSearchUseCase: NaturalSearchUseCase
    private let evaluateFeatureGateUseCase: EvaluateFeatureGateUseCase
    private var searchTask: Task<Void, Never>?

    init(naturalSearchUseCase: NaturalSearchUseCase, evaluateFeatureGateUseCase: EvaluateFeatureGateUseCase) {
        self.naturalSearchUseCase = naturalSearchUseCase
        self.evaluateFeatureGateUseCase = evaluateFeatureGateUseCase
    }

    func createReminderGate() async -> CreateReminderGate {
        isCheckingGate = true
        defer { isCheckingGate = false }
        do {
            return try await evaluateFeatureGateUseCase.canAddReminder() ? .allowed : .requiresPro
        } catch {
            return .requiresPro
        }
    }

    func performSearch(query: String) {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            searchResults = []
            parsedDate = nil
            resolvedConvertedDateText = nil
            resolvedSolarDate = nil
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
                    resolvedSolarDate = solar.date
                    resolvedConvertedDateText = String(format: String(localized: "search.converted_to_solar"), solar.day, solar.month, solar.year, canChi.year.description)
                } else if let solar = p.solarDate {
                    let lunar = await engine.convertToLunar(from: solar)
                    let canChi = await engine.computeCanChi(for: solar)
                    resolvedSolarDate = solar.date
                    resolvedConvertedDateText = String(format: String(localized: "search.converted_to_lunar"), lunar.day, lunar.month, lunar.year, canChi.year.description)
                }
            } else {
                resolvedConvertedDateText = nil
                resolvedSolarDate = nil
            }

            if let results = try? await naturalSearchUseCase.execute(query: trimmed) {
                if !Task.isCancelled {
                    self.searchResults = results
                }
            }
        }
    }
}
