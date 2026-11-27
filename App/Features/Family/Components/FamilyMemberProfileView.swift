import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem
import VNCalendarLunar

/// Person profile sheet (prototype `.psheet` / `.pp-*`). Only fields a reminder actually stores are shown.
struct FamilyMemberProfileView: View {
    let member: ReminderEvent
    let info: FamilyMemberInfo
    let memorialOrdinal: Int?
    /// Opens the reminder form for this member; the caller closes the sheet first.
    let onOpenReminder: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: VNSpacing.lg) {
            hero
            ScrollView {
                VStack(alignment: .leading, spacing: VNSpacing.md + 2) {
                    dateCard
                    if let note = member.note, !note.isEmpty {
                        Text(note)
                            .font(.vnQuote)
                            .foregroundColor(.vnTextPrimary)
                            .padding(.horizontal, VNSpacing.md + 2)
                            .padding(.vertical, VNSpacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.vnAccentGoldSurface, in: RoundedRectangle(cornerRadius: VNCornerRadius.small))
                    }
                    openButton
                }
                .padding(.horizontal, VNSpacing.screenMargin)
                .padding(.bottom, VNSpacing.xxl)
            }
        }
        .padding(.top, VNSpacing.lg)
        .background(Color.vnBackgroundPrimary.ignoresSafeArea())
    }

    // MARK: - Hero

    private var hero: some View {
        HStack(spacing: VNSpacing.lg) {
            Text(FamilyMemberInfo.initial(of: member.title))
                .font(.vnDisplay(.title, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 64, height: 64)
                .background(Color.vnAccentSky, in: Circle())
                .overlay(
                    Circle().strokeBorder(
                        info.isWorshipped ? Color.vnAccentImperialGold.opacity(0.7) : Color.vnOnNight.opacity(0.2),
                        lineWidth: 3
                    )
                )
                .saturation(info.isWorshipped ? 0.65 : 1)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: VNSpacing.space2) {
                if let relationship = member.relationship, !relationship.isEmpty {
                    Text(relationship.uppercased())
                        .font(.vnDisplay(.caption, weight: .bold))
                        .tracking(0.9)
                        .foregroundColor(.vnAccentImperialGold)
                }
                Text(member.title)
                    .font(.vnDisplay(.title2, weight: .bold))
                    .foregroundColor(.vnOnNight)
                    .accessibilityAddTraits(.isHeader)
                if let years = yearLine {
                    Text(years)
                        .font(.vnDisplay(.footnote, weight: .medium))
                        .foregroundColor(.vnOnNight.opacity(0.82))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, VNSpacing.lg)
        .padding(.trailing, 48)
        .padding(.vertical, VNSpacing.lg)
        .background(alignment: .topTrailing) { motif }
        .background(
            LinearGradient(colors: [.vnNight, .vnNight.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(alignment: .topTrailing) { closeButton }
        .shadow(color: VNShadow.card.color, radius: VNShadow.card.radius, y: VNShadow.card.y)
        .padding(.horizontal, VNSpacing.md)
    }

    /// Prototype `.pp-motif`: a bronze-drum sun turning slowly behind the hero.
    private var motif: some View {
        Image(systemName: "sun.max")
            .font(.system(size: 120, weight: .ultraLight))
            .foregroundColor(.vnAccentImperialGold.opacity(0.3))
            .vnSpinSlow(duration: VNMotion.Loop.drumTurn)
            .offset(x: 40, y: -40)
            .accessibilityHidden(true)
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.footnote.weight(.bold))
                .foregroundColor(.vnOnNight)
                .frame(width: 32, height: 32)
                .background(Color.vnOnNight.opacity(0.18), in: Circle())
                .frame(width: VNSize.minTapTarget, height: VNSize.minTapTarget)
        }
        .buttonStyle(.vnPress)
        .padding(VNSpacing.space2)
        .accessibilityLabel("family.profile.close")
    }

    private var yearLine: String? {
        guard let year = FamilyMemberInfo.yearText(member), let base = member.year else { return nil }
        return "\(year) · \(CanChiPair.year(for: base))"
    }

    // MARK: - Date card

    private var dateCard: some View {
        HStack(spacing: VNSpacing.md + 2) {
            if member.dateType == .lunar {
                VNMoonPhaseView(lunarDay: member.day, size: 44)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(keyLine.uppercased())
                    .font(.vnDisplay(.caption, weight: .bold))
                    .tracking(0.7)
                    .foregroundColor(.vnTextSecondary)
                Text(valueLine)
                    .font(.vnDisplay(.body, weight: .semibold))
                    .foregroundColor(.vnTextPrimary)
                if let ordinal = ordinalLine {
                    Text(ordinal)
                        .font(.vnDisplay(.footnote))
                        .foregroundColor(.vnAccentGoldText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(VNSpacing.lg)
        .background(Color.vnBackgroundSecondary, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.vnBorderSubtle, lineWidth: VNBorderWidth.hairline))
        .shadow(color: VNShadow.card.color, radius: VNShadow.card.radius, y: VNShadow.card.y)
        .accessibilityElement(children: .combine)
    }

    private var keyLine: String {
        let suffix = member.dateType == .lunar ? String(localized: "family.abbrev_lunar") : String(localized: "family.abbrev_solar")
        let format = info.isWorshipped
            ? String(localized: "family.profile.memorial_key")
            : String(localized: "family.profile.date_key")
        return String(format: format, member.day, member.month, suffix)
    }

    private var valueLine: String {
        let date = info.nextDate.formatted(Date.FormatStyle(date: .complete, time: .omitted, timeZone: VNTime.vietnam))
        return "\(date) · \(info.countdownText)"
    }

    private var ordinalLine: String? {
        guard let ordinal = memorialOrdinal else { return nil }
        return ordinal == 1
            ? String(localized: "family.profile.first_memorial")
            : String(format: String(localized: "family.profile.nth_memorial"), ordinal)
    }

    // MARK: - Action

    private var openButton: some View {
        Button(action: onOpenReminder) {
            Label(
                LocalizedStringKey(info.isWorshipped ? "family.profile.open_memorial" : "family.profile.edit"),
                systemImage: info.isWorshipped ? "bell.fill" : "pencil"
            )
            .font(.vnDisplay(.callout, weight: .semibold))
            .foregroundColor(info.isWorshipped ? .vnNight : .vnTextPrimary)
            .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
            .padding(.horizontal, VNSpacing.md + 2)
            .background(
                info.isWorshipped ? Color.vnAccentImperialGold : Color.vnBackgroundSecondary,
                in: RoundedRectangle(cornerRadius: VNCornerRadius.small + 2)
            )
        }
        .buttonStyle(.vnPress)
    }
}
