import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem
import VNCalendarLunar

public struct TodayDashboardCard: View {
    public let details: DayCalendarDetails?
    public var onAddReminder: () -> Void
    public var onQuickSearch: () -> Void

    public init(
        details: DayCalendarDetails?,
        onAddReminder: @escaping () -> Void = {},
        onQuickSearch: @escaping () -> Void = {}
    ) {
        self.details = details
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
        calendar.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? .current
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
        formatter.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? .current
        formatter.dateFormat = "EEEE, d 'Tháng' MM"
        return formatter.string(from: date).capitalized
    }

    private var weekOfYearText: String? {
        guard let date = gmt7Date else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? .current
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
            VNCard(allPadding: VNSpacing.xl) {
                VStack(alignment: .leading, spacing: 0) {
                    heroHeader
                    solarNumeralRow
                    hairlineDivider
                    lunarCalloutGrid
                    TodayHeroGuidance(
                        hours: EarthlyBranch.auspiciousHours(for: dynamicDayBranch),
                        suitable: suitableText,
                        taboo: tabooText
                    )
                }
            }
            .overlay(HeroCornerMarks().fill(Color.vnBorderSubtle.opacity(0.6)))

            TodayCardActions(onAddReminder: onAddReminder, onQuickSearch: onQuickSearch)
        }
    }

    // MARK: - Hero Header (Weekday + Auspicious Pill)
    private var heroHeader: some View {
        HStack(alignment: .top, spacing: VNSpacing.sm) {
            if let title = weekdayTitle {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.vnTextSecondary)
            }

            Spacer(minLength: 0)

            hoangDaoPill
        }
    }

    private var hoangDaoPill: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "sun.max")
                    .font(.system(size: 11, weight: .semibold))
                Text(dayStar.isAuspicious ? "HOÀNG ĐẠO" : "HẮC ĐẠO")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.66)
            }
            .foregroundColor(.vnAccentDeepPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.vnAccentRedSurface)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(Color.vnAccentHeritageRed.opacity(0.25), lineWidth: VNBorderWidth.hairline)
            )

            Text("Sao \(dayStar.vietnameseName)")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.vnTextSecondary)
        }
    }

    // MARK: - Solar Numeral
    private var solarNumeralRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: VNSpacing.sm) {
            Text("\(currentSolarDate.day)")
                .font(.system(size: 56, weight: .light))
                .foregroundColor(.vnTextPrimary)

            VStack(alignment: .leading, spacing: 2) {
                Text("DƯƠNG LỊCH")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.66)
                    .foregroundColor(.vnAccentImperialGold)

                if let week = weekOfYearText {
                    Text(week)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.vnTextSecondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.top, VNSpacing.xs)
    }

    private var hairlineDivider: some View {
        Divider()
            .background(Color.vnBorderSubtle.opacity(0.6))
            .padding(.vertical, VNSpacing.sm)
    }

    // MARK: - Lunar Callout + Can Chi
    private var lunarCalloutGrid: some View {
        HStack(spacing: VNSpacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text("ÂM LỊCH")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(0.66)
                    .foregroundColor(.vnAccentImperialGold)

                Text("Ngày \(currentLunarDate.day)")
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .foregroundColor(.vnAccentHeritageRed)

                Text(lunarMonthName)
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundColor(.vnTextPrimary)
            }

            Rectangle()
                .fill(Color.vnBorderSubtle.opacity(0.6))
                .frame(width: 1)

            VStack(spacing: 6) {
                canChiRow(label: "Ngày", value: currentCanChi.day.description)
                canChiRow(label: "Tháng", value: currentCanChi.month.description)
                canChiRow(label: "Năm", value: currentCanChi.year.description)
                canChiRow(label: "Ngũ Hành", value: dayElementName, valueColor: .vnAccentImperialGold)
            }
        }
        .padding(.vertical, VNSpacing.sm)
    }

    private func canChiRow(label: String, value: String, valueColor: Color = .vnTextPrimary) -> some View {
        HStack(spacing: VNSpacing.sm) {
            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.vnTextSecondary)

            Spacer(minLength: 0)

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(valueColor)
                .lineLimit(1)
        }
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
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.66)
                    .foregroundColor(.vnTextSecondary)

                Spacer(minLength: 0)

                Text("\(hours.count) giờ lành")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.vnAccentImperialGold)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(hours, id: \.self) { branch in
                        hourChip(for: branch)
                    }
                }
            }
        }
    }

    private func hourChip(for branch: EarthlyBranch) -> some View {
        VStack(spacing: 1) {
            Text(branch.vietnameseName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.vnAccentDeepPrimary)

            Text(hourRangeText(branch))
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(.vnTextSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.vnBackgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.small))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.small)
                .stroke(Color.vnBorderSubtle, lineWidth: VNBorderWidth.hairline)
        )
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
                tint: .vnAccentImperialGold,
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
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(tint)

                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.vnTextPrimary)
            }

            Text(text)
                .font(.system(size: 12, weight: .regular))
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
    }
}

// MARK: - Action Buttons

private struct TodayCardActions: View {
    let onAddReminder: () -> Void
    let onQuickSearch: () -> Void

    var body: some View {
        HStack(spacing: VNSpacing.sm) {
            Button(action: onAddReminder) {
                Label("Thêm Ngày Nhớ", systemImage: "plus")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .background(Color.vnAccentHeritageRed)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .shadow(color: Color.vnAccentHeritageRed.opacity(0.2), radius: 4, x: 0, y: 2)
            }

            Button(action: onQuickSearch) {
                Label("Tra Cứu", systemImage: "magnifyingglass")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .background(Color.vnBackgroundSecondary)
                    .foregroundColor(.vnTextPrimary)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.vnBorderSubtle, lineWidth: VNBorderWidth.hairline)
                    )
            }
        }
    }
}

// Four L-shaped corner strokes framing the hero almanac card.
private struct HeroCornerMarks: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let inset: CGFloat = 8
        let arm: CGFloat = 12
        let width: CGFloat = 1
        guard rect.width > inset * 2 + arm, rect.height > inset * 2 + arm else { return path }
        let left = rect.minX + inset
        let right = rect.maxX - inset
        let top = rect.minY + inset
        let bottom = rect.maxY - inset
        path.addRect(CGRect(x: left, y: top, width: arm, height: width))
        path.addRect(CGRect(x: left, y: top, width: width, height: arm))
        path.addRect(CGRect(x: right - arm, y: top, width: arm, height: width))
        path.addRect(CGRect(x: right - width, y: top, width: width, height: arm))
        path.addRect(CGRect(x: left, y: bottom - width, width: arm, height: width))
        path.addRect(CGRect(x: left, y: bottom - arm, width: width, height: arm))
        path.addRect(CGRect(x: right - arm, y: bottom - width, width: arm, height: width))
        path.addRect(CGRect(x: right - width, y: bottom - arm, width: width, height: arm))
        return path
    }
}
