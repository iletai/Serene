import SwiftUI
import VNCalendarDesignSystem
import VNCalendarDomain
import VNCalendarLunar

struct ReminderHeaderView: View {
    let isEditing: Bool
    let day: Int
    let month: Int
    let year: String
    let dateType: CalendarDateType
    let isLeapMonth: Bool

    @ScaledMetric(relativeTo: .largeTitle) private var numeralSize: CGFloat = 56

    // Faint neutral folio shadow: 0 4px 20px rgba(0,0,0,0.05).
    private static let folioShadow = VNShadow.ShadowConfig(
        color: Color.black.opacity(0.05),
        radius: 20,
        x: 0,
        y: 4
    )

    var body: some View {
        VNCard(
            allPadding: VNSpacing.cardPadding,
            cornerRadius: VNCornerRadius.card,
            backgroundColor: Color.vnBackgroundSecondary,
            borderColor: Color.vnAccentImperialGold.opacity(0.28),
            shadow: Self.folioShadow
        ) {
            VStack(alignment: .leading, spacing: VNSpacing.sm) {
                HStack(spacing: VNSpacing.xs) {
                    Circle()
                        .fill(Color.vnAccentImperialGold)
                        .frame(width: 6, height: 6)
                        .accessibilityHidden(true)
                    Text("reminder.eyebrow")
                        .font(.vnCaption2)
                        .fontWeight(.medium)
                        .tracking(0.66)
                        .foregroundColor(.vnAccentGoldText)
                }

                Text(isEditing ? String(localized: "reminder.title_edit") : String(localized: "reminder.title_add"))
                    .font(.system(.title, design: .serif, weight: .semibold))
                    .foregroundColor(.vnTextPrimary)
                    .minimumScaleFactor(0.8)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                    .accessibilityAddTraits(.isHeader)

                Text("reminder.subtitle")
                    .font(.system(.footnote, design: .serif))
                    .italic()
                    .foregroundColor(.vnTextSecondary)

                VNRowDivider()

                datePreview
            }
        }
    }

    // Solar/lunar preview: huge light numeral + red serif lunar callout + small seal.
    private var datePreview: some View {
        HStack(alignment: .center, spacing: VNSpacing.md) {
            Text("\(solarDate.day)")
                .font(.system(size: numeralSize, weight: .light))
                .foregroundColor(.vnTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            VStack(alignment: .leading, spacing: VNSpacing.space2) {
                Text(dateType == .lunar ? String(localized: "reminder.calendar_solar_upper") : String(localized: "reminder.calendar_lunar_upper"))
                    .font(.vnCaption2)
                    .fontWeight(.medium)
                    .tracking(0.66)
                    .foregroundColor(.vnAccentGoldText)
                Text(String(format: String(localized: "reminder.preview_lunar_date"), lunarDate.day, lunarDate.month))
                    .font(.system(.subheadline, design: .serif, weight: .bold))
                    .tracking(0.28)
                    .foregroundColor(.vnAccentHeritageRed)
                    .lineLimit(1)
                Text(String(format: String(localized: "reminder.preview_year_can_chi"), canChiYearName))
                    .font(.vnCaption1)
                    .foregroundColor(.vnTextSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            VNSealBadge.gio(size: .small)
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    // MARK: - Preview conversion (display only, mirrors ReminderDatePickerCard)

    private var selectedYear: Int {
        let typed = Int(year.trimmingCharacters(in: .whitespaces))
        return typed ?? VNTime.vietnamCalendar.component(.year, from: Date())
    }

    private var solarDate: SolarDate {
        if dateType == .lunar {
            let lunar = LunarDate(day: day, month: month, year: selectedYear, isLeapMonth: isLeapMonth)
            return LunarAstronomicalEngine().convertToSolar(from: lunar)
        }
        return SolarDate(day: day, month: month, year: selectedYear)
    }

    private var lunarDate: LunarDate {
        if dateType == .lunar {
            return LunarDate(day: day, month: month, year: selectedYear, isLeapMonth: isLeapMonth)
        }
        let solar = SolarDate(day: day, month: month, year: selectedYear)
        return LunarAstronomicalEngine().convertToLunar(from: solar)
    }

    private var canChiYearName: String {
        LunarAstronomicalEngine().computeCanChi(for: solarDate).year.description
    }
}
