import SwiftUI

public extension Font {
    // MARK: - Serif (Apple New York) for Ceremonial Titles, Lunar Dates & Section Headings
    /// Tiêu đề cực lớn trang trọng (34pt Bold Serif)
    static let vnDisplayLarge = Font.system(.largeTitle, design: .serif).weight(.bold)

    /// Tiêu đề chính / Hero (28pt Semibold Serif)
    static let vnTitleHero = Font.system(size: 28, weight: .semibold, design: .serif)

    /// Tiêu đề lễ hội / ngày lễ (22pt Medium Serif)
    static let vnTitleFestival = Font.system(size: 22, weight: .medium, design: .serif)

    /// Tiêu đề nghi lễ / cúng giỗ trang trọng (20pt Semibold Serif)
    static let vnTitleCeremonial = Font.system(size: 20, weight: .semibold, design: .serif)

    /// Tiêu đề phân đoạn Serif (20pt Semibold Serif)
    static let vnSectionHeaderSerif = Font.system(size: 20, weight: .semibold, design: .serif)

    /// Mô tả ngày âm lịch trang trọng (14pt Bold Serif / 700) — DESIGN §3 lunar callout.
    static let vnLunarDate = Font.system(size: 14, weight: .bold, design: .serif)

    /// Số ngày dương lịch hero "trang lịch ngày" (56pt Light Serif) — DESIGN §5.1 mobile hero numeral.
    static let vnHeroNumeral = Font.system(size: 56, weight: .light, design: .serif)

    /// Trích dẫn văn thơ / ca dao tục ngữ (16pt Regular Italic Serif)
    static let vnQuote = Font.system(size: 16, weight: .regular, design: .serif).italic()

    // MARK: - Sans (SF Pro) for Utility, Matrix Numerals, Hours & Body
    /// Tiêu đề mục ứng dụng (20pt Semibold Sans)
    static let vnSectionHeader = Font.system(.title3, design: .default).weight(.semibold)

    /// Đầu đề nổi bật (17pt Semibold Sans)
    static let vnHeadline = Font.system(.headline, design: .default)

    /// Thân bài chính (17pt Regular Sans)
    static let vnBody = Font.system(.body, design: .default)

    /// Chú thích nổi bật (16pt Regular Sans)
    static let vnCallout = Font.system(.callout, design: .default)

    /// Đầu đề phụ (15pt Regular Sans)
    static let vnSubheadline = Font.system(.subheadline, design: .default)

    /// Chú thích chân trang (13pt Regular Sans)
    static let vnFootnote = Font.system(.footnote, design: .default)

    /// Nhãn phụ cấp 1 (12pt Regular Sans)
    static let vnCaption1 = Font.system(.caption, design: .default)

    /// Nhãn phụ cấp 2 (11pt Regular Sans)
    static let vnCaption2 = Font.system(.caption2, design: .default)

    /// Nhãn Can Chi / Bát tự (11pt Regular Sans)
    static let vnCaptionCanChi = Font.system(size: 11, weight: .regular, design: .default)

    /// Giờ hoàng đạo / hắc đạo (13pt Medium Sans)
    static let vnHourNumeral = Font.system(size: 13, weight: .medium, design: .default)

    /// Nhãn thứ trong tuần (12pt Semibold Sans)
    static let vnWeekday = Font.system(size: 12, weight: .semibold, design: .default)

    // MARK: - Calendar Matrix Numerals & Elements (SF Pro)
    /// Số ngày dương lịch ô lưới (16pt Medium Sans)
    static let vnCellSolar = Font.system(size: 16, weight: .medium, design: .default)

    /// Số ngày dương lịch hôm nay / chọn (16pt Bold Sans)
    static let vnCellSolarBold = Font.system(size: 16, weight: .bold, design: .default)

    /// Số ngày âm lịch ô lưới (10pt Regular Sans)
    static let vnCellLunar = Font.system(size: 10, weight: .regular, design: .default)

    /// Số ngày âm lịch nổi bật Mùng 1 / Rằm 15 (10pt Semibold Sans)
    static let vnCellLunarHighlight = Font.system(size: 10, weight: .semibold, design: .default)

    /// Tiết khí ô lưới (9pt Semibold Sans)
    static let vnCellSolarTerm = Font.system(size: 9, weight: .semibold, design: .default)
}
