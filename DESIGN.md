# Design System: An Niên (Phố Đèn Lồng)

An Niên is a Vietnamese lunar-solar and memorial calendar for iOS: "Lịch Việt & Ngày Nhớ". Its design direction is **Phố Đèn Lồng (Lantern Street)**: the colours of a Vietnamese street at Tết and Trung Thu (lantern red, mai-blossom yellow, dong-leaf green, Hội An blue) set on a cool, clean page by day and a lunar-night indigo by night, with bold rounded type and motion that springs, stamps and sways. Three words govern it: **Tươi** (fresh: clear colour, generous space), **Vui** (playful: things you touch respond), **Bản Địa** (authentic: lunar phases, Can Chi, the 24 solar terms, family rites). One rule keeps it honest: **playful in the calendar, quiet in remembrance.**

The shipping system is the Swift package `VNCalendarDesignSystem`. Token names here are the Swift names (`Color.vnTextPrimary`, `VNSpacing.xl` written `VNSpacing-xl`). Canonical values live in `Tokens/*.swift`. A few names now describe their old role rather than their new look (`vnAccentHeritageRed` is lantern red, `vnAccentImperialGold` is mai yellow, `vnSectionHeaderSerif` is no longer a serif); keep using them.

## Content fundamentals

- **Vietnamese first**, with full diacritics, even in capitals: "RẰM", "GIỖ", "TIẾT HÀN LỘ". English is the second localisation.
- **Use the tradition's own words** and don't gloss them: Giỗ, Mùng 1, Rằm, Tết, Can Chi, Tiết Khí, Hoàng Đạo, Hắc Đạo, Âm lịch, Dương lịch, Văn Khấn, Gia Tộc.
- **Title Case for titles and actions**: "Thêm Ngày Nhớ", "Tra Cứu", "Tháng Mười · 2026". Sentence case for body and subtitles.
- **Capitals only for kickers and seals**: "ÂM LỊCH", "MÙNG 1". Kickers are uppercased by the component.
- **Actions are verb + object**, two to four words: "Thêm Ngày Giỗ Đầu Tiên", "Xem tất cả". Dismissals are one word: "Đóng", "Xong".
- **Dates**: "Thứ Hai, 12 Tháng 10"; lunar "Ngày 3 · Tháng Chín", or "15/8 âm" when compact; hours "03h - 05h". The middle dot joins paired facts.
- **Tone is warm and lively in the calendar** ("6 giờ lành hôm nay", "Còn 3 ngày là Rằm") and **calm and respectful around memorials** ("Gìn Giữ Đạo Hiếu Gia Tiên"). Empty states may quote ca dao. Never promotional urgency.
- **No emoji and no exclamation marks.** Personality comes from colour, artwork and motion, not punctuation.
- The app speaks as the calendar: no "tôi"; "bạn" only where an instruction needs it.

## Colour

Two themes, `light` (cool mist) and `dark` (lunar night). Every colour is a semantic token; never hard-code a hex.

**Surfaces.** Page `vnBackgroundPrimary`; cards, fields, grouped lists `vnBackgroundSecondary`; tracks, insets and hour cells `vnBackgroundTertiary`; sheets and the tab bar `vnSurfaceElevated`. The hero daily-sheet card is `vnNight` in both themes.

**Text.** `vnTextPrimary`, `vnTextSecondary`, `vnTextTertiary`; all pass 4.5:1 on all three backgrounds in both themes. On `vnNight` use `vnOnNight`, `vnAccentImperialGold` and `vnAccentBlossom` only.

**The four street colours**, each with a strong value for text and icons and a soft surface to sit on:

| colour | strong | surface | means |
|---|---|---|---|
| Đỏ Lồng Đèn | `vnAccentHeritageRed`, `vnAccentDeepPrimary` (text) | `vnAccentRedSurface` | Giỗ, Mùng 1, Rằm, today, seals, the primary action |
| Vàng Hoa Mai | `vnAccentImperialGold` (fill only), `vnAccentGoldText` (text) | `vnGoldContainer` + `vnOnGoldContainer`, `vnAccentGoldSurface` | Hoàng Đạo, Pro, the moon, festivals of light |
| Xanh Lá Dong | `vnAccentJade` | `vnAccentJadeSurface` | Tiết khí, seasons, success, app info |
| Xanh Lam Hội An | `vnAccentSky` | `vnAccentSkySurface` | Lễ hội, notifications, links, search |

`vnAccentBlossom` (Hoa Đào pink) is decoration: artwork, celebration petals, the lunar date on the night card. It never carries meaning on a light surface.

**Red still means "this day matters".** Use it for at most three things per screen. Spread personality with the other three colours instead: give each settings group, chip type and badge its own colour from the table.

**On fills** use `vnOnAccent` (white by day, night-indigo by night) on red, jade, sky and error fills; use the fixed `vnDeepCalligraphicInk` on `vnAccentImperialGold`.

**Status** (`vnStatusSuccess`, `vnStatusWarning`, `vnStatusError`) always comes with a word or icon. Hoàng Đạo vs Hắc Đạo is told by lightness (pale gold pill vs solid ink tag), shape and word, never hue alone. Calendar marks differ by shape as well as colour (see `VNIndicatorDotsView`).

**Borders.** `vnBorderSubtle` is a decorative hairline (about 1.3:1). Anything that must read as a boundary (fields, the secondary button) uses `vnBorderStrong` (3.3:1 or better). Keyboard focus is a `VNBorderWidth-focus` ring in `vnAccentSky`, offset 2px.

**No gradients** in UI. Depth comes from flat colour, the lip and soft shadows. Artwork may use flat transparency (halos), never colour-to-colour gradients.

## Typography

One family: **Be Vietnam Pro**, a typeface designed in Vietnam for Vietnamese, with the stacked diacritics drawn properly. It is open source (SIL OFL): bundle its files in the app; on the web load it from Google Fonts. The `display` and `text` families both name it, with SF Pro Rounded and SF Pro as fallbacks.

- **Display (700–800)** carries numerals, titles, seals, buttons and the mode picker: `vnHeroNumeral` (72/800, -2px, on the night card), `vnDisplayLarge`, `vnTitleHero`, `vnTitleFestival`, `vnTitleCeremonial`, `vnSectionHeaderSerif`, `vnLunarDate`, and `vnQuote` (500 italic, for ca dao).
- **Text (400–700)** carries everything read at a glance: `vnBody`, `vnCallout`, `vnSubheadline`, captions, Can Chi, hours, and the matrix (`vnCellSolar` 17/600 over `vnCellLunar` 10/500).
- Tighten large display sizes (-0.2 to -2px); open small caps (+0.4 to +0.8px). Kickers are 11/700 uppercase +0.8.
- Body, captions and button labels follow Dynamic Type; matrix numerals and seals stay fixed.
- An icon beside text matches the text's size, ±1pt.

## Spacing and layout

A 4pt scale anchored on **`VNSpacing-xl` (20): screen margin, card padding and section gap.**

- Icon to text `VNSpacing-xs`; title to subtitle `VNSpacing-space2`; list rows `VNSpacing-lg` × `VNSpacing-md`.
- Hero gaps `VNSpacing-golden` (32); page-top space `VNSpacing-hero` (48).
- Every interactive element has a hit area of at least `VNSize-minTapTarget` (44).
- The month grid is always 6 × 7 = 42 cells.
- The tab bar floats: a `VNCornerRadius-pill` on `vnSurfaceElevated`, at most `VNLayout-tabBarMaxWidth`, `VNLayout-tabBarBottomInset` above the safe area, `VNShadow-floating`. The active tab's icon sits in a `vnAccentRedSurface` pill with its label in `vnAccentDeepPrimary`. Scroll content clears it with `.vnTabBarClearance()`.

## Shape

Rounder and friendlier: `VNCornerRadius-micro` (6) for bars, swatches and the Hắc Đạo tag; `VNCornerRadius-small` (12) for cells, tiles and seals; `VNCornerRadius-card` (20) for cards and panels; `VNCornerRadius-sheet` (32) for sheets; `VNCornerRadius-pill` for every button, chip, field, segmented control and the tab bar. The one squared shape in a row of pills means Hắc Đạo or technical information.

## Elevation and materials

- Cards: `vnBorderSubtle` hairline + `VNShadow-folio`. Small raised pieces: `VNShadow-card`. Floating bar: `VNShadow-floating`. Sheets: `VNShadow-modal`. Shadows are ink-tinted and soft; the one coloured shadow is `VNShadow-warmDiffuse`, a red glow under the night hero card.
- **The lip.** Every pressable pill (buttons, the empty-state CTA) stands on `VNShadow-lip`, a hard 4px ledge. Pressing drops the pill onto it. This is the system's signature tactile detail; don't use it on things that can't be pressed.
- Bars are frosted: `vnBackgroundPrimary` at 85% over a 20pt blur.
- **The Ấn Triện** is now a solid cinnabar stamp with a pale inner ring, tilted -3°, that lands with the `stamp` motion. See `VNSealBadge`.

## Motion

Springy, physical, short, and borrowed from the calendar's own world: seals that stamp, sheets that tear off, lanterns that sway. The full vocabulary, with SwiftUI and CSS values, is on the `VNMotion` page; its tiles are live.

- Press: down 4pt in 0.10s, back on a spring (response 0.42, damping 0.55). Selection: snappy 0.30s with bounce 0.25. Choosing something pops it (1 → 1.14 → 0.95 → 1).
- Signature moves: `stamp` for seals, `turn` for tearing the daily sheet (lịch xé), `bloom` (petals) once after saving, `glow` for the moon, `sway` for lanterns in artwork.
- Interactive motion is over within 0.6s. Ambient loops: at most one per screen, never in a list.
- **On memorial screens** (Ngày Giỗ detail, Văn Khấn): press, selection and appear only; seals may stamp; no pop, bloom or loops beyond the incense in artwork.
- One haptic per action. Reduce Motion turns everything into a 0.15s fade and stops loops; the artwork SVGs honour it themselves.

## Artwork and iconography

- **Artwork** (Assets → Artwork) is flat, geometric and built from the palette: `app-icon.svg` (proposed new icon: gold crescent and sparkle on lantern red under a night binding strip), `hero-lunar-night.svg` (night sky, moon, swaying lanterns, mai and đào branch, Hội An roofs), `tet-festival.svg` (mai branch, lanterns and a lì xì envelope on dong-leaf green), `empty-memorial.svg` (lotus, incense with rising smoke), `empty-search.svg` (moon and magnifier), `pattern-moons.svg` (a repeating tile). Animated ones loop gently and stop under Reduce Motion.
- Draw new artwork the same way: circles, crescents, five-petal blossoms, lantern ellipses, rounded roofs; only palette colours; no outlines heavier than 2px at 1x; no faces or mascots; no text inside artwork.
- **Icons** are SF Symbols, semibold, tinted with a token; inside a solid tile they are `vnOnAccent`. Calendar-mode icons: `doc.text.fill`, `calendar`, `calendar.day.timeline.left`, `calendar.badge.clock`; moon phases `moonphase.*`. SF Symbols can't be redistributed, so previews here use hand-drawn stand-ins.
- No emoji.

## Components

Sixteen components plus the motion page, each with guidelines and a live preview: `VNButton`; `VNCard`, `VNGroupCard` (with `VNRowDivider`), `VNSettingsRow`; `VNChip`, `VNBadgeView`, `VNSealBadge`, `VNSectionLabel`, `VNSectionHeader`; `VNSearchField`, `VNNavBar` (with `VNDismissButton`), `VNCalendarModePicker`; `VNIndicatorDotsView`, `VNMoonPhaseView`, `VNHourTimelineView` (`VN12HourTimelineView` in code); `VNEmptyState`; `VNMotion`.

The components are SwiftUI; the previews are HTML renditions styled by `components/bundle.css`, built only from the tokens.

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

---

## 6. Family Tree — Cây Gia Phả (Artwork Diagram Spec)

Stitch reference screens:
*   `An Niên - Cây Gia Phả & Gia Tiên` — `screens/bd623b48fc394bb6a3e3c508610fcc84` (`.stitch/designs/family-tree-bd623b48.*`)
*   `An Niên - Lịch Ngày (Bản Tinh Hoa)` — `screens/a55f5cf282bf454688e66ce5d4af4927` (`.stitch/designs/daily-polish-a55f5cf282bf454688e66ce5d4af4927.*`)

Cây gia phả là **artwork biểu đồ**, không phải danh sách: thế hệ xếp dọc, connector vàng nối nhánh, ấn triện đánh dấu cặp vợ chồng.

### 6.1 Generation Bands
*   Nhãn đời dọc bên trái: `ĐỜI I`, `ĐỜI II`, `ĐỜI III`, `HẬU DUỆ` — 11pt/700, tracking +0.66, màu `vnAccentImperialGold`.
*   Tiêu đề đời bên cạnh: serif 17pt/700 `vnTextPrimary`; đếm số vị 12pt/500 `vnTextSecondary`.
*   Nguồn dữ liệu duy nhất: `ReminderEvent` hiện có (`title`, `relationship`, `day`, `month`, `year`, `category`, `note`). Group theo `relationship` (Cụ → Ông/Bà → Cha/Mẹ/Bác/Chú/Cô/Dì → còn lại) như `FamilyHierarchyView.groupedGenerations`.

### 6.2 Member Node (rice-paper card)
*   Nền `vnBackgroundSecondary`, radius `VNCornerRadius.card` (12pt), viền hairline `vnAccentImperialGold.opacity(0.28)` 1pt, shadow `VNShadow.folio`.
*   Tên: serif 17–20pt/600 `vnTextPrimary`.
*   Ngày giỗ: lunar style `dd/m Âm lịch`, sans 12pt `vnTextSecondary`, icon nhỏ cùng hàng.
*   Tag quan hệ: capsule `vnBackgroundTertiary`, 11pt/600 `vnTextSecondary`.
*   **Chỉ render field có thật trong `ReminderEvent`.** Không render tuổi thọ, số con, quê quán, chi/nhánh nếu chưa mở rộng domain.
*   Tap target toàn card ≥ 44pt; pressed state = viền `vnAccentHeritageRed.opacity(0.5)` 1.5pt.

### 6.3 Connectors & Couples
*   Connector orthogonal 1pt `vnAccentImperialGold` (opacity 0.45–0.7). **Không dùng `vnBorderSubtle`** cho connector — phải phân biệt được với viền card.
*   Cặp vợ chồng: 2 node cạnh nhau + Ấn Triện 40×40 vermilion ở giữa (viền 2pt, inset ring 1pt `vnAccentHeritageRed.opacity(0.4)`).
*   Nhánh xuống thế hệ sau: đường dọc từ tâm cặp → đường ngang → nhánh dọc vào từng node con.

### 6.4 Navigation & CTA
*   Bottom nav dùng chung floating pill (offset 14pt, `vnSurfaceElevated.opacity(0.85)` + blur, icon 22pt + label 11pt). Label khớp `MainTabView`: **Lịch Ngày / Ngày Giỗ / Văn Khấn / Gia Tộc**.
*   Tab active: icon + label `vnAccentHeritageRed`; inactive: `vnTextSecondary`.
*   CTA chính: floating pill "Thêm thành viên" fill `vnAccentHeritageRed`, chữ trắng, minHeight 52pt (`.large`).
*   Không thêm tab/ghost-link điều hướng thứ 5.

### 6.5 Known gaps of Stitch v1 export (không copy nguyên vào code)
| # | Gap | Quyết định |
|---|---|---|
| 1 | Export render "Thọ 89 tuổi", "2 Trai 3 Gái", "Từ Sơn, Bắc Ninh", "Ngành trưởng/Nội trợ" | **Bỏ** — domain chưa có field; chỉ dùng `ReminderEvent` hiện tại |
| 2 | Export nav bar đặc dính `bottom-0`, tab active là khối đỏ | **Sửa** — dùng floating pill + icon đỏ như §6.4 |
| 3 | Nav offset 0 / 24px | **Sửa** — 14pt trên safe area |
| 4 | Label nav khác nhau giữa 2 export | **Sửa** — theo `MainTabView` |
| 5 | Section gap 16px, `space-xl`=32px | **Sửa** — `VNSpacing.xl` = 20pt |
| 6 | Touch target "Chi tiết"/FAB/top icons < 44pt | **Sửa** — min 44pt (top bar visual 36, hit frame 44) |
| 7 | Radius ladder thấp 4px (card 8, button 2, seal 4) | **Sửa** — card 12 / small 8 / micro 4 / pill |
| 8 | Tree phẳng, connector chỉ dọc tuần tự | **Sửa** — thêm nhánh ngang theo §6.3; giữ fallback list khi dữ liệu < 2 thế hệ |
| 9 | Ghost link "Xem lịch tháng" thành tab thứ 5 | **Bỏ** — tap hero card để mở tháng |
| 10 | Hero numeral dùng sans | **Sửa** — serif 56pt/300 (`vnHeroNumeral`) |
| 11 | `secondary` map #775A19 thay vì gold | **Sửa** — `vnAccentImperialGold` #C5A059 |
| 12 | Seal viền 1.5px | **Sửa** — 2pt (`VNBorderWidth.focus`) |
| 13 | Nav active dùng fill khác nhau | **Sửa** — uniform theo §6.4 |
| 14 | Ornament pulse/glow chồng lớp | **Bỏ** — tĩnh tại, không animation nhấp nháy |
| 15 | "Bình minh/Hoàng hôn" ngoài spec hero; "CHÁNH THẤẤP"/"Đích Tôn" không map model | **Bỏ** — YAGNI, chưa có data source |
| 16 | Seal hiển thị "安年" + "Cát Nhật" | **Sửa** — seal là Can Chi (vd "Đinh Dậu") theo STYLE_BRIEF |
| 17 | Shadow nav 0.12 alpha ≠ `VNShadow.floating` (red 0.08) | **Sửa** — dùng đúng token |
