import SwiftUI
import TipKit
import VNCalendarDomain
import VNCalendarDesignSystem
import VNCalendarLunar

public struct TodayDashboardCard: View {
    public let details: DayCalendarDetails?
    public var onAddReminder: () -> Void
    public var onQuickSearch: () -> Void
    let upcomingMemorial: UpcomingMemorial?
    @State private var showDetails = false
    @ScaledMetric(relativeTo: .largeTitle) private var solarNumeralSize: CGFloat = 52
    @ScaledMetric(relativeTo: .title) private var lunarNumeralSize: CGFloat = 28

    public init(
        details: DayCalendarDetails?,
        upcomingMemorial: UpcomingMemorial? = nil,
        onAddReminder: @escaping () -> Void = {},
        onQuickSearch: @escaping () -> Void = {}
    ) {
        self.details = details
        self.upcomingMemorial = upcomingMemorial
        self.onAddReminder = onAddReminder
        self.onQuickSearch = onQuickSearch
    }

    private var currentSolarDate: SolarDate {
        details?.solarDate ?? SolarDate(from: Date())
    }

    private var currentLunarDate: LunarDate {
        details?.lunarDate ?? LunarAstronomicalEngine.shared.convertToLunar(from: SolarDate(from: Date()))
    }

    private var currentCanChi: FullCanChi {
        details?.canChi ?? LunarAstronomicalEngine.shared.computeCanChi(for: SolarDate(from: Date()))
    }

    private var dynamicDayBranch: EarthlyBranch {
        if let d = details {
            return d.canChi.day.branch
        }
        let now = SolarDate(from: Date())
        let jd = AstronomicalMath.julianDay(from: now)
        return EarthlyBranch(rawValue: (jd + 1) % 12) ?? .ty
    }

    private var monthBranch: EarthlyBranch {
        EarthlyBranch(rawValue: (currentLunarDate.month + 1) % 12) ?? .dan
    }

    private var dayStar: ZodiacStar {
        ZodiacStar.star(monthBranch: monthBranch, dayBranch: dynamicDayBranch)
    }

    private var dayOfficer: LunarOfficer {
        LunarOfficer.officer(monthBranch: monthBranch, dayBranch: dynamicDayBranch)
    }

    // ponytail: day-stem element only; full Na Yin table when engine provides it.
    private var dayElementName: String {
        switch currentCanChi.day.stem {
        case .giap, .at: "Mộc"
        case .binh, .dinh: "Hỏa"
        case .mau, .ky: "Thổ"
        case .canh, .tan: "Kim"
        case .nham, .quy: "Thủy"
        }
    }

    private var lunarMonthName: String {
        let names = [
            "Tháng Giêng", "Tháng Hai", "Tháng Ba", "Tháng Tư",
            "Tháng Năm", "Tháng Sáu", "Tháng Bảy", "Tháng Tám",
            "Tháng Chín", "Tháng Mười", "Tháng Một", "Tháng Chạp"
        ]
        let month = currentLunarDate.month
        guard month >= 1, month <= 12 else { return "Tháng \(month)" }
        return names[month - 1]
    }

    private var gmt7Date: Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = VNTime.vietnam
        var comps = DateComponents()
        comps.day = currentSolarDate.day
        comps.month = currentSolarDate.month
        comps.year = currentSolarDate.year
        return calendar.date(from: comps)
    }

    private var weekdayTitle: String? {
        guard let date = gmt7Date else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.timeZone = VNTime.vietnam
        formatter.dateFormat = "EEEE, d 'Tháng' MM"
        return formatter.string(from: date).capitalized
    }

    private var weekOfYearText: String? {
        guard let date = gmt7Date else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = VNTime.vietnam
        return "Tuần thứ \(calendar.component(.weekOfYear, from: date))"
    }

    private var suitableText: String {
        dayOfficer.suitableActivities.prefix(4).joined(separator: ", ")
    }

    private var tabooText: String {
        dayOfficer.tabooActivities.prefix(3).joined(separator: ", ")
    }

    public var body: some View {
        VStack(spacing: VNSpacing.md) {
            VNCard(allPadding: VNSpacing.lg) {
                VStack(alignment: .leading, spacing: VNSpacing.md) {
                    heroHeader
                    dateRow
                    canChiLine
                    if let memorial = upcomingMemorial {
                        memorialRow(memorial)
                    }
                    detailsDisclosure
                }
            }

            TodayCardActions(onAddReminder: onAddReminder, onQuickSearch: onQuickSearch)
        }
    }

    // MARK: - Hero Header (Weekday + single auspicious badge)
    private var heroHeader: some View {
        // Side by side when it fits; stacked at large accessibility sizes.
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: VNSpacing.sm) {
                weekdayText
                Spacer(minLength: 0)
                hoangDaoPill
            }
            VStack(alignment: .leading, spacing: VNSpacing.sm) {
                weekdayText
                hoangDaoPill
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var weekdayText: some View {
        if let title = weekdayTitle {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.vnTextSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
    }

    private var hoangDaoPill: some View {
        HStack(spacing: VNSpacing.xs) {
            Image(systemName: "sun.max")
                .font(.caption2.weight(.semibold))
                .accessibilityHidden(true)
            Text(dayStar.isAuspicious ? "HOÀNG ĐẠO" : "HẮC ĐẠO")
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
                .fixedSize()
                .tracking(0.66)
        }
        .foregroundColor(.vnAccentDeepPrimary)
        .padding(.horizontal, VNSpacing.sm)
        .padding(.vertical, VNSpacing.xs)
        .background(Color.vnAccentRedSurface)
        .clipShape(Capsule())
    }

    // MARK: - Solar + Lunar date (primary focus)
    private var dateRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: VNSpacing.md) {
            Text("\(currentSolarDate.day)")
                .font(.system(size: solarNumeralSize, weight: .light))
                .foregroundColor(.vnTextPrimary)
                .accessibilityLabel("Dương lịch ngày \(currentSolarDate.day)")

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: VNSpacing.space2) {
                Text("Âm lịch")
                    .font(.caption2.weight(.medium))
                    .foregroundColor(.vnAccentGoldText)
                Text("Ngày \(currentLunarDate.day)")
                    .font(.system(size: lunarNumeralSize, weight: .semibold, design: .serif))
                    .foregroundColor(.vnAccentHeritageRed)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(lunarMonthName)
                    .font(.system(.subheadline, design: .serif).weight(.semibold))
                    .foregroundColor(.vnTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var canChiLine: some View {
        Text("Ngày \(currentCanChi.day.description) · Tháng \(currentCanChi.month.description) · Năm \(currentCanChi.year.description)")
            .font(.footnote.weight(.medium))
            .foregroundColor(.vnTextSecondary)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
    }

    private func memorialRow(_ memorial: UpcomingMemorial) -> some View {
        HStack(spacing: VNSpacing.sm) {
            Image(systemName: "flame")
                .font(.footnote.weight(.semibold))
                .foregroundColor(.vnAccentHeritageRed)
                .accessibilityHidden(true)
            Text(memorial.title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.vnTextPrimary)
                .lineLimit(1)
            Spacer(minLength: VNSpacing.sm)
            Text(memorial.countdown)
                .font(.caption.weight(.semibold))
                .foregroundColor(.vnAccentHeritageRed)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(VNSpacing.sm)
        .background(Color.vnAccentRedSurface.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.small))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Secondary info (collapsed by default)
    private var detailsDisclosure: some View {
        DisclosureGroup(isExpanded: $showDetails) {
            VStack(alignment: .leading, spacing: VNSpacing.md) {
                Text(detailsSummary)
                    .font(.caption)
                    .foregroundColor(.vnTextSecondary)
                TodayHeroGuidance(
                    hours: EarthlyBranch.auspiciousHours(for: dynamicDayBranch),
                    suitable: suitableText,
                    taboo: tabooText
                )
            }
            .padding(.top, VNSpacing.sm)
        } label: {
            Text("Giờ hoàng đạo · Nên / kiêng")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.vnTextPrimary)
        }
        .tint(.vnTextSecondary)
    }

    private var detailsSummary: String {
        [weekOfYearText, "Sao \(dayStar.vietnameseName)", "Ngũ hành \(dayElementName)"]
            .compactMap { $0 }
            .joined(separator: " · ")
    }
}

// MARK: - Giờ Hoàng Đạo strip + guidance panels

private struct TodayHeroGuidance: View {
    let hours: [EarthlyBranch]
    let suitable: String
    let taboo: String

    var body: some View {
        VStack(alignment: .leading, spacing: VNSpacing.md) {
            hoursStrip
            guidancePanels
        }
        .padding(.top, VNSpacing.sm)
    }

    private var hoursStrip: some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            HStack(spacing: VNSpacing.sm) {
                Text("GIỜ HOÀNG ĐẠO")
                    .font(.caption2.weight(.semibold))
                    .tracking(0.66)
                    .foregroundColor(.vnTextSecondary)

                Spacer(minLength: 0)

                Text("\(hours.count) giờ lành")
                    .font(.caption2.weight(.medium))
                    .foregroundColor(.vnAccentGoldText)
            }
            .accessibilityElement(children: .combine)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: VNSpacing.xs) {
                    ForEach(hours, id: \.self) { branch in
                        hourChip(for: branch)
                    }
                }
            }
        }
    }

    private func hourChip(for branch: EarthlyBranch) -> some View {
        VStack(spacing: VNSpacing.space2) {
            Text(branch.vietnameseName)
                .font(.caption2.weight(.semibold))
                .foregroundColor(.vnAccentDeepPrimary)

            Text(hourRangeText(branch))
                .font(.caption2)
                .foregroundColor(.vnTextSecondary)
        }
        .padding(.horizontal, VNSpacing.sm)
        .padding(.vertical, VNSpacing.sm)
        .background(Color.vnBackgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.small))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.small)
                .stroke(Color.vnBorderSubtle, lineWidth: VNBorderWidth.hairline)
        )
        .accessibilityElement(children: .combine)
    }

    private func hourRangeText(_ branch: EarthlyBranch) -> String {
        let parts = branch.timeRange.split(separator: "-")
        guard parts.count == 2 else { return branch.timeRange }
        return "\(parts[0])h - \(parts[1])h"
    }

    private var guidancePanels: some View {
        HStack(alignment: .top, spacing: VNSpacing.sm) {
            guidancePanel(
                title: "Việc Nên Làm",
                icon: "checkmark.circle.fill",
                tint: .vnAccentGoldText,
                background: .vnAccentGoldSurface,
                text: suitable
            )

            guidancePanel(
                title: "Việc Kiêng Cữ",
                icon: "xmark.circle.fill",
                tint: .vnAccentHeritageRed,
                background: .vnAccentRedSurface,
                text: taboo
            )
        }
    }

    private func guidancePanel(title: String, icon: String, tint: Color, background: Color, text: String) -> some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            HStack(spacing: VNSpacing.xs) {
                Image(systemName: icon)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(tint)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.vnTextPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }

            Text(text)
                .font(.caption)
                .foregroundColor(.vnTextPrimary)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(VNSpacing.sm)
        .background(background.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.small))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.small)
                .stroke(Color.vnBorderSubtle.opacity(0.6), lineWidth: VNBorderWidth.hairline)
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Action Buttons

private struct TodayCardActions: View {
    let onAddReminder: () -> Void
    let onQuickSearch: () -> Void

    var body: some View {
        HStack(spacing: VNSpacing.sm) {
            VNButton("Thêm Ngày Nhớ", icon: "plus", variant: .primary, size: .small, isFullWidth: true, action: onAddReminder)
                .popoverTip(AddReminderTip())
            VNButton("Tra Cứu", icon: "magnifyingglass", variant: .secondary, size: .small, isFullWidth: true, action: onQuickSearch)
        }
    }
}
