# UI Redesign + BaseNavigationStack Integration — Design Spec

Date: 2026-11-03 · Status: awaiting review · Executor: Opus subagents

## 1. Goals
1. Move the visual identity away from the "Claude Code" look (warm cream + terracotta) while keeping Vietnamese heritage cues (cinnabar red, chrysanthemum gold).
2. Replace scattered navigation (14 `NavigationStack`, per-VM `isShowingX` flags) with `iletai/BaseNavigationStack` 2.x.
3. Standardise spacing/margins/tap targets/typography through tokens; fix accessibility defects found in the audit.
4. Persist all decisions in `DESIGN.md`, `docs/architecture/09-navigation.md`, memory.

Non-goals: new features, CloudKit/StoreKit/lunar logic changes, touching `VNCalendarLunar`/`VNCalendarDomain`/`VNCalendarData`.

## 2. Audit findings (evidence for scope)
- Navigation: 14 stacks; 4 tab roots use a stack only to hide the nav bar; Paywall presented from 5 places with 5 bool flags; 4 different close-button styles (leading vs trailing); Settings = sheet + stack + 5 pushes + nested Paywall/ShareSheet; no `onOpenURL`, no notification routing.
- Color: dark `vnTextTertiary` contrast 1.5–1.9 (bug); gold `C5A059` 2.3:1 on background (decorative only); `BorderSubtle` 1.6:1; 10 hard-coded `.white`; warm shadow literals in `ReminderHeaderView:16`, `LayoutTokens:45`.
- Typography: fixed-size fonts dominate. Counts differed between audits (~70 in `App/Features` vs 346 repo-wide) — **re-count with one grep before Phase 2**.
- Spacing: `padding`/`cornerRadius` mostly tokenised; off-scale `frame` literals (5,6,14,18,22,28,36,40…); `minHeight: 44` repeated 59×; horizontal margin 16 vs 20 mixed in Settings/CalendarSettings; bottom padding xl vs xxl inconsistent; `MainTabView:63` `ignoresSafeArea(.keyboard)` may hide the pill above keyboard (manual check).
- UX: `.onTapGesture` cards (Timeline, Family, Prayers) have no pressed state; ReminderForm role chips ~28pt; haptic setting honoured in only one place; Save disabled with no reason; Return key no-op; `.fraction(0.92)` sheets; no first-run guidance; `MemorialEmptyStateView` duplicates `VNEmptyState`.

## 3. Navigation design (approach A)
- Dependency: `iletai/BaseNavigationStack` `from: "2.0.0"` added to `project.yml` for the **AnNien app target only**. `VNCalendarKit` and other packages must NOT import it.
- Types live in `App/Navigation/`:
  - `AppRoute: Hashable, Sendable` — push destinations (Settings children: `.calendarSettings, .appearanceLanguage, .dataBackup, .privacySecurity, .about`).
  - `AppSheet: Identifiable, Hashable, Sendable` — `.reminderForm(...)`, `.paywall`, `.search`, `.settings`, `.holiday(...)`, `.ritual(...)`, `.share(...)`, `.dayDetail(...)`. Payloads must be `Sendable`/`Hashable`; pass ids, not models, where models are not `Sendable`.
  - `AppCover` — declared, unused (Paywall decision: **sheet**).
  - `typealias AppRouter = NavigationRouter<AppRoute, AppSheet, AppCover>`.
- One router per tab (`MainTab` enum keys), owned by `@State` in `MainTabView`, wrapped by `BaseNavigationContainer`. Settings sheet content hosts its own container + router for its 5 pushes.
- Tab roots drop their `NavigationStack` and `.toolbar(.hidden)`; custom headers stay.
- Views call `router.present/push/dismiss`; ViewModels keep no router and expose intent only (remove `isShowingPaywall` etc.; the Pro gate returns a decision the View routes on). Respects the MVVM rules in `CLAUDE.md`.
- Sequential modal hops (search → reminder form, day detail → reminder form) must dismiss then present; verify against real library API and add a short async hop only if SwiftUI requires it.
- Single `VNDismissButton`, trailing, used by every sheet.
- Deep links: `onOpenURL` + notification tap route into the matching tab router (memorial → Timeline detail, paywall, settings). Minimal: tab switch + sheet.
- Before coding, Phase 1 must read the real library source (`NavigationRouter`, `BaseNavigationContainer`) and correct any assumption above.
- Out of scope / untouched: `PrayerLibraryView`, `PrayerDetailView`, `AncestralShareCardView` are unreferenced (dead). Left as-is; owner to decide delete/keep.

## 4. Design system changes (`VNCalendarDesignSystem`)
Palette (semantic names unchanged; values replaced). Contrast computed in audit.

Light: Primary `F6F7F4`, Secondary `FFFFFF`, Tertiary `ECEEEA`, Elevated `FFFFFF`; Text `1B1D1F` / `4A4F52` / `6A7074`; Red `B5341D`, DeepPrimary `8F2410`; Gold `C5A059` (decorative only) + new `vnAccentGoldText` `7A5C14`; new Jade `2F6B57`; Warning `9A5300`; Error `B91C1C`; BorderSubtle `DADDD8`; new BorderStrong `8C9296`; RedSurface `F8E6E1`; JadeSurface `E3EFEA`; GoldContainer `F6E7BF` / on `6B4E0E`; new `vnOnAccent` `FFFFFF`.
Dark: Primary `131415`, Secondary `1C1E1F`, Tertiary `26292A`; Text `F2F1EC` / `B4B7B5` / `8E9391`; Red `E8715C`; Gold `E3C781`; Jade `6FBF9F`; Success `5DB67E`; Warning `E9A23B`; Error `F08A82`; `vnOnAccent` `131415`.
Rules: gold never carries text/info icons; verify Tertiary-on-Tertiary pairs ≥4.5 or restrict to large text; re-verify Success on new light background.

Tokens added: `VNSpacing.screenMargin=20`, `cardPadding=16`, `sectionGap=24`; `VNSize.minTapTarget=44`, `iconButton=40`, `iconBadge=24`; `VNLayout.tabBarMaxWidth`, `tabBarBottomInset`. Off-scale literals snap to the nearest token.
Typography: replace `.font(.system(size:))` with text styles or `@ScaledMetric`; Prayer reading text honours the user font-size setting on top of Dynamic Type; min body-ish size 11pt except grid cells (document exception).
Components: unify `.onTapGesture` cards into `Button` + press `ButtonStyle`; merge `MemorialEmptyStateView` into `VNEmptyState`; shared haptic helper honouring the setting; role chips ≥44pt with `.isSelected`; Save-button validation message; Return/`onSubmit`; dirty-form `confirmationDialog`; sheets `.large` + drag indicator; TipKit for two first-run tips.

## 5. Execution plan (Opus subagents)
- **Phase 1 – Foundation (1 agent, sequential, owns all shared files):** `project.yml`, tokens/palette, `VNDismissButton`, press `ButtonStyle`, haptic helper, `App/Navigation/*`, `MainTabView`, `AnNienApp` deep link. Gate: `xcodegen generate`, build, `swiftlint --strict --quiet`, router unit tests (headless, assert `[Route]`/sheet state).
- **Phase 2 – Fanout (5 agents, one worktree each, no shared-file edits):** (a) Calendar + Today, (b) Timeline, (c) Family, (d) Articles, (e) Settings + ReminderForm + Paywall + Search. Each: migrate navigation to router, apply tokens/typography/a11y fixes for its screens, keep ViewModel rules, add/adjust tests.
- **Phase 3 – Verify:** merge worktrees, full build + tests (`AnNien-Dev`), `swiftlint --strict`, light/dark + largest Dynamic Type screenshots on simulator, code review pass.
- **Phase 4 – Persist:** update `DESIGN.md` (§ palette/tokens), `CLAUDE.md` navigation rules, new `docs/architecture/09-navigation.md`, memory entries, audit report in `docs/plans/`.
- Conventional commits per phase on branch `feat/ui-redesign-navigation`; no push without explicit instruction.

## 6. Risks
- Library API differs from README assumptions → Phase 1 reads source first.
- Sheet-to-sheet transitions race → dismiss-then-present with test on device/simulator.
- Palette change touches ~600 colour call sites indirectly → semantic names unchanged, so no call-site edits except `.white` → `vnOnAccent`.
- Strict concurrency: sheet payloads must be `Sendable`.
- Snapshot/UI tests (if any) will need re-baselining.

## 7. Success criteria
Build + tests green; `swiftlint --strict` exit 0; one `NavigationStack` per container (no nested duplicates); zero `isShowing*` flags for presented screens; zero off-scale padding/frame literals outside documented exceptions; all text/UI pairs meet WCAG AA; all tappable controls ≥44pt; works at largest accessibility Dynamic Type without clipping on core screens.
