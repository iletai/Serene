## Mô tả thay đổi
<!-- Tóm tắt ngắn gọn thay đổi và lý do -->

## Kiểm tra
- [ ] `swiftlint --strict --quiet` pass (0 violation)
- [ ] `xcodebuild test -scheme AnNien-Dev -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -configuration Debug-Development` pass
- [ ] Không có secret, cert, PII bị commit
- [ ] Cập nhật `fastlane/metadata/vi/release_notes.txt` nếu có thay đổi user-facing

## Loại thay đổi
- [ ] feat: tính năng mới
- [ ] fix: sửa lỗi
- [ ] refactor: tái cấu trúc code không đổi hành vi
- [ ] docs: tài liệu
- [ ] ci: cấu hình CI/CD
- [ ] chore: việc lặt vặt
