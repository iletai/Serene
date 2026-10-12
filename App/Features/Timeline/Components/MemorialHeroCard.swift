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
                        .font(.system(size: 11, weight: .bold))
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
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, VNSpacing.sm)
                    .padding(.vertical, VNSpacing.xs)
                    .background(Color.vnAccentHeritageRed)
                    .clipShape(Capsule())
                    .shadow(color: VNShadow.floating.color, radius: VNShadow.floating.radius,
                            x: VNShadow.floating.x, y: VNShadow.floating.y)
            }
            .padding(.horizontal, VNSpacing.xl)
            .padding(.top, VNSpacing.md)

            // Memorial Title (New York Serif 22pt bold)
            Text(reminder.title)
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundColor(.vnTextPrimary)
                .padding(.horizontal, VNSpacing.xl)
                .padding(.top, VNSpacing.xs)

            // Date & Info Strip
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 13))
                        .foregroundColor(.vnAccentHeritageRed)
                    Text(dateText)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.vnAccentHeritageRed)
                }

                if let note = reminder.note, !note.isEmpty {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "pencil.and.list.clipboard")
                            .font(.system(size: 12))
                            .foregroundColor(.vnTextSecondary)
                        Text(note)
                            .font(.system(size: 12, design: .serif))
                            .italic()
                            .foregroundColor(.vnTextSecondary)
                            .lineLimit(2)
                    }
                }
            }
            .padding(VNSpacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.vnBackgroundPrimary)
            .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: VNCornerRadius.card)
                    .stroke(Color.vnBorderSubtle.opacity(0.8), lineWidth: VNBorderWidth.regular)
            )
            .padding(.horizontal, VNSpacing.xl)
            .padding(.top, VNSpacing.sm)

            // Bottom Actions
            HStack(spacing: VNSpacing.sm) {
                Button(action: onQuickRitual) {
                    HStack(spacing: 5) {
                        Image(systemName: "book.pages.fill")
                            .font(.system(size: 12))
                        Text("Xem Văn Khấn")
                            .font(.system(size: 13, weight: .bold, design: .serif))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .background(Color.vnAccentHeritageRed)
                    .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.small))
                }
                .buttonStyle(.plain)

                Button(action: onEdit) {
                    HStack(spacing: 5) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 12))
                        Text("Chi Tiết")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.vnTextPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .background(Color.vnBackgroundPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.small))
                    .overlay(
                        RoundedRectangle(cornerRadius: VNCornerRadius.small)
                            .stroke(Color.vnBorderSubtle, lineWidth: VNBorderWidth.regular)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(VNSpacing.xl)
        }
        .background(Color.vnBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.card)
                .stroke(Color.vnAccentHeritageRed.opacity(0.4), lineWidth: VNBorderWidth.regular)
        )
        .shadow(color: VNShadow.floating.color, radius: VNShadow.floating.radius,
                x: VNShadow.floating.x, y: VNShadow.floating.y)
    }
}
