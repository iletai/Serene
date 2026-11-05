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
                    VNDayEvaluationView(dayModel: dayModel).vnSheetSectionAppear(1)
                    VNDayDirectionsView(dayModel: dayModel).vnSheetSectionAppear(2)
                    auspiciousHoursSection.vnSheetSectionAppear(3)
                    VNDayActivitiesView(dayModel: dayModel).vnSheetSectionAppear(4)
                    folkQuoteCard.vnSheetSectionAppear(5)
                    familyEventsSection.vnSheetSectionAppear(6)
                    actionButton.vnSheetSectionAppear(7)
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
                    VNDismissButton { dismiss() }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    VNDismissButton { dismiss() }
                }
                #endif
            }
        }
    }

    // MARK: - Header Date Cluster
    private var headerDateCluster: some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            Text(solarDateText)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.vnTextSecondary)

            HStack(spacing: VNSpacing.sm) {
                Text(lunarHeroText)
                    .font(.system(.title, design: .serif).weight(.bold))
                    .foregroundColor(.vnAccentHeritageRed)

                if dayModel.isFirstDayOfLunarMonth {
                    VNSealBadge.mungMot(size: .medium)
                } else if dayModel.isFullMoonDay {
                    VNSealBadge.ram(size: .medium)
                } else if dayModel.hasAncestorDeathAnniversary {
                    VNSealBadge.gio(size: .medium)
                }
            }

            Text(String(format: String(localized: "daydetail.header.canchi_summary"), dayModel.lunarYearCanChi, dayModel.lunarMonthCanChi, dayModel.lunarDayCanChi))
                .font(.footnote)
                .foregroundColor(.vnTextSecondary)

            culturalBadgesRow
                .padding(.top, VNSpacing.space2)
        }
        .padding(.top, VNSpacing.xs)
    }

    private var solarDateText: String {
        let yearString = String(dayModel.solarYear)
        return String(format: String(localized: "daydetail.header.solar_full_date"), dayModel.weekdayName, dayModel.solarDay, dayModel.solarMonth, yearString)
    }

    private var lunarHeroText: String {
        if dayModel.isFirstDayOfLunarMonth {
            return String(format: String(localized: "daydetail.header.mung_mot"), dayModel.lunarMonthName)
        }
        if dayModel.isFullMoonDay {
            return String(format: String(localized: "daydetail.header.ram_15"), dayModel.lunarMonthName)
        }
        return String(format: String(localized: "daydetail.header.lunar_day"), dayModel.lunarDay, dayModel.lunarMonthName)
    }

    private var culturalBadgesRow: some View {
        HStack(spacing: VNSpacing.xs) {
            if let term = dayModel.solarTermName {
                Text(String(format: String(localized: "daydetail.badge.solar_term"), term))
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.vnAccentGoldText)
                    .padding(.horizontal, VNSpacing.sm)
                    .padding(.vertical, VNSpacing.xs)
                    .background(Color.vnAccentImperialGold.opacity(0.15))
                    .clipShape(Capsule())
            }

            if dayModel.isToday {
                Text("action.today")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.vnAccentHeritageRed)
                    .padding(.horizontal, VNSpacing.sm)
                    .padding(.vertical, VNSpacing.xs)
                    .background(Color.vnAccentHeritageRed.opacity(0.12))
                    .clipShape(Capsule())
            }

            if dayModel.isAuspiciousDay {
                Text("daydetail.badge.auspicious_day")
                    .font(.caption2.weight(.semibold))
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
            Text("daydetail.section.auspicious_hours")
                .font(.caption2.weight(.bold))
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
                            .font(.caption2.weight(.medium))
                            .foregroundColor(.vnTextPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
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
                    .font(.caption)
                    .accessibilityHidden(true)
                    .foregroundColor(.vnAccentHeritageRed)

                Text("daydetail.section.folk_quote")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.vnTextSecondary)
                    .tracking(0.6)

                Spacer()
            }

            Text(dayModel.folkQuote.quote)
                .font(.system(.footnote, design: .serif).weight(.medium).italic())
                .foregroundColor(.vnTextPrimary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Spacer()
                Text("— \(dayModel.folkQuote.authorOrOrigin)")
                    .font(.system(.caption2, design: .serif))
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
            Text("daydetail.section.family_events")
                .font(.caption2.weight(.bold))
                .foregroundColor(.vnTextSecondary)
                .tracking(0.5)

            if dayModel.anniversaries.isEmpty {
                HStack(spacing: VNSpacing.sm) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.callout)
                        .foregroundColor(.vnTextTertiary)
                        .accessibilityHidden(true)

                    Text("daydetail.family_events.empty")
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
                                    .font(.system(.subheadline, design: .serif).weight(.semibold))
                                    .foregroundColor(.vnTextPrimary)

                                Text(item.isAncestorDeath ? String(localized: "calendar.event.type.death_anniversary") : String(localized: "daydetail.event.type.anniversary"))
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
                Label("daydetail.action.add_anniversary", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: VNSize.minTapTarget)
                    .background(Color.vnAccentHeritageRed)
                    .foregroundColor(.vnOnAccent)
                    .clipShape(Capsule())
            }
        )
        .padding(.top, VNSpacing.xs)
    }
}
