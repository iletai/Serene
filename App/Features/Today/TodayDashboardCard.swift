import SwiftUI
import TipKit
import VNCalendarDomain
import VNCalendarDesignSystem
import VNCalendarKit
import VNCalendarLunar

/// Today's page, laid out as the prototype's "tờ lịch bloc": a blue month strip,
/// a large solar numeral, the lunar block split into moon tile + almanac lines,
/// then the auspicious-hour dial and the advice carousel.
public struct TodayDashboardCard: View {
    public let details: DayCalendarDetails?
    public var onAddReminder: () -> Void
    public var onQuickSearch: () -> Void
    let upcomingMemorial: UpcomingMemorial?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var solarNumeralSize: CGFloat = 132
    @ScaledMetric(relativeTo: .title) private var lunarNumeralSize: CGFloat = 44

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

    public var body: some View {
        VStack(alignment: .leading, spacing: VNSpacing.md) {
            blocCard
            TodayCardActions(onAddReminder: onAddReminder, onQuickSearch: onQuickSearch)
            if let memorial = upcomingMemorial {
                memorialRow(memorial)
            }
            hoursSection
            adviceSection
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    // MARK: - Bloc

    private var blocCard: some View {
        VStack(spacing: 0) {
            blocStrip
            solarBlock
            lunarBlock
            hoursLine
            quoteLine
        }
        .background(Color.vnBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: VNCard<EmptyView>.defaultCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: VNCard<EmptyView>.defaultCornerRadius, style: .continuous)
                .stroke(Color.vnBorderSubtle, lineWidth: VNBorderWidth.hairline)
        )
        .shadow(
            color: VNShadow.folio.color,
            radius: VNShadow.folio.radius,
            x: VNShadow.folio.x,
            y: VNShadow.folio.y
        )
        .accessibilityElement(children: .combine)
    }

    private var blocStrip: some View {
        HStack(spacing: VNSpacing.md) {
            Text(String(format: String(localized: "today.bloc_strip"), currentSolarDate.month, currentSolarDate.year))
            Spacer(minLength: VNSpacing.xs)
            Text(weekdayTitle?.uppercased() ?? "")
        }
        .font(.vnDisplay(.footnote, weight: .semibold))
        .tracking(1.0)
        .foregroundColor(.vnOnAccent)
        .padding(.horizontal, VNSpacing.xl)
        .padding(.top, VNSpacing.xl)
        .padding(.bottom, VNSpacing.md)
        .frame(maxWidth: .infinity)
        .background(Color.vnAccentSky)
    }

    private var solarBlock: some View {
        VStack(spacing: VNSpacing.xs) {
            Text("\(currentSolarDate.day)")
                .font(.vnDisplay(size: solarNumeralSize, weight: .heavy))
                .tracking(-4)
                .monospacedDigit()
                .foregroundColor(isRedLetterDay ? .vnAccentDeepPrimary : .vnAccentSky)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText())
                .animation(dateAnimation, value: currentSolarDate.day)
                .accessibilityLabel(String(format: String(localized: "today.solar_day_accessibility"), currentSolarDate.day))

            if let tag = solarTag {
                Text(tag.text)
                    .font(.vnDisplay(.subheadline, weight: .semibold))
                    .foregroundColor(tag.isFestival ? .vnAccentDeepPrimary : .vnAccentGoldText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(.horizontal, VNSpacing.xl)
        .padding(.top, VNSpacing.md)
        .padding(.bottom, VNSpacing.sm)
        .frame(maxWidth: .infinity)
    }

    private var lunarBlock: some View {
        HStack(alignment: .top, spacing: VNSpacing.lg) {
            moonTile
            almanacLines
        }
        .padding(.top, VNSpacing.lg)
        .padding(.horizontal, VNSpacing.xl)
        .overlay(alignment: .top) {
            dashedDivider
                .padding(.horizontal, VNSpacing.xl)
        }
    }

    private var dashedDivider: some View {
        Rectangle()
            .fill(Color.vnBorderSubtle)
            .frame(height: VNBorderWidth.hairline)
            .mask(
                HStack(spacing: 4) {
                    ForEach(0..<40, id: \.self) { _ in
                        Rectangle().frame(width: 5)
                    }
                }
            )
            .accessibilityHidden(true)
    }

    private var moonTile: some View {
        VStack(spacing: VNSpacing.space2) {
            VNMoonPhaseView(lunarDay: currentLunarDate.day, size: 40)
                .padding(.bottom, VNSpacing.xs)

            Text("\(currentLunarDate.day)")
                .font(.vnDisplay(size: lunarNumeralSize, weight: .bold))
                .monospacedDigit()
                .foregroundColor(currentLunarDate.day == 1 || currentLunarDate.day == 15 ? .vnAccentDeepPrimary : .vnTextPrimary)

            Text(lunarMonthLabel)
                .font(.vnDisplay(.footnote, weight: .medium))
                .foregroundColor(.vnTextSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(width: 104)
        .padding(.vertical, VNSpacing.md)
        .background(Color.vnBackgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.small, style: .continuous))
    }

    private var almanacLines: some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            Text("today.lunar_calendar_label")
                .font(.vnDisplay(.caption2, weight: .semibold))
                .tracking(1.0)
                .foregroundColor(.vnTextSecondary)

            Text(lunarDayName)
                .font(.vnDisplay(.body, weight: .bold))
                .foregroundColor(.vnTextPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(String(format: String(localized: "calendar.header.subtitle.year_canchi"), currentCanChi.year.description))
                .font(.vnDisplay(.subheadline))
                .foregroundColor(.vnTextPrimary)

            Text(String(format: String(localized: "today.bloc_canchi"), currentCanChi.day.description, currentCanChi.month.description))
                .font(.vnDisplay(.subheadline))
                .foregroundColor(.vnTextPrimary)

            Text(String(format: String(localized: "today.bloc_term_moon"), currentSolarTerm.vietnameseName, moonPhaseName))
                .font(.vnDisplay(.subheadline))
                .foregroundColor(.vnTextPrimary)

            auspiciousPill
                .padding(.top, VNSpacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var auspiciousPill: some View {
        HStack(spacing: VNSpacing.xs) {
            Image(systemName: "star.fill")
                .font(.system(size: 9, weight: .bold))
                .accessibilityHidden(true)
            Text(dayStar.isAuspicious ? LocalizedStringKey("today.auspicious") : LocalizedStringKey("today.inauspicious"))
            Text(verbatim: "· \(dayStar.vietnameseName)")
        }
        .font(.vnDisplay(.caption2, weight: .semibold))
        .tracking(0.6)
        .foregroundColor(dayStar.isAuspicious ? .vnAccentGoldText : .vnTextSecondary)
        .padding(.horizontal, VNSpacing.sm)
        .padding(.vertical, VNSpacing.xs)
        .background(dayStar.isAuspicious ? Color.vnAccentGoldSurface : Color.vnBackgroundTertiary)
        .clipShape(Capsule())
    }

    private var hoursLine: some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            Text("hero.auspicious_hours")
                .font(.vnDisplay(.caption2, weight: .semibold))
                .tracking(0.8)
                .foregroundColor(.vnAccentSky)
            Text(auspiciousHours.map(\.vietnameseName).joined(separator: " · "))
                .font(.vnDisplay(.subheadline, weight: .semibold))
                .foregroundColor(.vnTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, VNSpacing.lg)
        .padding(.vertical, VNSpacing.md)
        .background(Color.vnAccentSkySurface)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.small, style: .continuous))
        .padding(.horizontal, VNSpacing.xl)
        .padding(.top, VNSpacing.lg)
    }

    private var quoteLine: some View {
        Text(quote.quote)
            .font(.vnQuote)
            .foregroundColor(.vnTextSecondary)
            .multilineTextAlignment(.center)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, VNSpacing.xl)
            .padding(.top, VNSpacing.lg)
            .padding(.bottom, VNSpacing.xl)
    }

    // MARK: - Hours + advice sections

    private var hoursSection: some View {
        VStack(alignment: .leading, spacing: VNSpacing.sm) {
            VNGroupHeader(String(localized: "today.hours_section_header"))
            VNGroupCard {
                VNHourDialCard(auspiciousHours: auspiciousHours)
            }
        }
    }

    private var adviceSection: some View {
        VStack(alignment: .leading, spacing: VNSpacing.sm) {
            VNGroupHeader(String(localized: "today.advice_section_header"))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: VNSpacing.md) {
                    ForEach(adviceCards) { card in
                        VNAdviceTipCard(card: card)
                    }
                }
            }
            VNGroupFooter(String(localized: "today.advice_footer"))
        }
    }

    private func memorialRow(_ memorial: UpcomingMemorial) -> some View {
        VNGroupCard {
            VNListRow(
                icon: "flame.fill",
                iconTint: .vnAccentHeritageRed,
                title: memorial.title,
                subtitle: String(localized: "today.upcoming_memorial_subtitle"),
                showsChevron: false
            ) {
                Text(memorial.countdown)
                    .font(.vnDisplay(.caption, weight: .semibold))
                    .foregroundColor(.vnAccentDeepPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }

    // MARK: - Derived content

    private var currentSolarDate: SolarDate {
        details?.solarDate ?? SolarDate(from: Date())
    }

    private var currentLunarDate: LunarDate {
        details?.lunarDate ?? LunarAstronomicalEngine.shared.convertToLunar(from: SolarDate(from: Date()))
    }

    private var currentCanChi: FullCanChi {
        details?.canChi ?? LunarAstronomicalEngine.shared.computeCanChi(for: SolarDate(from: Date()))
    }

    private var currentSolarTerm: SolarTerm {
        details?.solarTerm ?? .dongChi
    }

    private var dynamicDayBranch: EarthlyBranch {
        if let details { return details.canChi.day.branch }
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

    private var auspiciousHours: [EarthlyBranch] {
        EarthlyBranch.auspiciousHours(for: dynamicDayBranch)
    }

    private var lunarMonthLabel: String {
        let names: [LocalizedStringResource] = [
            "today.lunar_month_1", "today.lunar_month_2", "today.lunar_month_3", "today.lunar_month_4",
            "today.lunar_month_5", "today.lunar_month_6", "today.lunar_month_7", "today.lunar_month_8",
            "today.lunar_month_9", "today.lunar_month_10", "today.lunar_month_11", "today.lunar_month_12"
        ]
        let month = currentLunarDate.month
        guard month >= 1, month <= 12 else {
            return String(format: String(localized: "calendar.month_name_number"), month)
        }
        let base = String(localized: names[month - 1]).lowercased()
        return currentLunarDate.isLeapMonth ? "\(base) nhuận" : base
    }

    private var lunarDayName: String {
        let month = lunarMonthLabel
        if currentLunarDate.day == 1 {
            return String(format: String(localized: "daydetail.header.mung_mot"), month)
        }
        if currentLunarDate.day == 15 {
            return String(format: String(localized: "daydetail.header.ram_15"), month)
        }
        return String(format: String(localized: "daydetail.header.lunar_day"), currentLunarDate.day, month)
    }

    private var moonPhaseName: String {
        VNMoonPhaseType.from(lunarDay: currentLunarDate.day).localizedName
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

    private var isSunday: Bool {
        guard let date = gmt7Date else { return false }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = VNTime.vietnam
        return calendar.component(.weekday, from: date) == 1
    }

    private var festivalHoliday: Holiday? {
        details?.holidays.first { $0.isNationalHoliday || $0.isTraditionHoliday }
    }

    private var isRedLetterDay: Bool {
        isSunday || festivalHoliday != nil
    }

    private var solarTag: (text: String, isFestival: Bool)? {
        if let festivalHoliday { return (festivalHoliday.title, true) }
        return (String(format: String(localized: "calendar.solar_term"), currentSolarTerm.vietnameseName), false)
    }

    private var quote: VNFolkQuote {
        VNFolkQuotes.quote(for: DateKey(solarDate: currentSolarDate))
    }

    private var dateAnimation: Animation? {
        reduceMotion ? nil : .smooth(duration: 0.35)
    }

    private var adviceCards: [VNAdviceTipCard.Model] {
        let starTone: VNAdviceTipCard.Tone = dayStar.isAuspicious ? .ochre : .grey
        let starTitle = dayStar.isAuspicious ? String(localized: "today.auspicious") : String(localized: "today.inauspicious")
        let starText = dayStar.isAuspicious
            ? String(localized: "today.advice.auspicious")
            : String(localized: "today.advice.inauspicious")
        return [
            .init(tone: starTone, icon: "star.fill", kicker: String(localized: "today.advice.kicker_day"), title: starTitle, text: starText),
            .init(
                tone: .jade,
                icon: "leaf.fill",
                kicker: String(localized: "today.advice.kicker_officer"),
                title: dayOfficer.name,
                text: dayOfficer.summary
            ),
            .init(
                tone: .ochre,
                icon: "sun.max.fill",
                kicker: String(localized: "today.advice.kicker_term"),
                title: currentSolarTerm.vietnameseName,
                text: String(localized: "today.advice.term_body")
            ),
            .init(
                tone: .grey,
                icon: "moon.stars.fill",
                kicker: String(localized: "today.advice.kicker_canchi"),
                title: String(format: String(localized: "today.bloc_canchi"), currentCanChi.day.description, currentCanChi.month.description),
                text: String(format: String(localized: "calendar.header.subtitle.year_canchi"), currentCanChi.year.description)
            )
        ]
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
