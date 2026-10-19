# Spec: Chuẩn hóa Branch/Release/CI-CD và MVVM + Clean Architecture

- **Ngày**: 2026-10-19
- **Trạng thái**: Draft — chờ duyệt
- **Phạm vi**: (1) Quy trình branch/release/CI-CD; (2) Kiến trúc App layer theo MVVM

---

## 1. Mục tiêu

| # | Mục tiêu | Tiêu chí thành công (kiểm chứng được) |
|---|---|---|
| M1 | Quy trình branch/release rõ ràng, không phụ thuộc thao tác tay | Release từ `main` + tag `v*` chạy end-to-end, có gate test/lint, không có tag nào bị bỏ qua workflow |
| M2 | Release pipeline đúng chuẩn phần mềm | `git tag`/`git ls-remote --tags` có tag; workflow deploy chạy test+lint trước khi đóng gói; changelog TestFlight sinh từ tag, không phải SHA |
| M3 | Loại bỏ PII khỏi repo public | `grep` PII trong `Fastfile` trả về 0 kết quả; giá trị lấy từ biến môi trường |
| M4 | App layer đúng MVVM như CLAUDE.md tuyên bố | Mỗi feature screen có 1 `@Observable @MainActor final class <Feature>ViewModel`; View không còn chứa business logic, không giữ `@State` business |

**Ngoài phạm vi**: snapshot tests mới, redesign UI, migrate StoreKit, thay đổi Domain/Data layer (đã đúng chuẩn).

---

## 2. Hiện trạng (bằng chứng)

### 2.1 Git / Release / CI-CD

| Hạng mục | Hiện trạng | Vấn đề |
|---|---|---|
| Default branch | `develop` trên remote (`origin/HEAD -> origin/develop`), **không có `main`** | `ci.yml` trigger `pull_request: [main, develop]` — nhánh `main` không tồn tại, CI cho PR vào `main` bất khả dụng |
| Tags | `git tag` rỗng; `git ls-remote --tags origin` rỗng | `deploy-testflight.yml` (`push: tags: ['v*']`) và `deploy-appstore.yml` (`push: tags: ['release-*']`) **chưa từng tự trigger**; release chỉ qua `workflow_dispatch` |
| Version | `Config/Shared.xcconfig`: `MARKETING_VERSION = 1.0.0` cố định; `CURRENT_PROJECT_VERSION` bump +1 từ TestFlight | Marketing version không bao giờ tăng; build number lái theo TestFlight, không theo git |
| CI (`ci.yml`) | `macos-15`, setup-xcode, ruby bundler-cache, swiftlint, xcodegen, `fastlane test`, upload artifact | Tốt. Thiếu `xcbeautify --renderer github-actions`; setup-xcode bên thứ ba thay vì `DEVELOPER_DIR` |
| Deploy | `deploy-testflight.yml` và `deploy-appstore.yml` build + upload | **Không chạy test/lint** trước khi đóng gói |
| Submit | `release` lane: `submit_for_review: false`, `automatic_release: false` | Không tự submit/auto-release; thao tác tay trên ASC |
| Changelog | `beta` lane hardcode `"Automated CI/CD build from commit <sha>"` | Tester TestFlight thấy changelog vô nghĩa |
| PII | `fastlane/Fastfile` `release` lane: tên, `+84326718280`, `iletai@hotmail.com` | Repo public — lộ dữ liệu cá nhân |
| `.env` | Tồn tại local, đã ignored đúng | Rủi ro `git add -f`; không có pre-commit guard |
| Signing | Match git private (`git@github.com:iletai/ios-certificates.git`), `readonly(is_ci)` | Đúng chuẩn |
| Community files | Có LICENSE (Apache-2.0), README×3, PRIVACY.md, docs/architecture×8 | Thiếu CONTRIBUTING, SECURITY, CODEOWNERS, CHANGELOG, PR/issue templates |

### 2.2 Kiến trúc App

**Đúng chuẩn** (giữ nguyên):
- Package imports đúng hướng: `VNCalendarDomain` chỉ `Foundation` + `VNCalendarLunar`; `VNCalendarData` có `SwiftData`/`Combine`, không có UI.
- Domain UseCases có logic thật (`GetMonthCalendarUseCase`, `ScheduleReminderUseCase`, `NaturalSearchUseCase`, `EvaluateFeatureGateUseCase`).
- Data dùng `@ModelActor` (`ReminderDataActor`, `HolidayDataActor`), map sang pure domain struct.
- Swift 6 strict concurrency pass; escape có giải trình.

**Sai** (phải sửa):
- **Không có MVVM**: toàn app chỉ có `VNCalendarAdapterViewModel` (adapter lịch). Tất cả `App/Features/**` là Fat View.
- **Business logic trong View**: `UpcomingTimelineView.swift:223-271` chứa `nextOccurrenceDate` + `calculateCountdown`; `:273-282` sort theo ngày lần tới. Không unit-test được.
- **Service Locator**: `AppContainer.shared` được kéo trực tiếp trong View (`UpcomingTimelineView.swift:7`, `CalendarMainView.swift:8`, `SettingsView.swift:12`, `FamilyHierarchyView.swift:13`).
- **Bypass UseCase**: `UpcomingTimelineView.swift:300-323` tự gọi `reminderRepository.deleteReminder` + `notificationEngine.pruneAndSchedule`; `CalendarMainView.swift:301-303` tương tự.
- **Sai layer**: `SubscriptionManager` (StoreKit infra, conformance `SubscriptionRepositoryProtocol`) nằm ở `App/Infrastructure/StoreKit/` thay vì `VNCalendarData`.

---

## 3. Thiết kế

### 3.1 Branch model: Git-Flow rút gọn có `release/*`

```
develop ──┬── feat/*    → PR → develop (squash merge)
          ├── fix/*     → PR → develop
          ├── release/x.y.z → PR → main (chỉ vài commit ổn định cuối)
          └── hotfix/*  → PR → main + back-merge develop
main  ──── tag v X.Y.Z → deploy pipelines
```

| Nhánh | Vai trò | Bảo vệ |
|---|---|---|
| `main` | Production, luôn deploy được | Protected: require PR + CI pass; không push trực tiếp |
| `develop` | Tích hợp, default branch | Protected: require PR + CI pass |
| `feat/*`, `fix/*`, `docs/*`, `ci/*` | Công việc ngắn ngày | — |
| `release/x.y.z` | Đóng băng, chỉ nhận fix; bump `MARKETING_VERSION` tại đây | — |
| `hotfix/x.y.z` | Sửa khẩn cấp từ `main`, tag patch | — |

**Quy tắc**:
- Mọi thay đổi vào `develop`/`main` qua PR; squash merge; tên PR theo Conventional Commits.
- Tag chỉ đặt trên commit của `main`: `vMAJOR.MINOR.PATCH`.
- `release/x.y.z` bump `MARKETING_VERSION` trong `Config/Shared.xcconfig`, merge vào `main`, tag, rồi back-merge `develop`.
- Build number (`CURRENT_PROJECT_VERSION`) do CI lấy từ `github.run_number`, không commit tay.

### 3.2 Version & tag

| Thành phần | Nguồn | Cơ chế |
|---|---|---|
| `MARKETING_VERSION` | `Config/Shared.xcconfig` | Bump trong nhánh `release/*`; 1 source of truth |
| `CURRENT_PROJECT_VERSION` | CI env `GITHUB_RUN_NUMBER` | Truyền qua `xcargs: CURRENT_PROJECT_VERSION=${{ github.run_number }}`; monotonic, không reset |
| Git tag | Script sau khi merge `main` | `scripts/release-tag.sh <version>`: tạo annotated tag `vX.Y.Z`, push |

### 3.3 CI/CD

**PR Quality Gate** (`.github/workflows/ci.yml`, sửa):
- Trigger: `pull_request: [develop, main]`, `push: [develop]`.
- Steps: checkout → ruby/setup-ruby (bundler-cache) → brew xcodegen/swiftlint/xcbeautify → `swiftlint --strict` → `xcodegen generate` → `fastlane test` với `xcbeautify --renderer github-actions`.
- Không đổi cấu trúc ngoài thêm xcbeautify + `DEVELOPER_DIR`.

**Deploy TestFlight** (`.github/workflows/deploy-testflight.yml`, sửa):
- Thêm job gate `lint-and-test` (tái dùng CI steps) `needs` trước job build, hoặc bước test ngay trong job.
- Thêm `workflow_dispatch` input `tag`; validate tag tồn tại.
- Truyền `CURRENT_PROJECT_VERSION=${{ github.run_number }}`.
- Release notes: đọc `fastlane/metadata/vi/release_notes.txt`; nếu trống thì generate từ commit range `git describe --tags --abbrev=0 HEAD^..HEAD` theo Conventional Commits.

**Deploy App Store** (`.github/workflows/deploy-appstore.yml`, sửa):
- Thêm `environment: production` (required reviewer) cho job submit.
- Thêm gate lint+test.
- `fastlane release` truyền `submit_for_review: true`, `automatic_release: true`, `phased_release: true`, `skip_metadata: false` — trừ khi dispatch input override.
- Giữ `cancel-in-progress: false`.

**PII**: chuyển `Fastfile` `release` lane sang đọc `ENV["APP_REVIEW_FIRST_NAME"]`, `APP_REVIEW_LAST_NAME`, `APP_REVIEW_PHONE`, `APP_REVIEW_EMAIL`; fail rõ ràng nếu thiếu.

**Secrets guard**: thêm pre-commit hook (`scripts/check-secrets.sh`) chặn `.p8`, `.p12`, `.mobileprovision`, `Secrets.xcconfig`, `.env` bị staged. Đăng ký qua `git config core.hooksPath .githooks`.

### 3.4 Community files

Thêm (nội dung ngắn, tiếng Anh vì repo public + badge):
- `.github/pull_request_template.md` — checklist: build, test, lint, strings, CHANGELOG.
- `.github/ISSUE_TEMPLATE/bug_report.yml`, `feature_request.yml`.
- `CONTRIBUTING.md` — setup (`xcodegen generate`, `bundle install`), branch naming, Conventional Commits, PR flow.
- `SECURITY.md` — private vulnerability reporting.
- `CODEOWNERS` — `* @iletai`.
- `.github/release.yml` — categories changelog theo label.
- `CHANGELOG.md` — seed `v1.0.0`, sau đó cập nhật theo release.
- Xóa `docs/design.md` (duplicate của `DESIGN.md`), sửa CLAUDE.md trỏ đúng.

### 3.5 MVVM + Clean Architecture

#### 3.5.1 Quy ước

Mỗi feature trong `App/Features/<Feature>/`:
```
<Feature>/
├── <Feature>View.swift
├── <Feature>ViewModel.swift       // @Observable @MainActor final class
└── Components/                    // dumb views, không business logic
```

**ViewModel**:
- `@Observable @MainActor public final class <Feature>ViewModel`.
- Khởi tạo bằng dependency (constructor injection), **không** `AppContainer.shared`.
- Chứa: state (`var reminders: [ReminderEvent] = []`, `var searchQuery`, `var isLoading`, `var errorMessage`) + intent methods (`func load() async`, `func save(_:) async`, `func delete(_:) async`).
- Không import SwiftUI (trừ khi cần type của framework như `Color` — tránh; dùng domain/design-system types).
- Không truy cập `ModelContainer`/SwiftData; chỉ qua repository/UseCase protocol.

**View**:
- `@State private var viewModel: <Feature>ViewModel`.
- `@Environment(AppContainer.self)` chỉ ở root (`AnNienApp`) để tạo viewModel; truyền dependency vào init.
- Không tính toán nghiệp vụ; chỉ bind + hiển thị.
- Subviews nhận dữ liệu thuần (dumb).

**DI**: `AppContainer` giữ nguyên là composition root, nhưng:
- Inject qua `.environment(container)` tại `AnNienApp`.
- View dùng `@Environment(AppContainer.self) private var container` (hoặc nhận trực tiếp trong init của View cha).
- Xóa `AppContainer.shared` usage khỏi View. Giữ `shared` chỉ cho AppIntents/Widget/notification callbacks nếu cần (ngoài View layer), ghi chú rõ.

#### 3.5.2 Chuyển logic nghiệp vụ

| Logic hiện tại | Đích mới |
|---|---|
| `nextOccurrenceDate` (`UpcomingTimelineView.swift:223`) | `ReminderEvent.nextOccurrence(after:calendar:)` — extension trong `VNCalendarDomain/Entities/ReminderEvent.swift` |
| `calculateCountdown` (`:255`) | `ReminderEvent.countdownText(for:)` hoặc `CountdownFormatter` trong Domain |
| Sort theo lần tới (`:273-282`) | `GetUpcomingRemindersUseCase.execute()` trả `[UpcomingReminder]` đã sort + countdown |
| Delete + prune (`:314-323`) | `ScheduleReminderUseCase.delete(id:)` tự gọi repository + `NotificationScheduling` protocol |
| Save + prune (`:300-312`) | `ScheduleReminderUseCase.execute(save:)` tự prune; bỏ block trùng trong View |
| Filter/search (`UpcomingTimelineView:18-28`) | `UpcomingTimelineViewModel.filteredReminders` (pure computed từ state) |

**Domain protocol mới**: `NotificationScheduling` trong `VNCalendarDomain/Repositories/`:
```swift
public protocol NotificationScheduling: Sendable {
    func pruneAndSchedule(reminders: [ReminderEvent]) async throws
}
```
`SmartNotificationEngine` conformance. `ScheduleReminderUseCase` nhận protocol này.

**Lưu ý**: không thêm UseCase cho logic thuần hiển thị (ví dụ format `dd/MM`). Chỉ chuyển logic có quy tắc nghiệp vụ (âm lịch, clamp 30/2, countdown).

#### 3.5.3 Các màn hình cần ViewModel

| Feature | ViewModel | Logic chuyển |
|---|---|---|
| Timeline | `UpcomingTimelineViewModel` | load/sort/filter/search/countdown/delete/save + gate create |
| Calendar | `CalendarMainViewModel` | load month (GetMonthCalendarUseCase), selected date, save/delete + prune |
| Settings | `SettingsViewModel` | backup, sync proverbs, subscription state, legal links |
| Family | `FamilyHierarchyViewModel` | load/sort hierarchy, add/edit/delete |
| Prayers | `PrayerLibraryViewModel` | load categories, filter, detail selection |
| ReminderForm | `ReminderFormViewModel` | validate form, offsets, save |
| OmniSearch | `OmniSearchViewModel` | debounce, NaturalSearchUseCase |
| Paywall | `PaywallViewModel` | product load, purchase/restore |
| Articles | `CulturalArticlesViewModel` | fetch list + cache |

**Ưu tiên triển khai**: Timeline → Calendar → ReminderForm → Settings → Family → Prayers → Search → Paywall → Articles.

#### 3.5.4 Di chuyển `SubscriptionManager`

- Chuyển `App/Infrastructure/StoreKit/SubscriptionManager.swift` → `Packages/VNCalendarData/Sources/VNCalendarData/StoreKit/SubscriptionManager.swift`.
- Thêm dependency `VNCalendarDomain` vào target `VNCalendarData` nếu chưa có (đã có).
- `AppContainer` import `VNCalendarData`, khởi tạo `SubscriptionManager`.
- Kiểm tra `App/Infrastructure/Intents/AnNienIntents.swift` và Widget nếu dùng `SubscriptionManager` trực tiếp — cập nhật import.
- `SubscriptionManager.shared` giữ tạm cho Widget/Intents (ngoài View); ghi `ponytail:` comment nếu chưa inject được ở process extension.

### 3.6 Cập nhật CLAUDE.md

Sửa để khớp thực tế sau refactor:
- Thêm mục "Branch & Release" mô tả Git-Flow rút gọn, tag, versioning.
- Thêm mục "MVVM Convention" mô tả ViewModel + DI.
- Xóa/ sửa `docs/design.md` reference.
- Bổ sung scripts (`build_simulator.sh`, `render_app_icon.py`, `release-tag.sh`).
- Bổ sung `AnNienUITests` target.

---

## 4. Kế hoạch kiểm chứng

| Thay đổi | Kiểm chứng |
|---|---|
| CI sửa | PR vào `develop` chạy được; `swiftlint --strict` pass; `fastlane test` pass |
| Deploy gate | `workflow_dispatch` trên dev branch: job lint+test fail → job deploy bị skip |
| Tag/tag script | `scripts/release-tag.sh 1.0.1` tạo tag local; push lên remote; workflow deploy trigger |
| PII | `grep -rn "iletai@hotmail.com\|+84326718280" fastlane/` → 0 kết quả |
| Version | Sau refactor, build CI có `CURRENT_PROJECT_VERSION == github.run_number`; `MARKETING_VERSION` đọc từ xcconfig |
| MVVM | (a) `grep -rn "AppContainer.shared" App/Features/` → 0 kết quả ngoài AppIntents/extension; (b) `grep -rn "nextOccurrenceDate\|calculateCountdown" App/Features/` → chỉ trong ViewModel; (c) mỗi feature có `<Feature>ViewModel.swift`; (d) unit test cho `UpcomingTimelineViewModel` (filter/sort/delete) và `ReminderEvent.nextOccurrence` |
| Clean Architecture | `xcodebuild test` pass toàn bộ; `swiftlint --strict` pass; package dependency rules giữ nguyên |
| SubscriptionManager move | Widget/Intents build pass; `VNCalendarData` import đúng |

---

## 5. Rủi ro & giảm thiểu

| Rủi ro | Giảm thiểu |
|---|---|
| Refactor ViewModel chạm 9 feature, diff lớn | Làm theo từng feature, mỗi feature 1 PR nhỏ; giữ nguyên behavior UI |
| `@Environment(AppContainer.self)` chưa hỗ trợ iOS 17? | `@Observable` + `.environment` có từ iOS 17 — OK |
| `SubscriptionManager` phụ thuộc `AppContainer`/SwiftData? | Kiểm tra trước khi move; nếu vòng lặp dependency, tách protocol `SubscriptionRepositoryProtocol` (đã có) và chỉ move impl |
| `SmartNotificationEngine` hiện là singleton | Thêm protocol `NotificationScheduling` vào Domain, giữ impl singleton; dần inject |
| Tag workflow có thể ship commit lỗi | Gate lint+test trong deploy workflow |
| `.gitignore` đã đúng nhưng `.env` local có secret | Pre-commit hook + nhắc rotate nếu từng lộ |

---

## 6. Thứ tự thực hiện

1. **Phase 1 — Branch/Release** (không chạm code Swift):
   - Tạo `main` từ `develop`, đổi default branch trên GitHub.
   - Sửa `.github/workflows/*` (branch trigger, gate, changelog, version env).
   - `scripts/release-tag.sh`, `.githooks/pre-commit`, community files.
   - Chuyển PII Fastfile → env.
2. **Phase 2 — Domain extraction**:
   - `ReminderEvent.nextOccurrence`/`countdownText`, `GetUpcomingRemindersUseCase`.
   - `NotificationScheduling`, sửa `ScheduleReminderUseCase`.
   - Unit tests Domain.
3. **Phase 3 — DI + SubscriptionManager**:
   - `.environment(container)`, xóa `AppContainer.shared` khỏi View.
   - Move `SubscriptionManager` → `VNCalendarData`.
4. **Phase 4 — ViewModel theo feature**:
   - Timeline → Calendar → ReminderForm → Settings → Family → Prayers → Search → Paywall → Articles.
5. **Phase 5 — Docs/CLAUDE.md**, xóa `docs/design.md`, cập nhật.

---

## 7. Định nghĩa hoàn thành (DoD)

- [ ] `main` + `develop` tồn tại, protected; PR vào cả hai chạy CI.
- [ ] Tag `v1.0.0` (hoặc tag khởi tạo) tồn tại; deploy workflow trigger được từ tag.
- [ ] Deploy workflow chạy lint+test trước build.
- [ ] Không còn PII trong `fastlane/Fastfile`.
- [ ] `grep AppContainer.shared App/Features` → 0.
- [ ] 9 feature có ViewModel; View không chứa business logic.
- [ ] `SubscriptionManager` nằm trong `VNCalendarData`.
- [ ] `xcodebuild test` + `swiftlint --strict` pass.
- [ ] Unit test cho `ReminderEvent.nextOccurrence` + `UpcomingTimelineViewModel`.
- [ ] CLAUDE.md khớp thực tế; `docs/design.md` đã xóa.
