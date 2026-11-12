import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem
import VNCalendarLunar

struct ReminderDatePickerCard: View {
    @Binding var dateType: CalendarDateType
    @Binding var day: Int
    @Binding var month: Int
    @Binding var year: String
    @Binding var isLeapMonth: Bool

    @FocusState private var isYearFocused: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Columns stack vertically at accessibility sizes so the pickers stay readable.
    private var columnsLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: VNSpacing.md))
            : AnyLayout(HStackLayout(spacing: VNSpacing.md))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: VNSpacing.sm) {
            Text("reminder.date_header")
                .font(.caption2.weight(.medium))
                .tracking(0.66)
                .foregroundColor(.vnAccentGoldText)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .accessibilityAddTraits(.isHeader)

            VNCard(
                allPadding: VNSpacing.cardPadding,
                cornerRadius: VNCornerRadius.card,
                backgroundColor: Color.vnBackgroundSecondary,
                borderColor: Color.vnAccentImperialGold.opacity(0.28),
                shadow: nil
            ) {
                VStack(spacing: VNSpacing.md) {
                    Picker("reminder.date_type", selection: $dateType) {
                        Text("reminder.date_type_lunar").tag(CalendarDateType.lunar)
                        Text("reminder.date_type_solar").tag(CalendarDateType.solar)
                    }
                    .pickerStyle(.segmented)
                    .tint(Color.vnAccentHeritageRed)

                    columnsLayout {
                        pickerColumn(title: String(localized: "reminder.day")) {
                            Picker("reminder.day", selection: $day) {
                                ForEach(1...31, id: \.self) { d in
                                    Text("\(d)").tag(d)
                                }
                            }
                        }

                        pickerColumn(title: String(localized: "reminder.month")) {
                            Picker("reminder.month", selection: $month) {
                                ForEach(1...12, id: \.self) { m in
                                    Text(String(format: String(localized: "reminder.month_option"), m)).tag(m)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: VNSpacing.xs) {
                            Text("reminder.year_optional")
                                .font(.caption.weight(.medium))
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                                .foregroundColor(.vnTextSecondary)
                            TextField("reminder.year_placeholder", text: $year)
                                .keyboardType(.numberPad)
                                .font(.callout.weight(.semibold))
                                .foregroundColor(.vnTextPrimary)
                                .focused($isYearFocused)
                                .padding(.bottom, VNSpacing.sm)
                                .background(Color.clear)
                                .overlay(alignment: .bottom) {
                                    Rectangle()
                                        .fill(isYearFocused ? Color.vnAccentHeritageRed : Color.vnBorderSubtle)
                                        .frame(height: isYearFocused ? VNBorderWidth.active : VNBorderWidth.hairline)
                                }
                        }
                    }

                    if dateType == .lunar {
                        Toggle("reminder.leap_month", isOn: $isLeapMonth)
                            .font(.footnote.weight(.medium))
                            .foregroundColor(.vnTextPrimary)
                            .tint(Color.vnAccentHeritageRed)
                    }

                    // Live Astronomical Preview
                    HStack(spacing: VNSpacing.xs) {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                            .foregroundColor(.vnAccentHeritageRed)
                            .accessibilityHidden(true)
                        Text(astronomicalPreviewText)
                            .font(.vnDisplay(.caption))
                            .foregroundColor(.vnTextSecondary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }
                    .padding(.horizontal, VNSpacing.sm)
                    .padding(.vertical, VNSpacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.vnAccentRedSurface.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.small))
                }
            }
        }
    }

    private func pickerColumn<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundColor(.vnTextSecondary)
            content()
                .pickerStyle(.menu)
                .font(.callout.weight(.semibold))
                .foregroundColor(.vnTextPrimary)
                .padding(.bottom, VNSpacing.xs)
                .background(Color.clear)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color.vnBorderSubtle)
                        .frame(height: VNBorderWidth.hairline)
                }
        }
    }

    private var astronomicalPreviewText: String {
        let engine = LunarAstronomicalEngine()
        let currentYear = VNTime.vietnamCalendar.component(.year, from: Date())
        let selectedYear = Int(year.trimmingCharacters(in: .whitespaces)) ?? currentYear

        if dateType == .lunar {
            let lunar = LunarDate(day: day, month: month, year: selectedYear, isLeapMonth: isLeapMonth)
            let solar = engine.convertToSolar(from: lunar)
            let canChi = engine.computeCanChi(for: solar)
            return String(format: String(localized: "reminder.preview_solar"), solar.day, solar.month, solar.year, canChi.year.description)
        } else {
            let solar = SolarDate(day: day, month: month, year: selectedYear)
            let lunar = engine.convertToLunar(from: solar)
            let canChi = engine.computeCanChi(for: solar)
            return String(format: String(localized: "reminder.preview_lunar"), lunar.day, lunar.month, lunar.year, canChi.year.description)
        }
    }
}
