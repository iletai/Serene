# Plan 1 — Branch/Release/CI-CD Chuẩn Hóa

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Sửa và chuẩn hóa pipeline CI/CD: branch model Git-Flow rút gọn, release gate, version/tag, changelog, PII, secret-guard, community files, và fix 2 lỗi SwiftLint có sẵn.

**Architecture:** GitHub Actions `ci.yml` (gate), `deploy-testflight.yml` (tag `v*` → gate → beta), `deploy-appstore.yml` (tag `release-*` → gate → environment `production` → submit). Fastlane giữ Match + ASC API key. Changelog từ `fastlane/metadata/vi/release_notes.txt` fallback về commit range Conventional Commits.

**Tech Stack:** GitHub Actions (macos-15), Fastlane (Match, ASC API key), XcodeGen, SwiftLint, bash, git hooks.

**Spec:** `docs/specs/2026-10-19-workflow-and-mvvm-standards-design.md` §3.1–3.4, §4, §6 Phase 1.

## Global Constraints

- Runner `macos-15`; Ruby 3.3; bundle cache.
- `swiftlint --strict --quiet` phải pass toàn repo trước khi commit bất cứ thứ gì Swift.
- Không push lên `origin/develop` trừ khi user xác nhận (Branch Management: push chỉ khi được yêu cầu).
- Marketing version bump trong nhánh `release/*`; build number = `github.run_number`.
- Repo public — không commit PII, secret, cert.
- `MARKETING_VERSION`/`CURRENT_PROJECT_VERSION` vẫn ở `Config/Shared.xcconfig` (không đổi vị trí).

## Review Focus

Những input/failure mode không được task tests cover, dễ "cắn" người dùng thật:

1. **Tag trên sai commit** — tag `v*` trỏ vào commit chưa qua CI → deploy ship code lỗi. → Task 2: gate job lint+test trước job deploy.
2. **Workflow_dispatch trên branch rác** — ai đó dispatch deploy từ `feat/...` thay vì `main`. → Task 2: validate ref name.
3. **PR vào `main` không chạy CI** — `main` chưa tồn tại → không branch protection được. → Task 3: tạo `main` từ develop, đổi default branch.
4. **PII hồi quy** — ai đó hardcode lại review info. → Task 4: Fastlane fail rõ ràng nếu env thiếu (pre-commit secret guard chặn file staged).
5. **`--no-verify` che lỗi lint** — commit có lint error vẫn vào được. → Task 1: fix 2 lỗi SwiftLint có sẵn; sau đó pre-commit hook thật sẽ chặn lỗi mới.
6. **Changelog fallback rỗng** — tag mới, chưa có tag trước, `git describe` fail → changelog trống. → Task 5: fallback cứng khi range trống.

---

### Task 1: Fix 2 lỗi SwiftLint có sẵn trong `SmartNotificationEngine.swift`

**Files:**
- Modify: `App/Infrastructure/Notifications/SmartNotificationEngine.swift:174-275` (`collectCandidates`, body 89 dòng)
- Modify: `App/Infrastructure/Notifications/SmartNotificationEngine.swift:344` (large tuple `requestedMonths: [(day: Int, month: Int, isLeap: Bool)]`)

**Interfaces:**
- Consumes: `NotificationCandidate`, `NotificationCandidate` fields, `MemorialEvent.advanceOffsets`.
- Produces: giữ nguyên public API; chỉ tách helper private + đổi tuple sang type.

- [ ] **Step 1: Tách hàm build text cho offset==0 thành helper private**

Mở file, tìm `collectCandidates` (bắt đầu dòng 174). Khối `if offset == 0 { titleText = ...; subtitleText = ... } else { ... }` dài dòng 220-252. Tách thành helper:

```swift
// Thêm private func trong SmartNotificationEngine class, ngay trước collectCandidates
private func copyText(
    key: String,
    args: [CVarArg],
    bundle: Bundle
) -> String {
    let raw = bundle.localizedString(forKey: key, value: nil, table: nil)
    let fmt: String
    if raw == key {
        switch key {
        case "notif.today_title": fmt = "Hôm nay là %@"
        case "notif.today_body_lunar": fmt = "Ngày %lld/%lld Âm lịch - %@"
        case "notif.today_body_lunar_clamped": fmt = "Ngày %lld/%lld ÂL (Tháng thiếu 29 ngày) - %@"
        case "notif.today_body_solar": fmt = "Ngày %lld/%lld Dương lịch - %@"
        case "notif.upcoming_title": fmt = "Sắp đến %@ (Còn %lld ngày)"
        case "notif.upcoming_body_lunar": fmt = "Sự kiện vào ngày %lld/%lld ÂL - %@"
        case "notif.upcoming_body_solar": fmt = "Sự kiện vào ngày %lld/%lld Dương lịch - %@"
        default: fmt = key
        }
    } else {
        fmt = raw
    }
    return String(format: fmt, arguments: args)
}

private func notificationTexts(
    for event: MemorialEvent,
    occ: TriggerOccurrence,
    offset: Int,
    bundle: Bundle
) -> (title: String, body: String) {
    var titleText = ""
    var subtitleText = ""
    // ... dán lại body cũ dùng copyText(...) thay vì copy(...)
    // return (titleText, subtitleText)
}
```

- [ ] **Step 2: Gọi helper trong `collectCandidates`, xóa body cũ**

Thay dòng 220-252 bằng:

```swift
let texts = notificationTexts(for: event, occ: occ, offset: offset, bundle: Self.activeBundle)
titleText = texts.title
subtitleText = texts.body
```

- [ ] **Step 3: Fix large tuple — dùng enum hoặc struct nhỏ**

Dòng 344: `let requestedMonths: [(day: Int, month: Int, isLeap: Bool)]`. Đổi sang:

```swift
// Thêm fileprivate/private struct trong file
private struct LeapMonthRequest: Sendable {
    let day: Int
    let month: Int
    let isLeap: Bool
}
```

Sửa khai báo: `var requestedMonths: [LeapMonthRequest] = []`. Sửa các gán: `[(event.day, event.month, false)]` → `[LeapMonthRequest(day: event.day, month: event.month, isLeap: false)]`, tương tự case `.both`, `.leapOnly`, `.adaptiveFallback`. Dòng 363 `let reqLunar = LunarDate(day: request.day, month: request.month, year: targetYear, isLeapMonth: request.isLeap)` giữ nguyên (đã đúng tên property).

- [ ] **Step 4: Run swiftlint**

Run: `swiftlint --strict --quiet`
Expected: 0 error. Nếu còn, tiếp tục tách helper.

- [ ] **Step 5: Build nhanh xác nhận không vỡ compile**

Run: `xcodebuild build -scheme AnNien-Dev -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -configuration Debug-Development | xcbeautify 2>/dev/null || xcodebuild build -scheme AnNien-Dev -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -configuration Debug-Development`
Expected: **BUILD SUCCEEDED**.

- [ ] **Step 6: Commit**

```bash
git add App/Infrastructure/Notifications/SmartNotificationEngine.swift
git commit -m "fix: reduce SmartNotificationEngine complexity to satisfy SwiftLint"
```

---

### Task 2: Sửa workflow CI + 2 deploy workflow

**Files:**
- Modify: `.github/workflows/ci.yml`
- Modify: `.github/workflows/deploy-testflight.yml`
- Modify: `.github/workflows/deploy-appstore.yml`

**Interfaces:**
- Consumes: `fastlane/Fastfile` lanes `test`, `beta`, `release`.
- Produces: workflow jobs và env vars (`GITHUB_RUN_NUMBER`, `APP_REVIEW_*`) mà Task 3/4/5 đọc.

- [ ] **Step 1: Sửa `ci.yml` — thêm xcbeautify + fix trigger**

Thay `ci.yml` toàn bộ bằng:

```yaml
name: CI - PR & Build Tests

on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [develop, main]
  workflow_dispatch:

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  lint-and-test:
    name: Lint & Test
    runs-on: macos-15
    timeout-minutes: 30

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Select latest stable Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: latest-stable

      - name: Setup Ruby and Bundler
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.3'
          bundler-cache: true

      - name: Install Tooling
        run: |
          which xcodegen || brew install xcodegen
          which swiftlint || brew install swiftlint
          which xcbeautify || brew install xcbeautify

      - name: SwiftLint Verification
        run: swiftlint --strict --quiet

      - name: Generate Xcode Project
        run: xcodegen generate

      - name: SPM Dependency Cache
        uses: actions/cache@v4
        with:
          path: ~/Library/Developer/Xcode/DerivedData/**/SourcePackages
          key: ${{ runner.os }}-spm-${{ hashFiles('**/Package.resolved', 'project.yml') }}
          restore-keys: |
            ${{ runner.os }}-spm-

      - name: Run Unit & Integration Tests
        run: set -o pipefail && bundle exec fastlane test 2>&1 | xcbeautify --renderer github-actions
        env:
          FASTLANE_XCODEBUILD_SETTINGS_TIMEOUT: 120

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: fastlane/test_output
```

- [ ] **Step 2: Sửa `deploy-testflight.yml` — thêm gate + version env + changelog từ tag**

Thay `deploy-testflight.yml` toàn bộ bằng:

```yaml
name: Deploy - TestFlight Beta

on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:

concurrency:
  group: deploy-testflight-${{ github.ref }}
  cancel-in-progress: false

jobs:
  gate:
    name: Lint & Test
    runs-on: macos-15
    timeout-minutes: 30
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4
      - name: Select latest stable Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: latest-stable
      - name: Setup Ruby and Bundler
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.3'
          bundler-cache: true
      - name: Install Tooling
        run: |
          which xcodegen || brew install xcodegen
          which swiftlint || brew install swiftlint
          which xcbeautify || brew install xcbeautify
      - name: SwiftLint Verification
        run: swiftlint --strict --quiet
      - name: Generate Xcode Project
        run: xcodegen generate
      - name: Run Unit & Integration Tests
        run: set -o pipefail && bundle exec fastlane test 2>&1 | xcbeautify --renderer github-actions

  deploy-testflight:
    name: Build & Distribute TestFlight
    needs: gate
    runs-on: macos-15
    timeout-minutes: 45
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Select latest stable Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: latest-stable

      - name: Setup Ruby and Bundler
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.3'
          bundler-cache: true

      - name: Install Tooling
        run: which xcodegen || brew install xcodegen

      - name: Generate Xcode Project
        run: xcodegen generate

      - name: Setup SSH for Match Git Repository
        uses: webfactory/ssh-agent@v0.9.0
        with:
          ssh-private-key: ${{ secrets.MATCH_SSH_KEY }}

      - name: Deploy to TestFlight via Fastlane
        run: bundle exec fastlane beta
        env:
          ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}
          ASC_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
          ASC_KEY_CONTENT_BASE64: ${{ secrets.ASC_KEY_CONTENT_BASE64 }}
          MATCH_GIT_URL: ${{ secrets.MATCH_GIT_URL }}
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
          APPLE_ID: ${{ secrets.APPLE_ID }}
          APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
          APPLE_ITC_TEAM_ID: ${{ secrets.APPLE_ITC_TEAM_ID }}
          FASTLANE_KEYCHAIN_PASSWORD: ${{ secrets.FASTLANE_KEYCHAIN_PASSWORD }}
          GITHUB_SHA: ${{ github.sha }}
          GITHUB_RUN_NUMBER: ${{ github.run_number }}
          RELEASE_NOTES_FILE: fastlane/metadata/vi/release_notes.txt
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Verify IPA Was Produced
        run: |
          test -s build/AnNien-Beta.ipa || { echo "::error::build/AnNien-Beta.ipa missing"; exit 1; }
          ls -lh build/AnNien-Beta.ipa

      - name: Upload IPA Artifact
        uses: actions/upload-artifact@v4
        with:
          name: AnNien-Beta-${{ github.sha }}
          path: build/AnNien-Beta.ipa
          retention-days: 14
```

- [ ] **Step 3: Sửa `deploy-appstore.yml` — thêm gate + environment production + submit mặc định**

Thay `deploy-appstore.yml` toàn bộ bằng:

```yaml
name: Deploy - App Store Release

on:
  push:
    tags:
      - 'release-*'
  workflow_dispatch:
    inputs:
      skip_metadata:
        description: 'Skip uploading metadata to App Store Connect'
        required: false
        type: boolean
        default: false

concurrency:
  group: deploy-appstore-${{ github.ref }}
  cancel-in-progress: false

jobs:
  gate:
    name: Lint & Test
    runs-on: macos-15
    timeout-minutes: 30
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4
      - name: Select latest stable Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: latest-stable
      - name: Setup Ruby and Bundler
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.3'
          bundler-cache: true
      - name: Install Tooling
        run: |
          which xcodegen || brew install xcodegen
          which swiftlint || brew install swiftlint
          which xcbeautify || brew install xcbeautify
      - name: SwiftLint Verification
        run: swiftlint --strict --quiet
      - name: Generate Xcode Project
        run: xcodegen generate
      - name: Run Unit & Integration Tests
        run: set -o pipefail && bundle exec fastlane test 2>&1 | xcbeautify --renderer github-actions

  deploy-appstore:
    name: Build & Submit to App Store
    needs: gate
    runs-on: macos-15
    timeout-minutes: 45
    environment: production
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Select latest stable Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: latest-stable

      - name: Setup Ruby and Bundler
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.3'
          bundler-cache: true

      - name: Install Tooling
        run: which xcodegen || brew install xcodegen

      - name: Generate Xcode Project
        run: xcodegen generate

      - name: Setup SSH for Match Git Repository
        uses: webfactory/ssh-agent@v0.9.0
        with:
          ssh-private-key: ${{ secrets.MATCH_SSH_KEY }}

      - name: Capture Screenshots via Simulator
        run: bundle exec fastlane capture_screenshots_only

      - name: Upload Screenshots Artifact
        uses: actions/upload-artifact@v4
        with:
          name: Screenshots-${{ github.sha }}
          path: fastlane/screenshots/vi/*.png
          retention-days: 14

      - name: Deploy to App Store via Fastlane
        run: bundle exec fastlane release
        env:
          ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}
          ASC_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
          ASC_KEY_CONTENT_BASE64: ${{ secrets.ASC_KEY_CONTENT_BASE64 }}
          MATCH_GIT_URL: ${{ secrets.MATCH_GIT_URL }}
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
          APPLE_ID: ${{ secrets.APPLE_ID }}
          APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
          APPLE_ITC_TEAM_ID: ${{ secrets.APPLE_ITC_TEAM_ID }}
          FASTLANE_KEYCHAIN_PASSWORD: ${{ secrets.FASTLANE_KEYCHAIN_PASSWORD }}
          GITHUB_SHA: ${{ github.sha }}
          GITHUB_RUN_NUMBER: ${{ github.run_number }}
          SKIP_METADATA: ${{ inputs.skip_metadata != null && inputs.skip_metadata || 'false' }}
          APP_REVIEW_FIRST_NAME: ${{ secrets.APP_REVIEW_FIRST_NAME }}
          APP_REVIEW_LAST_NAME: ${{ secrets.APP_REVIEW_LAST_NAME }}
          APP_REVIEW_PHONE: ${{ secrets.APP_REVIEW_PHONE }}
          APP_REVIEW_EMAIL: ${{ secrets.APP_REVIEW_EMAIL }}

      - name: Upload Screenshots to App Store Connect
        run: bundle exec fastlane upload_screenshots
        env:
          ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}
          ASC_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
          ASC_KEY_CONTENT_BASE64: ${{ secrets.ASC_KEY_CONTENT_BASE64 }}

      - name: Verify IPA Was Produced
        run: |
          test -s build/AnNien-Release.ipa || { echo "::error::build/AnNien-Release.ipa missing"; exit 1; }
          ls -lh build/AnNien-Release.ipa

      - name: Upload IPA Artifact
        uses: actions/upload-artifact@v4
        with:
          name: AnNien-Release-${{ github.sha }}
          path: build/AnNien-Release.ipa
          retention-days: 14
```

- [ ] **Step 4: Validate YAML**

Run: `python3 -c "import yaml,sys; yaml.safe_load(open('.github/workflows/ci.yml')); yaml.safe_load(open('.github/workflows/deploy-testflight.yml')); yaml.safe_load(open('.github/workflows/deploy-appstore.yml')); print('YAML OK')"`
Expected: `YAML OK`.

- [ ] **Step 5: Commit**

```bash
git add .github/workflows/ci.yml .github/workflows/deploy-testflight.yml .github/workflows/deploy-appstore.yml
git commit -m "ci: add lint+test gate to deploy workflows, fix branches, submit env"
```

---

### Task 3: Tạo `main` + sửa CLAUDE.md branch model

**Files:**
- Create: `scripts/release-tag.sh`
- Modify: `CLAUDE.md` (mục Branch & Release mới, xóa mâu thuẫn docs/design.md)
- Delete: `docs/design.md`

**Interfaces:**
- Consumes: Task 2 workflow (cần `main` để PR gate hoạt động).
- Produces: script `scripts/release-tag.sh <version>` để tạo tag.

- [ ] **Step 1: Tạo nhánh `main` từ develop (local)**

```bash
git checkout develop
git pull origin develop
git checkout -b main
git checkout develop
```

Chưa push lên remote (cần user xác nhận Branch Management).

- [ ] **Step 2: Viết `scripts/release-tag.sh`**

```bash
#!/usr/bin/env bash
# Create and push an annotated release tag. Usage: scripts/release-tag.sh 1.0.0
set -euo pipefail
VERSION="${1:?Usage: scripts/release-tag.sh <major.minor.patch>}"
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "error: version must match MAJOR.MINOR.PATCH" >&2; exit 1
fi
git checkout main && git pull origin main
echo "Creating release tag v$VERSION on $(git rev-parse --short HEAD)"
git tag -a "v$VERSION" -m "Release v$VERSION"
git push origin "v$VERSION"
echo "Tag v$VERSION pushed. Workflows deploy-testflight will trigger."
```

- [ ] **Step 3: Sửa CLAUDE.md — thêm Branch & Release, xóa mâu thuẫn docs/design.md**

Thêm section sau "Common Development Commands":

```markdown
## Branch & Release

**Branch model** (Git-Flow rút gọn):
- `main` — production, luôn deploy được, protected: require PR + CI pass.
- `develop` — tích hợp, default branch, protected: require PR + CI pass.
- `feat/*`, `fix/*`, `docs/*`, `ci/*` — công việc ngắn ngày, PR vào `develop`.
- `release/x.y.z` — đóng băng, bump `MARKETING_VERSION` trong `Config/Shared.xcconfig`, PR vào `main`.
- `hotfix/x.y.z` — sửa khẩn cấp từ `main`, back-merge `develop`.

**Release flow**:
1. Trên nhánh `release/x.y.z`: bump `MARKETING_VERSION = x.y.z` trong `Config/Shared.xcconfig`, commit.
2. PR `release/x.y.z` → `main`, merge (squash).
3. Chạy `scripts/release-tag.sh x.y.z` để tạo tag `vx.y.z` và push.
4. Tag `v*` trigger `deploy-testflight.yml` (TestFlight).
5. Tạo tag `release-x.y.z` trên cùng commit nếu muốn `deploy-appstore.yml` (App Store).

**Versioning**: `MARKETING_VERSION` bump tay trong `release/*`; `CURRENT_PROJECT_VERSION` do CI lấy `github.run_number`.
```

Xóa dòng trỏ `docs/design.md` (duplicate của `DESIGN.md`). Sửa mục Test để bổ sung `AnNienUITests`.

- [ ] **Step 4: Xóa `docs/design.md`**

```bash
git rm docs/design.md
```

- [ ] **Step 5: Verify CLAUDE.md không còn tham chiếu `docs/design.md`**

Run: `grep -n "docs/design.md" CLAUDE.md || echo "CLEAN"`
Expected: `CLEAN`.

- [ ] **Step 6: Commit**

```bash
git add scripts/release-tag.sh CLAUDE.md docs/design.md
git commit -m "docs: standardize branch/release model, add release-tag script"
```

---

### Task 4: PII → env trong Fastfile + secret guard

**Files:**
- Modify: `fastlane/Fastfile:180-198` (`release` lane)
- Modify: `fastlane/Fastfile:127-151` (`beta` lane — changelog từ tag)
- Create: `.githooks/pre-commit`
- Create: `scripts/check-secrets.sh`

**Interfaces:**
- Consumes: env `APP_REVIEW_*`, `GITHUB_RUN_NUMBER`, `RELEASE_NOTES_FILE`, `GITHUB_TOKEN` (Task 2).
- Produces: biến môi trường mới; pre-commit hook chặn secret.

- [ ] **Step 1: Sửa `release` lane — PII từ env, fail rõ ràng nếu thiếu**

Thay dòng 180-186 (hardcode) bằng:

```ruby
    app_review_info = {
      first_name: ENV.fetch("APP_REVIEW_FIRST_NAME"),
      last_name: ENV.fetch("APP_REVIEW_LAST_NAME"),
      phone_number: ENV.fetch("APP_REVIEW_PHONE"),
      email_address: ENV.fetch("APP_REVIEW_EMAIL"),
      notes: "App tra cứu Lịch Âm Dương và Quản lý Ngày Nhớ. Ứng dụng không yêu cầu đăng nhập tài khoản."
    }
```

- [ ] **Step 2: Sửa `beta` lane — changelog từ release_notes.txt, fallback commit range**

Thay dòng 143-144 bằng:

```ruby
    changelog_text = options[:changelog]
    if changelog_text.nil? && !is_ci
      changelog_text = prompt(text: "Changelog: ")
    end
    changelog_text ||= if ENV["RELEASE_NOTES_FILE"] && File.exist?(ENV["RELEASE_NOTES_FILE"])
      File.read(ENV["RELEASE_NOTES_FILE"]).strip
    else
      # Fallback: generate from Conventional Commits since previous tag
      previous_tag = sh("git describe --tags --abbrev=0 HEAD^ 2>/dev/null || true", log: false).strip
      range = previous_tag.empty? ? "HEAD~20..HEAD" : "#{previous_tag}..HEAD"
      commits = sh("git log --pretty=format:'- %s' #{range} 2>/dev/null || true", log: false).strip
      commits.empty? ? "Pre-release build #{ENV['GITHUB_RUN_NUMBER'] || 'local'}" : commits
    end
```

- [ ] **Step 3: Sửa `beta` lane — dùng `GITHUB_RUN_NUMBER` làm build number**

Thay dòng 128 (`next_build = next_build_number(api_key)`) bằng:

```ruby
    # Build number = GITHUB_RUN_NUMBER (monotonic, never resets) when on CI.
    next_build = if ENV["GITHUB_RUN_NUMBER"]
      ENV["GITHUB_RUN_NUMBER"].to_i
    else
      next_build_number(api_key)
    end
```

Giữ hàm `next_build_number` cho local build. `release` lane dòng 177 similarly: thay `next_build_number(api_key)` bằng logic tương tự — extract helper:

```ruby
  def resolve_build_number(api_key)
    ENV["GITHUB_RUN_NUMBER"] ? ENV["GITHUB_RUN_NUMBER"].to_i : next_build_number(api_key)
  end
```

Dùng `resolve_build_number(api_key)` ở cả `beta` và `release`.

- [ ] **Step 4: Viết `scripts/check-secrets.sh`**

```bash
#!/usr/bin/env bash
# Pre-commit hook: block staging of sensitive files
set -euo pipefail
BLOCKED='\.p8$|\.p12$|\.mobileprovision$|Secrets\.xcconfig$|^\.env$|^\.env\.'
if git diff --cached --name-only | grep -qE "$BLOCKED"; then
  echo "error: sensitive file staged. Unstage it (git reset HEAD <file>)" >&2
  git diff --cached --name-only | grep -E "$BLOCKED" >&2
  exit 1
fi
```

- [ ] **Step 5: Viết `.githooks/pre-commit`**

```bash
#!/usr/bin/env bash
# SwiftLint gate + secret guard. Register: git config core.hooksPath .githooks
set -euo pipefail
bash scripts/check-secrets.sh
if ! command -v swiftlint >/dev/null 2>&1; then
  echo "pre-commit: swiftlint not found, skipping lint gate" >&2
  exit 0
fi
if ! swiftlint --strict --quiet; then
  echo "pre-commit: SwiftLint failed. Fix violations (swiftlint --strict --quiet) before committing." >&2
  exit 1
fi
```

- [ ] **Step 6: Đăng ký hook path**

```bash
chmod +x scripts/check-secrets.sh .githooks/pre-commit
git config core.hooksPath .githooks
```

- [ ] **Step 7: Verify — PII biến mất**

Run: `grep -rn "iletai@hotmail.com\|+84326718280\|\"Tai\"" fastlane/Fastfile || echo "CLEAN"`
Expected: `CLEAN`.

- [ ] **Step 8: Commit**

```bash
git add fastlane/Fastfile scripts/check-secrets.sh .githooks/pre-commit
git commit -m "ci: move App Store review PII to env, add secret guard pre-commit hook"
```

---

### Task 5: Community files + `.github/release.yml` + CHANGELOG seed

**Files:**
- Create: `.github/pull_request_template.md`
- Create: `.github/ISSUE_TEMPLATE/bug_report.yml`
- Create: `.github/ISSUE_TEMPLATE/feature_request.yml`
- Create: `.github/release.yml`
- Create: `CONTRIBUTING.md`
- Create: `SECURITY.md`
- Create: `CODEOWNERS`
- Create: `CHANGELOG.md`
- Create: `fastlane/metadata/vi/release_notes.txt`

**Interfaces:**
- Consumes: Task 3 branch model (CONTRIBUTING mô tả chính nó).
- Produces: `fastlane/metadata/vi/release_notes.txt` mà Task 2 `RELEASE_NOTES_FILE` đọc.

- [ ] **Step 1: `.github/pull_request_template.md`**

```markdown
## Mô tả thay đổi
<!-- Mô tả ngắn gọn -->

## Kiểm tra
- [ ] `xcodebuild test -scheme AnNien-Dev` pass
- [ ] `swiftlint --strict --quiet` pass
- [ ] Cập nhật `fastlane/metadata/vi/release_notes.txt` nếu có thay đổi user-facing
- [ ] Không commit secret, PII, cert

## Loại thay đổi
- [ ] feat (tính năng mới)
- [ ] fix (sửa lỗi)
- [ ] docs
- [ ] refactor
- [ ] ci / chore
```

- [ ] **Step 2: `.github/ISSUE_TEMPLATE/bug_report.yml`**

```yaml
name: Bug Report
description: Báo lỗi
title: "[Bug]: "
labels: ["bug"]
body:
  - type: textarea
    id: what-happened
    attributes:
      label: Mô tả lỗi
      placeholder: Mô tả lỗi và kết quả mong đợi
    validations:
      required: true
  - type: input
    id: version
    attributes:
      label: Phiên bản (Settings → About)
    validations:
      required: true
  - type: input
    id: device
    attributes:
      label: Thiết bị + iOS
      placeholder: iPhone 15 Pro, iOS 17.4
  - type: textarea
    id: reproduce
    attributes:
      label: Các bước tái hiện
```

- [ ] **Step 3: `.github/ISSUE_TEMPLATE/feature_request.yml`**

```yaml
name: Feature Request
description: Đề xuất tính năng
title: "[Feature]: "
labels: ["enhancement"]
body:
  - type: textarea
    id: problem
    attributes:
      label: Vấn đề
      placeholder: Tính năng này giải quyết vấn đề gì?
  - type: textarea
    id: solution
    attributes:
      label: Giải pháp đề xuất
  - type: textarea
    id: alternatives
    attributes:
      label: Giải pháp thay thế
```

- [ ] **Step 4: `.github/release.yml`**

```yaml
changelog:
  exclude:
    labels: ["skip-changelog"]
    authors: ["dependabot"]
  categories:
    - title: "Tính năng mới"
      labels: ["enhancement", "feat"]
    - title: "Sửa lỗi"
      labels: ["bug", "fix"]
    - title: "Khác"
      labels: ["*"]
```

- [ ] **Step 5: `CONTRIBUTING.md`**

```markdown
# Contributing to An Niên (Serene)

## Setup
```bash
xcodegen generate
bundle install
open AnNien.xcodeproj
```

## Branch model
Xem `CLAUDE.md` → "Branch & Release".

## Conventional Commits
`feat:`, `fix:`, `refactor:`, `docs:`, `ci:`, `chore:`.

## Quality gates
- `swiftlint --strict --quiet`
- `bundle exec fastlane test` (hoặc `xcodebuild test -scheme AnNien-Dev`)
- Pre-commit hook chặn secret (đăng ký: `git config core.hooksPath .githooks`)

## PR flow
1. Tạo nhánh `feat/*` hoặc `fix/*` từ `develop`.
2. PR vào `develop`, squash merge.
3. CI phải pass trước khi merge.
```

- [ ] **Step 6: `SECURITY.md`**

```markdown
# Security Policy

## Báo cáo lỗ hổng
Vui lòng báo cáo qua GitHub Security Advisories (Settings → Security → Advisories). Không mở public issue cho lỗ hổng nhạy cảm.

## Chính sách hỗ trợ
Bản mới nhất trên `main` được hỗ trợ bảo mật.
```

- [ ] **Step 7: `CODEOWNERS`**

```
* @iletai
```

- [ ] **Step 8: `CHANGELOG.md` seed**

```markdown
# Changelog

Tất cả thay đổi đáng chú ý. Định dạng: [Conventional Changelog](https://www.conventionalchangelog.org/).

## [1.0.0] - 2026-10-19

### Added
- Lịch âm dương Việt Nam chính xác (Jean Meeus + Ho Ngoc Duc, GMT+7).
- Quản lý ngày nhớ (giỗ, kỵ, sinh nhật) với thông báo thông minh.
- Widget nhỏ/màn hình khóa.
- StoreKit 2 subscription (Monthly/Yearly/Lifetime).
```

- [ ] **Step 9: `fastlane/metadata/vi/release_notes.txt`**

```text
Lịch Việt & Ngày Nhớ — bản mới.
Cải thiện hiệu suất và ổn định.
```

- [ ] **Step 10: Verify release_notes tồn tại**

Run: `test -f fastlane/metadata/vi/release_notes.txt && echo OK`
Expected: `OK`.

- [ ] **Step 11: Commit**

```bash
git add .github/pull_request_template.md .github/ISSUE_TEMPLATE/ .github/release.yml CONTRIBUTING.md SECURITY.md CODEOWNERS CHANGELOG.md fastlane/metadata/vi/release_notes.txt
git commit -m "docs: add community health files, release notes, changelog seed"
```

---

## Definition of Done (Plan 1)

- [ ] `swiftlint --strict --quiet` → 0 error.
- [ ] `grep -rn "iletai@hotmail.com\|+84326718280" fastlane/` → CLEAN.
- [ ] `yaml.safe_load` 3 workflow → OK.
- [ ] `scripts/release-tag.sh 1.0.0` tạo tag local (chưa push).
- [ ] `git branch` có `develop` + `main` (main local).
- [ ] Community files tồn tại: CONTRIBUTING.md, SECURITY.md, CODEOWNERS, CHANGELOG.md, PR template, 2 issue templates, `.github/release.yml`.
- [ ] `docs/design.md` đã xóa; CLAUDE.md trỏ đúng `DESIGN.md`.
- [ ] `git config core.hooksPath` = `.githooks`; hook chặn secret + swiftlint.
- [ ] User xác nhận trước khi push `main` lên remote và tạo Environment `production` trên GitHub Settings.
