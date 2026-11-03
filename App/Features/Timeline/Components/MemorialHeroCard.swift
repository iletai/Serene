import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem

struct MemorialHeroCard: View {
    let reminder: ReminderEvent
    let dateText: String
    let countdownText: String
    let onQuickRitual: () -> Void
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top Ribbon & Status Row
            HStack(alignment: .center) {
                HStack(spacing: VNSpacing.xs) {
                    VNSealBadge.gio(size: .medium)

                    Text(reminder.relationship ?? "Gia Tiên")
                        .font(.caption2.weight(.bold))
                        .tracking(0.8)
                        .foregroundColor(.vnAccentHeritageRed)
                        .padding(.horizontal, VNSpacing.sm)
                        .padding(.vertical, VNSpacing.xs)
                        .background(Color.vnAccentRedSurface)
                        .clipShape(Capsule())
                }

                Spacer()

                // Countdown Badge
                Text(countdownText)
                    .font(.caption.weight(.bold))
                    .foregroundColor(.vnOnAccent)
                    .padding(.horizontal, VNSpacing.sm)
                    .padding(.vertical, VNSpacing.xs)
                    .background(Color.vnAccentHeritageRed)
                    .clipShape(Capsule())
                    .shadow(color: VNShadow.floating.color, radius: VNShadow.floating.radius,
                            x: VNShadow.floating.x, y: VNShadow.floating.y)
            }
            .padding(.horizontal, VNSpacing.cardPadding)
            .padding(.top, VNSpacing.md)

            // Memorial Title (New York Serif, title2 bold)
            Text(reminder.title)
                .font(.system(.title2, design: .serif).weight(.bold))
                .foregroundColor(.vnTextPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, VNSpacing.cardPadding)
                .padding(.top, VNSpacing.xs)

            // Date & Info Strip
            VStack(alignment: .leading, spacing: VNSpacing.xs) {
                HStack(spacing: VNSpacing.xs) {
                    Image(systemName: "calendar")
                        .font(.footnote)
                        .foregroundColor(.vnAccentHeritageRed)
                        .accessibilityHidden(true)
                    Text(dateText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.vnAccentHeritageRed)
                }

                if let note = reminder.note, !note.isEmpty {
                    HStack(alignment: .top, spacing: VNSpacing.xs) {
                        Image(systemName: "pencil.and.list.clipboard")
                            .font(.caption)
                            .foregroundColor(.vnTextSecondary)
                            .accessibilityHidden(true)
                        Text(note)
                            .font(.system(.caption, design: .serif))
                            .italic()
                            .foregroundColor(.vnTextSecondary)
                            .lineLimit(2)
                    }
                }
            }
            .padding(VNSpacing.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.vnBackgroundPrimary)
            .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: VNCornerRadius.card)
                    .stroke(Color.vnBorderSubtle.opacity(0.8), lineWidth: VNBorderWidth.regular)
            )
            .padding(.horizontal, VNSpacing.cardPadding)
            .padding(.top, VNSpacing.sm)

            // Bottom Actions
            HStack(spacing: VNSpacing.sm) {
                VNButton("Xem Văn Khấn", icon: "book.pages.fill", variant: .primary, size: .small, isFullWidth: true, action: onQuickRitual)
                VNButton("Chi Tiết", icon: "slider.horizontal.3", variant: .secondary, size: .small, isFullWidth: true, action: onEdit)
            }
            .padding(VNSpacing.cardPadding)
        }
        .background(Color.vnBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.card)
                .stroke(Color.vnAccentImperialGold.opacity(0.28), lineWidth: VNBorderWidth.hairline)
        )
        .shadow(color: VNShadow.folio.color, radius: VNShadow.folio.radius,
                x: VNShadow.folio.x, y: VNShadow.folio.y)
    }
}
