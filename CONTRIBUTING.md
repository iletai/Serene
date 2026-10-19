# Contributing to An Niên (Serene)

Dự án phát triển theo mô hình Clean Architecture (SPM monorepo), Swift 6 strict concurrency và SwiftUI.

## 1. Yêu cầu môi trường
- macOS 14+ (khuyến nghị macOS 15)
- Xcode 16.0+ (Swift 6)
- Homebrew: `xcodegen`, `swiftlint`, `xcbeautify`
- Ruby 3.3+ (quản lý qua `bundle`)

## 2. Thiết lập dự án ban đầu
```bash
# Cài đặt Ruby gems (fastlane)
bundle install

# Cài đặt CLI tools
brew install xcodegen swiftlint xcbeautify

# Sinh Xcode project
xcodegen generate

# Kích hoạt pre-commit hook (bắt buộc)
git config core.hooksPath .githooks
```

## 3. Quy ước Branch & Commits
- Branch model: **Git-Flow** với `develop` là nhánh tích hợp mặc định, `main` là nhánh production.
- Nhánh tính năng: `feat/<feature-name>`, `fix/<bug-name>`, `docs/<topic>` cắt từ `develop`.
- Quy chuẩn commit: **Conventional Commits**:
  - `feat:` tính năng mới
  - `fix:` sửa lỗi
  - `refactor:` tái cấu trúc code
  - `docs:` tài liệu
  - `ci:` cấu hình GitHub Actions / Fastlane
  - `chore:` việc lặt vặt

## 4. Quality Gates bắt buộc
Mỗi commit / PR phải vượt qua:
```bash
# 1. SwiftLint strict check (không chấp nhận warning)
swiftlint --strict --quiet

# 2. Chạy toàn bộ Unit & Integration tests
bundle exec fastlane test
# Hoặc trực tiếp qua xcodebuild:
xcodebuild test -scheme AnNien-Dev -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -configuration Debug-Development
```

## 5. Quy trình Release
1. Cắt nhánh `release/x.y.z` từ `develop`.
2. Tăng `MARKETING_VERSION` trong `Config/Shared.xcconfig`.
3. Mở PR `release/x.y.z` -> `main`.
4. Sau khi merge, chạy `scripts/release-tag.sh x.y.z` để gắn tag `vx.y.z`.
5. Tag kích hoạt pipeline build và upload TestFlight tự động.
