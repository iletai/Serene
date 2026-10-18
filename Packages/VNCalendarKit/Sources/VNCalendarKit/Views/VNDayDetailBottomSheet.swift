import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem

public struct VNDayDetailBottomSheet: View {
    public let dayModel: VNCalendarDayModel
    public var onAddReminder: () -> Void = {}
    @Environment(\.dismiss) private var dismiss

    public init(dayModel: VNCalendarDayModel, onAddReminder: @escaping () -> Void = {}) {
        self.dayModel = dayModel
        self.onAddReminder = onAddReminder
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: VNSpacing.md) {
                    headerDateCluster
                    VNDayEvaluationView(dayModel: dayModel)
                    VNDayDirectionsView(dayModel: dayModel)
                    auspiciousHoursSection
                    VNDayActivitiesView(dayModel: dayModel)
                    folkQuoteCard
                    familyEventsSection
                    actionButton
                }
                .padding(.horizontal, VNSpacing.xl)
                .padding(.vertical, VNSpacing.xl)
            }
            .background(Color.vnBackgroundPrimary)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.vnTextTertiary)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                    .accessibilityLabel("Đóng")
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.vnTextTertiary)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                    .accessibilityLabel("Đóng")
                }
                #endif
            }
        }
    }

    // MARK: - Header Date Cluster
    private var headerDateCluster: some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            Text(solarDateText)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.vnTextSecondary)

            HStack(spacing: VNSpacing.sm) {
                Text(lunarHeroText)
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundColor(.vnAccentHeritageRed)

                if dayModel.isFirstDayOfLunarMonth {
                    VNSealBadge.mungMot(size: .medium)
                } else if dayModel.isFullMoonDay {
                    VNSealBadge.ram(size: .medium)
                } else if dayModel.hasAncestorDeathAnniversary {
                    VNSealBadge.gio(size: .medium)
                }
            }

            Text("Năm \(dayModel.lunarYearCanChi) • Tháng \(dayModel.lunarMonthCanChi) • Ngày \(dayModel.lunarDayCanChi)")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.vnTextSecondary)

            culturalBadgesRow
                .padding(.top, VNSpacing.space2)
        }
        .padding(.top, VNSpacing.xs)
    }

    private var solarDateText: String {
        let yearString = String(dayModel.solarYear)
        return "\(dayModel.weekdayName), ngày \(dayModel.solarDay) tháng \(dayModel.solarMonth) năm \(yearString)"
    }

    private var lunarHeroText: String {
        if dayModel.isFirstDayOfLunarMonth {
            return "Mùng 1 \(dayModel.lunarMonthName)"
        }
        if dayModel.isFullMoonDay {
            return "Rằm 15 \(dayModel.lunarMonthName)"
        }
        return "Ngày \(dayModel.lunarDay) \(dayModel.lunarMonthName)"
    }

    private var culturalBadgesRow: some View {
        HStack(spacing: VNSpacing.xs) {
            if let term = dayModel.solarTermName {
                Text("Tiết \(term)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.vnAccentImperialGold)
                    .padding(.horizontal, VNSpacing.sm)
                    .padding(.vertical, VNSpacing.xs)
                    .background(Color.vnAccentImperialGold.opacity(0.15))
                    .clipShape(Capsule())
            }

            if dayModel.isToday {
                Text("Hôm nay")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.vnAccentHeritageRed)
                    .padding(.horizontal, VNSpacing.sm)
                    .padding(.vertical, VNSpacing.xs)
                    .background(Color.vnAccentHeritageRed.opacity(0.12))
                    .clipShape(Capsule())
            }

            if dayModel.isAuspiciousDay {
                Text("Hoàng Đạo")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.vnStatusSuccess)
                    .padding(.horizontal, VNSpacing.sm)
                    .padding(.vertical, VNSpacing.xs)
                    .background(Color.vnStatusSuccess.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Auspicious Hours Grid
    private var auspiciousHoursSection: some View {
        VStack(alignment: .leading, spacing: VNSpacing.sm) {
            Text("KHUNG GIỜ HOÀNG ĐẠO")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.vnTextSecondary)
                .tracking(0.5)

            let columns = [
                GridItem(.flexible(), spacing: VNSpacing.sm),
                GridItem(.flexible(), spacing: VNSpacing.sm),
                GridItem(.flexible(), spacing: VNSpacing.sm)
            ]

            LazyVGrid(columns: columns, spacing: VNSpacing.sm) {
                ForEach(dayModel.auspiciousHours, id: \.self) { branch in
                    HStack(spacing: VNSpacing.xs) {
                        Circle()
                            .fill(Color.vnAccentImperialGold)
                            .frame(width: VNSpacing.xs, height: VNSpacing.xs)

                        Text("\(branch.vietnameseName) (\(branch.timeRange))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.vnTextPrimary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, VNSpacing.sm)
                    .padding(.horizontal, VNSpacing.xs)
                    .background(Color.vnBackgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.small))
                    .overlay(
                        RoundedRectangle(cornerRadius: VNCornerRadius.small)
                            .stroke(Color.vnBorderSubtle.opacity(0.6), lineWidth: VNBorderWidth.hairline)
                    )
                }
            }
        }
    }

    // MARK: - Folk Quote Card
    private var folkQuoteCard: some View {
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

            Text(dayModel.folkQuote.quote)
                .font(.system(size: 13, weight: .medium, design: .serif).italic())
                .foregroundColor(.vnTextPrimary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Spacer()
                Text("— \(dayModel.folkQuote.authorOrOrigin)")
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

    // MARK: - Family Events
    private var familyEventsSection: some View {
        VStack(alignment: .leading, spacing: VNSpacing.sm) {
            Text("SỰ KIỆN & GIA ĐÌNH")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.vnTextSecondary)
                .tracking(0.5)

            if dayModel.anniversaries.isEmpty {
                HStack(spacing: VNSpacing.sm) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 16))
                        .foregroundColor(.vnTextTertiary)

                    Text("Không có sự kiện hoặc ngày giỗ nào cho ngày này.")
                        .font(.vnFootnote)
                        .foregroundColor(.vnTextSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(VNSpacing.md)
                .background(Color.vnBackgroundSecondary.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
            } else {
                VStack(spacing: VNSpacing.xs) {
                    ForEach(dayModel.anniversaries) { item in
                        HStack(spacing: 0) {
                            RoundedRectangle(cornerRadius: VNCornerRadius.micro)
                                .fill(item.isAncestorDeath ? Color.vnAccentHeritageRed : Color.vnAccentImperialGold)
                                .frame(width: 3)

                            VStack(alignment: .leading, spacing: VNSpacing.space2) {
                                Text(item.title)
                                    .font(.system(size: 14, weight: .semibold, design: .serif))
                                    .foregroundColor(.vnTextPrimary)

                                Text(item.isAncestorDeath ? "Kỳ Giỗ Gia Tiên" : "Sự Kiện Kỷ Niệm")
                                    .font(.vnCaption2)
                                    .foregroundColor(.vnTextSecondary)
                            }
                            .padding(.leading, VNSpacing.sm)
                            .padding(.vertical, VNSpacing.xs)

                            Spacer()

                            if item.isAncestorDeath {
                                VNSealBadge.gio(size: .small)
                            }
                        }
                        .padding(VNSpacing.xs)
                        .background(Color.vnBackgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
                    }
                }
            }
        }
    }

    // MARK: - Action Button
    private var actionButton: some View {
        Button(
            action: onAddReminder,
            label: {
                Label("Thêm Ngày Nhớ Cho Ngày Này", systemImage: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .background(Color.vnAccentHeritageRed)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        )
        .padding(.top, VNSpacing.xs)
    }
}
