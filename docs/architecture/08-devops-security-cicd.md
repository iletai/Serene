# Kiến Trúc DevOps, Bảo Mật Mã Nguồn & CI/CD Pipeline (DevOps, Security & CI/CD Architecture)

Tài liệu thiết kế kiến trúc toàn diện quy trình tự động hóa phát triển phần mềm (DevOps), cơ chế ký số mã nguồn tự động hóa (**Fastlane Match**), cấu hình đa môi trường (**XcodeGen & .xcconfig**), hệ thống tích hợp và phân phối liên tục (**GitHub Actions CI/CD**), và chiến lược bảo mật tuyệt đối chống rò rỉ bí mật (**Zero Secrets Leakage**) cho repository mã nguồn mở công khai của dự án **An Niên (Lịch Việt & Ngày Nhớ)** trên nền tảng **iOS 17.0+ / Swift 6**.

---

## 1. Nguyên Tắc Bảo Mật Repository Công Khai & Quản Lý Bí Mật (Zero Secrets Leakage)

Dự án được lưu trữ trên GitHub dưới dạng Public Repository. Để đảm bảo tính an toàn tối đa cho ứng dụng thương mại và chứng chỉ của Apple Developer Program, hệ thống thực thi triệt để 5 nguyên tắc bảo mật:

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                        PUBLIC REPOSITORY SECURITY ARCHITECTURE                          │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                         │
│   Developer Local Machine                                 Public GitHub Repository      │
│   ┌───────────────────────────┐                           ┌─────────────────────────┐   │
│   │ .env (Ignored locally)    │                           │ .env.example (Template) │   │
│   │ Certificates (.p12/.cer)  │                           │ project.yml (XcodeGen)  │   │
│   │ Provisioning Profiles     │                           │ Config/*.xcconfig       │   │
│   │ ASC API Key (.p8)         │                           │ fastlane/Fastfile       │   │
│   └─────────────┬─────────────┘                           │ .github/workflows/      │   │
│                 │ (Blocked by .gitignore)                 └────────────┬────────────┘   │
│                 ▼                                                      │                │
│   ┌───────────────────────────┐                                        │                │
│   │ Git Pre-commit / Push     │ ──── BLOCKED: Secret / Key / Profile   │                │
│   └───────────────────────────┘                                        │                │
│                                                                        │                │
│   Private Match Repo (AES-256)                            GitHub Actions CI/CD Runner   │
│   ┌───────────────────────────┐                           ┌─────────────────────────┐   │
│   │ Encrypted Certs & Profiles│ ◄─── Fastlane Match ─────┤ Ephemeral Keychain       │   │
│   │ Password: MATCH_PASSWORD  │      (SSH Key Auth)       │ Injected Secrets Only   │   │
│   └───────────────────────────┘                           └─────────────────────────┘   │
│                                                                                         │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

### 1.1. Năm Trụ Cột Bảo Mật

1. **Không lưu trữ bí mật trong mã nguồn**: Tuyệt đối không commit bất kỳ file khóa cá nhân (`.p8`, `.p12`, `.pem`, `.key`), file hồ sơ phân phối (`.mobileprovision`), chuỗi khóa API hay token vào git tree.
2. **Mã hóa chứng chỉ phân tán với Fastlane Match**: Toàn bộ chứng chỉ và provisioning profile được mã hóa bằng thuật toán `AES-256` sử dụng mật khẩu mạnh `MATCH_PASSWORD` và lưu trữ tại một Git Repository riêng tư (Private Repository).
3. **Phân tách hoàn toàn môi trường Dev và Production**: Tách biệt rõ ràng Bundle Identifier, App Group ID, CloudKit Container, và Entitlements giữa bản phát triển (`.dev`) và bản thương mại App Store.
4. **Môi trường CI/CD biệt lập & Vô danh**: GitHub Actions Runner khởi tạo một Keychain tạm thời (`ci_keychain`) chỉ tồn tại trong suốt phiên chạy (ephemeral) và tự động tiêu hủy sau khi kết thúc pipeline.
5. **Mẫu cấu hình an toàn (`.env.example`)**: Cung cấp file mẫu mô tả rõ danh mục biến môi trường với các giá trị placeholder chuẩn, giúp cộng tác viên khởi chạy dự án mà không lộ dữ liệu thật.

---

## 2. Quản Lý Dự Án Bằng XcodeGen (`project.yml`)

Dự án không lưu trữ file nhị phân `AnNien.xcodeproj` trên Git để triệt tiêu hiện tượng xung đột giải quyết merge conflict (`project.pbxproj`). Dự án được tái tạo tức thì (100% Deterministic) thông qua lệnh `xcodegen generate`.

### 2.1. File Cấu Hình Hoàn Chỉnh `project.yml`

```yaml
name: AnNien
options:
  bundleIdPrefix: com.iletai
  xcodeVersion: "16.0"
  deploymentTarget:
    iOS: "17.0"
  createIntermediateGroups: true
  groupSortPosition: top

configs:
  Debug-Development: debug
  Release-Development: release
  Debug-Production: debug
  Release-Production: release

configFiles:
  Debug-Development: Config/Development.xcconfig
  Release-Development: Config/Development.xcconfig
  Debug-Production: Config/Production.xcconfig
  Release-Production: Config/Production.xcconfig

packages:
  CalendarView:
    url: https://github.com/iletai/SwiftUICalendarView.git
    from: 3.1.0
  AppUpdateKit:
    url: https://github.com/iletai/AppUpdateKit.git
    from: 1.1.0
  VNCalendarLunar:
    path: Packages/VNCalendarLunar
  VNCalendarDomain:
    path: Packages/VNCalendarDomain
  VNCalendarData:
    path: Packages/VNCalendarData
  VNCalendarDesignSystem:
    path: Packages/VNCalendarDesignSystem
  VNCalendarKit:
    path: Packages/VNCalendarKit

targets:
  AnNien:
    type: application
    platform: iOS
    deploymentTarget: "17.0"
    sources:
      - path: App
        createIntermediateGroups: true
    settings:
      base:
        CODE_SIGN_ENTITLEMENTS: $(CODE_SIGN_ENTITLEMENTS)
        PRODUCT_BUNDLE_IDENTIFIER: $(PRODUCT_BUNDLE_IDENTIFIER)
        INFOPLIST_KEY_CFBundleDisplayName: $(APP_DISPLAY_NAME)
    dependencies:
      - package: CalendarView
      - package: AppUpdateKit
      - package: VNCalendarLunar
      - package: VNCalendarDomain
      - package: VNCalendarData
      - package: VNCalendarDesignSystem
      - package: VNCalendarKit
      - target: AnNienWidget

  AnNienWidget:
    type: app-extension
    platform: iOS
    deploymentTarget: "17.0"
    sources:
      - path: Extensions/Widget
        createIntermediateGroups: true
    settings:
      base:
        CODE_SIGN_ENTITLEMENTS: $(WIDGET_CODE_SIGN_ENTITLEMENTS)
        PRODUCT_BUNDLE_IDENTIFIER: $(WIDGET_BUNDLE_IDENTIFIER)
        INFOPLIST_KEY_CFBundleDisplayName: $(APP_DISPLAY_NAME) Widget
    dependencies:
      - package: VNCalendarLunar
      - package: VNCalendarDomain
      - package: VNCalendarData
      - package: VNCalendarDesignSystem

  AnNienTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - path: Tests
        createIntermediateGroups: true
    dependencies:
      - target: AnNien

schemes:
  AnNien-Dev:
    build:
      targets:
        AnNien: all
        AnNienWidget: all
        AnNienTests: [test]
    run:
      config: Debug-Development
    test:
      config: Debug-Development
      targets:
        - AnNienTests
    profile:
      config: Release-Development
    analyze:
      config: Debug-Development
    archive:
      config: Release-Development

  AnNien-Prod:
    build:
      targets:
        AnNien: all
        AnNienWidget: all
        AnNienTests: [test]
    run:
      config: Debug-Production
    test:
      config: Debug-Production
      targets:
        - AnNienTests
    profile:
      config: Release-Production
    analyze:
      config: Debug-Production
    archive:
      config: Release-Production
```

---

## 3. Hệ Thống Cấu Hình Phân Tầng (`Config/*.xcconfig`)

Hệ thống cấu hình sử dụng kiến trúc phân cấp `.xcconfig`, kế thừa từ file nền tảng `Shared.xcconfig`.

```
Config/
├── Shared.xcconfig           # Quy chuẩn Swift 6, iOS 17.0, Asset Catalog, InfoPlist
├── Development.xcconfig      # Ghi đè Bundle ID .dev, cờ DEV, Entitlements Dev
├── Production.xcconfig       # Ghi đè Bundle ID chính, cờ PROD, Entitlements Prod
└── Entitlements/
    ├── AnNien-Dev.entitlements
    ├── AnNien-Prod.entitlements
    ├── AnNienWidget-Dev.entitlements
    └── AnNienWidget-Prod.entitlements
```

### 3.1. `Config/Shared.xcconfig`

```ini
// Shared build settings across all configurations
SWIFT_VERSION = 6.0
IPHONEOS_DEPLOYMENT_TARGET = 17.0
TARGETED_DEVICE_FAMILY = 1
MARKETING_VERSION = 1.0.0
CURRENT_PROJECT_VERSION = 1
SWIFT_STRICT_CONCURRENCY = complete
ENABLE_USER_SCRIPT_SANDBOXING = YES
ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon
ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor
GENERATE_INFOPLIST_FILE = YES
INFOPLIST_KEY_CFBundleDisplayName = $(APP_DISPLAY_NAME)
INFOPLIST_KEY_UILaunchScreen_Generation = YES
INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait
INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight
```

### 3.2. `Config/Development.xcconfig`

```ini
#include "Shared.xcconfig"

PRODUCT_BUNDLE_IDENTIFIER = com.iletai.annien.dev
WIDGET_BUNDLE_IDENTIFIER = com.iletai.annien.dev.widget
APP_DISPLAY_NAME = An Niên Dev
CLOUDKIT_CONTAINER_ID = iCloud.com.iletai.annien.dev
APP_GROUP_ID = group.com.iletai.annien.dev
CODE_SIGN_ENTITLEMENTS = Config/Entitlements/AnNien-Dev.entitlements
WIDGET_CODE_SIGN_ENTITLEMENTS = Config/Entitlements/AnNienWidget-Dev.entitlements
SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) DEV
DEBUG_INFORMATION_FORMAT = dwarf-with-dsym
OTHER_SWIFT_FLAGS = $(inherited) -D DEV
```

### 3.3. `Config/Production.xcconfig`

```ini
#include "Shared.xcconfig"

PRODUCT_BUNDLE_IDENTIFIER = com.iletai.annien
WIDGET_BUNDLE_IDENTIFIER = com.iletai.annien.widget
APP_DISPLAY_NAME = An Niên
CLOUDKIT_CONTAINER_ID = iCloud.com.iletai.annien
APP_GROUP_ID = group.com.iletai.annien
CODE_SIGN_ENTITLEMENTS = Config/Entitlements/AnNien-Prod.entitlements
WIDGET_CODE_SIGN_ENTITLEMENTS = Config/Entitlements/AnNienWidget-Prod.entitlements
SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) PROD
DEBUG_INFORMATION_FORMAT = dwarf-with-dsym
OTHER_SWIFT_FLAGS = $(inherited) -D PROD
```

### 3.4. Định Nghĩa Quyền Hạn (`Config/Entitlements/`)

#### `Config/Entitlements/AnNien-Dev.entitlements`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.com.iletai.annien.dev</string>
    </array>
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudKit</string>
    </array>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.iletai.annien.dev</string>
    </array>
</dict>
</plist>
```

#### `Config/Entitlements/AnNien-Prod.entitlements`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.com.iletai.annien</string>
    </array>
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudKit</string>
    </array>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.iletai.annien</string>
    </array>
</dict>
</plist>
```

#### `Config/Entitlements/AnNienWidget-Dev.entitlements` & `AnNienWidget-Prod.entitlements`
Cấu hình quyền truy cập App Group tương ứng để Widget chia sẻ dữ liệu với ứng dụng chính.

---

## 4. Tự Động Hóa Ký Số & Phân Phối Bằng Fastlane

Quy trình tự động hóa Fastlane bao gồm: xác thực App Store Connect qua API Key (`.p8`), đồng bộ chứng chỉ với `match`, chạy kiểm thử với `scan`, và phân phối TestFlight/AppStore với `gym`/`pilot`/`deliver`.

### 4.1. Cấu Hình `fastlane/Appfile`

```ruby
app_identifier("com.iletai.annien")
apple_id(ENV["APPLE_ID"])
team_id(ENV["APPLE_TEAM_ID"])
itc_team_id(ENV["APPLE_ITC_TEAM_ID"])
```

### 4.2. Cấu Hình `fastlane/Matchfile`

```ruby
git_url(ENV["MATCH_GIT_URL"])
storage_mode("git")
type("appstore")
app_identifier([
  "com.iletai.annien",
  "com.iletai.annien.widget",
  "com.iletai.annien.dev",
  "com.iletai.annien.dev.widget"
])
username(ENV["APPLE_ID"])
team_id(ENV["APPLE_TEAM_ID"])
git_branch("main")
shallow_clone(true)
readonly(is_ci)
```

### 4.3. Cấu Hình `fastlane/Fastfile`

```ruby
default_platform(:ios)

platform :ios do
  before_all do
    ensure_bundle_exec
  end

  private_lane :setup_ci_keychain do
    if is_ci
      create_keychain(
        name: "ci_keychain",
        password: ENV["FASTLANE_KEYCHAIN_PASSWORD"] || "ci_keychain_password",
        default_keychain: true,
        unlock: true,
        timeout: 3600,
        lock_when_sleeps: false
      )
    end
  end

  private_lane :app_store_connect_auth do
    app_store_connect_api_key(
      key_id: ENV["ASC_KEY_ID"],
      issuer_id: ENV["ASC_ISSUER_ID"],
      key_content: ENV["ASC_KEY_CONTENT"] || (ENV["ASC_KEY_CONTENT_BASE64"] ? Base64.decode64(ENV["ASC_KEY_CONTENT_BASE64"]) : nil),
      is_key_content_base64: false,
      in_house: false
    )
  end

  desc "Run unit and integration tests"
  lane :test do
    scan(
      scheme: "AnNien-Dev",
      devices: ["iPhone 16"],
      clean: true,
      code_coverage: true,
      output_directory: "fastlane/test_output",
      output_types: "html,junit",
      fail_build: true
    )
  end

  desc "Sync certificates and provisioning profiles via Match"
  lane :sync_signing do |options|
    setup_ci_keychain
    api_key = app_store_connect_auth
    type = options[:type] || "appstore"
    readonly = options[:readonly].nil? ? is_ci : options[:readonly]

    match(
      type: type,
      readonly: readonly,
      keychain_name: is_ci ? "ci_keychain" : nil,
      keychain_password: is_ci ? (ENV["FASTLANE_KEYCHAIN_PASSWORD"] || "ci_keychain_password") : nil,
      api_key: api_key
    )
  end

  desc "Build and upload beta build to TestFlight"
  lane :beta do |options|
    setup_ci_keychain
    api_key = app_store_connect_auth

    # Match code signing for Production App & Extensions
    match(
      type: "appstore",
      readonly: is_ci,
      keychain_name: is_ci ? "ci_keychain" : nil,
      keychain_password: is_ci ? (ENV["FASTLANE_KEYCHAIN_PASSWORD"] || "ci_keychain_password") : nil,
      api_key: api_key
    )

    # Calculate incremented build number directly from App Store Connect
    current_build = latest_testflight_build_number(
      api_key: api_key,
      app_identifier: "com.iletai.annien"
    )
    increment_build_number(
      build_number: current_build + 1
    )

    # Archive and export .ipa
    build_app(
      scheme: "AnNien-Prod",
      configuration: "Release-Production",
      export_method: "app-store",
      clean: true,
      output_directory: "./build",
      output_name: "AnNien-Beta.ipa"
    )

    # Distribute to TestFlight
    changelog_text = options[:changelog] || prompt(text: "Changelog: ") if !is_ci
    changelog_text ||= "Automated CI/CD build from commit #{ENV['GITHUB_SHA'] ? ENV['GITHUB_SHA'][0..7] : 'local'}"

    upload_to_testflight(
      api_key: api_key,
      skip_waiting_for_build_processing: true,
      changelog: changelog_text,
      distribute_external: false
    )
  end

  desc "Build and submit release to App Store Connect"
  lane :release do |options|
    setup_ci_keychain
    api_key = app_store_connect_auth

    match(
      type: "appstore",
      readonly: is_ci,
      keychain_name: is_ci ? "ci_keychain" : nil,
      keychain_password: is_ci ? (ENV["FASTLANE_KEYCHAIN_PASSWORD"] || "ci_keychain_password") : nil,
      api_key: api_key
    )

    build_app(
      scheme: "AnNien-Prod",
      configuration: "Release-Production",
      export_method: "app-store",
      clean: true,
      output_directory: "./build",
      output_name: "AnNien-Release.ipa"
    )

    upload_to_app_store(
      api_key: api_key,
      force: true,
      skip_screenshots: true,
      skip_metadata: false,
      submit_for_review: options[:submit_for_review] || false,
      automatic_release: options[:automatic_release] || false
    )
  end
end
```

---

## 5. Quy Chuẩn Kiểm Tra Mã Nguồn (`.swiftlint.yml`)

Quy chuẩn SwiftLint được cấu hình ở chế độ nghiêm ngặt (`--strict`), ép buộc mã nguồn tuân thủ Clean Code và loại trừ hoàn toàn việc force-unwrapping nguy hiểm:

```yaml
disabled_rules:
  - trailing_whitespace

opt_in_rules:
  - empty_count
  - empty_string
  - force_unwrapping
  - fatal_error_message
  - first_where
  - implicitly_unwrapped_optional
  - redundant_type_annotation
  - unneeded_parentheses_in_closure_argument
  - vertical_parameter_alignment_on_call
  - yoda_condition

excluded:
  - .build
  - DerivedData
  - Pods
  - fastlane
  - build

line_length:
  warning: 140
  error: 200
  ignores_comments: true
  ignores_urls: true

file_length:
  warning: 500
  error: 1200

type_body_length:
  warning: 300
  error: 500

function_body_length:
  warning: 60
  error: 100

cyclomatic_complexity:
  warning: 10
  error: 20
```

---

## 6. Mẫu Cấu Hình Biến Môi Trường (`.env.example`) & `.gitignore`

### 6.1. File Mẫu Môi Trường `.env.example`

```bash
# App Store Connect API Key (Generated in App Store Connect -> Users and Access -> Integrations -> Keys)
ASC_KEY_ID="XXXXXXXXXX"
ASC_ISSUER_ID="00000000-0000-0000-0000-000000000000"
# Base64 encoded .p8 private key (or raw key in ASC_KEY_CONTENT)
ASC_KEY_CONTENT_BASE64="LS0tLS1CRUdJTiBQUklWQVRFIGtFWS0tLS0tCg=="

# Fastlane Match Configuration (Private Git Repository for encrypted certs)
MATCH_GIT_URL="git@github.com:iletai/ios-certificates.git"
MATCH_PASSWORD="your-secure-passphrase-to-encrypt-certificates"
MATCH_SSH_KEY="-----BEGIN OPENSSH PRIVATE KEY-----\n..."

# Apple Developer Team IDs
APPLE_ID="developer@example.com"
APPLE_TEAM_ID="XXXXXXXXXX"
APPLE_ITC_TEAM_ID="00000000"

# CI Keychain temporary password
FASTLANE_KEYCHAIN_PASSWORD="ci_temporary_keychain_password"
```

### 6.2. Quy Tắc Loại Trừ Git `.gitignore`

```gitignore
# Xcode
xcuserdata/
*.hmap
*.ipa
*.dSYM.zip
*.dSYM
timeline.xctimeline
playground.xcworkspace

# Generated Xcode Project (XcodeGen)
*.xcodeproj
*.xcworkspace
.build/
Package.resolved

# Fastlane & Signing
fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots/**/*.png
fastlane/test_output
fastlane/keys/
*.p8
*.p12
*.mobileprovision
fastlane/.env

# Local Environment & Secrets
.env
.env.local
*.xcconfig.local
.DS_Store
DerivedData/
```

---

## 7. Quy Trình GitHub Actions CI/CD Workflows

### 7.1. Workflow Kiểm Thử & Kiểm Tra Mã Nguồn (`.github/workflows/ci.yml`)

Kích hoạt trên mỗi Pull Request và Push vào nhánh `main` / `develop`:

```yaml
name: CI - PR & Build Tests

on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [develop]

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  lint-and-test:
    name: Lint & Test
    runs-on: macos-14
    timeout-minutes: 30

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Select Xcode 16
        run: sudo xcode-select -s /Applications/Xcode_16.0.app || sudo xcode-select -s /Applications/Xcode.app

      - name: Setup Ruby and Bundler
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.3'
          bundler-cache: true

      - name: Install Tooling
        run: |
          which xcodegen || brew install xcodegen
          which swiftlint || brew install swiftlint

      - name: SwiftLint Verification
        run: swiftlint --strict --quiet

      - name: Generate Xcode Project
        run: xcodegen generate

      - name: SPM Dependency Cache
        uses: actions/cache@v4
        with:
          path: .build
          key: ${{ runner.os }}-spm-${{ hashFiles('**/Package.resolved', 'project.yml') }}
          restore-keys: |
            ${{ runner.os }}-spm-

      - name: Run Unit & Integration Tests
        run: bundle exec fastlane test
        env:
          FASTLANE_XCODEBUILD_SETTINGS_TIMEOUT: 120

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: fastlane/test_output
```

### 7.2. Workflow Đóng Gói & Phân Phối TestFlight (`.github/workflows/deploy-testflight.yml`)

Tự động kích hoạt khi người dùng gắn Git Tag có định dạng `v*` (VD: `v1.0.0-beta.1`):

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
  deploy-testflight:
    name: Build & Distribute TestFlight
    runs-on: macos-14
    timeout-minutes: 45

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Select Xcode 16
        run: sudo xcode-select -s /Applications/Xcode_16.0.app || sudo xcode-select -s /Applications/Xcode.app

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
```

---

## 8. Sổ Tay Hướng Dẫn Vận Hành & Khắc Phục Sự Cố (Runbook)

### 8.1. Thiết Lập Môi Trường Phát Triển Cục Bộ Cho Lập Trình Viên Mới

```bash
# 1. Cài đặt các công cụ CLI cần thiết
brew install xcodegen swiftlint rbenv

# 2. Cài đặt các gem Ruby của Fastlane
bundle install

# 3. Tạo file cấu hình môi trường từ mẫu
cp .env.example .env
# Chỉnh sửa các giá trị thực tế trong .env

# 4. Tải và cài đặt chứng chỉ phân phối cục bộ (Development)
bundle exec fastlane sync_signing type:development

# 5. Sinh file project Xcode và mở ứng dụng
xcodegen generate
open AnNien.xcodeproj
```

### 8.2. Quy Trình Xoay Vòng & Cấp Mới Chứng Chỉ (Certificate Rotation)

Khi chứng chỉ ký số Apple Developer hết hạn:

```bash
# Xóa chứng chỉ cũ và cấp phát lại chứng chỉ mới cho cả App và Widget
bundle exec fastlane match nuke development
bundle exec fastlane match nuke distribution

# Khởi tạo lại bộ chứng chỉ và profile mới
bundle exec fastlane match development
bundle exec fastlane match appstore
```

### 8.3. Ma Trận Khắc Phục Lỗi Phổ Biến Trên CI/CD

| Hiện Tượng Lỗi | Nguyên Nhân Gốc | Giải Pháp Xử Lý |
|---|---|---|
| `User interaction is not allowed` | Keychain trên macOS runner bị khóa khi Fastlane cố truy cập Private Key. | Đảm bảo lane `setup_ci_keychain` đã được gọi trước `match` với cờ `unlock: true`. |
| `Provisioning profile doesn't match the entitlements file` | Sai lệch `CLOUDKIT_CONTAINER_ID` hoặc App Group giữa `.entitlements` và cấu hình trên Apple Developer Portal. | Kiểm tra đối chiếu Bundle ID giữa `Development.xcconfig` và file `AnNien-Dev.entitlements`. |
| `Permission denied (publickey)` khi clone Match repo | GitHub Actions thiếu quyền truy cập Private Repo lưu chứng chỉ. | Kiểm tra Secret `MATCH_SSH_KEY` trong GitHub Settings và cấu hình Deploy Key có quyền Read/Write trên Match Repo. |
| `Failed to verify code signature on Simulator` | Xảy ra khi dùng chứng chỉ App Store để build trên Simulator. | Scheme `AnNien-Dev` phải dùng cấu hình `Debug-Development` với signing `Automatic` hoặc Development Cert. |
