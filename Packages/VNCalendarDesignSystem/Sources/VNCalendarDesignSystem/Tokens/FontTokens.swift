import CoreText
import SwiftUI

public extension Font {
    // MARK: - Display (Be Vietnam Pro 700–800) for Numerals, Titles, Seals & Buttons
    /// Tiêu đề cực lớn (34pt ExtraBold)
    static let vnDisplayLarge = vnDisplay(.largeTitle, weight: .heavy)

    /// Tiêu đề chính / Hero (28pt ExtraBold)
    static let vnTitleHero = vnDisplay(.title, weight: .heavy)

    /// Tiêu đề lễ hội / ngày lễ (22pt Bold)
    static let vnTitleFestival = vnDisplay(.title2, weight: .bold)

    /// Tiêu đề nghi lễ / cúng giỗ (20pt Bold)
    static let vnTitleCeremonial = vnDisplay(.title3, weight: .bold)

    /// Tiêu đề phân đoạn (20pt ExtraBold). Name kept from the serif era.
    static let vnSectionHeaderSerif = vnDisplay(.title3, weight: .heavy)

    /// Mô tả ngày âm lịch (15pt Bold)
    static let vnLunarDate = vnDisplay(size: 15, weight: .bold)

    /// Số ngày dương lịch hero trên thẻ đêm (72pt ExtraBold)
    static let vnHeroNumeral = vnDisplay(size: 72, weight: .heavy)

    /// Trích dẫn ca dao tục ngữ (16pt Medium Italic)
    static let vnQuote = vnDisplay(.callout, weight: .medium, italic: true)

    // MARK: - Text (Be Vietnam Pro 400–700) for Utility, Hours & Body
    /// Tiêu đề mục ứng dụng (20pt Bold)
    static let vnSectionHeader = vnDisplay(.title3, weight: .bold)

    /// Đầu đề nổi bật (17pt Bold)
    static let vnHeadline = vnDisplay(.headline, weight: .bold)

    /// Thân bài chính (17pt Regular)
    static let vnBody = vnDisplay(.body)

    /// Chú thích nổi bật (16pt Regular)
    static let vnCallout = vnDisplay(.callout)

    /// Đầu đề phụ (15pt Regular)
    static let vnSubheadline = vnDisplay(.subheadline)

    /// Chú thích chân trang (13pt Regular)
    static let vnFootnote = vnDisplay(.footnote)

    /// Nhãn phụ cấp 1 (12pt Medium)
    static let vnCaption1 = vnDisplay(.caption, weight: .medium)

    /// Nhãn phụ cấp 2 (11pt SemiBold)
    static let vnCaption2 = vnDisplay(.caption2, weight: .semibold)

    /// Nhãn Can Chi / Bát tự (11pt Medium)
    static let vnCaptionCanChi = vnDisplay(size: 11, weight: .medium)

    /// Giờ hoàng đạo / hắc đạo (13pt SemiBold)
    static let vnHourNumeral = vnDisplay(size: 13, weight: .semibold)

    /// Nhãn thứ trong tuần (12pt Bold)
    static let vnWeekday = vnDisplay(size: 12, weight: .bold)

    // MARK: - Calendar Matrix Numerals (fixed size)
    /// Số ngày dương lịch ô lưới (17pt SemiBold)
    static let vnCellSolar = vnDisplay(size: 17, weight: .semibold)

    /// Số ngày dương lịch hôm nay / chọn (17pt ExtraBold)
    static let vnCellSolarBold = vnDisplay(size: 17, weight: .heavy)

    /// Số ngày âm lịch ô lưới (10pt Medium)
    static let vnCellLunar = vnDisplay(size: 10, weight: .medium)

    /// Số ngày âm lịch nổi bật Mùng 1 / Rằm (10pt Bold)
    static let vnCellLunarHighlight = vnDisplay(size: 10, weight: .bold)

    /// Tiết khí ô lưới (9pt Bold)
    static let vnCellSolarTerm = vnDisplay(size: 9, weight: .bold)

    // MARK: - Be Vietnam Pro helpers

    /// Fixed-size Be Vietnam Pro (does not follow Dynamic Type, like `.system(size:)`).
    static func vnDisplay(size: CGFloat, weight: Font.Weight = .regular, italic: Bool = false) -> Font {
        _ = BeVietnamPro.register
        return .custom(BeVietnamPro.name(weight, italic: italic), fixedSize: size)
    }

    /// Be Vietnam Pro scaled with the given Dynamic Type style, like `.system(_ style:)`.
    static func vnDisplay(_ style: Font.TextStyle, weight: Font.Weight? = nil, italic: Bool = false) -> Font {
        _ = BeVietnamPro.register
        let resolved = weight ?? (style == .headline ? .semibold : .regular)
        return .custom(BeVietnamPro.name(resolved, italic: italic), size: BeVietnamPro.baseSize(style), relativeTo: style)
    }
}

private enum BeVietnamPro {
    /// Registers the bundled font files once, on first use of any VN font token.
    static let register: Void = {
        let urls = Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? []
        CTFontManagerRegisterFontURLs(urls as CFArray, .process, true, nil)
    }()

    static func name(_ weight: Font.Weight, italic: Bool) -> String {
        // Only Medium ships an italic cut (used by vnQuote).
        if italic { return "BeVietnamPro-MediumItalic" }
        switch weight {
        case .ultraLight, .thin, .light: return "BeVietnamPro-Light"
        case .medium: return "BeVietnamPro-Medium"
        case .semibold: return "BeVietnamPro-SemiBold"
        case .bold: return "BeVietnamPro-Bold"
        case .heavy, .black: return "BeVietnamPro-ExtraBold"
        default: return "BeVietnamPro-Regular"
        }
    }

    /// iOS default point sizes at the Large content size category.
    static func baseSize(_ style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .callout: 16
        case .subheadline: 15
        case .footnote: 13
        case .caption: 12
        case .caption2: 11
        default: 17
        }
    }
}
