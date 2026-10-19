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

    // Faint folio shadow from canonical: 0 4px 20px -2px rgba(90,84,79,0.05).
    private static let folioShadow = VNShadow.ShadowConfig(
        color: Color(red: 90.0 / 255.0, green: 84.0 / 255.0, blue: 79.0 / 255.0, opacity: 0.05),
        radius: 20,
        x: 0,
        y: 4
    )

    var body: some View {
        VNCard(
            allPadding: VNSpacing.xl,
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
                    Text("VĂN HÓA & GIA TỘC")
                        .font(.vnCaption2)
                        .fontWeight(.medium)
                        .tracking(0.66)
                        .foregroundColor(.vnAccentImperialGold)
                }

                Text(isEditing ? "Chỉnh Sửa Sự Kiện" : "Thêm Sự Kiện & Lễ Tiết")
                    .font(.vnTitleHero)
                    .foregroundColor(.vnTextPrimary)

                Text("Lưu giữ nếp nhà, vẹn tròn hiếu nghĩa")
                    .font(.system(size: 13, weight: .regular, design: .serif))
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
                .font(.system(size: 56, weight: .light))
                .foregroundColor(.vnTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            VStack(alignment: .leading, spacing: VNSpacing.space2) {
                Text(dateType == .lunar ? "DƯƠNG LỊCH" : "ÂM LỊCH")
                    .font(.vnCaption2)
                    .fontWeight(.medium)
                    .tracking(0.66)
                    .foregroundColor(.vnAccentImperialGold)
                Text("Ngày \(lunarDate.day) Tháng \(lunarDate.month)")
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .tracking(0.28)
                    .foregroundColor(.vnAccentHeritageRed)
                    .lineLimit(1)
                Text("Năm \(canChiYearName)")
                    .font(.vnCaption1)
                    .foregroundColor(.vnTextSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            VNSealBadge.gio(size: .small)
        }
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
