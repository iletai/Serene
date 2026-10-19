# Plan 2 — MVVM + Clean Architecture Refactor

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Chuyển đổi toàn bộ App layer từ Fat View sang MVVM chuẩn Swift 6 (`@Observable @MainActor final class <Feature>ViewModel`), di chuyển domain business logic từ View về Domain/ViewModel, chuyển DI qua `@Environment(AppContainer.self)`, và đưa `SubscriptionManager` về đúng package `VNCalendarData`.

**Architecture:**
- Domain: thêm `ReminderEvent.nextOccurrence(after:calendar:)`, `countdownText(for:)`, `NotificationScheduling` protocol.
- Data: `SubscriptionManager` chuyển từ `App/Infrastructure/StoreKit/` sang `Packages/VNCalendarData/Sources/VNCalendarData/StoreKit/`.
- App Container: giữ vai trò composition root, inject qua `.environment(container)` tại `AnNienApp`.
- ViewModels: 9 feature ViewModels (`@Observable @MainActor final class <Feature>ViewModel`), thuần state + intents, constructor-injected, không import `SwiftData`, hạn chế tối đa import UI types.
- Views: `@State private var viewModel: <Feature>ViewModel`, thuần layout + binding.

**Tech Stack:** Swift 6 (Strict Concurrency `complete`), SwiftUI, SwiftData, Observation (`@Observable`), OSLog.

**Spec:** `docs/specs/2026-10-19-workflow-and-mvvm-standards-design.md` §3.5, §4, §6 Phase 2–4.

## Global Constraints

- Swift 6 strict concurrency (`SWIFT_STRICT_CONCURRENCY = complete`) — không dùng `#unchecked Sendable` bừa bãi.
- SwiftLint strict: file < 500 lines, function < 60 lines, type < 300 lines, cyclomatic complexity < 10.
- `VNCalendarDomain` **không** import SwiftUI/SwiftData/UIKit.
- `VNCalendarData` **không** import SwiftUI.
- Views **không** gọi `AppContainer.shared` trực tiếp.

## Review Focus

1. **Vòng lặp dependency khi move `SubscriptionManager`** — `SubscriptionManager` có import gì từ `App/` không? → Task 6: kiểm tra imports trước khi move.
2. **SwiftUI Canvas Preview chết sau khi bỏ `.shared`** — View cần preview mock data → Task 8: View init nhận `viewModel` hoặc inject qua `.environment`.
3. **`@Environment(AppContainer.self)` trong Sheet** — Sheet không tự kế thừa environment nếu dùng kiểu cũ. Trong iOS 17 `@Observable` environment tự động truyền vào sheets; verify.
4. **Race condition khi delete rồi load lại** — Task delete chưa hoàn thành đã load lại. → Task 7: UseCase tuần tự hóa.
5. **Memory leak từ deinit closure trong ViewModel** — adapter ViewModel đã dùng `nonisolated(unsafe)` có giải trình. ViewModel mới không retain cycles.

---

### Task 6: Di chuyển `SubscriptionManager` về `VNCalendarData`

**Files:**
- Create: `Packages/VNCalendarData/Sources/VNCalendarData/StoreKit/SubscriptionManager.swift`
- Delete: `App/Infrastructure/StoreKit/SubscriptionManager.swift`
- Modify: `Packages/VNCalendarData/Package.swift` (nếu cần export thêm)
- Modify: `App/AppContainer.swift:22,68`
- Modify: `App/Features/Paywall/PaywallView.swift` (nếu import SubscriptionManager trực tiếp)
- Modify: `Extensions/Widget/LunarTimelineProvider.swift` (nếu có)
- Modify: `App/Infrastructure/Intents/AnNienIntents.swift` (nếu có)

**Interfaces:**
- Consumes: StoreKit 2, `VNCalendarDomain/Repositories/SubscriptionRepositoryProtocol.swift`.
- Produces: `VNCalendarData.SubscriptionManager` conforming `SubscriptionRepositoryProtocol`.

- [ ] **Step 1: Rà soát import của `SubscriptionManager.swift`**

Run: `grep "import" App/Infrastructure/StoreKit/SubscriptionManager.swift`
Đảm bảo file không import `App` hay module UI nào ngoài Foundation/StoreKit/VNCalendarDomain.

- [ ] **Step 2: Di chuyển file sang `VNCalendarData`**

```bash
mkdir -p Packages/VNCalendarData/Sources/VNCalendarData/StoreKit
git mv App/Infrastructure/StoreKit/SubscriptionManager.swift Packages/VNCalendarData/Sources/VNCalendarData/StoreKit/SubscriptionManager.swift
```

- [ ] **Step 3: Cập nhật `AppContainer.swift`**

Kiểm tra `AppContainer.swift:22,68`. File này đã `import VNCalendarData`, kiểu `SubscriptionManager` giờ đến từ package này thay vì App target.

- [ ] **Step 4: Regenerate Xcode project và build**

Run: `xcodegen generate && xcodebuild build -scheme AnNien-Dev -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -configuration Debug-Development | xcbeautify 2>/dev/null || xcodebuild build -scheme AnNien-Dev -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -configuration Debug-Development`
Expected: **BUILD SUCCEEDED**. Nếu file nào báo thiếu `SubscriptionManager`, thêm `import VNCalendarData`.

- [ ] **Step 5: Run tests**

Run: `xcodebuild test -scheme AnNien-Dev -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -configuration Debug-Development -only-testing:AnNienTests/StoreKitSubscriptionTests`
Expected: **TEST SUCCEEDED**.

- [ ] **Step 6: Commit**

```bash
git add Packages/VNCalendarData/Sources/VNCalendarData/StoreKit/SubscriptionManager.swift App/
git commit -m "refactor(data): move SubscriptionManager from App to VNCalendarData"
```

---

### Task 7: Domain — Thêm `ReminderEvent` extensions + `NotificationScheduling` protocol

**Files:**
- Modify: `Packages/VNCalendarDomain/Sources/VNCalendarDomain/Entities/ReminderEvent.swift`
- Create: `Packages/VNCalendarDomain/Sources/VNCalendarDomain/Repositories/NotificationScheduling.swift`
- Modify: `Packages/VNCalendarDomain/Sources/VNCalendarDomain/UseCases/ScheduleReminderUseCase.swift`
- Modify: `App/Infrastructure/Notifications/SmartNotificationEngine.swift` (conform `NotificationScheduling`)
- Modify: `App/AppContainer.swift:75` (truyền notification engine vào use case)
- Test: `Packages/VNCalendarDomain/Tests/VNCalendarDomainTests/ReminderEventOccurrenceTests.swift`

**Interfaces:**
- Consumes: `VNCalendarLunar.LunarAstronomicalEngine`, `SolarDate`, `LunarDate`.
- Produces: `ReminderEvent.nextOccurrence(after:calendar:) -> Date`, `ReminderEvent.countdownText(relativeTo:calendar:) -> String`, `NotificationScheduling.pruneAndSchedule(reminders:) async throws`.

- [ ] **Step 1: Write failing test cho `nextOccurrence` và `countdownText`**

Tạo `Packages/VNCalendarDomain/Tests/VNCalendarDomainTests/ReminderEventOccurrenceTests.swift`:

```swift
import XCTest
import VNCalendarLunar
@testable import VNCalendarDomain

final class ReminderEventOccurrenceTests: XCTestCase {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = VNTime.vietnam
        return cal
    }

    func testNextOccurrence_SolarFutureThisYear() {
        let reminder = ReminderEvent(title: "Test", dateType: .solar, day: 25, month: 12)
        let anchor = calendar.date(from: DateComponents(year: 2026, month: 10, day: 19))!
        let next = reminder.nextOccurrence(after: anchor, calendar: calendar)
        let comps = calendar.dateComponents([.year, .month, .day], from: next)
        XCTAssertEqual(comps.year, 2026)
        XCTAssertEqual(comps.month, 12)
        XCTAssertEqual(comps.day, 25)
    }

    func testNextOccurrence_SolarPastMovesToNextYear() {
        let reminder = ReminderEvent(title: "Past", dateType: .solar, day: 1, month: 1)
        let anchor = calendar.date(from: DateComponents(year: 2026, month: 10, day: 19))!
        let next = reminder.nextOccurrence(after: anchor, calendar: calendar)
        let comps = calendar.dateComponents([.year, .month, .day], from: next)
        XCTAssertEqual(comps.year, 2027)
        XCTAssertEqual(comps.month, 1)
        XCTAssertEqual(comps.day, 1)
    }

    func testCountdownText_Today() {
        let reminder = ReminderEvent(title: "Today", dateType: .solar, day: 19, month: 10)
        let anchor = calendar.date(from: DateComponents(year: 2026, month: 10, day: 19, hour: 10))!
        XCTAssertEqual(reminder.countdownText(relativeTo: anchor, calendar: calendar), "Hôm nay")
    }

    func testCountdownText_Tomorrow() {
        let reminder = ReminderEvent(title: "Tomorrow", dateType: .solar, day: 20, month: 10)
        let anchor = calendar.date(from: DateComponents(year: 2026, month: 10, day: 19, hour: 10))!
        XCTAssertEqual(reminder.countdownText(relativeTo: anchor, calendar: calendar), "Ngày mai")
    }

    func testCountdownText_DaysLeft() {
        let reminder = ReminderEvent(title: "Future", dateType: .solar, day: 25, month: 10)
        let anchor = calendar.date(from: DateComponents(year: 2026, month: 10, day: 19, hour: 10))!
        XCTAssertEqual(reminder.countdownText(relativeTo: anchor, calendar: calendar), "Còn 6 ngày")
    }
}
```

- [ ] **Step 2: Run test — verify failure**

Run: `swift test --package-path Packages/VNCalendarDomain --filter ReminderEventOccurrenceTests`
Expected: FAIL (methods not defined).

- [ ] **Step 3: Implement extensions trong `ReminderEvent.swift`**

Thêm vào cuối `Packages/VNCalendarDomain/Sources/VNCalendarDomain/Entities/ReminderEvent.swift`:

```swift
import VNCalendarLunar

extension ReminderEvent {
    public func nextOccurrence(after anchorDate: Date, calendar: Calendar) -> Date {
        let solarNow = SolarDate(from: anchorDate, calendar: calendar)
        if dateType == .lunar {
            let engine = LunarAstronomicalEngine.shared
            let currentLunar = engine.convertToLunar(from: solarNow)
            var targetLunarYear = currentLunar.year
            if currentLunar.month > month || (currentLunar.month == month && currentLunar.day > day) {
                targetLunarYear += 1
            }
            let targetLunar = LunarDate(day: day, month: month, year: targetLunarYear, isLeapMonth: isLeapMonth)
            let targetSolar = engine.convertToSolar(from: targetLunar)
            return targetSolar.date ?? anchorDate
        } else {
            var comps = DateComponents(year: solarNow.year, month: month, day: day)
            if let date = calendar.date(from: comps) {
                if date < anchorDate {
                    comps.year = solarNow.year + 1
                    return calendar.date(from: comps) ?? date
                }
                return date
            }
            if let clampedDay = calendar.range(of: .day, in: .month, for: calendar.date(from: DateComponents(year: solarNow.year, month: month, day: 1)) ?? anchorDate)?.count {
                comps.day = min(day, clampedDay)
                if let date = calendar.date(from: comps), date >= anchorDate {
                    return date
                }
            }
            return anchorDate
        }
    }

    public func countdownText(relativeTo anchorDate: Date, calendar: Calendar) -> String {
        let today = calendar.startOfDay(for: anchorDate)
        let target = nextOccurrence(after: today, calendar: calendar)
        let diff = calendar.dateComponents([.day], from: today, to: target).day ?? 0

        if diff == 0 {
            return "Hôm nay"
        } else if diff == 1 {
            return "Ngày mai"
        } else if diff > 1 {
            return "Còn \(diff) ngày"
        } else {
            return "Đã qua"
        }
    }
}
```

- [ ] **Step 4: Run test — verify pass**

Run: `swift test --package-path Packages/VNCalendarDomain --filter ReminderEventOccurrenceTests`
Expected: PASS.

- [ ] **Step 5: Tạo `NotificationScheduling.swift` trong Domain**

`Packages/VNCalendarDomain/Sources/VNCalendarDomain/Repositories/NotificationScheduling.swift`:

```swift
import Foundation

public protocol NotificationScheduling: Sendable {
    func pruneAndSchedule(reminders: [ReminderEvent]) async throws
}
```

- [ ] **Step 6: Sửa `ScheduleReminderUseCase` — tích hợp notification auto-prune**

Trong `Packages/VNCalendarDomain/Sources/VNCalendarDomain/UseCases/ScheduleReminderUseCase.swift`:

```swift
public final class ScheduleReminderUseCase: Sendable {
    private let reminderRepository: ReminderRepositoryProtocol
    private let subscriptionRepository: SubscriptionRepositoryProtocol
    private let notificationScheduler: NotificationScheduling?

    public init(
        reminderRepository: ReminderRepositoryProtocol,
        subscriptionRepository: SubscriptionRepositoryProtocol,
        notificationScheduler: NotificationScheduling? = nil
    ) {
        self.reminderRepository = reminderRepository
        self.subscriptionRepository = subscriptionRepository
        self.notificationScheduler = notificationScheduler
    }

    public func execute(save reminder: ReminderEvent) async throws {
        if try await reminderRepository.getReminder(by: reminder.id) == nil {
            let isPro = await subscriptionRepository.isFeatureUnlocked(.unlimitedReminders)
            if !isPro {
                let count = try await reminderRepository.fetchAllReminders().count
                guard count < FeatureGateRule.freeMaxReminders else {
                    throw ScheduleReminderError.freeTierLimitReached
                }
            }
        }
        try await reminderRepository.saveReminder(reminder)
        await pruneNotifications()
    }

    public func execute(delete id: UUID) async throws {
        try await reminderRepository.deleteReminder(by: id)
        await pruneNotifications()
    }

    private func pruneNotifications() async {
        guard let scheduler = notificationScheduler,
              let all = try? await reminderRepository.fetchAllReminders() else { return }
        try? await scheduler.pruneAndSchedule(reminders: all)
    }
}
```

- [ ] **Step 7: `SmartNotificationEngine` conformance + `AppContainer` wire up**

Thêm `extension SmartNotificationEngine: NotificationScheduling {}` (đã có sẵn chữ ký `func pruneAndSchedule(reminders: [ReminderEvent]) async throws`).
Trong `AppContainer.swift:75`:

```swift
self.scheduleReminderUseCase = ScheduleReminderUseCase(
    reminderRepository: self.reminderRepository,
    subscriptionRepository: self.subscriptionManager,
    notificationScheduler: self.notificationEngine
)
```

- [ ] **Step 8: Build and test**

Run: `xcodegen generate && swiftlint --strict --quiet && xcodebuild test -scheme AnNien-Dev -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -configuration Debug-Development -only-testing:AnNienTests`
Expected: **TEST SUCCEEDED**.

- [ ] **Step 9: Commit**

```bash
git add Packages/VNCalendarDomain/ App/Infrastructure/Notifications/SmartNotificationEngine.swift App/AppContainer.swift
git commit -m "feat(domain): add ReminderEvent occurrence math and NotificationScheduling to ScheduleReminderUseCase"
```

---

### Task 8: DI chuẩn qua SwiftUI Environment

**Files:**
- Modify: `App/AnNienApp.swift:43` (thêm `.environment(container)`)
- Modify: `App/Features/Main/MainTabView.swift` (nếu cần)

**Interfaces:**
- Consumes: `AppContainer` (`@Observable`).
- Produces: `@Environment(AppContainer.self)` có sẵn cho toàn bộ cây View con.

- [ ] **Step 1: Gắn environment tại root**

Trong `App/AnNienApp.swift:43`, sửa:

```swift
WindowGroup {
    MainTabView()
        .environment(container)
        .preferredColorScheme(preferredScheme)
        // ... giữ nguyên modifiers khác
```

- [ ] **Step 2: Build để xác nhận SwiftUI chấp nhận `@Environment(AppContainer.self)`**

Run: `xcodebuild build -scheme AnNien-Dev -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -configuration Debug-Development`
Expected: **BUILD SUCCEEDED**.

- [ ] **Step 3: Commit**

```bash
git add App/AnNienApp.swift
git commit -m "refactor(di): inject AppContainer via SwiftUI environment"
```

---

### Task 9: MVVM — Timeline (`UpcomingTimelineViewModel`)

**Files:**
- Create: `App/Features/Timeline/UpcomingTimelineViewModel.swift`
- Modify: `App/Features/Timeline/UpcomingTimelineView.swift`
- Test: `Tests/UpcomingTimelineViewModelTests.swift`

**Interfaces:**
- Consumes: `ReminderRepositoryProtocol`, `ScheduleReminderUseCase`, `EvaluateFeatureGateUseCase`.
- Produces: `UpcomingTimelineViewModel` với state: `reminders`, `searchQuery`, `selectedFilter`, `isShowingCreateReminder`, `isShowingPaywall`, `editingReminder`, `selectedRitualTitle`; intents: `load()`, `checkAndCreate()`, `save(_:)`, `delete(_:)`, `filteredReminders`, `urgentMemorial`.

- [ ] **Step 1: Write test cho `UpcomingTimelineViewModel`**

Tạo `Tests/UpcomingTimelineViewModelTests.swift`:

```swift
import XCTest
import VNCalendarDomain
@testable import AnNien

@MainActor
final class UpcomingTimelineViewModelTests: XCTestCase {
    final class MockReminderRepo: ReminderRepositoryProtocol, @unchecked Sendable {
        var items: [ReminderEvent] = []
        func fetchAllReminders() async throws -> [ReminderEvent] { items }
        func getReminder(by id: UUID) async throws -> ReminderEvent? { items.first { $0.id == id } }
        func saveReminder(_ reminder: ReminderEvent) async throws {
            items.removeAll { $0.id == reminder.id }
            items.append(reminder)
        }
        func deleteReminder(by id: UUID) async throws { items.removeAll { $0.id == id } }
    }

    final class MockSubRepo: SubscriptionRepositoryProtocol, @unchecked Sendable {
        var unlocked = true
        func isFeatureUnlocked(_ feature: AppFeature) async -> Bool { unlocked }
        func getSubscriptionStatus() async -> SubscriptionStatus { .active(tier: .yearly) }
        func getAvailableProducts() async throws -> [SubscriptionProduct] { [] }
        func purchase(productId: String) async throws -> PurchaseResult { .success }
        func restorePurchases() async throws {}
    }

    func testFilterAndSearch() async {
        let repo = MockReminderRepo()
        let sub = MockSubRepo()
        let schedule = ScheduleReminderUseCase(reminderRepository: repo, subscriptionRepository: sub)
        let gate = EvaluateFeatureGateUseCase(subscriptionRepository: sub, reminderRepository: repo)

        repo.items = [
            ReminderEvent(title: "Giỗ Cụ", category: .deathAnniversary, day: 1, month: 1),
            ReminderEvent(title: "Sinh nhật Bé", category: .birthday, day: 2, month: 2)
        ]

        let vm = UpcomingTimelineViewModel(
            reminderRepository: repo,
            scheduleReminderUseCase: schedule,
            evaluateFeatureGateUseCase: gate
        )
        await vm.load()

        XCTAssertEqual(vm.reminders.count, 2)
        vm.selectedFilter = .memorialOnly
        XCTAssertEqual(vm.filteredReminders.count, 1)
        XCTAssertEqual(vm.filteredReminders.first?.title, "Giỗ Cụ")

        vm.selectedFilter = .all
        vm.searchQuery = "Sinh"
        XCTAssertEqual(vm.filteredReminders.count, 1)
        XCTAssertEqual(vm.filteredReminders.first?.title, "Sinh nhật Bé")
    }
}
```

- [ ] **Step 2: Viết `UpcomingTimelineViewModel.swift`**

Tạo `App/Features/Timeline/UpcomingTimelineViewModel.swift`:

```swift
import SwiftUI
import Observation
import VNCalendarDomain
import VNCalendarLunar

@Observable
@MainActor
public final class UpcomingTimelineViewModel {
    public var reminders: [ReminderEvent] = []
    public var searchQuery = ""
    public var selectedFilter: MemorialFilterTab = .all
    public var isShowingCreateReminder = false
    public var isShowingPaywall = false
    public var editingReminder: ReminderEvent?
    public var selectedRitualTitle: String?

    private let reminderRepository: ReminderRepositoryProtocol
    private let scheduleReminderUseCase: ScheduleReminderUseCase
    private let evaluateFeatureGateUseCase: EvaluateFeatureGateUseCase
    private var calendar: Calendar

    public init(
        reminderRepository: ReminderRepositoryProtocol,
        scheduleReminderUseCase: ScheduleReminderUseCase,
        evaluateFeatureGateUseCase: EvaluateFeatureGateUseCase,
        calendar: Calendar = {
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = VNTime.vietnam
            return cal
        }()
    ) {
        self.reminderRepository = reminderRepository
        self.scheduleReminderUseCase = scheduleReminderUseCase
        self.evaluateFeatureGateUseCase = evaluateFeatureGateUseCase
        self.calendar = calendar
    }

    public var filteredReminders: [ReminderEvent] {
        let base = reminders.filter { selectedFilter.matches(category: $0.category) }
        guard !searchQuery.isEmpty else { return base }
        return base.filter {
            $0.title.localizedCaseInsensitiveContains(searchQuery) ||
            ($0.note?.localizedCaseInsensitiveContains(searchQuery) == true) ||
            ($0.relationship?.localizedCaseInsensitiveContains(searchQuery) == true)
        }
    }

    public var urgentMemorial: ReminderEvent? {
        reminders.first { $0.category == .deathAnniversary || $0.category == .ancestral }
    }

    public func countdownText(for reminder: ReminderEvent) -> String {
        reminder.countdownText(relativeTo: Date(), calendar: calendar)
    }

    public func load() async {
        guard let items = try? await reminderRepository.fetchAllReminders() else { return }
        let today = calendar.startOfDay(for: Date())
        self.reminders = items.sorted {
            $0.nextOccurrence(after: today, calendar: calendar) < $1.nextOccurrence(after: today, calendar: calendar)
        }
    }

    public func checkAndCreate() {
        Task {
            do {
                if try await evaluateFeatureGateUseCase.canAddReminder() {
                    isShowingCreateReminder = true
                } else {
                    isShowingPaywall = true
                }
            } catch {
                isShowingPaywall = true
            }
        }
    }

    public func save(_ reminder: ReminderEvent) {
        Task {
            try? await scheduleReminderUseCase.execute(save: reminder)
            await load()
        }
    }

    public func delete(_ reminder: ReminderEvent) {
        Task {
            try? await scheduleReminderUseCase.execute(delete: reminder.id)
            await load()
        }
    }
}
```

- [ ] **Step 3: Refactor `UpcomingTimelineView.swift` thành thin view**

Sửa `App/Features/Timeline/UpcomingTimelineView.swift`:
- Thay `@State private var container = AppContainer.shared` + `@State private var reminders...` bằng:
  ```swift
  @Environment(AppContainer.self) private var container
  @State private var viewModel: UpcomingTimelineViewModel?
  ```
- Khởi tạo viewModel trong `.task` hoặc View init. Khuyên dùng pattern idiomatic:
  ```swift
  public init() {}
  // trong body:
  NavigationStack { ... }
  .task {
      if viewModel == nil {
          viewModel = UpcomingTimelineViewModel(
              reminderRepository: container.reminderRepository,
              scheduleReminderUseCase: container.scheduleReminderUseCase,
              evaluateFeatureGateUseCase: container.evaluateFeatureGateUseCase
          )
      }
      await viewModel?.load()
  }
  ```
- Thay toàn bộ `reminders`, `searchQuery`, `saveReminder`, `deleteReminder`, `nextOccurrenceDate`, `calculateCountdown` bằng `viewModel.*`.
- **Xóa hoàn toàn** `nextOccurrenceDate` và `calculateCountdown` khỏi View (đã có trong Domain + ViewModel).

- [ ] **Step 4: Update `project.yml` để nhận test file mới + regenerate**

Run: `xcodegen generate`

- [ ] **Step 5: Run tests + swiftlint**

Run: `swiftlint --strict --quiet && xcodebuild test -scheme AnNien-Dev -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -configuration Debug-Development -only-testing:AnNienTests/UpcomingTimelineViewModelTests`
Expected: **TEST SUCCEEDED**, 0 SwiftLint violation.

- [ ] **Step 6: Commit**

```bash
git add App/Features/Timeline/ Tests/UpcomingTimelineViewModelTests.swift project.yml
git commit -m "refactor(timeline): extract UpcomingTimelineViewModel and clean up view"
```

---

### Task 10: MVVM — Calendar (`CalendarMainViewModel`)

**Files:**
- Create: `App/Features/Calendar/CalendarMainViewModel.swift`
- Modify: `App/Features/Calendar/CalendarMainView.swift`

**Interfaces:**
- Consumes: `GetMonthCalendarUseCase`, `ReminderRepositoryProtocol`, `ScheduleReminderUseCase`, `EvaluateFeatureGateUseCase`, `VNCalendarAdapterViewModel`.
- Produces: `CalendarMainViewModel` chứa: `todayDetails`, `adapterViewModel`, state sheets (`isShowingCreateReminder`, `isShowingPaywall`, `isShowingSearch`, `isShowingSettings`), intents: `loadData()`, `checkAndShowReminderForm()`, `saveReminder(_:)`.

- [ ] **Step 1: Viết `CalendarMainViewModel.swift`**

Tạo `App/Features/Calendar/CalendarMainViewModel.swift`:

```swift
import SwiftUI
import Observation
import VNCalendarDomain
import VNCalendarKit
import VNCalendarLunar

@Observable
@MainActor
public final class CalendarMainViewModel {
    public let adapterViewModel: VNCalendarAdapterViewModel
    public var todayDetails: DayCalendarDetails?
    public var isShowingCreateReminder = false
    public var isShowingPaywall = false
    public var isShowingSearch = false
    public var isShowingSettings = false

    private let getMonthCalendarUseCase: GetMonthCalendarUseCase
    private let reminderRepository: ReminderRepositoryProtocol
    private let scheduleReminderUseCase: ScheduleReminderUseCase
    private let evaluateFeatureGateUseCase: EvaluateFeatureGateUseCase

    public init(
        adapterViewModel: VNCalendarAdapterViewModel = VNCalendarAdapterViewModel(),
        getMonthCalendarUseCase: GetMonthCalendarUseCase,
        reminderRepository: ReminderRepositoryProtocol,
        scheduleReminderUseCase: ScheduleReminderUseCase,
        evaluateFeatureGateUseCase: EvaluateFeatureGateUseCase
    ) {
        self.adapterViewModel = adapterViewModel
        self.getMonthCalendarUseCase = getMonthCalendarUseCase
        self.reminderRepository = reminderRepository
        self.scheduleReminderUseCase = scheduleReminderUseCase
        self.evaluateFeatureGateUseCase = evaluateFeatureGateUseCase
    }

    public func loadData() async {
        let now = Date()
        let solar = SolarDate(from: now)
        todayDetails = try? await getMonthCalendarUseCase.execute(solarDate: solar)

        if let reminders = try? await reminderRepository.fetchAllReminders() {
            adapterViewModel.updateReminders(reminders)
        }
    }

    public func checkAndShowReminderForm() {
        Task {
            do {
                if try await evaluateFeatureGateUseCase.canAddReminder() {
                    isShowingCreateReminder = true
                } else {
                    isShowingPaywall = true
                }
            } catch {
                isShowingPaywall = true
            }
        }
    }

    public func saveReminder(_ reminder: ReminderEvent) {
        Task {
            try? await scheduleReminderUseCase.execute(save: reminder)
            await loadData()
        }
    }
}
```

- [ ] **Step 2: Refactor `CalendarMainView.swift` thành thin view**

Thay `@State private var container = AppContainer.shared` và các state bằng:

```swift
@Environment(AppContainer.self) private var container
@State private var viewModel: CalendarMainViewModel?
```

Wiring trong `.task`:

```swift
.task {
    if viewModel == nil {
        viewModel = CalendarMainViewModel(
            getMonthCalendarUseCase: container.getMonthCalendarUseCase,
            reminderRepository: container.reminderRepository,
            scheduleReminderUseCase: container.scheduleReminderUseCase,
            evaluateFeatureGateUseCase: container.evaluateFeatureGateUseCase
        )
    }
    await viewModel?.loadData()
}
```

Xóa `saveReminder`, `checkAndShowReminderForm`, `loadData` khỏi View (chuyển qua `viewModel.*`).

- [ ] **Step 3: Build và test**

Run: `swiftlint --strict --quiet && xcodebuild test -scheme AnNien-Dev -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -configuration Debug-Development`
Expected: **BUILD & TESTS SUCCEEDED**.

- [ ] **Step 4: Commit**

```bash
git add App/Features/Calendar/
git commit -m "refactor(calendar): extract CalendarMainViewModel and remove business logic from view"
```

---

### Task 11: MVVM — ReminderForm (`ReminderFormViewModel`)

**Files:**
- Create: `App/Features/ReminderForm/ReminderFormViewModel.swift`
- Modify: `App/Features/ReminderForm/ReminderFormView.swift`

**Interfaces:**
- Consumes: `ReminderEvent`, `ReminderCategory`, `CalendarDateType`, `RecurrenceRule`, `LeapMonthPolicy`.
- Produces: `ReminderFormViewModel` quản lý: `title`, `category`, `dateType`, `selectedDate`, `isLeapMonth`, `recurrence`, `alertOffsets`, `hour`, `minute`, `note`, `relationship`; validate; build `ReminderEvent` để save.

- [ ] **Step 1: Viết `ReminderFormViewModel.swift`**

Chuyển 11 `@State` biến của form sang `@Observable @MainActor final class ReminderFormViewModel`. Thêm `func buildReminder() -> ReminderEvent?`, `var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }`.

- [ ] **Step 2: Refactor `ReminderFormView.swift` dùng ViewModel**

View chỉ bind tới `viewModel.*` và gọi `onSave(vm.buildReminder()!)`.

- [ ] **Step 3: Verify swiftlint + compile**

Run: `swiftlint --strict --quiet && xcodebuild build -scheme AnNien-Dev -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -configuration Debug-Development`
Expected: 0 error.

- [ ] **Step 4: Commit**

```bash
git add App/Features/ReminderForm/
git commit -m "refactor(reminder-form): extract ReminderFormViewModel"
```

---

### Task 12: MVVM — Settings, Family, Prayers (`SettingsViewModel`, `FamilyHierarchyViewModel`, `PrayerLibraryViewModel`)

**Files:**
- Create: `App/Features/Settings/SettingsViewModel.swift`
- Modify: `App/Features/Settings/SettingsView.swift`
- Create: `App/Features/Family/FamilyHierarchyViewModel.swift`
- Modify: `App/Features/Family/FamilyHierarchyView.swift`
- Create: `App/Features/Prayers/PrayerLibraryViewModel.swift`
- Modify: `App/Features/Prayers/PrayerLibraryView.swift`

- [ ] **Step 1: Viết `SettingsViewModel.swift` và refactor `SettingsView.swift`**

Chuyển logic backup/restore (`DataBackupEngine`), sync proverbs (`container.syncProverbs()`), legal links (`LegalLinksService`), refresh subscription sang `SettingsViewModel`. Xóa `AppContainer.shared` khỏi `SettingsView.swift:12,195`.

- [ ] **Step 2: Viết `FamilyHierarchyViewModel.swift` và refactor `FamilyHierarchyView.swift`**

Chuyển fetch/filter ancestor memorials sang `FamilyHierarchyViewModel`. Xóa `AppContainer.shared` khỏi `FamilyHierarchyView.swift:13`.

- [ ] **Step 3: Viết `PrayerLibraryViewModel.swift` và refactor `PrayerLibraryView.swift`**

Chuyển fetch prayers qua `PrayerRepositoryProtocol`, filter category, search sang `PrayerLibraryViewModel`. Xóa `AppContainer.shared` nếu có.

- [ ] **Step 4: Build và test toàn bộ**

Run: `swiftlint --strict --quiet && xcodebuild test -scheme AnNien-Dev -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -configuration Debug-Development`
Expected: **TEST SUCCEEDED**.

- [ ] **Step 5: Commit**

```bash
git add App/Features/Settings/ App/Features/Family/ App/Features/Prayers/
git commit -m "refactor(features): extract ViewModels for Settings, Family, and Prayers"
```

---

### Task 13: MVVM — Search, Paywall, Articles (`OmniSearchViewModel`, `PaywallViewModel`, `CulturalArticlesViewModel`)

**Files:**
- Create: `App/Features/Search/OmniSearchViewModel.swift`
- Modify: `App/Features/Search/OmniSearchView.swift`
- Create: `App/Features/Paywall/PaywallViewModel.swift`
- Modify: `App/Features/Paywall/PaywallView.swift`
- Create: `App/Features/Articles/CulturalArticlesViewModel.swift`
- Modify: `App/Features/Articles/CulturalArticlesView.swift`

- [ ] **Step 1: Viết `OmniSearchViewModel.swift` và refactor `OmniSearchView.swift`**

Chuyển debounce search, gọi `NaturalSearchUseCase` sang ViewModel.

- [ ] **Step 2: Viết `PaywallViewModel.swift` và refactor `PaywallView.swift`**

Chuyển fetch products, purchase, restore sang `PaywallViewModel`.

- [ ] **Step 3: Viết `CulturalArticlesViewModel.swift` và refactor `CulturalArticlesView.swift`**

Chuyển fetch articles sang ViewModel.

- [ ] **Step 4: Audit `AppContainer.shared`**

Run: `grep -rn "AppContainer.shared" App/Features/ || echo "CLEAN"`
Expected: `CLEAN` (0 kết quả trong `App/Features/`).

- [ ] **Step 5: Build và test toàn bộ**

Run: `swiftlint --strict --quiet && xcodebuild test -scheme AnNien-Dev -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -configuration Debug-Development`
Expected: **TEST SUCCEEDED**.

- [ ] **Step 6: Commit**

```bash
git add App/Features/Search/ App/Features/Paywall/ App/Features/Articles/
git commit -m "refactor(features): extract ViewModels for Search, Paywall, and Articles"
```

---

### Task 14: Cập nhật CLAUDE.md phản ánh kiến trúc MVVM thực tế

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Bổ sung section "MVVM Architecture Guidelines" vào `CLAUDE.md`**

Mô tả:
- Mỗi feature có `ViewModel.swift` (`@Observable @MainActor final class`).
- Views không gọi `AppContainer.shared`; dùng `@Environment(AppContainer.self)`.
- Business logic (lunar occurrence, countdown, filter) thuộc Domain/ViewModel, cấm đặt trong View.
- UseCases tự orchestrate notifications khi save/delete.
- `SubscriptionManager` nằm trong `VNCalendarData`.

- [ ] **Step 2: Verify `CLAUDE.md` khớp toàn bộ cấu trúc file mới**

Run: `git diff CLAUDE.md`

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md with MVVM conventions and clean architecture rules"
```

---

## Definition of Done (Plan 2)

- [ ] `grep -rn "AppContainer.shared" App/Features/` → CLEAN.
- [ ] 9 feature có `<Feature>ViewModel.swift` riêng.
- [ ] `SubscriptionManager.swift` nằm trong `Packages/VNCalendarData/`.
- [ ] `ReminderEvent.nextOccurrence` + `countdownText` có unit tests trong `VNCalendarDomainTests` và pass.
- [ ] `UpcomingTimelineViewModelTests` pass.
- [ ] `swiftlint --strict --quiet` → 0 error.
- [ ] `xcodebuild test -scheme AnNien-Dev` → ALL TESTS PASS.
- [ ] CLAUDE.md mô tả đúng thực tế MVVM mới.
