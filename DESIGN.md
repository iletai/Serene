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

Font sizes and tracking live in `FontTokens.swift`; families never change.

---

## 4. Layout Rules (from canonical HTML)

*   Outer margin: 20pt. Card padding: 20pt. Section gap: 20pt (`VNSpacing.xl`).
*   Corner radius: 8pt structural cards (`VNCornerRadius.card`), 4pt small buttons/cells (`VNCornerRadius.small`), full pill only for Can Chi / Hoàng Đạo tags / filter chips.
*   Borders: 1px hairline — gold-tinted (`gold @ 0.28`) on rice-paper cards, `vnBorderSubtle` for internal rules. No heavy shadows; faint folio shadow `0 4px 20px -2px rgba(90,84,79,0.05)`.
*   Hero "trang lịch ngày": dual corner framing marks (`vnBorderSubtle @ 0.6`), huge light-weight solar numeral, red serif lunar callout, Can Chi column rows, Giờ Hoàng Đạo chip strip, Việc Nên Làm / Việc Kiêng Cữ as two side-by-side tinted panels.
*   Calendar grid: fixed 6x7 = 42 cells, no layout shift. Weekday header T2…T6 + CN (CN red). Mùng 1: red tint bg + red border. Rằm: gold tint bg + gold border. Today: solid `#C23B22`, white numerals. Hoàng Đạo: 4pt gold dot. Giỗ: 4pt red dot. Out-of-month: opacity 0.35. Legend row under grid.
*   Seal (Ấn Triện): 40x40 square, 2px red border, red serif text, inset ring + faint red shadow.
*   Bottom nav: floating pill, `vnSurfaceElevated @ 0.85` + ultraThin material, hairline `vnBorderSubtle @ 0.4`, ~12pt above safe area, icon 22pt + 11pt label, active red + filled symbol.
*   Top bar: translucent `vnBackgroundPrimary @ 0.9` + blur, serif red title, 11pt secondary subtitle, 36pt rounded hit targets.

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
