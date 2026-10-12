import SwiftUI
import VNCalendarDesignSystem
import VNCalendarDomain
import VNCalendarLunar

public struct VNWeekCalendarView: View {
    public let weekDays: [VNCalendarDayModel]
    public let selectedDayModel: VNCalendarDayModel?
    public let onSelectDay: (DateKey, Date) -> Void
    public let onPreviousWeek: () -> Void
    public let onNextWeek: () -> Void
    public let onAddReminder: () -> Void
    public let onTapDayDetail: () -> Void

    @State private var dragOffset: CGFloat = 0

    public init(
        weekDays: [VNCalendarDayModel],
        selectedDayModel: VNCalendarDayModel?,
        onSelectDay: @escaping (DateKey, Date) -> Void,
        onPreviousWeek: @escaping () -> Void,
        onNextWeek: @escaping () -> Void,
        onAddReminder: @escaping () -> Void = {},
        onTapDayDetail: @escaping () -> Void = {}
    ) {
        self.weekDays = weekDays
        self.selectedDayModel = selectedDayModel
        self.onSelectDay = onSelectDay
        self.onPreviousWeek = onPreviousWeek
        self.onNextWeek = onNextWeek
        self.onAddReminder = onAddReminder
        self.onTapDayDetail = onTapDayDetail
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 7-Day Horizontal Strip (Thanh 7 Ngày Trong Tuần)
            weekStripView
                .offset(x: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation.width * 0.4
                        }
                        .onEnded { value in
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                if value.translation.width < -60 {
                                    onNextWeek()
                                } else if value.translation.width > 60 {
                                    onPreviousWeek()
                                }
                                dragOffset = 0
                            }
                        }
                )
                .padding(.horizontal, VNSpacing.md)
                .padding(.vertical, VNSpacing.xs)

            Divider()
                .background(Color.vnBorderSubtle)

            // Agenda / Hourly Schedule of the Selected Day
            ScrollView {
                VStack(spacing: VNSpacing.md) {
                    if let model = selectedDayModel {
                        // Selected Day Overview Header Card
                        dayOverviewHeaderCard(for: model)

                        // 12 Lunar Hours Timeline
                        lunarHoursTimeline(for: model)

                        // Anniversaries & Reminders Section
                        anniversariesSection(for: model)
                    } else {
                        Text("Chọn một ngày trong tuần để xem chi tiết")
                            .font(.system(size: 14))
                            .foregroundColor(.vnTextSecondary)
                            .padding(.top, VNSpacing.space32)
                    }
                }
                .padding(.horizontal, VNSpacing.xl)
                .padding(.bottom, VNSpacing.xl)
                .padding(.vertical, VNSpacing.sm)
            }
        }
    }

    // MARK: - 7-Day Week Strip

    private var weekStripView: some View {
        HStack(spacing: VNSpacing.xs) {
            ForEach(weekDays) { day in
                let isSelected = (day.dateKey == selectedDayModel?.dateKey)

                Button {
                    onSelectDay(day.dateKey, day.solarDate)
                } label: {
                    VStack(spacing: 3) {
                        // Thứ (T2, T3...)
                        Text(shortWeekday(from: day.weekdayName))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(isSelected ? .vnRicePaperWhite : .vnTextSecondary)

                        // Ngày Dương
                        Text("\(day.solarDay)")
                            .font(.system(size: 16, weight: isSelected ? .bold : .semibold, design: .serif))
                            .foregroundColor(isSelected ? .vnRicePaperWhite : .vnTextPrimary)

                        // Ngày Âm (1/8 hoặc 23)
                        let isHighlight = day.isFirstDayOfLunarMonth || day.isFullMoonDay
                        Text(day.lunarDayText)
                            .font(.system(size: 10, weight: isHighlight ? .bold : .regular))
                            .foregroundColor(
                                isSelected ? .vnRicePaperWhite.opacity(0.9) : (isHighlight ? .vnAccentHeritageRed : .vnTextSecondary)
                            )

                        // Dấu chấm sự kiện
                        VNIndicatorDotsView(
                            hasAncestorDeath: day.hasAncestorDeathAnniversary,
                            hasFestival: day.hasFestival,
                            hasPersonalEvent: !day.anniversaries.isEmpty && !day.hasAncestorDeathAnniversary
                        )
                        .frame(height: 5)
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        isSelected ? Color.vnAccentHeritageRed :
                            (day.isToday ? Color.vnAccentImperialGold.opacity(0.12) : Color.vnBackgroundSecondary)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
                    .overlay(
                        RoundedRectangle(cornerRadius: VNCornerRadius.card)
                            .stroke(
                                isSelected ? Color.vnAccentHeritageRed :
                                    (day.isToday ? Color.vnAccentImperialGold : Color.vnBorderSubtle.opacity(0.4)),
                                lineWidth: isSelected ? VNBorderWidth.active : VNBorderWidth.hairline
                            )
                    )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
    }

    // MARK: - Selected Day Header Card

    private func dayOverviewHeaderCard(for model: VNCalendarDayModel) -> some View {
        Button(action: onTapDayDetail) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("\(model.weekdayName), \(model.solarDay)/\(model.solarMonth)/\(model.solarYear)")
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .foregroundColor(.vnTextPrimary)

                        if model.isToday {
                            Text("Hôm nay")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.vnAccentHeritageRed)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.vnAccentHeritageRed.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }

                    Text("Âm lịch: Ngày \(model.lunarDay) \(model.lunarMonthName) (\(model.lunarDayCanChi))")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.vnAccentHeritageRed)

                    Text("\(model.zodiacStar.fullTitle) • Trực \(model.lunarOfficer.name)")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.vnTextSecondary)
                }

                Spacer()

                Image(systemName: "info.circle")
                    .font(.system(size: 18))
                    .foregroundColor(.vnAccentHeritageRed)
            }
            .padding(VNSpacing.md)
            .background(Color.vnBackgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: VNCornerRadius.medium)
                    .stroke(Color.vnBorderSubtle.opacity(0.6), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 12 Lunar Hours Timeline

    private func lunarHoursTimeline(for model: VNCalendarDayModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("12 GIỜ ĐỊA CHI TRONG NGÀY")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.vnTextSecondary)
                .tracking(0.6)

            let columns = [
                GridItem(.flexible(), spacing: 6),
                GridItem(.flexible(), spacing: 6),
                GridItem(.flexible(), spacing: 6),
                GridItem(.flexible(), spacing: 6)
            ]

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(EarthlyBranch.allCases, id: \.self) { branch in
                    let isAuspicious = model.auspiciousHours.contains(branch)

                    VStack(spacing: 2) {
                        HStack(spacing: 2) {
                            if isAuspicious {
                                Circle()
                                    .fill(Color.vnAccentImperialGold)
                                    .frame(width: 4, height: 4)
                            }
                            Text("Giờ \(branch.vietnameseName)")
                                .font(.system(size: 11, weight: isAuspicious ? .bold : .medium, design: .serif))
                                .foregroundColor(isAuspicious ? .vnTextPrimary : .vnTextSecondary)
                        }

                        Text(branch.timeRange)
                            .font(.system(size: 9, weight: .regular))
                            .foregroundColor(isAuspicious ? .vnAccentImperialGold : .vnTextTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(isAuspicious ? Color.vnAccentImperialGold.opacity(0.1) : Color.vnBackgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.small))
                    .overlay(
                        RoundedRectangle(cornerRadius: VNCornerRadius.small)
                            .stroke(
                                isAuspicious ? Color.vnAccentImperialGold.opacity(0.4)
                                    : Color.vnBorderSubtle.opacity(0.4),
                                lineWidth: 0.5
                            )
                    )
                }
            }
        }
        .padding(VNSpacing.xl)
        .background(Color.vnBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.card)
                .stroke(Color.vnBorderSubtle.opacity(0.6), lineWidth: VNBorderWidth.hairline)
        )
    }

    // MARK: - Anniversaries Section

    private func anniversariesSection(for model: VNCalendarDayModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("SỰ KIỆN & LỄ GIỖ TRONG NGÀY")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.vnTextSecondary)
                    .tracking(0.6)

                Spacer()

                Button(action: onAddReminder) {
                    Label("Thêm", systemImage: "plus")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.vnAccentHeritageRed)
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
                .accessibilityLabel("Thêm sự kiện")
            }

            if model.anniversaries.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 14))
                        .foregroundColor(.vnTextTertiary)

                    Text("Không có ngày giỗ hay sự kiện nào trong ngày này.")
                        .font(.system(size: 12))
                        .foregroundColor(.vnTextSecondary)
                }
                .padding(.vertical, 8)
            } else {
                VStack(spacing: 6) {
                    ForEach(model.anniversaries) { item in
                        HStack(spacing: 10) {
                            Rectangle()
                                .fill(item.isAncestorDeath ? Color.vnAccentHeritageRed : Color.vnAccentImperialGold)
                                .frame(width: 3)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.system(size: 13, weight: .semibold, design: .serif))
                                    .foregroundColor(.vnTextPrimary)

                                Text(item.isAncestorDeath ? "Kỳ Giỗ Gia Tiên" : "Kỷ Niệm Gia Đình")
                                    .font(.system(size: 11))
                                    .foregroundColor(.vnTextSecondary)
                            }

                            Spacer()

                            if item.isAncestorDeath {
                                VNSealBadge.gio(size: .small)
                            }
                        }
                        .padding(8)
                        .background(Color.vnBackgroundPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.small))
                    }
                }
            }
        }
        .padding(VNSpacing.xl)
        .background(Color.vnBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.card)
                .stroke(Color.vnBorderSubtle.opacity(0.6), lineWidth: VNBorderWidth.hairline)
        )
    }

    // MARK: - Helpers

    private func shortWeekday(from full: String) -> String {
        switch full {
        case "Thứ Hai": return "T2"
        case "Thứ Ba": return "T3"
        case "Thứ Tư": return "T4"
        case "Thứ Năm": return "T5"
        case "Thứ Sáu": return "T6"
        case "Thứ Bảy": return "T7"
        case "Chủ Nhật": return "CN"
        default: return full
        }
    }
}
