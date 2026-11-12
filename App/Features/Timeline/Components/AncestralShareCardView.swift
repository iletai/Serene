import SwiftUI
import VNCalendarDesignSystem
import VNCalendarDomain
import VNCalendarLunar

public struct AncestralShareCardView: View {
    public let reminder: ReminderEvent
    @Environment(\.dismiss) private var dismiss
    @State private var renderedImage: Image?
    @State private var isShowingShareSheet = false

    public init(reminder: ReminderEvent) {
        self.reminder = reminder
    }

    private var nextDateString: String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = VNTime.vietnam
        let today = cal.startOfDay(for: Date())
        let solarNow = SolarDate(from: today, calendar: cal)

        let nextDate: Date
        if reminder.dateType == .lunar {
            let engine = LunarAstronomicalEngine.shared
            let currentLunar = engine.convertToLunar(from: solarNow)
            var targetLunarYear = currentLunar.year
            if currentLunar.month > reminder.month
                || (currentLunar.month == reminder.month && currentLunar.day > reminder.day) {
                targetLunarYear += 1
            }
            let targetLunar = LunarDate(
                day: reminder.day, month: reminder.month,
                year: targetLunarYear, isLeapMonth: reminder.isLeapMonth
            )
            nextDate = engine.convertToSolar(from: targetLunar).date ?? today
        } else {
            var comps = DateComponents(year: solarNow.year, month: reminder.month, day: reminder.day)
            var date = cal.date(from: comps) ?? today
            if date < today {
                comps.year = solarNow.year + 1
                date = cal.date(from: comps) ?? date
            }
            nextDate = date
        }

        let occ = SolarDate(from: nextDate, calendar: cal)
        return String(format: String(localized: "timeline.share_solar_date"), occ.day, occ.month, occ.year)
    }

    private var lunarDateString: String {
        String(format: String(localized: "timeline.share_lunar_date"), reminder.day, reminder.month)
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: VNSpacing.lg) {
                // The Visual Shareable Card Canvas
                shareCardCanvas
                    .padding(.horizontal, VNSpacing.screenMargin)
                    .padding(.top, VNSpacing.md)

                Spacer()

                // Actions: Share to Zalo / iMessage
                VStack(spacing: VNSpacing.sm) {
                    VNButton(
                        String(localized: "timeline.share_card_cta"),
                        icon: "square.and.arrow.up",
                        variant: .primary,
                        size: .large,
                        isFullWidth: true
                    ) {
                        shareInvitation()
                    }

                    Button("action.close") {
                        dismiss()
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.vnTextSecondary)
                    .frame(minHeight: VNSize.minTapTarget)
                    .contentShape(Rectangle())
                }
                .padding(.horizontal, VNSpacing.screenMargin)
                .padding(.bottom, VNSpacing.xl)
            }
            .background(Color.vnBackgroundPrimary.ignoresSafeArea())
            .vnNavBar(title: String(localized: "timeline.share_view_title"))
        }
    }

    // MARK: - Share Card Canvas (Thiệp Báo Giỗ)

    private var shareCardCanvas: some View {
        VStack(spacing: VNSpacing.md) {
            // Top Ceremonial Ribbon
            HStack {
                Spacer()
                VNSealBadge(
                    text: reminder.category == .deathAnniversary ? String(localized: "timeline.seal_death_anniversary") : String(localized: "timeline.seal_filial_piety"),
                    shape: .rounded(),
                    color: .cinnabarGold,
                    size: .medium
                )
                Spacer()
            }
            .padding(.top, VNSpacing.sm)

            // Header Title
            VStack(spacing: VNSpacing.xs) {
                Text("timeline.share_card_title")
                    .font(.vnDisplay(.footnote, weight: .bold))
                    .foregroundColor(.vnAccentHeritageRed)
                    .tracking(2.0)

                Text("timeline.share_card_subtitle")
                    .font(.vnDisplay(.caption2, weight: .medium, italic: true))
                    .foregroundColor(.vnTextSecondary)
            }

            Rectangle()
                .fill(Color.vnBorderSubtle)
                .frame(height: VNBorderWidth.hairline)
                .padding(.horizontal, VNSpacing.md)

            // Member Info
            VStack(spacing: VNSpacing.xs) {
                if let rel = reminder.relationship, !rel.isEmpty {
                    Text(rel.uppercased())
                        .font(.caption.weight(.bold))
                        .foregroundColor(.vnAccentGoldText)
                        .padding(.horizontal, VNSpacing.sm)
                        .padding(.vertical, VNSpacing.space2)
                        .background(Color.vnAccentGoldSurface)
                        .clipShape(Capsule())
                }

                Text(reminder.title)
                    .font(.vnDisplay(.title2, weight: .bold))
                    .foregroundColor(.vnTextPrimary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, VNSpacing.xs)

            // Date Cluster Box
            VStack(spacing: VNSpacing.sm) {
                HStack(spacing: VNSpacing.md) {
                    VStack(alignment: .leading, spacing: VNSpacing.space2) {
                        Text("timeline.share_lunar_label")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.vnTextSecondary)
                        Text(lunarDateString)
                            .font(.vnDisplay(.subheadline, weight: .bold))
                            .foregroundColor(.vnAccentHeritageRed)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: VNSpacing.space2) {
                        Text("timeline.share_solar_label")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.vnTextSecondary)
                        Text(nextDateString)
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(.vnTextPrimary)
                    }
                }
                .padding(VNSpacing.md)
                .background(Color.vnBackgroundPrimary)
                .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: VNCornerRadius.card)
                        .strokeBorder(Color.vnBorderSubtle, lineWidth: VNBorderWidth.hairline)
                )
            }
            .padding(.horizontal, VNSpacing.sm)

            if let note = reminder.note, !note.isEmpty {
                Text(String(format: String(localized: "timeline.share_note_format"), note))
                    .font(.vnDisplay(.caption, weight: .medium))
                    .foregroundColor(.vnTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, VNSpacing.md)
            }

            // Footer Stamp
            HStack {
                Text("timeline.share_footer")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.vnTextTertiary)
                    .tracking(1.0)

                Spacer()

                VNSealBadge(text: "AN NIÊN", shape: .square, color: .cinnabarWhite, size: .small)
            }
            .padding(.horizontal, VNSpacing.md)
            .padding(.top, VNSpacing.xs)
            .padding(.bottom, VNSpacing.sm)
        }
        .padding(VNSpacing.xl)
        .background(Color.vnBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.card)
                .strokeBorder(Color.vnAccentImperialGold.opacity(0.4), lineWidth: VNBorderWidth.active)
        )
        .shadow(color: VNShadow.card.color, radius: VNShadow.card.radius, x: VNShadow.card.x, y: VNShadow.card.y)
    }

    private func shareInvitation() {
        let noteLine = reminder.note.map { String(format: String(localized: "timeline.share_note_line"), $0) } ?? ""
        let text = String(format: String(localized: "timeline.share_message"), reminder.title, reminder.relationship ?? String(localized: "timeline.share_default_relationship"), lunarDateString, nextDateString, noteLine)

        #if canImport(UIKit)
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
        #endif
    }
}
