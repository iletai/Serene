<div align="center">

# An Niên (Serene) — Lịch Việt & Ngày Nhớ

[ English ](README.md) · [ **Tiếng Việt** ](README.vi.md) · [ 日本語 ](README.ja.md)

<p align="center">
  <img src="docs/assets/banner.svg" alt="An Niên Banner" width="100%">
</p>

[![CI](https://github.com/iletai/Serene/actions/workflows/ci.yml/badge.svg)](https://github.com/iletai/Serene/actions)
[![Swift 6](https://img.shields.io/badge/Swift-6.0-orange.svg?style=flat&logo=swift)](https://swift.org)
[![iOS 17.0+](https://img.shields.io/badge/iOS-17.0%2B-blue.svg?style=flat&logo=apple)](https://developer.apple.com/ios/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

An Niên là ứng dụng iOS thuần túy (native) được xây dựng bằng SwiftUI, SwiftData và WidgetKit, kết hợp thuật toán tính toán thiên văn Âm Dương Lịch Việt Nam chính xác với hệ thống quản lý ngày giỗ, ngày nhớ và nghi lễ thông minh. Thiết kế theo phong cách Neo-Minimalism, typography Apple New York và kiểm tra đồng thời nghiêm ngặt Swift 6 (Strict Concurrency).

[Tính năng nổi bật](#-tính-năng-nổi-bật) · [Kiến trúc](#-kiến-trúc) · [Cài đặt & Build](#-cài-đặt--build) · [License](#-license)

</div>

---

## 📱 Ảnh chụp màn hình

<div align="center">
  <img src="docs/assets/screenshots/calendar.png" alt="Lưới lịch" width="28%">&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="docs/assets/screenshots/memorial.png" alt="Quản lý ngày giỗ" width="28%">&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="docs/assets/screenshots/widget.png" alt="Tiện ích màn hình" width="28%">
</div>

---

## ✨ Tính năng nổi bật

- **Động cơ Âm Lịch (`VNCalendarLunar`)**: Tính toán thiên văn độ chính xác cao dựa trên thuật toán Jean Meeus & Hồ Ngọc Đức với cơ sở múi giờ GMT+7. Tính toán Can Chi, 24 Tiết Khí, giờ Hoàng Đạo / Hắc Đạo và tháng nhuận với 0 thư viện phụ thuộc ngoài.
- **Trình điều khiển giao diện lịch (`VNCalendarKit`)**: Lớp thích ứng lưới 42 ô (6x7) hiệu năng cao bọc quanh `iletai/SwiftUICalendarView`, ngăn ngừa dịch chuyển giao diện và tra cứu khóa ngày `dateKey` (`YYYYMMDD`) với độ phức tạp $O(1)$.
- **Hệ thống thông báo thông minh**: Quản lý hạn mức 64 thông báo chờ của iOS bằng cách ưu tiên 60 cảnh báo hàng đầu cộng 4 khe dự trữ hệ thống theo công thức suy giảm theo thời gian (time-decay hyperbolic):
  $$\text{Điểm} = \text{priority} \times \text{offsetWeight} \times \frac{1}{1 + 0.05 \times \text{daysUntil}}$$
  Tự động xử lý điều kiện biên như chuyển ngày giỗ mùng 30 âm lịch sang ngày 29 trong các tháng thiếu.
- **Quản lý Ngày Giỗ & Nghi Lễ**: Theo dõi ngày giỗ âm lịch, các nghi lễ truyền thống Việt Nam với cơ chế lưu trữ ngoại tuyến ưu tiên (offline-first) và đồng bộ gia tăng microCMS qua ETag.
- **Kiếm tiền StoreKit 2**: Hỗ trợ mua hàng trong ứng dụng gồm Gói tháng (`com.iletai.annien.sub.monthly`), Gói năm (`com.iletai.annien.sub.yearly`) và Trọn đời (`com.iletai.annien.nonconsumable.lifetime`), mở khóa ngày giỗ không giới hạn, chế độ gia phả gia đình và widget màn hình khóa nâng cao.

---

## 🏛️ Kiến trúc

An Niên tuân theo Clean Architecture dưới dạng monorepo SPM đa gói quản lý qua XcodeGen (`project.yml`):

```
Packages/
├── VNCalendarLunar/          # Thuật toán thiên văn (0 phụ thuộc)
├── VNCalendarDomain/         # Thực thể domain, Use Case & giao thức Repository
├── VNCalendarData/           # Mô hình SwiftData & cài đặt Repository
├── VNCalendarDesignSystem/   # Token thiết kế Neo-minimalist & thành phần UI
└── VNCalendarKit/            # Adapter giao diện lịch & bố cục lưới
App/                          # Composition Root (AppContainer), Feature Views, StoreKit Paywall
Extensions/Widget/            # WidgetKit extensions (Nhỏ, Vừa, Màn hình khóa)
Config/                       # Cấu hình build (.xcconfig) & Entitlements
```

### Quy tắc phụ thuộc mô-đun
- `VNCalendarLunar`: Không có phụ thuộc nội bộ hoặc bên ngoài.
- `VNCalendarDomain`: Chỉ phụ thuộc `VNCalendarLunar`. Không import SwiftUI, SwiftData.
- `VNCalendarData`: Phụ thuộc `VNCalendarDomain` và `VNCalendarLunar`.
- `VNCalendarDesignSystem`: Phụ thuộc `VNCalendarDomain`.
- `VNCalendarKit`: Phụ thuộc `VNCalendarDomain`, `VNCalendarDesignSystem`, `VNCalendarLunar` và `iletai/SwiftUICalendarView`.
- `AnNien (App)`: Import tất cả các gói cục bộ và `iletai/AppUpdateKit`.

---

## 🚀 Cài đặt & Build

### Yêu cầu hệ thống
- macOS 14.0+
- Xcode 15.4+ với bộ biên dịch Swift 6
- XcodeGen (`brew install xcodegen`)
- Bundler (`bundle install`)

### Thiết lập và Biên dịch
1. Clone mã nguồn:
   ```bash
   git clone https://github.com/iletai/Serene.git
   cd Serene
   ```
2. Sinh dự án Xcode:
   ```bash
   xcodegen generate
   ```
3. Chạy kiểm thử qua fastlane hoặc xcodebuild:
   ```bash
   bundle exec fastlane test
   ```

---

## 📄 License

Phân phối dưới giấy phép MIT. Xem [LICENSE](LICENSE) để biết thêm chi tiết.
