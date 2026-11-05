import SwiftUI
import VNCalendarDesignSystem

/// Traditional memorial prayer text, presented via `AppSheet.ritual(title:)`.
struct RitualPrayerModal: View {
    @Environment(AppRouter.self) private var router
    let title: String

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: VNSpacing.lg) {
                    VStack(alignment: .leading, spacing: VNSpacing.xs) {
                        HStack(spacing: VNSpacing.xs) {
                            VNSealBadge.gio(size: .medium)

                            Text("timeline.prayer_modal_eyebrow")
                                .font(.caption2.weight(.bold))
                                .tracking(1.0)
                                .foregroundColor(.vnAccentHeritageRed)
                        }

                        Text(title)
                            .font(.system(.title2, design: .serif).weight(.bold))
                            .foregroundColor(.vnTextPrimary)

                        Text("timeline.prayer_modal_subtitle")
                            .font(.system(.footnote, design: .serif))
                            .italic()
                            .foregroundColor(.vnTextSecondary)
                    }

                    VNRowDivider()

                    VStack(alignment: .leading, spacing: VNSpacing.md) {
                        Text(String(format: String(localized: "timeline.prayer_modal_body"), title))
                        .font(.system(.subheadline, design: .serif))
                        .foregroundColor(.vnTextPrimary)
                        .lineSpacing(VNSpacing.sm)
                        .padding(VNSpacing.lg)
                        .background(Color.vnBackgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
                        .overlay(
                            RoundedRectangle(cornerRadius: VNCornerRadius.card)
                                .stroke(Color.vnBorderSubtle, lineWidth: VNBorderWidth.hairline)
                        )
                    }
                }
                .padding(VNSpacing.lg)
            }
            .background(Color.vnBackgroundPrimary.ignoresSafeArea())
            .vnNavBar(title: String(localized: "timeline.prayer_modal_title")) {
                VNDismissButton(style: .text(String(localized: "action.close"))) { router.dismissModals() }
            }
        }
    }
}
