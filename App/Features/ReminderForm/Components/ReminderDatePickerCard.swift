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

    var body: some View {
        VStack(alignment: .leading, spacing: VNSpacing.sm) {
            Text("HỆ LỊCH & THỜI ĐIỂM")
                .font(.system(size: 11, weight: .medium))
                .tracking(0.66)
                .foregroundColor(.vnAccentImperialGold)

            VNCard(
                allPadding: VNSpacing.xl,
                cornerRadius: VNCornerRadius.card,
                backgroundColor: Color.vnBackgroundSecondary,
                borderColor: Color.vnAccentImperialGold.opacity(0.28),
                shadow: nil
            ) {
                VStack(spacing: VNSpacing.md) {
                    Picker("Hệ Lịch", selection: $dateType) {
                        Text("Âm Lịch (Khuyên Dùng)").tag(CalendarDateType.lunar)
                        Text("Dương Lịch").tag(CalendarDateType.solar)
                    }
                    .pickerStyle(.segmented)
                    .tint(Color.vnAccentHeritageRed)

                    HStack(spacing: VNSpacing.md) {
                        pickerColumn(title: "Ngày") {
                            Picker("Ngày", selection: $day) {
                                ForEach(1...31, id: \.self) { d in
                                    Text("\(d)").tag(d)
                                }
                            }
                        }

                        pickerColumn(title: "Tháng") {
                            Picker("Tháng", selection: $month) {
                                ForEach(1...12, id: \.self) { m in
                                    Text("Tháng \(m)").tag(m)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: VNSpacing.xs) {
                            Text("Năm (tùy chọn)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.vnTextSecondary)
                            TextField("VD: 2024", text: $year)
                                .keyboardType(.numberPad)
                                .font(.system(size: 16, weight: .semibold))
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
                        Toggle("Là sự kiện trong Tháng Nhuận", isOn: $isLeapMonth)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.vnTextPrimary)
                            .tint(Color.vnAccentHeritageRed)
                    }

                    // Live Astronomical Preview
                    HStack(spacing: VNSpacing.xs) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11))
                            .foregroundColor(.vnAccentHeritageRed)
                        Text(astronomicalPreviewText)
                            .font(.system(size: 12, design: .serif))
                            .foregroundColor(.vnTextSecondary)
                            .lineLimit(1)
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
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.vnTextSecondary)
            content()
                .pickerStyle(.menu)
                .font(.system(size: 16, weight: .semibold))
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
        let currentYear = Calendar.current.component(.year, from: Date())
        let selectedYear = Int(year.trimmingCharacters(in: .whitespaces)) ?? currentYear

        if dateType == .lunar {
            let lunar = LunarDate(day: day, month: month, year: selectedYear, isLeapMonth: isLeapMonth)
            let solar = engine.convertToSolar(from: lunar)
            let canChi = engine.computeCanChi(for: solar)
            let solarDayStr = String(format: "%02d", solar.day)
            let solarMonthStr = String(format: "%02d", solar.month)
            return "Dương lịch: \(solarDayStr)/\(solarMonthStr)/\(solar.year) (Năm \(canChi.year.description))"
        } else {
            let solar = SolarDate(day: day, month: month, year: selectedYear)
            let lunar = engine.convertToLunar(from: solar)
            let canChi = engine.computeCanChi(for: solar)
            let lunarDayStr = String(format: "%02d", lunar.day)
            let lunarMonthStr = String(format: "%02d", lunar.month)
            return "Âm lịch: \(lunarDayStr)/\(lunarMonthStr)/\(lunar.year) (Năm \(canChi.year.description))"
        }
    }
}
