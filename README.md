<div align="center">

# An Niên (Serene) — Lịch Việt & Ngày Nhớ

[ **English** ](README.md) · [ **Tiếng Việt** ](README.vi.md) · [ **日本語** ](README.ja.md)

<p align="center">
  <img src="docs/assets/banner.svg" alt="An Niên Banner" width="100%">
</p>

[![CI](https://github.com/iletai/Serene/actions/workflows/ci.yml/badge.svg)](https://github.com/iletai/Serene/actions)
[![Swift 6](https://img.shields.io/badge/Swift-6.0-orange.svg?style=flat&logo=swift)](https://swift.org)
[![iOS 17.0+](https://img.shields.io/badge/iOS-17.0%2B-blue.svg?style=flat&logo=apple)](https://developer.apple.com/ios/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

An Niên is a native iOS application built with SwiftUI, SwiftData, and WidgetKit, combining accurate Vietnamese Lunar-Solar astronomical calculations with a smart memorial and ritual tracking system. Designed with Neo-Minimalist aesthetics, Apple New York typography, and strict Swift 6 concurrency.

[Key Features](#-key-features) · [Architecture](#-architecture) · [Getting Started](#-getting-started) · [License](#-license)

</div>

---

## 📱 Screenshots

<div align="center">
  <img src="docs/assets/screenshots/calendar.png" alt="Calendar Grid" width="28%">&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="docs/assets/screenshots/memorial.png" alt="Memorial Manager" width="28%">&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="docs/assets/screenshots/widget.png" alt="Widgets" width="28%">
</div>

---

## ✨ Key Features

- **Lunar Engine (`VNCalendarLunar`)**: High-precision astronomical calculations based on Jean Meeus & Ho Ngoc Duc algorithms with GMT+7 timezone basis. Computes Can Chi (Stem-Branch), 24 Solar Terms (Tiết Khí), auspicious/inauspicious hours (Hoàng Đạo / Hắc Đạo), and leap months with zero external dependencies.
- **Calendar UI Adapter (`VNCalendarKit`)**: High-performance grid wrapper around `iletai/SwiftUICalendarView` featuring a fixed 42-cell matrix preventing layout shifts and O(1) integer `dateKey` (`YYYYMMDD`) lookup.
- **Smart Notification Engine**: Manages the iOS 64 pending notification quota by prioritizing the top 60 alerts plus 4 system reserves using a time-decay hyperbolic score:
  $$\text{Score} = \text{priority} \times \text{offsetWeight} \times \frac{1}{1 + 0.05 \times \text{daysUntil}}$$
  Automatically handles boundary edge cases such as shifting 30th lunar day memorials to the 29th in short months.
- **Memorials & Rituals Tracker**: Tracks death anniversiversary dates (ngày giỗ), traditional Vietnamese rituals, and offerings with offline-first local fallback and ETag-based microCMS incremental synchronization.
- **StoreKit 2 Monetization**: Native monetization supporting Monthly (`com.iletai.annien.sub.monthly`), Yearly (`com.iletai.annien.sub.yearly`), and Lifetime (`com.iletai.annien.nonconsumable.lifetime`) purchases, gating unlimited memorial dates, family heritage mode, and advanced lock-screen widgets.

---

## 🏛️ Architecture

An Niên follows Clean Architecture principles structured as a modular SPM monorepo managed via XcodeGen (`project.yml`):

```
Packages/
├── VNCalendarLunar/          # Astronomical calculations (0 dependencies)
├── VNCalendarDomain/         # Domain entities, use cases, & repository protocols
├── VNCalendarData/           # SwiftData models & repository implementations
├── VNCalendarDesignSystem/   # Neo-minimalist design tokens & UI components
└── VNCalendarKit/            # Calendar view adapters & grid layout
App/                          # Composition Root (AppContainer), Feature Views, StoreKit Paywall
Extensions/Widget/            # WidgetKit extensions (Small, Medium, Lock Screen)
Config/                       # Build configurations (.xcconfig) & Entitlements
```

### Dependency Rules
- `VNCalendarLunar`: No internal or external dependencies.
- `VNCalendarDomain`: Depends only on `VNCalendarLunar`. No SwiftUI/SwiftData imports.
- `VNCalendarData`: Depends on `VNCalendarDomain` and `VNCalendarLunar`.
- `VNCalendarDesignSystem`: Depends on `VNCalendarDomain`.
- `VNCalendarKit`: Depends on `VNCalendarDomain`, `VNCalendarDesignSystem`, `VNCalendarLunar`, and external `iletai/SwiftUICalendarView`.
- `AnNien (App)`: Imports all local packages and external `iletai/AppUpdateKit`.

---

## 🚀 Getting Started

### Prerequisites
- macOS 14.0+
- Xcode 15.4+ with Swift 6 compiler
- XcodeGen (`brew install xcodegen`)
- Bundler (`bundle install`)

### Setup & Build
1. Clone the repository:
   ```bash
   git clone https://github.com/iletai/Serene.git
   cd Serene
   ```
2. Generate the Xcode project:
   ```bash
   xcodegen generate
   ```
3. Run tests via fastlane or xcodebuild:
   ```bash
   bundle exec fastlane test
   ```

---

## 📄 License

Distributed under the MIT License. See [LICENSE](LICENSE) for more information.
