# UI Redesign + BaseNavigationStack Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Executor model: Opus (user-specified).

**Goal:** Replace the cream/terracotta look with a neutral porcelain palette, standardise spacing/typography/a11y via tokens, and move all navigation onto `iletai/BaseNavigationStack` 2.x.

**Architecture:** One `NavigationRouter<AppRoute, AppSheet, AppCover>` per tab, each wrapped by `BaseNavigationContainer`; the Settings sheet hosts its own container/router. Views call the router; ViewModels expose decisions (e.g. a feature-gate result) and never hold a router. Design-system tokens/palette change first (Phase 1), then 5 feature agents work in parallel worktrees (Phase 2).

**Tech Stack:** Swift 6 (strict concurrency), SwiftUI, XcodeGen, `BaseNavigationStack` (from 2.0.0), XCTest, SwiftLint `--strict`.

**Spec:** `docs/specs/2026-11-03-ui-redesign-navigation-design.md`

## Global Constraints
- iOS 17.0 minimum; Swift 6, `SWIFT_STRICT_CONCURRENCY = complete`.
- `BaseNavigationStack` dependency: AnNien app target only. `VNCalendarKit`, `VNCalendarDesignSystem`, `VNCalendarDomain`, `VNCalendarData`, `VNCalendarLunar` MUST NOT import it.
- `VNCalendarDomain` must not import SwiftUI/SwiftData/UIKit.
- ViewModels: `@Observable @MainActor final class`, constructor-injected, no `AppContainer.shared`, no SwiftData import, no router.
- Gate before every commit: `swiftlint --strict --quiet` exit 0; never `--no-verify`.
- Max function body 60 lines, cyclomatic complexity 10, no force unwrap / IUO.
- Comments in code in English. User-facing strings stay Vietnamese.
- Commits: conventional commits. **No push** unless the user says so.
- Branch: `feat/ui-redesign-navigation` cut from `docs/ui-redesign-navigation`. Phase-2 worktrees branch from the Phase-1 tip and merge back with `--no-ff`.
- Do not delete or edit `PrayerLibraryView`, `PrayerDetailView`, `AncestralShareCardView` (dead code, user decision: keep). Exception: Task 10 may token-fix literals in them.
- Library API (verified from source, `Sources/BaseNavigationStack`): `router.push(_ route) -> Bool`, `pop()`, `popToRoot()`, `replacePath(_:)`, `present(sheet:)`, `present(cover:)`, `dismiss()`, `dismissModals()`, `send(_:)`. `sheet`/`cover` require `Identifiable & Hashable & Sendable`. `popToRoot()` also clears modals. Container: `BaseNavigationContainer(router:content:destination:sheet:cover:)` (a 3-arg convenience init without sheet/cover exists). Router is injected via `.environment(router)` and read with `@Environment(AppRouter.self)`; sheet content inherits it.
- `ReminderEvent`, `Holiday`, `Prayer` are `Identifiable, Equatable, Sendable` but NOT `Hashable`.

## Review Focus
1. Double-tap on a row/button pushes or presents twice → router `push` returns false for duplicate top; sheet re-present must not stack. Test in Task 4.
2. Present a sheet while one is open (search → reminder form, day detail → reminder form) → must dismiss, then present; never silently drop. Test in Task 4 and manual check in Task 8.
3. Free-tier user taps "add" → Paywall, not the form; gate throwing also → Paywall. Test in Task 8.
4. Largest accessibility Dynamic Type (`accessibilityXXXL`) with long Vietnamese strings → no clipped core text. Manual screenshots in Task 11.
5. Dark mode `vnTextTertiary` regression (was 1.5:1) → contrast unit test in Task 2.

---

## PHASE 1 — Foundation (one agent, sequential)

### Task 1: Dependency + layout tokens
**Files:**
- Modify: `project.yml` (packages + AnNien dependencies)
- Modify: `Packages/VNCalendarDesignSystem/Sources/VNCalendarDesignSystem/Tokens/LayoutTokens.swift`
- Test: `Tests/DesignTokensTests.swift`

**Interfaces:**
- Produces: `VNSpacing.screenMargin`, `.cardPadding`, `.sectionGap`; `VNSize.minTapTarget`, `.iconButton`, `.iconBadge`; `VNLayout.tabBarMaxWidth`, `.tabBarBottomInset`, `.tabBarItemHeight`.

- [ ] **Step 1: Write the failing test**
```swift
import XCTest
import VNCalendarDesignSystem

final class DesignTokensTests: XCTestCase {
    func testLayoutTokensMatchSpec() {
        XCTAssertEqual(VNSpacing.screenMargin, 20)
        XCTAssertEqual(VNSpacing.cardPadding, 16)
        XCTAssertEqual(VNSpacing.sectionGap, 24)
        XCTAssertEqual(VNSize.minTapTarget, 44)
        XCTAssertEqual(VNSize.iconButton, 40)
        XCTAssertEqual(VNSize.iconBadge, 24)
        XCTAssertEqual(VNLayout.tabBarMaxWidth, 520)
        XCTAssertEqual(VNLayout.tabBarBottomInset, 12)
        XCTAssertEqual(VNLayout.tabBarItemHeight, 48)
    }
}
```
- [ ] **Step 2:** `xcodegen generate && xcodebuild test -scheme AnNien-Dev -destination 'platform=iOS Simulator,name=<sim from xcrun simctl list devices available>' -configuration Debug-Development -only-testing:AnNienTests/DesignTokensTests` → FAIL (symbols undefined).
- [ ] **Step 3:** In `project.yml` add
```yaml
  BaseNavigationStack:
    url: https://github.com/iletai/BaseNavigationStack.git
    from: 2.0.0
```
under `packages:` and `- package: BaseNavigationStack` under the `AnNien` target dependencies only. In `LayoutTokens.swift` add (inside `VNSpacing`) `public static let screenMargin: CGFloat = 20`, `cardPadding = 16`, `sectionGap = 24`, and two new enums:
```swift
public enum VNSize {
    /// HIG minimum tap target.
    public static let minTapTarget: CGFloat = 44
    public static let iconButton: CGFloat = 40
    public static let iconBadge: CGFloat = 24
}

public enum VNLayout {
    public static let tabBarMaxWidth: CGFloat = 520
    public static let tabBarBottomInset: CGFloat = 12
    public static let tabBarItemHeight: CGFloat = 48
}
```
- [ ] **Step 4:** Re-run Step 2 command → PASS; `swiftlint --strict --quiet` exit 0.
- [ ] **Step 5:** `git add project.yml Packages Tests && git commit -m "feat(design-system): add layout tokens and BaseNavigationStack dependency"`

### Task 2: Palette + contrast test
**Files:**
- Modify: `Packages/VNCalendarDesignSystem/Sources/VNCalendarDesignSystem/Tokens/ColorTokens.swift`
- Modify: `DESIGN.md` is deferred to Task 12.
- Test: `Tests/ContrastTests.swift`

**Interfaces:**
- Produces: `public enum VNPalette` with `static let` `UInt32` hex pairs `(light: UInt32, dark: UInt32)` for every semantic token; new tokens `Color.vnAccentJade`, `.vnAccentJadeSurface`, `.vnAccentGoldText`, `.vnBorderStrong`, `.vnOnAccent`. Existing `Color.vn*` names unchanged and now read from `VNPalette`.

Values (from spec §4): Light — BackgroundPrimary `F6F7F4`, Secondary `FFFFFF`, Tertiary `ECEEEA`, SurfaceElevated `FFFFFF`, TextPrimary `1B1D1F`, TextSecondary `4A4F52`, TextTertiary `6A7074`, Red `B5341D`, DeepPrimary `8F2410`, Gold `C5A059`, GoldText `7A5C14`, Jade `2F6B57`, JadeSurface `E3EFEA`, RedSurface `F8E6E1`, GoldContainer `F6E7BF`, OnGoldContainer `6B4E0E`, Warning `9A5300`, Error `B91C1C`, Success `2E6F40`, BorderSubtle `DADDD8`, BorderStrong `8C9296`, OnAccent `FFFFFF`. Dark — Primary `131415`, Secondary `1C1E1F`, Tertiary `26292A`, SurfaceElevated `26292A`, TextPrimary `F2F1EC`, TextSecondary `B4B7B5`, TextTertiary `8E9391`, Red `E8715C`, Gold `E3C781`, Jade `6FBF9F`, Success `5DB67E`, Warning `E9A23B`, Error `F08A82`, OnAccent `131415`; for dark tokens not listed keep the current dark hex unless it fails the contrast test, then derive a passing value.

- [ ] **Step 1: Write the failing test**
```swift
import XCTest
import VNCalendarDesignSystem

final class ContrastTests: XCTestCase {
    private func lum(_ hex: UInt32) -> Double {
        func ch(_ v: UInt32) -> Double {
            let c = Double(v) / 255
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * ch((hex >> 16) & 0xFF) + 0.7152 * ch((hex >> 8) & 0xFF) + 0.0722 * ch(hex & 0xFF)
    }
    private func ratio(_ a: UInt32, _ b: UInt32) -> Double {
        let (x, y) = (lum(a), lum(b))
        return (max(x, y) + 0.05) / (min(x, y) + 0.05)
    }

    func testBodyTextMeetsAAOnAllBackgrounds() {
        for useDark in [false, true] {
            let bgs = [VNPalette.backgroundPrimary, VNPalette.backgroundSecondary, VNPalette.backgroundTertiary]
            let texts = [VNPalette.textPrimary, VNPalette.textSecondary]
            for bg in bgs { for t in texts {
                XCTAssertGreaterThanOrEqual(ratio(useDark ? t.dark : t.light, useDark ? bg.dark : bg.light), 4.5)
            } }
        }
    }

    func testTertiaryTextAndAccentsOnPrimary() {
        for useDark in [false, true] {
            let bg = useDark ? VNPalette.backgroundPrimary.dark : VNPalette.backgroundPrimary.light
            for token in [VNPalette.textTertiary, VNPalette.accentHeritageRed, VNPalette.accentJade] {
                XCTAssertGreaterThanOrEqual(ratio(useDark ? token.dark : token.light, bg), 4.5)
            }
        }
    }

    func testOnAccentAgainstRedAndJade() {
        for useDark in [false, true] {
            let on = useDark ? VNPalette.onAccent.dark : VNPalette.onAccent.light
            for fill in [VNPalette.accentHeritageRed, VNPalette.accentJade] {
                XCTAssertGreaterThanOrEqual(ratio(on, useDark ? fill.dark : fill.light), 4.5)
            }
        }
    }
}
```
- [ ] **Step 2:** Run `-only-testing:AnNienTests/ContrastTests` → FAIL (`VNPalette` undefined).
- [ ] **Step 3:** In `ColorTokens.swift` add `public enum VNPalette { public static let backgroundPrimary: (light: UInt32, dark: UInt32) = (0xF6F7F4, 0x131415) … }` for all tokens above, then rewrite each `Color.vn*` to `Color(light: Color(hex: VNPalette.x.light), dark: Color(hex: VNPalette.x.dark))` using the existing `init(light:dark:)` at `ColorTokens.swift:17`. Add the new tokens. If a test pair fails (e.g. dark Success), adjust the hex until ≥4.5 and record the final value in the commit body.
- [ ] **Step 4:** Test PASS. Replace `.white` literals with `Color.vnOnAccent` at: `CalendarSettingsView.swift:253`, `PrayerDetailView.swift:104`, `FamilyHierarchyView.swift:90`, `MemorialHeroCard.swift:34`, `PaywallView.swift:155,237`, `VNDayDetailBottomSheet.swift:292`, `VNDayCellView.swift:73`, `VNEmptyState.swift:103`, `VNNavBar.swift:68` (re-grep `\.white` first; line numbers may drift). Replace the warm shadow literals at `ReminderHeaderView.swift:16` and `LayoutTokens.swift:45` with neutral `Color.black.opacity(0.05)`.
- [ ] **Step 5:** `swiftlint --strict --quiet`; build; commit `feat(design-system): neutral porcelain palette with jade accent and contrast tests`.

### Task 3: Shared UI primitives (dismiss, press style, haptics)
**Files:**
- Modify: `Packages/VNCalendarDesignSystem/Sources/VNCalendarDesignSystem/Components/VNNavBar.swift` (`VNDismissButton` at line 17)
- Modify: `Packages/VNCalendarDesignSystem/Sources/VNCalendarDesignSystem/Modifiers/VNCellPressButtonStyle.swift` (reuse; add `VNCardPressButtonStyle` only if the cell style does not fit cards)
- Create: `Packages/VNCalendarDesignSystem/Sources/VNCalendarDesignSystem/Modifiers/VNHaptics.swift`
- Test: `Tests/VNHapticsTests.swift`

**Interfaces:**
- Produces: `VNDismissButton` always placed by callers at `.topBarTrailing` with `minWidth/minHeight: VNSize.minTapTarget`; `VNHaptics.impact(_ style: VNHapticStyle, enabled: Bool)` where `enabled` is injected so the type is testable; callers pass the app setting.

- [ ] **Step 1:** Read `CalendarSettingsView.swift` around the haptic toggle (audit: ~line 412) to find the `@AppStorage` key. Write a failing test that `VNHaptics.shouldFire(enabled: false) == false` and `true == true` (pure function; the UIKit call is behind it).
- [ ] **Step 2:** Run → FAIL. **Step 3:** Implement
```swift
public enum VNHapticStyle: Sendable { case light, medium, success }

public enum VNHaptics {
    /// Pure gate so the setting can be unit tested without UIKit.
    public static func shouldFire(enabled: Bool) -> Bool { enabled }

    @MainActor
    public static func impact(_ style: VNHapticStyle = .light, enabled: Bool) {
        guard shouldFire(enabled: enabled) else { return }
        #if canImport(UIKit)
        switch style {
        case .light: UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium: UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .success: UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        #endif
    }
}
```
Make `VNDismissButton` tap area ≥ `VNSize.minTapTarget`. Pass `hapticEnabled` at call sites in Phase 2 (Task 6–10 replace the 6 raw generator calls: `CalendarMainView:296`, `PrayerLibraryView:255`, `PrayerCategoryCard:74`, `PrayerDetailView:324,341`, `CulturalArticlesView:387`, `MainTabView` `triggerHaptic`).
- [ ] **Step 4:** PASS; lint. **Step 5:** commit `feat(design-system): unify dismiss button and settings-aware haptics`.

### Task 4: Navigation types + router tests
**Files:**
- Create: `App/Navigation/AppNavigation.swift`
- Test: `Tests/AppNavigationTests.swift`

**Interfaces:**
- Produces:
```swift
import BaseNavigationStack
import Foundation
import VNCalendarDomain

enum AppRoute: Hashable, Sendable {
    case calendarSettings, appearanceLanguage, dataBackup, privacySecurity, about
}

enum AppSheet: Identifiable, Sendable {
    case reminderForm(editing: ReminderEvent?, initialDate: Date?)
    case paywall
    case search
    case settings
    case holiday(Holiday)
    case ritual(title: String)
    case share(text: String)
    case dayDetail(dateKey: Int)

    var id: String {
        switch self {
        case .reminderForm(let editing, let date):
            return "reminderForm-\(editing?.id.uuidString ?? "new")-\(date?.timeIntervalSince1970 ?? 0)"
        case .paywall: return "paywall"
        case .search: return "search"
        case .settings: return "settings"
        case .holiday(let holiday): return "holiday-\(holiday.id)"
        case .ritual(let title): return "ritual-\(title)"
        case .share(let text): return "share-\(text.hashValue)"
        case .dayDetail(let key): return "dayDetail-\(key)"
        }
    }
}

// Hashable by id only: ReminderEvent/Holiday are not Hashable.
extension AppSheet: Hashable {
    static func == (lhs: AppSheet, rhs: AppSheet) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

enum AppCover: Identifiable, Hashable, Sendable {
    case unused
    var id: String { "unused" }
}

typealias AppRouter = NavigationRouter<AppRoute, AppSheet, AppCover>

/// Result the Views route on; keeps ViewModels router-free.
enum CreateReminderGate: Sendable { case allowed, requiresPro }
```
(Adjust `AppSheet.holiday`/`.dayDetail` payload types after reading `Holiday`/`VNDayModel`; `Holiday.id` type may be `UUID` or `String` — use string interpolation either way. `dayDetail` is only needed if Calendar Task 6 keeps the day sheet in the App; otherwise delete the case.)

- [ ] **Step 1: Write failing tests** (headless, `@MainActor`)
```swift
import XCTest
@testable import AnNien

@MainActor
final class AppNavigationTests: XCTestCase {
    func testDoubleTapPushIsIgnored() {
        let router = AppRouter()
        XCTAssertTrue(router.push(.about))
        XCTAssertFalse(router.push(.about))
        XCTAssertEqual(router.path, [.about])
    }

    func testSheetThenSecondSheetReplacesNotStacks() {
        let router = AppRouter()
        router.present(sheet: .search)
        router.dismissModals()
        router.present(sheet: .paywall)
        XCTAssertEqual(router.sheet, .paywall)
    }

    func testPopToRootClearsModals() {
        let router = AppRouter()
        router.push(.dataBackup)
        router.present(sheet: .settings)
        router.popToRoot()
        XCTAssertTrue(router.path.isEmpty)
        XCTAssertNil(router.sheet)
    }

    func testSheetIdsAreStableAndDistinct() {
        XCTAssertEqual(AppSheet.paywall.id, AppSheet.paywall.id)
        XCTAssertNotEqual(AppSheet.search, AppSheet.settings)
        XCTAssertNotEqual(AppSheet.ritual(title: "A"), AppSheet.ritual(title: "B"))
    }
}
```
- [ ] **Step 2:** Run `-only-testing:AnNienTests/AppNavigationTests` → FAIL. **Step 3:** create the file above. **Step 4:** PASS + lint. **Step 5:** commit `feat(navigation): add typed routes, sheets and router tests`.

### Task 5: Container wiring, tab routers, deep links
**Files:**
- Create: `App/Navigation/AppSheetView.swift` (maps `AppSheet` → view), `App/Navigation/AppRouteView.swift` (maps `AppRoute` → view)
- Modify: `App/Features/Main/MainTabView.swift`, `App/AnNienApp.swift`

**Interfaces:**
- Consumes: Task 4 types; existing feature views (`ReminderFormView`, `PaywallView`, `OmniSearchView`, `SettingsView`, `HolidayDetailSheet`, `RitualPrayerModal`, `ShareSheet`, `CalendarSettingsView` and other settings children).
- Produces: `AppSheetView(sheet: AppSheet)` and `AppRouteView(route: AppRoute)`; `MainTabView` owns `@State private var routers: [MainTab: AppRouter]`; `MainTab` becomes `Hashable` (it already is via `Int` raw value); `selectedTab` becomes `MainTab`.

- [ ] **Step 1: Failing test** — `MainTab` ↔ deep link:
```swift
func testDeepLinkSelectsTabAndPresentsSheet() {
    let handler = DeepLinkHandler()
    let action = handler.action(for: URL(string: "annien://settings")!)
    XCTAssertEqual(action, .present(tab: .calendar, sheet: .settings))
    XCTAssertNil(handler.action(for: URL(string: "annien://nope")!))
}
```
Add `struct DeepLinkHandler { enum Action: Equatable { case select(MainTab), present(tab: MainTab, sheet: AppSheet) }; func action(for url: URL) -> Action? }` in `App/Navigation/DeepLinkHandler.swift`. Supported hosts: `calendar`, `memorial`, `rituals`, `family` → `.select`; `settings`, `paywall`, `search` → `.present(tab: .calendar, sheet:)`. Register scheme `annien` in `App/Info.plist` `CFBundleURLTypes`.
- [ ] **Step 2:** run → FAIL. **Step 3:** implement; then rewrite `MainTabView.body`:
```swift
TabView(selection: $selectedTab) {
    ForEach(MainTab.allCases) { tab in
        tabContainer(for: tab)
            .tag(tab)
            .toolbar(.hidden, for: .tabBar)
    }
}
```
with
```swift
private func tabContainer(for tab: MainTab) -> some View {
    let router = routers[tab] ?? AppRouter()   // routers pre-filled in init via State(initialValue:)
    return BaseNavigationContainer(
        router: router,
        content: { tabRoot(for: tab) },
        destination: { AppRouteView(route: $0) },
        sheet: { AppSheetView(sheet: $0) },
        cover: { _ in EmptyView() }
    )
}
```
Routers are created once: `_routers = State(initialValue: Dictionary(uniqueKeysWithValues: MainTab.allCases.map { ($0, AppRouter()) }))`. `AppSheetView` wraps `.settings` in its own `BaseNavigationContainer` with a fresh `@State AppRouter` so Settings pushes and its nested Paywall/Share sheets live in the Settings router. Hide the nav bar on tab roots with `.toolbar(.hidden, for: .navigationBar)` on `tabRoot` (custom headers remain). Tab bar pill: replace literals `520/14/48/22/11` with `VNLayout.*`; icon and caption use `@ScaledMetric` / `.caption2`; replace `triggerHaptic` with `VNHaptics.impact(enabled:)`. In `AnNienApp` add `.onOpenURL { … }` passing to `MainTabView` through a binding `pendingDeepLink`. Notification-tap routing: in the existing notification delegate (find via `UNUserNotificationCenterDelegate` in `App/Infrastructure`) post the same `DeepLinkHandler.Action` for the memorial tab.
- [ ] **Step 4:** build; the 4 tab roots still reference their old `NavigationStack`/`.sheet` until Phase 2 — to keep the build green, Task 5 leaves those views untouched; only the container is added. (Nested stack is temporary and removed per feature in Tasks 6–10.) Run tests + lint.
- [ ] **Step 5:** commit `feat(navigation): wire per-tab routers, sheet and route views, deep links`.
- [ ] **Phase 1 gate:** full build, `-only-testing:AnNienTests` green, `swiftlint --strict --quiet` exit 0. Tag `git tag phase1-foundation` (local).

---

## PHASE 2 — Feature fanout (5 Opus agents in parallel worktrees)

Each agent: create worktree from `phase1-foundation` (`git worktree add ../Serene-<name> -b feat/ui-<name> phase1-foundation`), `xcodegen generate`, edit **only** its listed files, never `project.yml`/`MainTabView`/`App/Navigation/*`/DesignSystem tokens (if a new shared token is needed, report it instead). Common recipe for every screen:

1. **Navigation:** delete the screen's own `NavigationStack` and `.toolbar(.hidden, …)` when it is a tab root; delete `.sheet(isPresented:)`/`.sheet(item:)`; add `@Environment(AppRouter.self) private var router`; replace presentation with `router.present(sheet: …)`/`router.push(…)`; replace `@Environment(\.dismiss)` in sheet roots with `router.dismiss()`; sheet roots keep a `NavigationStack` only if they need a toolbar and are not inside `AppSheetView`'s container (they are not — `AppSheetView` supplies one for `.settings` only; every other sheet root keeps its own stack for its toolbar).
2. **Gate pattern (replaces `isShowingCreateReminder`/`isShowingPaywall`):** in the ViewModel
```swift
func createReminderGate() async -> CreateReminderGate {
    do { return try await evaluateFeatureGateUseCase.canAddReminder() ? .allowed : .requiresPro }
    catch { return .requiresPro }
}
```
and in the View
```swift
Task {
    switch await viewModel.createReminderGate() {
    case .allowed: router.present(sheet: .reminderForm(editing: nil, initialDate: nil))
    case .requiresPro: router.present(sheet: .paywall)
    }
}
```
Delete the now-unused `isShowing*` properties and `checkAndShowReminderForm`. Update tests that referenced them (none found by grep at plan time).
3. **Spacing:** horizontal margin `VNSpacing.screenMargin`; card inner `VNSpacing.cardPadding`; section gaps `VNSpacing.sectionGap`; every `.frame(minHeight: 44)` → `VNSize.minTapTarget`; snap off-scale literals (5,6→4/8; 14→12/16; 18→16/20; 22→20/24; 28→24/32; 36/40→`VNSize.iconButton` or 32) per the audit table in the spec.
4. **Typography:** replace each `.font(.system(size:))` with a text style (`.caption2/.caption/.footnote/.subheadline/.body/.title3`) or `@ScaledMetric` for numerals/icons, keeping `design: .serif` where it is a ceremonial title. Add `.lineLimit(2).minimumScaleFactor(0.8)` on long Vietnamese labels.
5. **Interaction/a11y:** each `.onTapGesture` row/card → `Button` with the press style from Task 3 + `.accessibilityElement(children: .combine)`; all tappables ≥ `VNSize.minTapTarget`; icon-only buttons get `accessibilityLabel`; haptics via `VNHaptics.impact(enabled:)`.
6. **Verify per task:** build, run the screen in simulator in light/dark and `accessibilityXXXL`, `swiftlint --strict --quiet`, tests green, commit `refactor(<feature>): …`.

### Task 6: Calendar + Today
**Files:** Modify `App/Features/Calendar/CalendarMainView.swift`, `CalendarMainViewModel.swift`, `App/Features/Today/TodayDashboardCard.swift`; read `Packages/VNCalendarKit/Sources/VNCalendarKit/Views/VNCalendarContainerView.swift` and `VNDayDetailBottomSheet.swift` (modify only to remove hard-coded literals and to expose an `onSelectDay`-style callback if one is missing; no BaseNavigationStack import).
- Replace sheets at `CalendarMainView:71-89` (create reminder, paywall, search, settings) with `router.present(sheet:)`; header buttons present `.search` / `.settings`.
- `onAddReminder` from the day-detail sheet: close the package sheet, then run the gate pattern.
- Today card: remove fixed fonts at `TodayDashboardCard:150-165,179,213,275-303,350`; `@ScaledMetric` for the 56pt and 28pt numerals; combine accessibility elements per block.
- Replace the `.fraction(0.92)` detents with `.large` + `.presentationDragIndicator(.visible)` (sheet attributes live in `AppSheetView`; report instead of editing if needed).

### Task 7: Timeline (Ngày Giỗ)
**Files:** Modify `App/Features/Timeline/UpcomingTimelineView.swift`, `UpcomingTimelineViewModel.swift`, `Components/MemorialTimelineCard.swift`, `MemorialHeroCard.swift`, `MemorialEmptyStateView.swift`; Tests `Tests/UpcomingTimelineViewModelTests.swift`.
- Sheets at `UpcomingTimelineView:41-64` → router (`.reminderForm(editing:…)`, `.paywall`, `.ritual(title:)`). Remove the hand-rolled `Binding` for `selectedRitualTitle`.
- `MemorialTimelineCard:84-86` `.onTapGesture` → `Button` + press style.
- Delete `MemorialEmptyStateView` and use `VNEmptyState` (check call sites first with grep; keep the Vietnamese copy).
- Update `UpcomingTimelineViewModelTests` for `createReminderGate()` (free tier → `.requiresPro`, pro → `.allowed`, throwing repo → `.requiresPro`).

### Task 8: Family (Gia Tộc)
**Files:** Modify `App/Features/Family/FamilyHierarchyView.swift`, `FamilyHierarchyViewModel.swift`.
- Sheets at `:44-61` → router; member rows at `:264,:300` become `Button`s with 44pt target and `accessibilityLabel` (name + relation).
- Remove literal `28` at `:288`; `.white` already replaced in Task 2.
- Add a unit test `Tests/FamilyHierarchyViewModelTests.swift` for `createReminderGate()` using mocks copied from `UpcomingTimelineViewModelTests` (repeat the mock classes; do not share).

### Task 9: Articles (Văn Khấn tab)
**Files:** Modify `App/Features/Articles/CulturalArticlesView.swift`, `CulturalArticlesViewModel.swift`.
- `.sheet(item: selectedHoliday)` at `:52-54` → `router.present(sheet: .holiday(holiday))`; `HolidayDetailSheet` (defined `:294`) close button → shared `VNDismissButton` trailing + `router.dismiss()`.
- Clean 10 literals; replace haptic at `:387`.
- Keep `PrayerLibraryView`/`PrayerDetailView` untouched here (user: do not delete).

### Task 10: Settings + ReminderForm + Paywall + Search + dead-code literals
**Files:** Modify `App/Features/Settings/*`, `App/Features/ReminderForm/**`, `App/Features/Paywall/*`, `App/Features/Search/OmniSearchView.swift`, `OmniSearchViewModel.swift`; token-only edits to `App/Features/Prayers/**` and `AncestralShareCardView.swift`.
- Settings: it is now presented by `AppSheetView` inside its own container, so delete `SettingsView:24`'s `NavigationStack`; five `NavigationLink(destination:)` (`:86,97,109,120,131`) → `router.push(.calendarSettings …)`; `isShowingPaywall` and the Paywall sheet (`:38,:285`) → `router.present(sheet: .paywall)`; export → `.share(text:)` (or keep `ShareSheet` if it needs a `UIViewControllerRepresentable` payload that is not a `String` — then keep it as `sheet(isPresented:)` local and note it in the commit). Margins unified to `screenMargin` (fix the 16/20 mix).
- ReminderForm: chips `ReminderTitleSection:62` get `minHeight: VNSize.minTapTarget` + `.accessibilityAddTraits(isSelected ? .isSelected : [])`; fixed fonts at `ReminderTitleSection:12,29,47,59`, `ReminderCategoryGrid:44-50` → text styles with `lineLimit(2)`; Save button: remove `.disabled` and instead on empty title focus the field and show an inline error row (`accessibilityHint("Nhập tên người được tưởng nhớ trước")`); `.onSubmit` moves focus title → note, with keyboard Done for both; add `ReminderFormViewModel.isDirty` and `.interactiveDismissDisabled(viewModel.isDirty)` + `confirmationDialog("Bỏ thay đổi?")`. Add tests in `Tests/ReminderFormViewModelTests.swift`: `isDirty` false initially, true after title edit, false after save.
- Close buttons: Paywall `:63`, ReminderForm `:72`, Search → `VNDismissButton` trailing.
- Search "create reminder" hop: `router.dismiss()` then in the `Task` after `await Task.yield()` call the gate pattern.
- TipKit: add `App/Features/Main/Tips.swift` with two `Tip`s (add-reminder button, Family tab) shown via `.popoverTip`; configure `Tips.configure()` in `AnNienApp.init`. Do this in the Settings agent's commit series, but only touch `AnNienApp.swift` with a single-line `Tips.configure()` addition and report it to the coordinator to avoid merge conflict.

**Phase 2 merge:** coordinator merges the 5 branches into `feat/ui-redesign-navigation` with `--no-ff`; expected conflicts only in `AnNienApp.swift` (one line). Resolve, then run `xcodegen generate`, full build, all tests, lint.

---

### Task 11A: UI gallery (local + GitHub CI) — added after Phase 2 started
**Why:** screenshots taken by agents live only on the author's simulator; the owner cannot see UI results without running the simulator, and the app has no way to seed data / unlock Pro, so the Pro-only Family tree and filled lists were never captured. Goal: one command locally and one GitHub Actions job that build the app, drive it through every screen in light / dark / accessibility-XXXL, and publish a browsable gallery.

**Files:**
- Create: `App/Infrastructure/UITestSupport.swift` — compiled only for `DEV`/`DEBUG` (`#if DEV || DEBUG`, never in PROD). Reads launch argument `-UITestSeed` (installs deterministic sample reminders, an in-memory store and Pro unlocked) and `-UITestRoute <tab|settings|paywall|search|reminderForm|holiday|ritual>` (routes through the existing `DeepLinkCenter`/`DeepLinkHandler`). Wire it from `AppContainer`/`AnNienApp` with the smallest hook; read both files first.
- Create: `Tests/UITests/UIGalleryTests.swift` — XCUITest class `UIGalleryTests`; a table of screens × variants {light, dark, xxxl}; variants applied through launch arguments (`-AppleInterfaceStyle Dark`, `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXXXL`, `-AppleLanguages (vi)`); each shot is an `XCTAttachment(screenshot:)` named `<screen>--<variant>` with `lifetime = .keepAlways`; scroll-to-bottom shot for XXXL on list screens. Screens: calendar, today-card, timeline (seeded), family tree (seeded, Pro), articles, holiday sheet, ritual sheet, reminder form (empty-title error state), settings, calendar settings, paywall, search.
- Create: `scripts/ui-gallery/build-gallery.sh` — takes an `.xcresult` path and an output dir; exports attachments (`xcrun xcresulttool export attachments --path … --output-path …`), renames to `<screen>--<variant>.png`, writes a self-contained `index.html` (one row per screen, columns light / dark / XXXL, lazy images, relative links, no CDN).
- Create: `scripts/ui-gallery/run-local.sh` — boots simulator `iPhone 16 Pro` (or `$SIM_ID`), runs `xcodebuild test -only-testing:AnNienUITests/UIGalleryTests -resultBundlePath /tmp/ui-gallery.xcresult`, calls `build-gallery.sh`, then `open <out>/index.html`.
- Create: `.github/workflows/ui-gallery.yml` — triggers `pull_request` (paths `App/**`, `Packages/**`, `project.yml`, `Tests/UITests/**`) and `workflow_dispatch`; `macos-15`; reuse the Xcode/xcodegen/SPM-cache steps of `ci.yml`; run the same xcodebuild command; run `build-gallery.sh`; `actions/upload-artifact@v4` name `ui-gallery` (index.html + PNGs) and `ui-gallery-xcresult`; write the screen list and the artifact link to `$GITHUB_STEP_SUMMARY`; on pull requests post/update ONE sticky PR comment (via `actions/github-script`, `GITHUB_TOKEN`, `pull-requests: write`) with the run link and the number of screens captured. No GitHub Pages / external hosting (outward-facing; owner decides later).
- Modify: `project.yml` only if `AnNienUITests` needs the new file included (it already globs `Tests/UITests`) — verify, do not change unless required.

**Rules:** no secrets in files; the seed hook must not exist in PROD builds (verify with `xcodebuild -scheme AnNien-Prod build` compile + `grep` that symbols are absent, or `#if` proof in the report); tests must not use `sleep` beyond `waitForExistence`; the workflow must be validated with `actionlint` if installed (else `python3 -c "import yaml…"` parse) because it cannot run on GitHub until the owner pushes; do NOT push.

**Verify:** (1) `scripts/ui-gallery/run-local.sh` produces ≥ 12 screens × 3 variants and opens a gallery whose images are non-blank (check file sizes > 20 KB and spot-check 3 images by viewing them); (2) the Family tree, Timeline list and Today card show seeded data; (3) PROD scheme still builds; (4) `swiftlint --strict --quiet` exit 0; (5) full `AnNienTests` unaffected. Commit as `test(ui): add UI gallery tests and scripts`, `ci: add ui-gallery workflow`.

## PHASE 3 — Verification

### Task 11: Verify and review
**Files:** none (report to `docs/plans/2026-11-03-ui-redesign-verification.md`).
- [ ] `swiftlint --strict --quiet` → exit 0.
- [ ] `xcodebuild test -scheme AnNien-Dev … -configuration Debug-Development` → all green; record counts.
- [ ] Success-criteria greps (each must print 0 or the documented exceptions):
  - `grep -rn "NavigationStack" App | grep -v "App/Navigation\|sheet roots"` → only sheet roots/`AppSheetView`.
  - `grep -rnE "isShowing(Paywall|CreateReminder|Search|Settings)" App` → 0.
  - `grep -rnE "\.font\(\.system\(size" App` → list remaining, each justified (grid cells exception).
  - `grep -rnE "\.white\b|Color\.white" App Packages/*/Sources` → 0.
  - `grep -rn "import BaseNavigationStack" Packages` → 0.
- [ ] Simulator screenshots (use `axe-ios-simulator` or `xcrun simctl io booted screenshot`) for Calendar, Timeline, Family, Articles, Settings, ReminderForm, Paywall in light, dark, and `accessibilityXXXL`; attach paths to the report. Manually check keyboard + tab pill (`ignoresSafeArea(.keyboard)`), search→form hop, double-tap on rows, free-tier gate.
- [ ] Run `pr-review-toolkit:code-reviewer` over `git diff develop...HEAD`; fix findings; re-run lint/tests.
- [ ] Commit report `docs(plans): add UI redesign verification report`.

## PHASE 4 — Persist

### Task 12: Documentation and memory
**Files:** Modify `DESIGN.md` (palette + token tables, contrast table, spacing rules), `CLAUDE.md` (navigation rules: one router per tab, no `NavigationStack` in tab roots, views call router, VMs return gate results, `VNCalendarKit` free of the library), `docs/design.md` if it duplicates `DESIGN.md`; Create `docs/architecture/09-navigation.md` (route map table, sheet map, deep-link table, router ownership diagram); copy the four audit summaries into `docs/plans/2026-11-03-ui-audit.md`.
- [ ] Write memory files in `/Users/lequangtrongtai/.claude/projects/-Users-lequangtrongtai-orca-Serene/memory/`: `navigation-basenavigationstack.md` (type: project; API gotchas: `present(sheet:)`, domain entities not Hashable → id-based `AppSheet`, popToRoot clears modals) and `design-system-palette-2026-11.md` (type: project; new palette, contrast rule: gold never for text). Add one-line pointers in `MEMORY.md`.
- [ ] Update the claude-mem work_state list `ui-redesign-rituals` to done for this task.
- [ ] Commit `docs: record navigation architecture, palette and UI audit`. Do NOT push; ask the user.

## Self-review (done at plan time)
- Spec §3 → Tasks 4, 5, 6–10; §4 palette/tokens → Tasks 1–2; components → Task 3 and Task 7/10; §5 phases → structure above; §7 criteria → Task 11 greps.
- Type names consistent: `AppRouter`, `AppSheet.reminderForm(editing:initialDate:)`, `CreateReminderGate`, `VNHaptics.impact(_:enabled:)`, `VNSize.minTapTarget`.
- Known soft spots (called out, not hidden): `AppSheet.dayDetail` and `.share` payloads depend on what Tasks 6/10 find; `Holiday.id` type unverified; notification-delegate location unverified; line numbers come from the audits and may drift — executors must re-grep before editing.
