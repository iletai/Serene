# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**An Niên (Serene)** is an iOS Vietnamese Lunar-Solar and Memorial Calendar app ("Lịch Việt & Ngày Nhớ").
- **Target Platform**: iOS 17.0+
- **Language & Runtime**: Swift 6 (Strict Concurrency `complete`), SwiftUI, SwiftData, WidgetKit, StoreKit 2
- **Project Generator**: XcodeGen (`project.yml`)

---

## Common Development Commands

### Project Generation & Dependencies
- **Generate Xcode project**: `xcodegen generate` (Run after editing `project.yml` or adding/removing files)
- **Install Ruby dependencies**: `bundle install`

### Linting
- **Run SwiftLint**: `swiftlint --strict --quiet`
- **Autocorrect SwiftLint issues**: `swiftlint --fix`

### Testing
- **Run all tests (Fastlane)**: `bundle exec fastlane test`
- **Run all tests (xcodebuild)**:
  ```bash
  # Pick a simulator that exists locally: xcrun simctl list devices available
  xcodebuild test -scheme AnNien-Dev -destination 'platform=iOS Simulator,name=<sim>' -configuration Debug-Development
  ```
- **Run a single test suite / test case**:
  ```bash
  xcodebuild test -scheme AnNien-Dev -destination 'platform=iOS Simulator,name=<sim>' -configuration Debug-Development -only-testing:AnNienTests/<TestSuiteName>/<testMethodName>
  ```

### Build & Release Lanes (Fastlane)
- **Sync code signing (Match)**: `bundle exec fastlane sync_signing type:development` (or `type:appstore`)
- **Build & upload to TestFlight**: `bundle exec fastlane beta`
- **Build & release to App Store**: `bundle exec fastlane release`

---

## High-Level Architecture

The project follows Clean Architecture with a multi-package SPM monorepo structure managed via `project.yml`:

```
Packages/
├── VNCalendarLunar/          # Astronomy algorithms (Jean Meeus & Ho Ngoc Duc, GMT+7, 0 dependencies)
├── VNCalendarDomain/         # Domain entities, Use Cases, Repository interfaces (Pure Swift, no UI/Data imports)
├── VNCalendarData/           # SwiftData models, CloudKit sync, Repository implementations
├── VNCalendarDesignSystem/   # Design tokens (Neo-Minimalism), typography, reusable UI components
└── VNCalendarKit/            # Adapter layer for iletai/SwiftUICalendarView (O(1) dateKey lookup, 6x7 grid)
App/                          # Composition Root (AppContainer), Feature Views, StoreKit Paywall
Extensions/Widget/            # WidgetKit extensions (Small, Medium, Lock Screen)
Config/                       # Build configurations (.xcconfig) & Entitlements
fastlane/                     # Automation lanes (Match, Test, TestFlight, App Store)

External SPM:
  iletai/SwiftUICalendarView  # Calendar grid library wrapped by VNCalendarKit (from 3.1.0)
  iletai/AppUpdateKit         # Force/soft update gating (from 1.1.0), depended on by the AnNien app target
```

### Module Dependency Rules
- `VNCalendarLunar`: No internal or external dependencies.
- `VNCalendarDomain`: Depends only on `VNCalendarLunar`. Must not import SwiftUI, SwiftData, or UIKit.
- `VNCalendarData`: Depends on `VNCalendarDomain` and `VNCalendarLunar`. Implements domain repository protocols with SwiftData/CloudKit.
- `VNCalendarDesignSystem`: Depends on `VNCalendarDomain`.
- `VNCalendarKit`: Depends on `VNCalendarDomain`, `VNCalendarDesignSystem`, `VNCalendarLunar`, and external `iletai/SwiftUICalendarView` (v3.1.0+).
- `AnNien (App)`: Imports all local packages and targets, plus external `iletai/AppUpdateKit` (v1.1.0+) for update gating.
- `AnNienWidget`: Depends on `VNCalendarLunar`, `VNCalendarDomain`, `VNCalendarData`, `VNCalendarDesignSystem`.

---

## Build Configurations & Schemes

| Configuration | Scheme | Bundle Identifier | Compilation Flag | CloudKit Container |
|---|---|---|---|---|
| **Development** | `AnNien-Dev` | `com.iletai.annien.dev` | `DEV` | `iCloud.com.iletai.annien.dev` |
| **Production** | `AnNien-Prod` | `com.iletai.annien` | `PROD` | `iCloud.com.iletai.annien` |

Configuration files are in `Config/`:
- `Shared.xcconfig`: Base deployment target (iOS 17.0), Swift 6, strict concurrency settings.
- `Development.xcconfig`: Dev bundle IDs, dev entitlements, `DEV` condition flag.
- `Production.xcconfig`: Production bundle IDs, prod entitlements, `PROD` condition flag.

---

## Key Core Systems

1. **Lunar Engine (`VNCalendarLunar`)**:
   - Accurate astronomical calculations for Vietnamese lunar calendar (GMT+7 timezone basis).
   - Can Chi, 24 Solar Terms (Tiết Khí), Hoàng Đạo / Hắc Đạo hours, leap month handling.

2. **Calendar UI Adapter (`VNCalendarKit`)**:
   - Adapts `iletai/SwiftUICalendarView` using fixed 42-cell (6x7) matrix to prevent layout shift.
   - O(1) cell lookup via integer `dateKey` (`YYYYMMDD`).

3. **Smart Notification Engine**:
   - Manages iOS 64 pending notification quota: schedules top 60 prioritized alerts + 4 system reserve slots.
   - Applies time-decay hyperbolic score: `priority × offsetWeight × 1/(1 + 0.05 × daysUntil)`, where `offsetWeight` is `1.0` for the day-of event and `1.0/(abs(offset)+1)` for each advance reminder offset.
   - Handles boundary conditions: automatically shifts 30th lunar day memorials to 29th in short months.

4. **Offline-First & microCMS Synchronization**:
   - Local fallback via `bundled_holidays.json` bundled in the app.
   - ETag-based caching (`If-None-Match`) for incremental content updates from microCMS.

5. **StoreKit 2 Monetization & Feature Gating**:
   - Products: Monthly (`com.iletai.annien.sub.monthly`), Yearly (`com.iletai.annien.sub.yearly`), Lifetime (`com.iletai.annien.nonconsumable.lifetime`).
   - Free tier: Up to 5 memorial dates, small widget.
   - Pro tier: Unlimited dates, CloudKit sync, family heritage mode, medium & lock screen widgets.

---

## Code & Quality Guidelines

### Mandatory Quality Gate
- Before any commit, push, or PR: run `swiftlint --strict --quiet` and require exit 0. Warnings fail under `--strict`.
- Do not rely on local SwiftLint being old: CI pins nothing (`brew install swiftlint` = latest). If local version differs from CI, trust CI and re-check after `brew upgrade swiftlint`.
- A local pre-commit hook (`.git/hooks/pre-commit`) enforces this; never bypass with `git commit --no-verify`.

- **Swift Version**: Swift 6 with complete concurrency checking (`SWIFT_STRICT_CONCURRENCY = complete`).
- **SwiftLint Rules**: Strict linting enforced in CI (`.swiftlint.yml`). Key constraints:
  - Max line length: 140 (warning) / 200 (error)
  - Max function body length: 60 (warning) / 100 (error)
  - Max type body length: 300 (warning) / 500 (error)
  - Max cyclomatic complexity: 10 (warning) / 20 (error)
  - Disallowed: Force unwrapping, implicitly unwrapped optionals.
- **Design System (`DESIGN.md`)**:
  - Canonical values: `Packages/VNCalendarDesignSystem/Sources/VNCalendarDesignSystem/Tokens/ColorTokens.swift`. `DESIGN.md` documents the same tokens.
  - Key tokens: New Rice Ivory (`#FEF9F1`), Woven Linen (`#F8F3EB`), Deep Calligraphic Ink (`#1D1C17`), Hearth Ash (`#59413C`), Cinnabar Lacquer Red (`#C23B22`), Imperial Chrysanthemum Gold (`#C5A059`).
  - Typography: Apple New York Serif (ceremonial titles, dates) + SF Pro (matrix numerals, body).
