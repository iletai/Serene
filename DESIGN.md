# Design System: An Niên (Vietnamese Lunar Editorial)
**Stitch Project ID:** 9156707561340621727
**Source of truth:** `.stitch/ref/STYLE_BRIEF.md` + `.stitch/ref/canonical.html` (Stitch-approved). Hex values below match `ColorTokens.swift` exactly.

## 1. Visual Theme & Atmosphere
The Creative North Star for An Niên is **"Vietnamese Lunar Editorial" (Đông Dương Thư Tịch & Ấn Triện)**—a serene, high-end editorial digital sanctuary tailored for Vietnamese families, ancestral remembrance (ngày giỗ chạp), and lunar-solar harmony.

Moving away from the cluttered, ad-heavy traditional calendar apps and sterile AI-generated utilities, An Niên captures the tactile warmth of handcrafted rice paper (giấy Dó / giấy điệp), imperial lacquerware (sơn son thếp vàng), debossed red seals (Ấn Triện), and Vietnamese calligraphic ink (mực nho). The interface embodies **Tĩnh Tại (Serenity)** with expansive negative space, **Trang Nhã (Elegance)** through intentional golden-ratio proportions, and **Bản Địa (Authenticity)** with deep support for Lunar phases, Can Chi cycles, 24 Solar Terms (Tiết khí), and family heritage.

---

## 2. Color Palette & Roles (Stitch-Approved Vietnamese Materiality)

Semantic tokens are dynamic (light / dark). Light values come from the Stitch canonical design; dark values are the app's existing lacquerware counterparts.

### Surfaces
*   **Nền chính `vnBackgroundPrimary`:** `#FEF9F1` / `#181614` — primary canvas background, warm handmade mulberry paper.
*   **Thẻ nâng cao `vnBackgroundSecondary`:** `#F8F3EB` / `#24201D` — hero card surface, elevated panels, toolbars.
*   **Nhóm / chip `vnBackgroundTertiary`:** `#ECE8E0` / `#2E2925` — grouped lists, category chips, insets.
*   **Bề mặt nổi `vnSurfaceElevated`:** `#FFFFFF` / `#2E2925` — sheets, floating bottom nav pill, popovers.
*   **Viền mảnh `vnBorderSubtle`:** `#E1BFB8` / `#38322D` — hairline dividers and cell frames. Gold hairline for rice-paper card frames: `vnImperialChrysanthemumGold.opacity(0.28)`.

### Text
*   **Chữ chính `vnTextPrimary`:** `#1D1C17` / `#FAF7F0` — primary text and calendar numerals.
*   **Chữ phụ `vnTextSecondary`:** `#59413C` / `#A89F91` — lunar dates, Can Chi, metadata.
*   **Chữ thứ ba `vnTextTertiary`:** `#8D706B` / `#59413C` — out-of-month cells, placeholders.

### Accents
*   **Đỏ Son Chu Sa `vnAccentHeritageRed`:** `#C23B22` / `#D9534F` — primary accent: Giỗ, Mùng 1, Rằm, Ấn Triện, today's cell.
*   **Đỏ Son Đậm `vnAccentDeepPrimary`:** `#A0220B` / `#D9534F` — deep vermilion for text/icons on light surfaces.
*   **Nền Son Nhạt `vnAccentRedSurface`:** `#F5E3DA` / `#3A1D1A` — soft red tint (Mùng 1 cells, selected tabs).
*   **Vàng Quỳ Hoàng Cúc `vnAccentImperialGold`:** `#C5A059` / `#E9CB8F` — gold accent: Tiết Khí, Hoàng Đạo, Pro tier.
*   **Container Vàng `vnGoldContainer`:** `#FED488` / `#5D4201` — gold chips and "Hôm nay" status pill.
*   **Chữ trên Container Vàng `vnOnGoldContainer`:** `#785A1A` / `#FFDEA5`.
*   **Nền Vàng Quỳ Nhạt `vnAccentGoldSurface`:** `#F8F2E4` / `#332B1A` — soft gold tint, Rằm cells, festival cards.

### Status
*   **Thành công `vnStatusSuccess`:** `#2E6F40` / `#3E8E55` — completed memorial tasks.
*   **Cảnh báo `vnStatusWarning`:** `#D97706` / `#E58E26` — reminder warnings, Hắc đạo hours.
*   **Lỗi `vnStatusError`:** `#B91C1C` / `#D9534F`.

---

## 3. Typography Rules

No bundled font files. The native iOS pairing is the correct equivalent of Stitch's Noto Serif + Be Vietnam Pro:

*   **Display & Ceremonial Titles (Apple New York Serif):** large solar dates (56pt / 300 light on mobile), lunar month titles, festival names, section headings, poetry excerpts. Conveys dignity, heritage, and timelessness.
*   **Utility & Calendar Matrix (SF Pro):** grid numerals, Can Chi labels, hour schedules, form fields, labels (label-md: 11pt / 500 / +0.06em tracking), lunar callout (14pt Serif / 700).

#### Type Ladder (canonical-derived)

| Role | Size / Weight | FontTokens | Dùng cho |
|---|---|---|---|
| Display date | 56 / 300 serif | `vnHeroNumeral` | Số dương lịch hero |
| Headline large | 28 / 600 serif | `vnTitleHero` | Tiêu đề hero card |
| Headline medium | 22 / 500 serif | `vnTitleFestival` | Tiêu đề tháng |
| Section title | 20 / 600 serif | `vnSectionHeaderSerif` | Section heading |
| Body large | 17 / 400 sans | `vnBody` | Thân bài |
| Callout | 16 / 600 (title) hoặc 16 / 400 (body) | `vnCallout` | Card title |
| Subheadline | 15 / 400 sans | `vnSubheadline` | Sub body |
| Label small | 13 / 600 serif | `vnFootnote` + weight | Nút nhỏ, label lớn |
| Label medium | 11 / 500 +0.06em | `vnCaption2` + tracking | Eyebrow, meta, nav label |
| Lunar callout | 14 / 700 serif | `vnLunarDate` | Lunar ngày |
| Cell grid | solar 14 / lunar 10 italic | `vnCellSolar` + italic | Ô lưới 42 cells |

Icon-to-text: icon cao ≈ `fontSize` text cùng hàng (±1), không bao giờ icon cao hơn 1.5× height text kế bên.

Font sizes and tracking live in `FontTokens.swift`; families never change.

---

## 4. Layout Rules (from canonical HTML & Design System Truth)

### 4.1 Spacing Scale & Hierarchy

| Token | Giá trị | Vai trò & Ngữ cảnh áp dụng |
|---|---|---|
| `VNSpacing.space2` | 2pt | Gap siêu nhỏ: Title-to-Subtitle trong component, spacing giữa các indicator dots. |
| `VNSpacing.xs` | 4pt | Gap vi mô: HStack icon-với-text, padding dọc tag/badge, spacing giữa modes segmented picker. |
| `VNSpacing.sm` | 8pt | Gap thành phần phụ: Khoảng cách giữa leading accent bar và title trong header, horizontal chip padding. |
| `VNSpacing.md` | 12pt | Gap cơ sở: Spacing trong list row, search field padding, khoảng cách icon-to-text trong row, legend items gap. |
| `VNSpacing.lg` | 16pt | Gap phân đoạn nội bộ: Horizontal padding của row danh sách, button medium padding. |
| `VNSpacing.xl` | 20pt | **Mốc bố cục chuẩn**: Outer screen margin, card inner padding, section gap giữa các khối nội dung. |
| `VNSpacing.xxl` | 24pt | Gap lớn: Phân cách giữa các block chức năng chính hoặc bottom sheet header. |
| `VNSpacing.space32` / `golden` | 32pt | **Tỷ lệ vàng**: Hero gap bố cục trang nhất (`≈ 20 × 1.618`), khoảng đệm màn hình thoáng đãng. |
| `VNSpacing.hero` | 48pt | Khoảng đệm đặc biệt: Header trang Nhật Lịch, khoảng trống lớn đầu trang rỗng/chào đón. |

#### Canonical Deviations & Hiển thị đặc biệt
*   Canonical HTML dùng `space-md = 14pt`; token `VNSpacing.md = 12pt`. Chốt giữ **12pt** (thang chẵn), mọi chỗ canonical `space-md` map về `md` — lệch tối đa 2pt, chấp nhận được.
*   Main content dưới top-bar fixed: `pt = 80pt` (`VNSpacing.hero` 48 + header, hoặc `.safeAreaInset` tự trừ) — không dùng nhầm `hero`.
*   Đáy Scroll: `pb ≥ 128pt` để Floating Bottom Nav (cao ~56 + offset 14) không đè nội dung cuối.
*   Bottom Nav offset: **14pt** trên safe area (canonical `bottom: space-md`).

#### Component Gap Matrix (Nguyên tắc phối ghép)
*   **HStack Icon-Text:** Dùng `VNSpacing.xs` (4pt).
*   **Title-Subtitle nội bộ:** Dùng `VNSpacing.space2` (2pt) hoặc cố định 1-2pt.
*   **List Row Padding:** Ngang `VNSpacing.lg` (16pt), dọc `VNSpacing.md` (12pt).
*   **Card Container Padding:** Mặc định `VNSpacing.xl` (20pt) cả 4 chiều (`EdgeInsets`).
*   **Section Gap:** Luôn cách nhau `VNSpacing.xl` (20pt).
*   **Outer Screen Margin:** Luôn đặt `VNSpacing.xl` (20pt) ở 2 lề màn hình.

---

### 4.2 Interactive Elements & Buttons

| Size | minHeight | horizontalPadding | Corner Radius | fontSize / Typo | Ngữ cảnh |
|---|---|---|---|---|---|
| `.small` | 44pt | `VNSpacing.md` (12pt) | `VNCornerRadius.small` (8pt) | 12pt Serif semibold | Thao tác phụ gọn, filter, thẻ nhỏ. |
| `.medium` | 44pt | `VNSpacing.lg` (16pt) | `VNCornerRadius.small` (8pt) | 14pt Serif semibold | Nút chuẩn toàn ứng dụng. |
| `.large` | 52pt | `VNSpacing.xl` (20pt) | `VNCornerRadius.small` (8pt) | 16pt Serif semibold | Nút hành động chính (CTA, Paywall, Save). |

> Tỷ lệ text/height: `.small` 12/44 = 0.27, `.medium` 14/44 = 0.32, `.large` 16/52 = 0.31. Icon trong button luôn `fontSize - 1`, giữ quan hệ size-1 cố định.

#### Touch Target & Top-Bar Exception Rule
*   **Chuẩn tối thiểu HIG:** Mọi phần tử tương tác (button, row, toggle, picker segment, cell) bắt buộc đạt khung chạm tối thiểu **44pt** (`minHeight: 44` / `minWidth: 44`).
*   **Ngoại lệ Top Bar:** Icon hit frame trên top navigation bar / toolbar cho phép kích thước thị giác **36x36pt**, nhưng vùng chạm thực tế (`frame(minWidth: 44, minHeight: 44)`) vẫn phải đạt tối thiểu 44pt thông qua `VNDismissButton` hoặc tap target inset.

---

### 4.3 Corner Radius Decision Tree

```
Chọn Corner Radius cho Component?
├── Micro shape dưới scale (accent bar 3pt, swatch ring 10×10, ribbon)  ──> VNCornerRadius.micro (4pt)
├── Button / Grid Cell / Mode Segment / Seal bo góc      ──> VNCornerRadius.small (8pt)
├── Floating Card / Surface Container / Field / Inner Panel
│   (VNCard, VNGroupCard, VNSearchField, inner panel)    ──> VNCornerRadius.card (12pt structural)
├── Sheet / Modal Container (Bottom sheet lớn)           ──> VNCornerRadius.sheet (28pt)
└── Tag ngữ nghĩa đặc thù:
    ├── Chi tiết Can Chi, Hoàng Đạo, Filter chip, Pills    ──> Capsule / VNCornerRadius.pill (999pt)
    └── Hắc Đạo hoặc thẻ thông tin kỹ thuật               ──> VNCornerRadius.small (8pt)
```

> **Deviation có chủ đích khỏi Stitch canonical:** canonical HTML ghi `rounded-xl = 8pt` (card) và `rounded-lg = 4pt` (button/cell). An Niên nâng toàn thang **+4** (`card 12`, `small 8`, `micro 4`, `sheet 28`) để bo góc mềm hơn, hợp chất liệu giấy dó/sơn son; quyết định do người dùng chốt. Hierarchy vẫn nguyên: `sheet > card > small > micro`.

---

### 4.4 Borders, Shadows & Surface Materials

*   **Border Rules:**
    *   **Thẻ Giấy Điệp / Rice-paper card frame:** Viền hairline 1pt mang sắc vàng quỳ: `Color.vnAccentImperialGold.opacity(0.28)`.
    *   **Viền ngăn cách nội bộ & hairline:** Dùng `Color.vnBorderSubtle` với bề dày `VNBorderWidth.hairline` (1.0pt) hoặc `VNBorderWidth.hairlineThin` (0.5pt).
    *   **Focus / Active State:** Viền kích hoạt đạt `VNBorderWidth.active` (1.5pt) hoặc `VNBorderWidth.focus` (2.0pt) với sắc Đỏ Son `vnAccentHeritageRed.opacity(0.5)`.
*   **Shadow Palette (Tuyệt đối không dùng shadow đen đặc nặng):**
    *   `VNShadow.folio`: `0 4px 20px -2px rgba(90,84,79,0.05)` (bóng giấy mộc mặc định cho VNCard).
    *   `VNShadow.card`: `radius: 4, y: 2, black @ 0.04` (độ nổi nhẹ cho thẻ nhỏ, nút seal).
    *   `VNShadow.warmDiffuse`: `radius: 16, y: 6, vnAccentHeritageRed @ 0.06` (ánh đỏ son lan tỏa nhẹ).
    *   `VNShadow.floating`: `radius: 12, y: 6, vnAccentHeritageRed @ 0.08` (cho bottom nav bar hoặc dock nổi).
    *   `VNShadow.modal`: `radius: 16, y: 8, black @ 0.08` (cho sheet / popup).
*   **Group Stack & Dividers:**
    *   Trong `VNGroupCard`, dùng `VStack(spacing: 0)` kèm `VNRowDivider(leadingInset:)`.
    *   **Cấm:** Không dùng `Divider()` trần mặc định của hệ thống.
*   **Ấn Triện (Seal):**
    *   Kích thước vuông chuẩn: 40x40pt.
    *   Viền ngoài: 2pt (`VNBorderWidth.focus`) màu Đỏ Son Chu Sa.
    *   Inset ring: Vòng viền trong inset 1pt với nét mảnh `vnAccentHeritageRed.opacity(0.4)`.
*   **Lưới Lịch & Indicator Dots (Calendar Grid):**
    *   Lưới cố định 6x7 = 42 ô, triệt tiêu hoàn toàn layout shift khi đổi tháng.
    *   **3 bậc dot, không gộp:**
        | Dùng | Kích thước | Token |
        |---|---|---|
        | Chấm trạng thái trong ô (Hoàng Đạo vàng, Giỗ đỏ) | **4pt** | `VNSpacing.xs` |
        | Chấm nhấn "Hôm nay" trên strip | **6pt** | hằng số (không thuộc thang spacing) |
        | Dot legend dưới lưới | **8pt** | `VNSpacing.sm` |
    *   Ô ngoài tháng: làm mờ với opacity chính xác **0.35**.
    *   Chữ ô lưới: solar `14pt`, lunar `10pt italic`; chữ "Hôm nay" trên strip `11pt`.
*   **Hero Card Trang Lịch Ngày:**
    *   4 góc L (`12×12pt` stroke `vnBorderSubtle.opacity(0.6)`, offset 8pt từ góc card).
    *   Divider giữa đầu card có ornament mặt trời đặt chính giữa, nền phủ lên đường kẻ.
*   **Top Bar:** title serif **18pt/600** đỏ son, subtitle **11pt/500**, hit target 36pt (ngoại lệ 44pt rule), nền `vnBackgroundPrimary.opacity(0.9)` + blur.
*   **Bottom Nav pill:** offset **14pt**, shadow `VNShadow.floating`, surface `vnSurfaceElevated.opacity(0.85)` + ultraThinMaterial, hairline `vnBorderSubtle.opacity(0.4)`, icon 22pt + label 11pt.

---

## 5. Rich Multi-Mode Calendar Architecture

1.  **Nhật Lịch (Traditional Daily Block / Block Lịch Xé — `VNBlockCalendarView.swift`):**
    *   Large focal calligraphic solar day numeral (56pt light weight on mobile).
    *   Vietnamese Lunar date accompanied by an authentic Ấn Triện seal badge.
    *   Can Chi (Ngày, Tháng, Năm), Tiết Khí (Solar Terms), Giờ Hoàng Đạo, Hướng Hỷ Thần / Tài Thần, Việc Nên Làm / Kiêng Cữ, và Danh ngôn văn hoá dân gian.
2.  **Tháng (Month Grid - 6x7 Matrix):**
    *   Strict 42-cell grid avoiding layout shifts.
    *   Solar and Lunar date integration in each cell.
    *   Ấn Triện emblems on Mùng 1 & Rằm.
    *   Indicators for Giỗ gia tiên, Lễ hội, and Hôm nay.
    *   Implementation note: there is no `VNMonthCalendarView.swift`. The month grid renders inline inside `Packages/VNCalendarKit/Sources/VNCalendarKit/Views/VNCalendarContainerView.swift` via its private `monthGridView` (cells built by `VNDayCellView`).
3.  **Tuần (Week Strip & Hourly Schedule — `VNWeekCalendarView.swift`):**
    *   Horizontal scrollable / selectable 7-day strip.
    *   Detailed daily timeline with auspicious hours and memorial reminders.
4.  **Năm (Year Overview — `VNYearCalendarView.swift`):**
    *   12-month mini-grid overview for rapid navigation across the lunar-solar year.
