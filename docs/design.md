# An Niên — Hệ Thống Thiết Kế & Đặc Tả Giao Diện (Design System & UI/UX Specification)

Tài liệu đặc tả toàn diện ngôn ngữ thiết kế, Design Tokens, cấu trúc Wireframe, khả năng tiếp cận (Accessibility) và hiệu ứng chuyển động (Spring Animations) cho ứng dụng **An Niên — Lịch Việt & Ngày Nhớ** trên nền tảng **iOS 17.0+ / iOS 18.0+**.

---

## 1. Triết Lý Thiết Kế & Thẩm Mỹ Đông Dương Tối Giản (Vietnamese Neo-Minimalism)

### 1.0. Stitch Design Prototype
- **Màn hình Stitch Prototype**: `An Niên - Lịch Việt & Ngày Nhớ` (Project: `projects/9156707561340621727`)
- **Visual Artifacts**: Lưới 42 ô lịch Âm Dương, Thẻ Thông tin Hôm Nay, Can Chi & Tiết khí, Danh sách Giỗ gia đình, Bottom Navigation.

### 1.1. Tôn Chỉ Nghệ Thuật
An Niên kết hợp giữa **Thẩm mỹ Cổ điển Việt Nam** (sự mộc mạc của giấy điệp, màu sơn son thếp vàng cung đình Huế, nét mực nho thư pháp) với **Apple Human Interface Guidelines (iOS 17/18)** (tối giản, chiều sâu phân lớp, kiểu chữ sắc nét, chuyển động vật lý tự nhiên).

- **Tĩnh tại (Serenity)**: Giao diện tạo cảm giác an yên, không xáo động bởi quảng cáo hay các chi tiết đồ họa thừa.
- **Trang nhã (Elegance)**: Tỉ lệ vàng, khoảng trắng thoáng đãng (negative space) mô phỏng trang sách cổ.
- **Bản địa (Authenticity)**: Thể hiện trọn vẹn văn hóa Âm Dương, Lục Thập Hoa Giáp (Can Chi), 24 Tiết Khí và nếp sống hiếu nghĩa gia đình Việt.

---

## 2. Hệ Thống Design Tokens (Tokens Specification)

### 2.1. Bảng Màu Bản Địa (Vietnamese Heritage Palette)

Bảng màu được tính toán theo độ tương phản WCAG 2.1 Level AAA cho văn bản thông thường và Level AA cho các chỉ số phụ.

| Token Name | Light Mode Hex | Dark Mode Hex | Tên Dân Gian | Ý Nghĩa Văn Hóa & Ứng Dụng |
|---|---|---|---|---|
| `backgroundPrimary` | `#FEF9F1` | `#181614` | **Gạo Mới (Giấy Dó) / Than Mài** | Nền chính ứng dụng, gợi sắc trắng ngà giấy điệp mộc |
| `backgroundSecondary` | `#F8F3EB` | `#24201D` | **Vải Xô / Gỗ Mun Ấm** | Nền thẻ (Card), ô lịch được chọn, thanh công cụ |
| `backgroundTertiary` | `#ECE8E0` | `#2E2925` | **Bãi Cát Cổ / Gỗ Mun Tối** | Nền thành phần phụ, phân tách nhóm |
| `surfaceElevated` | `#FFFFFF` | `#2E2925` | **Trắng / Gỗ Mun Tối** | Sheets, floating bottom nav pill, popovers |
| `textPrimary` | `#1D1C17` | `#FAF7F0` | **Mực Nho / Giấy Dó Trắng** | Văn bản chính, số ngày Dương lịch, tiêu đề lớn |
| `textSecondary` | `#59413C` | `#A89F91` | **Tro Bếp / Khói Mờ** | Số ngày Âm lịch, Can Chi, chú thích, nhãn phụ |
| `textTertiary` | `#8D706B` | `#59413C` | **Khói Lam / Tro Bếp** | Ngày ngoài tháng (Out-of-month), placeholder |
| `accentHeritageRed` | `#C23B22` | `#D9534F` | **Đỏ Son Chu Sa** | Điểm nhấn Mùng 1, Rằm, Giỗ gia tiên, Tết cổ truyền |
| `accentDeepPrimary` | `#A0220B` | `#D9534F` | **Đỏ Son Đậm** | Text/icon điểm nhấn trên nền sáng |
| `accentImperialGold`| `#C5A059` | `#E9CB8F` | **Vàng Quỳ Hoàng Cúc / Đồng Thau Cổ** | Tiết khí, sao tốt (Hoàng đạo), gói Pro / Gia Phả |
| `borderSubtle` | `#E1BFB8` | `#38322D` | **Nếp Cũ Tre Mộc / Viền Tối** | Đường kẻ viền mỏng 0.5pt ngăn cách các ô lịch |
| `statusSuccess` | `#2E6F40` | `#3E8E55` | **Lá Tre** | Hoàn thành sự kiện, trạng thái tốt lành |
| `statusWarning` | `#D97706` | `#E58E26` | **Hổ Phách** | Giờ hắc đạo, cảnh báo trùng lịch |
| `statusError` | `#B91C1C` | `#D9534F` | **Huyết Dụ** | Lỗi xóa dữ liệu, cảnh báo xung khắc tuổi |

Nguồn chuẩn: `DESIGN.md` mục 2 và `Packages/VNCalendarDesignSystem/Sources/VNCalendarDesignSystem/Tokens/ColorTokens.swift`.

---

### 2.2. Hệ Thống Kiểu Chữ (Typography System)

An Niên kết hợp cặp font chữ bản địa hóa chuẩn mực của Apple:
1. **New York (Apple Serif)**: Dành cho Tiêu đề lớn, Tên ngày lễ văn hóa, Năm Can Chi, và Câu trích dẫn phong tục mang hồn cốt hoài niệm.
2. **SF Pro (Apple Sans-Serif)**: Dành cho Số ngày Dương/Âm trên lưới lịch, nhãn điều hướng, bảng giờ và biểu mẫu nhập liệu để đạt độ đọc tối ưu.

```
+-----------------------------------------------------------------------------------------+
| Style               | Font Family | Weight   | Size (pt) | Leading (pt) | Tracking (pt) |
+-----------------------------------------------------------------------------------------+
| Display Large       | New York    | Bold     | 34        | 41           | +0.37         |
| Title 1 (Hero Date) | New York    | Semibold | 28        | 34           | +0.34         |
| Title 2 (Festival)  | New York    | Medium   | 22        | 28           | +0.22         |
| Title 3 (Section)   | SF Pro      | Semibold | 20        | 25           | -0.45         |
| Headline            | SF Pro      | Semibold | 17        | 22           | -0.43         |
| Body                | SF Pro      | Regular  | 17        | 22           | -0.43         |
| Callout             | SF Pro      | Regular  | 16        | 21           | -0.31         |
| Subheadline         | SF Pro      | Regular  | 15        | 20           | -0.23         |
| Footnote            | SF Pro      | Regular  | 13        | 18           | -0.08         |
| Caption 1 (Lunar)   | SF Pro      | Medium   | 12        | 16           | 0.00          |
| Caption 2 (Can Chi) | SF Pro      | Regular  | 11        | 13           | +0.06         |
| Cell Solar Number   | SF Pro      | Medium   | 16        | 18           | -0.20         |
| Cell Lunar Number   | SF Pro      | Regular  | 10        | 12           | +0.10         |
+-----------------------------------------------------------------------------------------+
```

---

### 2.3. Khoảng Cách (Spacing) & Lưới Bố Cục (Layout Grid)

Hệ thống bước nhảy 4pt/8pt đảm bảo nhịp điệu thị giác nhất quán trên mọi kích thước iPhone và iPad.

- `space2`: 2pt — Khoảng cách giữa chấm sự kiện và số ngày Âm.
- `space4`: 4pt — Khoảng cách số Dương và số Âm trong ô lịch.
- `space8`: 8pt — Khoảng cách giữa các nhãn con, padding trong cell.
- `space12`: 12pt — Khoảng cách giữa các trường nhập liệu nhỏ.
- `space16`: 16pt — Khoảng cách giữa các nhãn con, padding trong cell (`VNSpacing.lg`, dùng cục bộ — KHÔNG phải lề chuẩn toàn cục).
- `space20`: 20pt — Lề ngoài (outer margin) + padding card + section gap chuẩn toàn cục = `VNSpacing.xl`.
- `space24`: 24pt — Khoảng cách giữa các nhóm tính năng (Section Spacing).
- `space32`: 32pt — Padding đầu trang hoặc đáy danh sách.
- `space48`: 48pt — Hero spacing trên màn hình Today Dashboard.

---

### 2.4. Viền (Borders) & Góc Bo (Corner Radius)

- **Độ dày đường kẻ (Line Width)**:
  - `hairline`: 0.5pt (Divider giữa các hàng/cột lịch).
  - `regular`: 1.0pt (Border ô được chọn hoặc viền Card).
  - `active`: 1.5pt / `focus`: 2.0pt (`VNBorderWidth` — ô đang chọn / đang focus; KHÔNG dùng cho Today).
- **Bán kính góc bo (Corner Radius)**:
  - `radiusSmall` / `VNCornerRadius.small`: 4pt (Badge ngày lễ, tag Can Chi, nút/cell nhỏ).
  - `card` / `VNCornerRadius.card`: 8pt (Card cấu trúc chuẩn).
  - `radiusMedium` / `VNCornerRadius.medium`: 10pt (Ô ngày lịch, button phụ).
  - `radiusLarge` / `VNCornerRadius.large`: 16pt (Card thông tin ngày, Widget).
  - `radiusSheet` / `VNCornerRadius.sheet`: 24pt (Day Detail Bottom Sheet modal).
  - `radiusPill` / `VNCornerRadius.pill`: 999pt (Nút hành động chính Capsule).

---

### 2.5. Hiệu Ứng Đổ Bóng (Elevations & Shadows)

An Niên sử dụng bóng mờ tông ấm hữu cơ (Organic Warm Diffuse Shadow), tuyệt đối không dùng bóng xám lạnh công nghiệp.

- **Level 1 (Cell Active / Card)**: `Color.black.opacity(0.04)`, Radius: 4, X: 0, Y: 2
- **Level 2 (Floating Action / Sheet)**: `Color.vnAccentHeritageRed.opacity(0.08)`, Radius: 12, X: 0, Y: 6
- **Level 3 (Modal / Popover)**: `Color.black.opacity(0.12)`, Radius: 24, X: 0, Y: 12

---

## 3. Mã Nguồn Cài Đặt Design Tokens (Swift Implementation)

Mã nguồn nằm trong package `VNCalendarDesignSystem`:

```swift
// Packages/VNCalendarDesignSystem/Sources/VNCalendarDesignSystem/Tokens/ColorTokens.swift
import SwiftUI

public extension Color {
    // MARK: - Initializers
    init(hex: UInt, alpha: Double = 1.0) { ... }
    init(light: Color, dark: Color) { ... }

    // MARK: - Light Mode Base Tokens
    static let vnNewRiceIvory = Color(hex: 0xFEF9F1)
    static let vnWovenLinen = Color(hex: 0xF8F3EB)
    static let vnDeepCalligraphicInk = Color(hex: 0x1D1C17)
    static let vnHearthAshGray = Color(hex: 0x59413C)
    static let vnCinnabarLacquerRed = Color(hex: 0xC23B22)
    static let vnImperialChrysanthemumGold = Color(hex: 0xC5A059)
    // ... dark-mode base tokens (vnLacquerCharcoal, vnWarmEbony, vnRicePaperWhite, vnCinnabarEmbers, vnAntiqueBrass)

    // MARK: - Semantic Adaptive Tokens
    static let vnBackgroundPrimary = Color(light: vnNewRiceIvory, dark: vnLacquerCharcoal)
    static let vnBackgroundSecondary = Color(light: vnWovenLinen, dark: vnWarmEbony)
    static let vnBackgroundTertiary = Color(light: vnAncientSand, dark: vnDarkSand)
    static let vnSurfaceElevated = Color(light: Color(hex: 0xFFFFFF), dark: vnDarkSand)

    static let vnTextPrimary = Color(light: vnDeepCalligraphicInk, dark: vnRicePaperWhite)
    static let vnTextSecondary = Color(light: vnHearthAshGray, dark: vnMutedHearth)
    static let vnTextTertiary = Color(light: vnMistGray, dark: vnHearthAshGray)

    static let vnAccentHeritageRed = Color(light: vnCinnabarLacquerRed, dark: vnCinnabarEmbers)
    static let vnAccentDeepPrimary = Color(light: vnVermilionDark, dark: vnCinnabarEmbers)
    static let vnAccentImperialGold = Color(light: vnImperialChrysanthemumGold, dark: vnAntiqueBrass)
    static let vnAccentRedSurface = Color(light: vnVermilionSurface, dark: Color(hex: 0x3A1D1A))
    static let vnAccentGoldSurface = Color(light: vnGoldSurface, dark: Color(hex: 0x332B1A))
    static let vnGoldContainer = Color(light: Color(hex: 0xFED488), dark: Color(hex: 0x5D4201))
    static let vnOnGoldContainer = Color(light: Color(hex: 0x785A1A), dark: Color(hex: 0xFFDEA5))

    static let vnBorderSubtle = Color(light: vnOldRiceBorder, dark: vnDarkBorder)
    static let vnStatusSuccess = Color(light: Color(hex: 0x2E6F40), dark: Color(hex: 0x3E8E55))
    static let vnStatusWarning = Color(light: Color(hex: 0xD97706), dark: Color(hex: 0xE58E26))
    static let vnStatusError = Color(light: Color(hex: 0xB91C1C), dark: Color(hex: 0xD9534F))
}

// Packages/VNCalendarDesignSystem/Sources/VNCalendarDesignSystem/Tokens/FontTokens.swift
import SwiftUI

public extension Font {
    // MARK: - Serif (New York) for Cultural & Emotional Content
    static let vnDisplayLarge = Font.system(.largeTitle, design: .serif).weight(.bold)
    static let vnTitleHero = Font.system(size: 28, weight: .semibold, design: .serif)
    static let vnTitleFestival = Font.system(size: 22, weight: .medium, design: .serif)
    static let vnTitleCeremonial = Font.system(size: 20, weight: .semibold, design: .serif)
    static let vnSectionHeaderSerif = Font.system(size: 20, weight: .semibold, design: .serif)
    static let vnLunarDate = Font.system(size: 14, weight: .medium, design: .serif)
    static let vnQuote = Font.system(size: 16, weight: .regular, design: .serif).italic()

    // MARK: - Sans (SF Pro) for Utility & Calendar Grid
    static let vnSectionHeader = Font.system(.title3, design: .default).weight(.semibold)
    static let vnHeadline = Font.system(.headline, design: .default)
    static let vnBody = Font.system(.body, design: .default)
    static let vnCallout = Font.system(.callout, design: .default)
    static let vnSubheadline = Font.system(.subheadline, design: .default)
    static let vnFootnote = Font.system(.footnote, design: .default)
    static let vnCaption1 = Font.system(.caption, design: .default)
    static let vnCaption2 = Font.system(.caption2, design: .default)
    static let vnCaptionCanChi = Font.system(size: 11, weight: .regular, design: .default)
    static let vnHourNumeral = Font.system(size: 13, weight: .medium, design: .default)
    static let vnWeekday = Font.system(size: 12, weight: .semibold, design: .default)

    // MARK: - Grid Cell Numerals
    static let vnCellSolar = Font.system(size: 16, weight: .medium, design: .default)
    static let vnCellSolarBold = Font.system(size: 16, weight: .bold, design: .default)
    static let vnCellLunar = Font.system(size: 10, weight: .regular, design: .default)
    static let vnCellLunarHighlight = Font.system(size: 10, weight: .semibold, design: .default)
    static let vnCellSolarTerm = Font.system(size: 9, weight: .semibold, design: .default)
}

// Packages/VNCalendarDesignSystem/Sources/VNCalendarDesignSystem/Tokens/LayoutTokens.swift
import SwiftUI

public enum VNSpacing {
    public static let space2: CGFloat = 2
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 20
    public static let xxl: CGFloat = 24
    public static let space32: CGFloat = 32
    public static let hero: CGFloat = 48
}

public enum VNCornerRadius {
    public static let small: CGFloat = 4
    public static let medium: CGFloat = 10
    public static let card: CGFloat = 8
    public static let large: CGFloat = 16
    public static let sheet: CGFloat = 24
    public static let pill: CGFloat = 999
}
```

---

## 4. Đặc Tả Wireframe & Cấu Trúc Thành Phần (Wireframes & View Hierarchies)

---

### 4.1. Lưới Lịch 42 Ô Cố Định (Calendar Grid - 6x7 Matrix)

Lưới luôn cố định 42 ô (6 hàng x 7 cột) bất kể tháng có 28, 30 hay 31 ngày, giúp triệt tiêu hoàn toàn hiện tượng rung giật chiều cao (Layout Shift) khi lướt chuyển tháng.

#### Wireframe ASCII Mockup:
```
+-----------------------------------------------------------------------------------+
|  [<]  Tháng 9, 2026   -   Tháng 8 (Đủ) Bính Ngọ                          [Hôm Nay] |
|       Tiết Thu Phân (23/09) • Trực Trừ • Hoàng Đạo                         [ + ]  |
+-----------------------------------------------------------------------------------+
|   T2   |   T3   |   T4   |   T5   |   T6   |   T7   |   CN                        |
+--------+--------+--------+--------+--------+--------+-----------------------------+
| 31     |  1     |  2     |  3     |  4     |  5     |  6                          |
| 20/7   | 21     | 22     | 23     | 24     | 25     | 26                          |
+--------+--------+--------+--------+--------+--------+-----------------------------+
|  7     |  8     |  9     | 10     | 11     | 12     | 13                          |
| 27     | 28     | 29     | 1/8(🔴)| 2      | 3      | 4                           |
|        |        |        | [MÙNG]|        |        |                             |
+--------+--------+--------+--------+--------+--------+-----------------------------+
| 14     | 15     | 16     | 17     | 18     | 19     | 20                          |
| 5      | 6      | 7      | 8      | 9      | 10     | 11                          |
+--------+--------+--------+--------+--------+--------+-----------------------------+
| 21     | 22     | 23     | 24     | 25     | 26     | 27                          |
| 12     | 13     | 14     | 15(🟡) | 16     | 17     | 18                          |
|        |        | (ThuPh)| [RẰM]  | [GIỖ]⚫ |        |                             |
+--------+--------+--------+--------+--------+--------+-----------------------------+
| 28     | 29     | 30     |  1     |  2     |  3     |  4                          |
| 19     | 20(⭕)  | 21     | 22/8   | 23     | 24     | 25                          |
|        | [H.NAY]|        |        |        |        |                             |
+--------+--------+--------+--------+--------+--------+-----------------------------+
|  5     |  6     |  7     |  8     |  9     | 10     | 11                          |
| 26     | 27     | 28     | 29     | 1/9(🔴)| 2      | 3                           |
+-----------------------------------------------------------------------------------+
```

#### Quy Tắc Hiển Thị Ô Lịch (Cell Anatomy):
1. **Số Dương Lịch (Góc trên trái / Giữa)**:
   - Màu `textPrimary` cho ngày trong tháng.
   - Màu `textTertiary` cho ngày ngoài tháng (Out-of-month).
   - Đậm hơn nếu là ngày hiện tại (`vnCellSolarBold`).
2. **Số Âm Lịch (Góc dưới phải)**:
   - Ngày thường: Hiển thị số ngày (VD: `14`, `28`).
   - Mùng 1: Hiển thị `1/tháng` (VD: `1/8`) kèm màu `accentHeritageRed` đậm nét.
   - Ngày Rằm (15 ÂL): Hiển thị `15` với huy hiệu tròn hoặc màu son chu sa.
   - Tiết Khí: Viết tắt 2 chữ (VD: `ThuPh` cho Thu Phân, `ĐôngCh` cho Đông Chí) với màu `accentImperialGold`.
3. **Chỉ Báo Sự Kiện (Indicators)**:
   - Dấu chấm Đỏ Chu: Ngày Giỗ gia tiên / Kỷ niệm hiếu nghĩa.
   - Dấu chấm Vàng Hoàng Cúc: Ngày Lễ hội / Sự kiện văn hóa quốc gia.
   - Nền đặc `#C23B22`, chữ trắng (KHÔNG vòng viền/ring): Ngày Hôm Nay.
   - Nền `backgroundSecondary` phủ trọn ô: Ngày được chọn (Selected Date).

---

### 4.2. Trang Chủ Hôm Nay (Today Dashboard)

#### Wireframe ASCII Mockup:
```
+-----------------------------------------------------------------------------------+
|  AN NIÊN                                                            [Cài Đặt ⚙️]   |
|  Thứ Ba, ngày 29 tháng 9 năm 2026                                                 |
+-----------------------------------------------------------------------------------+
|  +-----------------------------------------------------------------------------+  |
|  |  HÔM NAY                                                                    |  |
|  |                                                                             |  |
|  |      29                     Nhằm ngày 20 tháng 8 năm Bính Ngọ               |  |
|  |  Tháng 9                    Ngày Kỷ Dậu, Tháng Đinh Dậu, Năm Bính Ngọ       |  |
|  |                             Tiết Khí: Thu Phân                              |  |
|  |                                                                             |  |
|  |  [ Giờ Hoàng Đạo: Tý (23-1), Dần (3-5), Mão (5-7), Ngọ (11-13), Mùi (13-15) ] |  |
|  +-----------------------------------------------------------------------------+  |
+-----------------------------------------------------------------------------------+
|  [ + Thêm Ngày Giỗ / Nhớ ]       [ 📜 Văn Khấn Nhanh ]       [ 🔍 Tra Cứu Ngày ]   |
+-----------------------------------------------------------------------------------+
|  VIỆC NÊN LÀM & PHONG TỤC HÔM NAY                                                 |
|  • Trực Khai: Tốt cho việc cúng tế, xuất hành, khởi công, khai trương.            |
|  • Hướng tốt: Xuất hành hướng Đông Bắc nghênh đón Hỷ Thần.                        |
+-----------------------------------------------------------------------------------+
|  SỰ KIỆN GIA ĐÌNH SẮP TỚI (30 NGÀY)                                               |
|  +-----------------------------------------------------------------------------+  |
|  | 🔴 Giỗ Cụ Cố Nội (Nguyễn Văn An)                               Còn 5 ngày   |  |
|  |    05/09 Âm lịch (14/10/2026 Dương) • Chi Trưởng cúng giỗ                   |  |
|  +-----------------------------------------------------------------------------+  |
|  | 🟡 Lễ Thường Tân (Cơm Mới)                                   Còn 19 ngày   |  |
|  |    10/10 Âm lịch (18/11/2026 Dương) • Phong tục cúng cơm mới gặt hái        |  |
|  +-----------------------------------------------------------------------------+  |
+-----------------------------------------------------------------------------------+
```

---

### 4.3. Bảng Chi Tiết Ngày (Day Detail Bottom Sheet)

Khi chạm vào bất kỳ ô nào trên lưới lịch, một Bottom Sheet tương tác sẽ trượt lên với các presentation detents: `.fraction(0.35)`, `.fraction(0.7)`, `.large`.

#### Wireframe ASCII Mockup:
```
+-----------------------------------------------------------------------------------+
|                                      =====                                        |
|  Thứ Năm, 24 Tháng 9, 2026                                                        |
|  15 Tháng Tám (Rằm Trung Thu) • Năm Bính Ngọ                                      |
+-----------------------------------------------------------------------------------+
|  [ ĐÁNH GIÁ NGÀY ]                                                                |
|  ⭐️ Ngày Hoàng Đạo (Kim Đường Hoàng Đạo) • Trực Định (Bình yên, hội họp tốt)      |
|  Nhị Thập Bát Tú: Sao Bích (Tốt cho khai trương, hôn lễ, an táng)                 |
+-----------------------------------------------------------------------------------+
|  [ KHUNG GIỜ HOÀNG ĐẠO TRONG NGÀY ]                                               |
|  (🟢 Tý: 23h-01h)  (🟢 Sửu: 01h-03h)  (🟢 Mão: 05h-07h)                           |
|  (🟢 Ngọ: 11h-13h) (🟢 Thân: 15h-17h) (🟢 Dậu: 17h-19h)                          |
+-----------------------------------------------------------------------------------+
|  [ SỰ KIỆN & LỄ HỘI GIA ĐÌNH TRONG NGÀY ]                                         |
|  +-----------------------------------------------------------------------------+  |
|  | 🌕 Tết Trung Thu (Tết Trông Trăng, Rằm Tháng Tám)                            |  |
|  |    Phá cỗ, rước đèn, tết đoàn viên gia đình.                                |  |
|  |    [ Đọc Tích Truyện & Văn Khấn Rằm Trung Thu > ]                          |  |
|  +-----------------------------------------------------------------------------+  |
|  | 🔴 Giỗ Cụ Bà Nội (Lê Thị Mai)                                               |  |
|  |    Âm lịch: 15/08 Hàng năm • Báo trước 3 ngày đã gửi                        |  |
|  |    Ghi chú: Chuẩn bị 3 mâm cỗ chay, hoa quả ngũ sắc.                        |  |
|  +-----------------------------------------------------------------------------+  |
|  [ + Thêm nhắc nhở cho ngày này ]                                                 |
+-----------------------------------------------------------------------------------+
```

---

### 4.4. Biểu Mẫu Thêm / Sửa Ngày Cần Nhớ (Reminder Form)

Được thiết kế tối ưu cho thói quen cúng giỗ, nhớ ngày mất của người Việt, hỗ trợ chọn lịch Âm hoặc Dương kèm tự động xử lý năm nhuận.

#### Wireframe ASCII Mockup:
```
+-----------------------------------------------------------------------------------+
|  [Hủy]                       Tạo Ngày Cần Nhớ                             [Lưu]   |
+-----------------------------------------------------------------------------------+
|  TÊN SỰ KIỆN / NGƯỜI THÂN                                                         |
|  [ Giỗ Ông Nội (Nguyễn Văn Hùng)                                               ]  |
|                                                                                   |
|  PHÂN LOẠI                                                                        |
|  (•) Ngày Giỗ Gia Tiên    ( ) Sinh Nhật    ( ) Kỷ Niệm Cưới    ( ) Lễ Bái / Tiết  |
+-----------------------------------------------------------------------------------+
|  CHỌN HỆ LỊCH                                                                     |
|  [     Âm Lịch (Mặc định)     |           Dương Lịch           ]                  |
|                                                                                   |
|  NGÀY ÂM LỊCH:                                                                    |
|  Ngày [ 18 v ]   Tháng [ 07 (Tháng Bảy) v ]   Năm mất [ 2012 (Nhâm Thìn) v ]     |
|                                                                                   |
|  TỰ ĐỘNG XỬ LÝ NĂM NHUẬN ÂM LỊCH:                                                 |
|  [x] Tự động lùi về ngày 29 nếu tháng thiếu (không có ngày 30)                    |
|  [x] Nhắc vào tháng chính nếu gặp năm nhuận                                       |
+-----------------------------------------------------------------------------------+
|  QUAN HỆ GIA PHẢ                                                                  |
|  Danh xưng: [ Cụ / Ông / Bà / Cha / Mẹ / Bác / Chú / Cô / Thím v ]                |
+-----------------------------------------------------------------------------------+
|  LẬP LỊCH BÁO TRƯỚC (QUẢN LÝ HẠN NGẠCH 64 SLOTS)                                  |
|  [x] Báo trước 14 ngày (Bàn bạc gia đình, phân công giỗ chạp)                     |
|  [x] Báo trước 3 ngày  (Đi chợ, mua sắm lễ vật)                                  |
|  [x] Báo trước 1 ngày  (Chuẩn bị nấu cỗ)                                          |
|  [x] Đúng ngày (06:00 Sáng)                                                       |
+-----------------------------------------------------------------------------------+
|  GHI CHÚ / BÀI VĂN KHẤN ĐÍNH KÈM                                                  |
|  [ Văn khấn cúng giỗ gia tiên mẫu số 2, cúng hoa quả tươi...                   ]  |
+-----------------------------------------------------------------------------------+
```

---

### 4.5. Dòng Thời Gian Kỷ Niệm Sắp Tới (Upcoming Timeline)

Hiển thị danh sách giỗ chạp, ngày rằm, mùng một và kỷ niệm gia đình theo trục thời gian tuyến tính cuộn mượt.

#### Wireframe ASCII Mockup:
```
+-----------------------------------------------------------------------------------+
|  NGÀY NHỚ GIA ĐÌNH                                                      [ + Thêm] |
|  Tìm kiếm sự kiện, tên người thân...                                              |
+-----------------------------------------------------------------------------------+
|  THÁNG 10, 2026 (THÁNG 8 & 9 ÂM LỊCH)                                             |
|                                                                                   |
|  o--- 14 THÁNG 10 (05/08 ÂL) -------------------------------------------------+  |
|  |    🔴 GIỖ CỤ CỐ NỘI (Nguyễn Văn An)                             Còn 5 ngày |  |
|  |       Âm lịch: 05/08 • Giỗ đầu (Trưởng họ cúng)                            |  |
|  |       Nhắc trước: Đã gửi nhắc nhở 3 ngày                                   |  |
|  +----------------------------------------------------------------------------+  |
|  |                                                                                |
|  o--- 24 THÁNG 10 (15/08 ÂL) -------------------------------------------------+  |
|  |    🌕 TẾT TRUNG THU (RẰM THÁNG TÁM)                            Còn 15 ngày |  |
|  |       Âm lịch: 15/08 • Lễ hội truyền thống                                 |  |
|  +----------------------------------------------------------------------------+  |
|  |                                                                                |
|  o--- 29 THÁNG 10 (20/08 ÂL) -------------------------------------------------+  |
|  |    🔵 SINH NHẬT MẸ (Trần Thị Lan)                              Còn 20 ngày |  |
|  |       Dương lịch: 29/10 • Mừng thọ 65 tuổi                                 |  |
|  +----------------------------------------------------------------------------+  |
|                                                                                   |
|  THÁNG 11, 2026 (THÁNG 9 & 10 ÂM LỊCH)                                            |
|  o--- 09 THÁNG 11 (01/09 ÂL) -------------------------------------------------+  |
|  |    🔴 MÙNG 1 ĐẦU THÁNG CHÍN ÂM LỊCH                            Còn 31 ngày |  |
|  |       Dâng hương gia tiên, cầu an                                          |  |
|  +----------------------------------------------------------------------------+  |
+-----------------------------------------------------------------------------------+
```

---

## 5. Khả Năng Tiếp Cận & Chuẩn HIG (Accessibility & VoiceOver Guidelines)

An Niên tuân thủ 100% chuẩn Accessibility của Apple để người cao tuổi và người khiếm thị có thể dễ dàng tra cứu lịch và ngày giỗ.

### 5.1. Hỗ Trợ Dynamic Type Toàn Diện
Tất cả các thành phần văn bản sử dụng `@ScaledMetric` để mở rộng tự nhiên theo thiết lập cỡ chữ của hệ thống mà không làm gãy lưới 42 ô.

```swift
struct VNDayCellAccessibilityModifier: ViewModifier {
    @ScaledMetric(relativeTo: .body) private var solarFontSize: CGFloat = 16
    @ScaledMetric(relativeTo: .caption2) private var lunarFontSize: CGFloat = 10
    
    func body(content: Content) -> some View {
        content
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }
}
```

### 5.2. Chuẩn VoiceOver Rotor & Đọc Âm Lịch Chi Tiết
Mỗi ô lịch cung cấp chuỗi ngữ nghĩa (`accessibilityLabel`) đầy đủ cấu trúc ngày Dương, ngày Âm, Can Chi và sự kiện hiếu nghĩa:

```swift
public extension CalendarDayState {
    func makeVoiceOverDescription(dayModel: VNCalendarDayModel) -> String {
        var desc = "Thứ \(dayModel.weekdayName), ngày \(dayModel.solarDay) tháng \(dayModel.solarMonth) năm \(dayModel.solarYear) Dương lịch. "
        desc += "Nhằm ngày \(dayModel.lunarDay) tháng \(dayModel.lunarMonthName) năm \(dayModel.lunarYearCanChi) Âm lịch. "
        
        if dayModel.isFirstDayOfLunarMonth {
            desc += "Hôm nay là Mùng 1 đầu tháng Âm lịch. "
        } else if dayModel.isFullMoonDay {
            desc += "Hôm nay là Ngày Rằm 15 Âm lịch. "
        }
        
        if let solarTerm = dayModel.solarTermName {
            desc += "Tiết khí \(solarTerm). "
        }
        
        if !dayModel.anniversaries.isEmpty {
            let names = dayModel.anniversaries.map(\.title).joined(separator: ", ")
            desc += "Có \(dayModel.anniversaries.count) sự kiện gia đình: \(names). "
        }
        
        if dayModel.isToday {
            desc += "Hôm nay. "
        }
        if dayModel.isSelected {
            desc += "Đang chọn."
        }
        
        return desc
    }
}
```

### 5.3. Khu Vực Tương Tác Cảm Ứng (Minimum Tap Target)
Mọi ô ngày trên lưới 42 ô lịch và các nút bấm đều đảm bảo vùng cảm ứng tối thiểu **$44 \times 44\text{ pt}$** theo đúng chuẩn Apple HIG. Khi hiển thị trên màn hình nhỏ (iPhone SE), ô lịch tự động mở rộng vùng nhận cảm ứng (`contentShape(Rectangle())`).

### 5.4. Chế Độ Giảm Chuyển Động (Reduce Motion)
Hệ thống tự động lắng nghe biến môi trường `@Environment(\.accessibilityReduceMotion)`. Khi người dùng kích hoạt Reduce Motion, các hiệu ứng trượt lò xo (Spring Physics) sẽ chuyển đổi sang hiệu ứng mờ dần nhẹ nhàng (`.opacity.animation(.easeInOut(duration: 0.15))`).

---

## 6. Động Lực Học Chuyển Động (Apple Spring Animations)

An Niên áp dụng hệ thống chuyển động vật lý Apple Spring trên iOS 17/18:

### 6.1. Bảng Thông Số Animation Tokens

```swift
import SwiftUI

public enum VNAnimation {
    // MARK: - Chuyển Tháng Lưới Lịch (Smooth Horizontal Paging)
    public static let monthTransition = Animation.spring(
        response: 0.38,
        dampingRatio: 0.82,
        blendDuration: 0.1
    )
    
    // MARK: - Chạm Chọn Ô Lịch (Snappy Day Selection Pulse)
    public static let cellSelection = Animation.spring(
        response: 0.28,
        dampingRatio: 0.70,
        blendDuration: 0
    )
    
    // MARK: - Trượt Bottom Sheet (Bouncy Sheet Detents)
    public static let sheetSpring = Animation.spring(
        response: 0.45,
        dampingRatio: 0.78,
        blendDuration: 0.15
    )
    
    // MARK: - Mở Thẻ Thông Tin Mở Rộng
    public static let cardExpansion = Animation.snappy(
        duration: 0.35,
        extraBounce: 0.08
    )
}
```

### 6.2. Hiệu Ứng Phản Hồi Khi Chạm Ô Lịch (Cell Tap Physics)

Khi chạm vào một ô lịch:
1. Scale co nhẹ xuống `0.94` trong 60ms.
2. Nẩy bung về `1.04` và ổn định tại `1.0` với lò xo `response: 0.28, dampingRatio: 0.7`.
3. Kích hoạt haptic feedback phản hồi xúc giác nhẹ (`UIImpactFeedbackGenerator(style: .light).impactOccurred()`).

```swift
struct DayCellPressModifier: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.94 : 1.0)
            .animation(VNAnimation.cellSelection, value: isPressed)
            ._onButtonGesture { pressing in
                self.isPressed = pressing
            } perform: {}
    }
}
```
