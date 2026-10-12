import XCTest
@testable import VNCalendarDesignSystem
import SwiftUI

@MainActor
final class DesignSystemTests: XCTestCase {
    func testColorTokensExist() {
        // Base Light Tokens
        XCTAssertNotNil(Color.vnNewRiceIvory)
        XCTAssertNotNil(Color.vnWovenLinen)
        XCTAssertNotNil(Color.vnAncientSand)
        XCTAssertNotNil(Color.vnDeepCalligraphicInk)
        XCTAssertNotNil(Color.vnHearthAshGray)
        XCTAssertNotNil(Color.vnMistGray)
        XCTAssertNotNil(Color.vnCinnabarLacquerRed)
        XCTAssertNotNil(Color.vnImperialChrysanthemumGold)
        XCTAssertNotNil(Color.vnOldRiceBorder)

        // Base Dark Tokens
        XCTAssertNotNil(Color.vnLacquerCharcoal)
        XCTAssertNotNil(Color.vnWarmEbony)
        XCTAssertNotNil(Color.vnDarkSand)
        XCTAssertNotNil(Color.vnRicePaperWhite)
        XCTAssertNotNil(Color.vnMutedHearth)
        XCTAssertNotNil(Color.vnCinnabarEmbers)
        XCTAssertNotNil(Color.vnAntiqueBrass)
        XCTAssertNotNil(Color.vnDarkBorder)

        // Semantic Adaptive Tokens
        XCTAssertNotNil(Color.vnBackgroundPrimary)
        XCTAssertNotNil(Color.vnBackgroundSecondary)
        XCTAssertNotNil(Color.vnBackgroundTertiary)
        XCTAssertNotNil(Color.vnTextPrimary)
        XCTAssertNotNil(Color.vnTextSecondary)
        XCTAssertNotNil(Color.vnTextTertiary)
        XCTAssertNotNil(Color.vnAccentHeritageRed)
        XCTAssertNotNil(Color.vnAccentImperialGold)
        XCTAssertNotNil(Color.vnBorderSubtle)
        XCTAssertNotNil(Color.vnStatusSuccess)
        XCTAssertNotNil(Color.vnStatusWarning)
        XCTAssertNotNil(Color.vnStatusError)
    }

    func testFontTokensExist() {
        // Serif Tokens
        XCTAssertNotNil(Font.vnDisplayLarge)
        XCTAssertNotNil(Font.vnTitleHero)
        XCTAssertNotNil(Font.vnTitleFestival)
        XCTAssertNotNil(Font.vnTitleCeremonial)
        XCTAssertNotNil(Font.vnSectionHeaderSerif)
        XCTAssertNotNil(Font.vnLunarDate)
        XCTAssertNotNil(Font.vnQuote)

        // Sans Tokens
        XCTAssertNotNil(Font.vnSectionHeader)
        XCTAssertNotNil(Font.vnHeadline)
        XCTAssertNotNil(Font.vnBody)
        XCTAssertNotNil(Font.vnCallout)
        XCTAssertNotNil(Font.vnSubheadline)
        XCTAssertNotNil(Font.vnFootnote)
        XCTAssertNotNil(Font.vnCaption1)
        XCTAssertNotNil(Font.vnCaption2)
        XCTAssertNotNil(Font.vnCaptionCanChi)
        XCTAssertNotNil(Font.vnHourNumeral)
        XCTAssertNotNil(Font.vnCellSolar)
        XCTAssertNotNil(Font.vnCellSolarBold)
        XCTAssertNotNil(Font.vnCellLunar)
        XCTAssertNotNil(Font.vnCellLunarHighlight)
        XCTAssertNotNil(Font.vnCellSolarTerm)
    }

    func testLayoutTokens() {
        XCTAssertEqual(VNSpacing.space2, 2)
        XCTAssertEqual(VNSpacing.xs, 4)
        XCTAssertEqual(VNSpacing.sm, 8)
        XCTAssertEqual(VNSpacing.md, 12)
        XCTAssertEqual(VNSpacing.lg, 16)
        XCTAssertEqual(VNSpacing.xl, 20)
        XCTAssertEqual(VNSpacing.xxl, 24)
        XCTAssertEqual(VNSpacing.space32, 32)
        XCTAssertEqual(VNSpacing.golden, 32)
        XCTAssertEqual(VNSpacing.hero, 48)

        XCTAssertEqual(VNCornerRadius.small, 4)
        XCTAssertEqual(VNCornerRadius.medium, 10)
        XCTAssertEqual(VNCornerRadius.card, 8)
        XCTAssertEqual(VNCornerRadius.large, 16)
        XCTAssertEqual(VNCornerRadius.sheet, 24)
        XCTAssertEqual(VNCornerRadius.pill, 999)

        XCTAssertEqual(VNBorderWidth.hairline, 1.0)
        XCTAssertEqual(VNBorderWidth.hairlineThin, 0.5)
        XCTAssertEqual(VNBorderWidth.regular, 1.0)
        XCTAssertEqual(VNBorderWidth.active, 1.5)
        XCTAssertEqual(VNBorderWidth.focus, 2.0)

        XCTAssertEqual(VNShadow.card.radius, 4)
        XCTAssertEqual(VNShadow.warmDiffuse.radius, 16)
        XCTAssertEqual(VNShadow.floating.radius, 12)
        XCTAssertEqual(VNShadow.modal.radius, 16)
        XCTAssertEqual(VNShadow.modal.color, Color.black.opacity(0.08))

        // Folio shadow: 0 4px 20px rgba(90,84,79,0.05) — spread omitted (SwiftUI has none).
        XCTAssertEqual(VNShadow.folio.radius, 20)
        XCTAssertEqual(VNShadow.folio.y, 4)
        XCTAssertEqual(VNShadow.folio.x, 0)
        XCTAssertEqual(VNShadow.folio.color, Color(hex: 0x5A544F).opacity(0.05))
    }

    func testBadgeViewStyles() {
        let roundedBadge = VNBadgeView(text: "Mùng 1", style: .rounded())
        XCTAssertNotNil(roundedBadge.body)

        let capsuleBadge = VNBadgeView(text: "Hoàng Đạo", style: .capsule)
        XCTAssertNotNil(capsuleBadge.body)

        let ribbonBadge = VNBadgeView(text: "Giỗ Cụ", style: .ribbon(accentColor: .vnAccentHeritageRed))
        XCTAssertNotNil(ribbonBadge.body)
    }

    func testIndicatorDotsView() {
        let dots = VNIndicatorDotsView(hasAncestorDeath: true, hasFestival: true, hasPersonalEvent: true)
        XCTAssertNotNil(dots.body)
        XCTAssertTrue(dots.hasAncestorDeath)
        XCTAssertTrue(dots.hasFestival)
        XCTAssertTrue(dots.hasPersonalEvent)
    }

    // MARK: - VNSealBadge Tests

    func testSealBadgePresets() {
        let mungMot = VNSealBadge.mungMot()
        XCTAssertEqual(mungMot.text, "MÙNG 1")
        XCTAssertEqual(mungMot.shape, .rounded())
        XCTAssertEqual(mungMot.color, .cinnabarWhite)
        XCTAssertNotNil(mungMot.body)

        let ram = VNSealBadge.ram()
        XCTAssertEqual(ram.text, "RẰM")
        XCTAssertEqual(ram.shape, .rounded())
        XCTAssertEqual(ram.color, .cinnabarGold)
        XCTAssertNotNil(ram.body)

        let gio = VNSealBadge.gio()
        XCTAssertEqual(gio.text, "GIỖ")
        XCTAssertEqual(gio.shape, .square)
        XCTAssertEqual(gio.color, .vermilionDarkGold)
        XCTAssertNotNil(gio.body)

        let tet = VNSealBadge.tet()
        XCTAssertEqual(tet.text, "TẾT")
        XCTAssertEqual(tet.shape, .pill)
        XCTAssertEqual(tet.color, .cinnabarGold)
        XCTAssertNotNil(tet.body)
    }

    func testSealBadgeCustomization() {
        let customBadge = VNSealBadge(
            text: "XUÂN",
            icon: "sparkles",
            shape: .circle,
            color: .custom(background: .red, foreground: .white, border: .yellow),
            size: .large
        )
        XCTAssertEqual(customBadge.text, "XUÂN")
        XCTAssertEqual(customBadge.icon, "sparkles")
        XCTAssertEqual(customBadge.shape, .circle)
        XCTAssertEqual(customBadge.size, .large)
        XCTAssertEqual(customBadge.size.fontSize, 13)
        XCTAssertNotNil(customBadge.body)

        let smallBadge = VNSealBadge(text: "ẤN", size: .small)
        XCTAssertEqual(smallBadge.size.fontSize, 9)
        XCTAssertNotNil(smallBadge.body)
    }

    // MARK: - VNCalendarModePicker Tests

    func testCalendarModeEnum() {
        XCTAssertEqual(VNCalendarMode.allCases.count, 4)
        XCTAssertEqual(VNCalendarMode.block.rawValue, "block")
        XCTAssertEqual(VNCalendarMode.month.rawValue, "month")
        XCTAssertEqual(VNCalendarMode.week.rawValue, "week")
        XCTAssertEqual(VNCalendarMode.year.rawValue, "year")

        XCTAssertEqual(VNCalendarMode.block.title, "Nhật Lịch")
        XCTAssertEqual(VNCalendarMode.month.title, "Tháng")
        XCTAssertEqual(VNCalendarMode.week.title, "Tuần")
        XCTAssertEqual(VNCalendarMode.year.title, "Năm")

        XCTAssertFalse(VNCalendarMode.block.icon.isEmpty)
        XCTAssertFalse(VNCalendarMode.month.icon.isEmpty)
        XCTAssertFalse(VNCalendarMode.week.icon.isEmpty)
        XCTAssertFalse(VNCalendarMode.year.icon.isEmpty)
    }

    func testCalendarModePicker() {
        var selectedMode = VNCalendarMode.block
        let binding = Binding(get: { selectedMode }, set: { selectedMode = $0 })
        let picker = VNCalendarModePicker(selectedMode: binding)
        XCTAssertEqual(picker.modes, VNCalendarMode.allCases)
        XCTAssertNotNil(picker.body)

        let subsetPicker = VNCalendarModePicker(
            selectedMode: binding,
            modes: [.month, .year]
        )
        XCTAssertEqual(subsetPicker.modes.count, 2)
        XCTAssertNotNil(subsetPicker.body)
    }

    // MARK: - VNSectionHeader Tests

    func testSectionHeader() {
        let headerWithBar = VNSectionHeader(
            title: "Giờ Hoàng Đạo",
            subtitle: "Hôm nay có 6 giờ tốt",
            accent: .verticalBar(),
            actionTitle: "Xem tất cả",
            action: {}
        )
        XCTAssertEqual(headerWithBar.title, "Giờ Hoàng Đạo")
        XCTAssertEqual(headerWithBar.subtitle, "Hôm nay có 6 giờ tốt")
        XCTAssertEqual(headerWithBar.actionTitle, "Xem tất cả")
        XCTAssertNotNil(headerWithBar.body)

        let headerWithSeal = VNSectionHeader(
            title: "Lễ Tiết & Phong Tục",
            accent: .seal(text: "LỄ")
        )
        XCTAssertEqual(headerWithSeal.title, "Lễ Tiết & Phong Tục")
        XCTAssertNil(headerWithSeal.subtitle)
        XCTAssertNotNil(headerWithSeal.body)

        let headerWithIcon = VNSectionHeader(
            title: "Ghi Chú",
            accent: .icon(systemName: "pencil")
        )
        XCTAssertNotNil(headerWithIcon.body)

        let headerPlain = VNSectionHeader(
            title: "Đơn Giản",
            accent: .none
        )
        XCTAssertNotNil(headerPlain.body)
    }

    // MARK: - VNCard Tests

    func testCard() {
        let defaultCard = VNCard {
            Text("Nội dung thẻ")
        }
        XCTAssertEqual(defaultCard.cornerRadius, VNCornerRadius.card)
        XCTAssertEqual(defaultCard.backgroundColor, Color.vnBackgroundSecondary)
        // DESIGN §4: gold-tinted hairline (gold @ 0.28) on rice-paper cards.
        XCTAssertEqual(defaultCard.borderColor, Color.vnAccentImperialGold.opacity(0.28))
        XCTAssertEqual(defaultCard.borderWidth, VNBorderWidth.hairline)
        // DESIGN §4: card padding 20pt.
        XCTAssertEqual(defaultCard.padding, EdgeInsets(
            top: VNSpacing.xl, leading: VNSpacing.xl, bottom: VNSpacing.xl, trailing: VNSpacing.xl
        ))
        XCTAssertNotNil(defaultCard.body)

        // DESIGN §4 folio shadow: radius 20 / y 4.
        typealias DefaultCard = VNCard<Text>
        XCTAssertEqual(DefaultCard.folioShadow.radius, 20)
        XCTAssertEqual(DefaultCard.folioShadow.y, 4)
        XCTAssertEqual(DefaultCard.defaultCornerRadius, VNCornerRadius.card)

        // DESIGN §5.1 hero numeral: 56pt light serif. Font has no size API on macOS;
        // UIFont bridge verifies point size on iOS.
        XCTAssertNotNil(Font.vnHeroNumeral)
        #if canImport(UIKit)
        XCTAssertEqual(UIFont(Font.vnHeroNumeral).pointSize, 56, accuracy: 0.5)
        #endif

        let customCard = VNCard(
            allPadding: VNSpacing.lg,
            cornerRadius: VNCornerRadius.large,
            backgroundColor: Color.vnAncientSand,
            borderColor: Color.vnAccentHeritageRed,
            borderWidth: VNBorderWidth.regular,
            shadow: nil
        ) {
            VStack {
                Text("Tiêu đề")
                Text("Chi tiết")
            }
        }
        XCTAssertEqual(customCard.cornerRadius, VNCornerRadius.large)
        XCTAssertEqual(customCard.backgroundColor, Color.vnAncientSand)
        XCTAssertEqual(customCard.borderColor, Color.vnAccentHeritageRed)
        XCTAssertEqual(customCard.borderWidth, VNBorderWidth.regular)
        XCTAssertNil(customCard.shadow)
        XCTAssertNotNil(customCard.body)
    }
}
