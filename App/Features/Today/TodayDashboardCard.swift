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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
        case .giap, .at: String(localized: "today.element.wood")
        case .binh, .dinh: String(localized: "today.element.fire")
        case .mau, .ky: String(localized: "today.element.earth")
        case .canh, .tan: String(localized: "today.element.metal")
        case .nham, .quy: String(localized: "today.element.water")
        }
    }

    private var lunarMonthName: String {
        let names: [LocalizedStringResource] = [
            "today.lunar_month_1",
            "today.lunar_month_2",
            "today.lunar_month_3",
            "today.lunar_month_4",
            "today.lunar_month_5",
            "today.lunar_month_6",
            "today.lunar_month_7",
            "today.lunar_month_8",
            "today.lunar_month_9",
            "today.lunar_month_10",
            "today.lunar_month_11",
            "today.lunar_month_12"
        ]
        let month = currentLunarDate.month
        guard month >= 1, month <= 12 else { return String(format: String(localized: "calendar.month_name_number"), month) }
        return String(localized: names[month - 1])
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
        formatter.locale = Locale.current
        formatter.timeZone = VNTime.vietnam
        formatter.dateFormat = String(localized: "today.weekday_date_format")
        return formatter.string(from: date).capitalized
    }

    private var weekOfYearText: String? {
        guard let date = gmt7Date else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = VNTime.vietnam
        return String(format: String(localized: "today.week_of_year"), calendar.component(.weekOfYear, from: date))
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
                .font(.vnDisplay(.subheadline, weight: .semibold))
                .foregroundColor(.vnTextSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .contentTransition(.opacity)
                .animation(dateAnimation, value: title)
        }
    }

    private var hoangDaoPill: some View {
        HStack(spacing: VNSpacing.xs) {
            Image(systemName: "sun.max")
                .font(.caption2.weight(.semibold))
                .accessibilityHidden(true)
            Text(dayStar.isAuspicious ? LocalizedStringKey("today.auspicious") : LocalizedStringKey("today.inauspicious"))
                .font(.vnDisplay(.caption2, weight: .semibold))
                .lineLimit(1)
                .fixedSize()
                .tracking(0.66)
        }
        .foregroundColor(.vnAccentDeepPrimary)
        .padding(.horizontal, VNSpacing.sm)
        .padding(.vertical, VNSpacing.xs)
        .background(Color.vnAccentRedSurface)
        .clipShape(Capsule())
        .contentTransition(.opacity)
        .animation(dateAnimation, value: dayStar.isAuspicious)
    }

    // MARK: - Solar + Lunar date (primary focus)
    private var dateRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: VNSpacing.md) {
            Text("\(currentSolarDate.day)")
                .font(.vnDisplay(size: solarNumeralSize, weight: .light))
                .foregroundColor(.vnTextPrimary)
                .contentTransition(.numericText())
                .animation(dateAnimation, value: currentSolarDate.day)
                .accessibilityLabel(String(format: String(localized: "today.solar_day_accessibility"), currentSolarDate.day))

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: VNSpacing.space2) {
                Text("common.date_type_lunar")
                    .font(.vnDisplay(.caption2, weight: .medium))
                    .foregroundColor(.vnAccentGoldText)
                Text(String(format: String(localized: "today.lunar_day"), currentLunarDate.day))
                    .font(.vnDisplay(size: lunarNumeralSize, weight: .semibold))
                    .foregroundColor(.vnAccentHeritageRed)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .contentTransition(.numericText())
                    .animation(dateAnimation, value: currentLunarDate.day)
                Text(lunarMonthName)
                    .font(.vnDisplay(.subheadline, weight: .semibold))
                    .foregroundColor(.vnTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .contentTransition(.interpolate)
                    .animation(dateAnimation, value: currentLunarDate.month)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var dateAnimation: Animation? {
        reduceMotion ? nil : .smooth(duration: 0.35)
    }

    private var canChiLine: some View {
        Text(String(format: String(localized: "today.canchi_line"), currentCanChi.day.description, currentCanChi.month.description, currentCanChi.year.description))
            .font(.vnDisplay(.footnote, weight: .medium))
            .foregroundColor(.vnTextSecondary)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
            .contentTransition(.opacity)
            .animation(dateAnimation, value: currentCanChi.day.description)
    }

    private func memorialRow(_ memorial: UpcomingMemorial) -> some View {
        HStack(spacing: VNSpacing.sm) {
            Image(systemName: "flame")
                .font(.footnote.weight(.semibold))
                .foregroundColor(.vnAccentHeritageRed)
                .accessibilityHidden(true)
            Text(memorial.title)
                .font(.vnDisplay(.subheadline, weight: .semibold))
                .foregroundColor(.vnTextPrimary)
                .lineLimit(1)
            Spacer(minLength: VNSpacing.sm)
            Text(memorial.countdown)
                .font(.vnDisplay(.caption, weight: .semibold))
                .foregroundColor(.vnAccentHeritageRed)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .contentTransition(.numericText())
                .animation(dateAnimation, value: memorial.countdown)
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
                    .font(.vnDisplay(.caption))
                    .foregroundColor(.vnTextSecondary)
                    .contentTransition(.opacity)
                    .animation(dateAnimation, value: detailsSummary)
                TodayHeroGuidance(
                    hours: EarthlyBranch.auspiciousHours(for: dynamicDayBranch),
                    suitable: suitableText,
                    taboo: tabooText
                )
            }
            .padding(.top, VNSpacing.sm)
        } label: {
            Text("today.details_title")
                .font(.vnDisplay(.subheadline, weight: .semibold))
                .foregroundColor(.vnTextPrimary)
        }
        .tint(.vnTextSecondary)
        .animation(reduceMotion ? nil : VNAnimation.cardExpansion, value: showDetails)
        .sensoryFeedback(.selection, trigger: showDetails)
    }

    private var detailsSummary: String {
        [weekOfYearText, String(format: String(localized: "today.star_name"), dayStar.vietnameseName), String(format: String(localized: "today.element_summary"), dayElementName)]
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
                Text("hero.auspicious_hours")
                    .font(.vnDisplay(.caption2, weight: .semibold))
                    .tracking(0.66)
                    .foregroundColor(.vnTextSecondary)

                Spacer(minLength: 0)

                Text(String(format: String(localized: "today.auspicious_hours_count"), hours.count))
                    .font(.vnDisplay(.caption2, weight: .medium))
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
                .font(.vnDisplay(.caption2, weight: .semibold))
                .foregroundColor(.vnAccentDeepPrimary)

            Text(hourRangeText(branch))
                .font(.vnDisplay(.caption2))
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
                title: String(localized: "today.suitable_activities"),
                icon: "checkmark.circle.fill",
                tint: .vnAccentGoldText,
                background: .vnAccentGoldSurface,
                text: suitable
            )

            guidancePanel(
                title: String(localized: "today.taboo_activities"),
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
                    .font(.vnDisplay(.caption2, weight: .semibold))
                    .foregroundColor(.vnTextPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }

            Text(text)
                .font(.vnDisplay(.caption))
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
            VNButton(String(localized: "action.add_reminder"), icon: "plus", variant: .primary, size: .small, isFullWidth: true, action: onAddReminder)
                .popoverTip(AddReminderTip())
            VNButton(String(localized: "action.search"), icon: "magnifyingglass", variant: .secondary, size: .small, isFullWidth: true, action: onQuickSearch)
        }
    }
}
