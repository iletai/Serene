import SwiftUI
import Observation
import VNCalendarDomain
import VNCalendarLunar
import VNCalendarDesignSystem

public typealias VNCalendarDisplayMode = VNCalendarMode

@Observable
@MainActor
public final class VNCalendarAdapterViewModel {
    public var displayMode: VNCalendarDisplayMode = .month
    public var displayMonthDate: Date {
        didSet { schedulePrefetch() }
    }
    public var selectedDate: Date
    public var selectedDateKey: DateKey
    public var selectedDayModel: VNCalendarDayModel?
    public var isDetailSheetPresented = false

    private var prefetchTask: Task<Void, Never>?
    // nonisolated(unsafe): needed so deinit can remove the observer; @Observation rejects plain nonisolated.
    nonisolated(unsafe) private var folkQuoteObserver: NSObjectProtocol?
    private let cache = VNMonthLunarCache.shared
    private var allReminders: [ReminderEvent] = []
    private var calendar: Calendar

    public init(
        initialDate: Date = Date(),
        reminders: [ReminderEvent] = [],
        initialMode: VNCalendarDisplayMode = .month
    ) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? TimeZone(secondsFromGMT: 7 * 3600) ?? .current
        self.calendar = cal
        self.displayMode = initialMode
        self.displayMonthDate = initialDate
        self.selectedDate = initialDate
        self.selectedDateKey = DateKey(date: initialDate, calendar: cal)
        self.allReminders = reminders
        cache.precomputeMonthWindow(around: initialDate, reminders: reminders)
        self.selectedDayModel = cache.dayModel(for: selectedDateKey)
        folkQuoteObserver = NotificationCenter.default.addObserver(
            forName: .annienFolkQuotesDidChange, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshAfterFolkQuoteChange()
            }
        }
    }

    deinit {
        if let folkQuoteObserver {
            NotificationCenter.default.removeObserver(folkQuoteObserver)
        }
    }

    public func updateReminders(_ reminders: [ReminderEvent]) {
        self.allReminders = reminders
        cache.precomputeMonthWindow(around: displayMonthDate, reminders: reminders)
        self.selectedDayModel = cache.dayModel(for: selectedDateKey)
    }

    public func dayModel(for key: DateKey) -> VNCalendarDayModel? {
        cache.dayModel(for: key)
    }

    public func setDisplayMode(_ mode: VNCalendarDisplayMode) {
        self.displayMode = mode
    }

    public func selectDateKey(_ key: DateKey, date: Date) {
        self.selectedDate = date
        self.selectedDateKey = key
        self.displayMonthDate = date
        self.selectedDayModel = cache.dayModel(for: key)
        self.isDetailSheetPresented = true
    }

    public func selectDate(_ date: Date) {
        let key = DateKey(date: date, calendar: calendar)
        self.selectedDate = date
        self.selectedDateKey = key
        self.displayMonthDate = date
        if let model = cache.dayModel(for: key) {
            self.selectedDayModel = model
        } else {
            cache.computeMonth42Cells(for: date, reminders: allReminders)
            self.selectedDayModel = cache.dayModel(for: key)
        }
    }

    public func selectToday() {
        let today = Date()
        self.displayMonthDate = today
        self.selectedDate = today
        self.selectedDateKey = DateKey(date: today, calendar: calendar)
        if let model = cache.dayModel(for: selectedDateKey) {
            self.selectedDayModel = model
        } else {
            cache.computeMonth42Cells(for: today, reminders: allReminders)
            self.selectedDayModel = cache.dayModel(for: selectedDateKey)
        }
    }

    public func selectMonth(_ month: Int, year: Int? = nil) {
        var comp = calendar.dateComponents([.year, .month, .day], from: displayMonthDate)
        comp.month = month
        if let year {
            comp.year = year
        }
        comp.day = 1
        if let newDate = calendar.date(from: comp) {
            self.displayMonthDate = newDate
            self.displayMode = .month
        }
    }

    // MARK: - Navigation Methods

    public func previous() {
        switch displayMode {
        case .block:
            previousDay()
        case .month:
            previousMonth()
        case .week:
            previousWeek()
        case .year:
            previousYear()
        }
    }

    public func next() {
        switch displayMode {
        case .block:
            nextDay()
        case .month:
            nextMonth()
        case .week:
            nextWeek()
        case .year:
            nextYear()
        }
    }

    public func previousDay() {
        if let prev = calendar.date(byAdding: .day, value: -1, to: selectedDate) {
            selectDate(prev)
        }
    }

    public func nextDay() {
        if let next = calendar.date(byAdding: .day, value: 1, to: selectedDate) {
            selectDate(next)
        }
    }

    public func previousWeek() {
        if let prev = calendar.date(byAdding: .day, value: -7, to: selectedDate) {
            selectDate(prev)
        }
    }

    public func nextWeek() {
        if let next = calendar.date(byAdding: .day, value: 7, to: selectedDate) {
            selectDate(next)
        }
    }

    public func previousMonth() {
        if let prev = calendar.date(byAdding: .month, value: -1, to: displayMonthDate) {
            displayMonthDate = prev
            if displayMode == .block {
                selectDate(prev)
            }
        }
    }

    public func nextMonth() {
        if let next = calendar.date(byAdding: .month, value: 1, to: displayMonthDate) {
            displayMonthDate = next
            if displayMode == .block {
                selectDate(next)
            }
        }
    }

    public func previousYear() {
        if let prev = calendar.date(byAdding: .year, value: -1, to: displayMonthDate) {
            displayMonthDate = prev
        }
    }

    public func nextYear() {
        if let next = calendar.date(byAdding: .year, value: 1, to: displayMonthDate) {
            displayMonthDate = next
        }
    }

    // MARK: - Data Providers

    public func currentWeekDates() -> [VNCalendarDayModel] {
        cache.computeWeekDays(around: selectedDate, reminders: allReminders)
    }

    public func yearMonthsData() -> [VNYearMonthModel] {
        let year = calendar.component(.year, from: displayMonthDate)
        return cache.computeYearMonths(for: year, reminders: allReminders)
    }

    // MARK: - Private Helpers

    private func schedulePrefetch() {
        prefetchTask?.cancel()
        let targetDate = self.displayMonthDate
        let items = self.allReminders

        prefetchTask = Task(priority: .userInitiated) { [weak self] in
            guard let self, !Task.isCancelled else { return }
            self.cache.precomputeMonthWindow(around: targetDate, reminders: items)
            if !Task.isCancelled {
                self.selectedDayModel = self.cache.dayModel(for: self.selectedDateKey)
            }
        }
    }

    private func refreshAfterFolkQuoteChange() {
        cache.precomputeMonthWindow(around: displayMonthDate, reminders: allReminders)
        selectedDayModel = cache.dayModel(for: selectedDateKey)
    }
}
