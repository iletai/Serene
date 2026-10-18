import SwiftUI
import VNCalendarDesignSystem
import VNCalendarDomain
import VNCalendarLunar

public struct VNBlockCalendarView: View {
    public let dayModel: VNCalendarDayModel?
    public let onPreviousDay: () -> Void
    public let onNextDay: () -> Void
    public let onSelectToday: () -> Void
    public let onTapDetails: () -> Void

    @State private var dragOffset: CGFloat = 0

    public init(
        dayModel: VNCalendarDayModel?,
        onPreviousDay: @escaping () -> Void,
        onNextDay: @escaping () -> Void,
        onSelectToday: @escaping () -> Void,
        onTapDetails: @escaping () -> Void
    ) {
        self.dayModel = dayModel
        self.onPreviousDay = onPreviousDay
        self.onNextDay = onNextDay
        self.onSelectToday = onSelectToday
        self.onTapDetails = onTapDetails
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: VNSpacing.md) {
                if let model = dayModel {
                    // Physical Block Calendar Card (Tờ Lịch Xé)
                    blocCard(for: model)
                        .offset(x: dragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    dragOffset = value.translation.width * 0.4
                                }
                                .onEnded { value in
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        if value.translation.width < -60 {
                                            onNextDay()
                                        } else if value.translation.width > 60 {
                                            onPreviousDay()
                                        }
                                        dragOffset = 0
                                    }
                                }
                        )

                    // Cultural Quote / Ca Dao Tục Ngữ Card
                    quoteCard(for: model)

                    // Auspicious Details & Directions Card
                    astrologyDetailsCard(for: model)

                    // Quick Day Navigation Toolbar
                    quickNavToolbar
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                }
            }
            .padding(.horizontal, VNSpacing.xl)
            .padding(.vertical, VNSpacing.xs)
        }
    }

    // MARK: - Bloc Calendar Card (Tờ Lịch Xé Truyền Thống)

    private func blocCard(for model: VNCalendarDayModel) -> some View {
        VStack(spacing: 0) {
            blocHeaderClamp

            VStack(spacing: VNSpacing.sm) {
                blocSolarSection(for: model)

                Rectangle()
                    .fill(Color.vnBorderSubtle)
                    .frame(height: VNBorderWidth.hairline)
                    .padding(.horizontal, VNSpacing.lg)
                    .padding(.vertical, VNSpacing.xs)

                blocLunarSection(for: model)
                blocAuspiciousPills(for: model)
                    .padding(.bottom, VNSpacing.sm)
            }
            .padding(.horizontal, VNSpacing.xl)
            .background(Color.vnBackgroundSecondary)
        }
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.card)
                .stroke(Color.vnBorderSubtle, lineWidth: VNBorderWidth.regular)
        )
        .shadow(color: VNShadow.folio.color, radius: VNShadow.folio.radius,
                x: VNShadow.folio.x, y: VNShadow.folio.y)
        .contentShape(Rectangle())
        .onTapGesture {
            onTapDetails()
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Xem chi tiết ngày")
        .accessibilityAction(named: "Xem chi tiết") { onTapDetails() }
    }

    private var blocHeaderClamp: some View {
        HStack {
            Circle()
                .fill(Color.vnImperialChrysanthemumGold)
                .frame(width: VNSpacing.sm, height: VNSpacing.sm)
                .shadow(color: .black.opacity(0.3), radius: 1)

            Spacer()

            Text("LỊCH VẠN NIÊN")
                .font(.system(size: 11, weight: .bold, design: .serif))
                .foregroundColor(.vnRicePaperWhite)
                .tracking(2.0)

            Spacer()

            Circle()
                .fill(Color.vnImperialChrysanthemumGold)
                .frame(width: VNSpacing.sm, height: VNSpacing.sm)
                .shadow(color: .black.opacity(0.3), radius: 1)
        }
        .padding(.horizontal, VNSpacing.lg)
        .padding(.vertical, VNSpacing.sm)
        .background(Color.vnAccentHeritageRed)
    }

    private func blocSolarSection(for model: VNCalendarDayModel) -> some View {
        VStack(spacing: VNSpacing.space2) {
            Text(model.weekdayName.uppercased())
                .font(.system(size: 16, weight: .bold, design: .serif))
                .foregroundColor(isWeekend(model.weekdayName) ? .vnAccentHeritageRed : .vnTextSecondary)
                .tracking(1.2)
                .padding(.top, VNSpacing.sm)

            Text("\(model.solarDay)")
                .font(.vnHeroNumeral)
                .foregroundColor(isWeekend(model.weekdayName) ? .vnAccentHeritageRed : .vnTextPrimary)
                .frame(height: 76)

            Text("Tháng \(model.solarMonth) năm \(String(model.solarYear))")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.vnTextSecondary)
        }
    }

    private func blocLunarSection(for model: VNCalendarDayModel) -> some View {
        VStack(spacing: VNSpacing.xs) {
            HStack(spacing: VNSpacing.sm) {
                Text(lunarDayDisplay(for: model))
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundColor(.vnAccentHeritageRed)

                if model.isFirstDayOfLunarMonth {
                    VNSealBadge.mungMot(size: .medium)
                } else if model.isFullMoonDay {
                    VNSealBadge.ram(size: .medium)
                } else if model.hasAncestorDeathAnniversary {
                    VNSealBadge.gio(size: .medium)
                }
            }

            Text("Tháng \(model.lunarMonthName) • Năm \(model.lunarYearCanChi)")
                .font(.system(size: 14, weight: .semibold, design: .serif))
                .foregroundColor(.vnTextPrimary)

            Text("Ngày \(model.lunarDayCanChi) • Tháng \(model.lunarMonthCanChi)")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.vnTextSecondary)
        }
    }

    private func blocAuspiciousPills(for model: VNCalendarDayModel) -> some View {
        HStack(spacing: VNSpacing.xs) {
            if let term = model.solarTermName {
                Text("Tiết \(term)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.vnAccentImperialGold)
                    .padding(.horizontal, VNSpacing.sm)
                    .padding(.vertical, VNSpacing.xs)
                    .background(Color.vnAccentImperialGold.opacity(0.12))
                    .clipShape(Capsule())
            }

            Text(model.zodiacStar.fullTitle)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(model.isAuspiciousDay ? .vnStatusSuccess : .vnTextSecondary)
                .padding(.horizontal, VNSpacing.sm)
                .padding(.vertical, VNSpacing.xs)
                .background(model.isAuspiciousDay ? Color.vnStatusSuccess.opacity(0.12) : Color.vnBackgroundSecondary)
                .clipShape(Capsule())

            Text(model.lunarOfficer.title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.vnAccentHeritageRed)
                .padding(.horizontal, VNSpacing.sm)
                .padding(.vertical, VNSpacing.xs)
                .background(Color.vnAccentHeritageRed.opacity(0.1))
                .clipShape(Capsule())
        }
    }

    // MARK: - Ca Dao / Tục Ngữ Card

    private func quoteCard(for model: VNCalendarDayModel) -> some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            HStack {
                Image(systemName: "quote.opening")
                    .font(.system(size: 12))
                    .foregroundColor(.vnAccentHeritageRed)

                Text("CA DAO • TỤC NGỮ TRUYỀN THỐNG")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.vnTextSecondary)
                    .tracking(0.6)

                Spacer()
            }

            Text(model.folkQuote.quote)
                .font(.system(size: 14, weight: .medium, design: .serif).italic())
                .foregroundColor(.vnTextPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Spacer()
                Text("— \(model.folkQuote.authorOrOrigin)")
                    .font(.system(size: 11, weight: .regular, design: .serif))
                    .foregroundColor(.vnTextSecondary)
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

    // MARK: - Astrology & Directions Card

    private func astrologyDetailsCard(for model: VNCalendarDayModel) -> some View {
        VStack(alignment: .leading, spacing: VNSpacing.sm) {
            directionsRow(for: model)

            Divider()
                .background(Color.vnBorderSubtle.opacity(0.6))

            auspiciousHoursSection(for: model)

            if !model.suitableActivities.isEmpty || !model.tabooActivities.isEmpty {
                Divider()
                    .background(Color.vnBorderSubtle.opacity(0.6))
                suitableTabooSummary(for: model)
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

    private func directionsRow(for model: VNCalendarDayModel) -> some View {
        HStack(spacing: VNSpacing.md) {
            VStack(alignment: .leading, spacing: VNSpacing.space2) {
                Text("HỶ THẦN")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.vnTextSecondary)
                Text(model.joyGodDirection)
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .foregroundColor(.vnAccentHeritageRed)
            }

            Divider()
                .frame(height: VNSpacing.xxl)

            VStack(alignment: .leading, spacing: VNSpacing.space2) {
                Text("TÀI THẦN")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.vnTextSecondary)
                Text(model.wealthGodDirection)
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .foregroundColor(.vnAccentImperialGold)
            }

            Spacer()

            Button(action: onTapDetails) {
                HStack(spacing: VNSpacing.xs) {
                    Text("Chi tiết")
                        .font(.system(size: 12, weight: .medium))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(.vnAccentHeritageRed)
            }
            .buttonStyle(.plain)
        }
    }

    private func auspiciousHoursSection(for model: VNCalendarDayModel) -> some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            Text("GIỜ HOÀNG ĐẠO")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.vnTextSecondary)
                .tracking(0.5)

            Text(auspiciousHoursText(for: model))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.vnTextPrimary)
                .lineSpacing(2)
        }
    }

    private func suitableTabooSummary(for model: VNCalendarDayModel) -> some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            if !model.suitableActivities.isEmpty {
                HStack(alignment: .top, spacing: VNSpacing.xs) {
                    Text("Nên:")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.vnStatusSuccess)
                    Text(model.suitableActivities.prefix(3).joined(separator: ", "))
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.vnTextPrimary)
                }
            }

            if !model.tabooActivities.isEmpty {
                HStack(alignment: .top, spacing: VNSpacing.xs) {
                    Text("Kiêng:")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.vnStatusError)
                    Text(model.tabooActivities.prefix(3).joined(separator: ", "))
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.vnTextSecondary)
                }
            }
        }
    }

    // MARK: - Quick Navigation Toolbar

    private var quickNavToolbar: some View {
        HStack(spacing: VNSpacing.md) {
            Button(action: onPreviousDay) {
                Label("Ngày Trước", systemImage: "chevron.left")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.vnTextPrimary)
                    .padding(.horizontal, VNSpacing.md)
                    .padding(.vertical, VNSpacing.sm)
                    .background(Color.vnBackgroundSecondary)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.vnBorderSubtle, lineWidth: VNBorderWidth.hairline))
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .buttonStyle(.plain)
            .accessibilityLabel("Ngày trước")

            Spacer()

            Button(action: onSelectToday) {
                Text("Hôm Nay")
                    .font(.system(size: 12, weight: .semibold, design: .serif))
                    .foregroundColor(.vnAccentHeritageRed)
                    .padding(.horizontal, VNSpacing.lg)
                    .padding(.vertical, VNSpacing.sm)
                    .background(Color.vnAccentHeritageRed.opacity(0.1))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.vnAccentHeritageRed.opacity(0.3), lineWidth: VNBorderWidth.hairline))
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .buttonStyle(.plain)
            .accessibilityLabel("Hôm nay")

            Spacer()

            Button(action: onNextDay) {
                HStack(spacing: VNSpacing.xs) {
                    Text("Ngày Sau")
                    Image(systemName: "chevron.right")
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.vnTextPrimary)
                .padding(.horizontal, VNSpacing.md)
                .padding(.vertical, VNSpacing.sm)
                .background(Color.vnBackgroundSecondary)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.vnBorderSubtle, lineWidth: VNBorderWidth.hairline))
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .buttonStyle(.plain)
            .accessibilityLabel("Ngày sau")
        }
        .padding(.vertical, VNSpacing.xs)
    }

    // MARK: - Helpers

    private func isWeekend(_ weekdayName: String) -> Bool {
        weekdayName == "Chủ Nhật" || weekdayName == "Thứ Bảy"
    }

    private func lunarDayDisplay(for model: VNCalendarDayModel) -> String {
        if model.isFirstDayOfLunarMonth {
            return "MÙNG 1"
        }
        if model.isFullMoonDay {
            return "RẰM 15"
        }
        return "NGÀY \(model.lunarDay)"
    }

    private func auspiciousHoursText(for model: VNCalendarDayModel) -> String {
        model.auspiciousHours.map { "\($0.vietnameseName) (\($0.timeRange))" }.joined(separator: ", ")
    }
}
