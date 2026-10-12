import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem

struct MemorialTimelineCard: View {
    let reminder: ReminderEvent
    let dateText: String
    let countdownText: String
    let onViewRitual: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var isPassed: Bool { countdownText.hasPrefix("Đã qua") }
    private var isToday: Bool { countdownText == "Hôm nay" }
    private var isMemorial: Bool {
        reminder.category == .deathAnniversary || reminder.category == .ancestral
    }

    private var tileBackground: Color {
        if isPassed { return .vnBackgroundTertiary }
        switch reminder.category {
        case .deathAnniversary, .ancestral: return .vnAccentRedSurface
        case .worship: return .vnGoldContainer
        default: return .vnBackgroundTertiary
        }
    }

    private var tileForeground: Color {
        if isPassed { return .vnTextSecondary }
        switch reminder.category {
        case .deathAnniversary, .ancestral: return .vnAccentHeritageRed
        case .worship: return .vnOnGoldContainer
        default: return .vnTextSecondary
        }
    }

    private var tileIcon: String {
        switch reminder.category {
        case .deathAnniversary, .ancestral: return "flame.fill"
        case .worship: return "sparkles"
        default: return "calendar"
        }
    }

    private var pillBackground: Color {
        if isPassed { return .vnBackgroundTertiary }
        if isToday { return .vnGoldContainer }
        return .vnAccentDeepPrimary
    }

    private var pillForeground: Color {
        if isPassed { return .vnTextSecondary }
        if isToday { return .vnOnGoldContainer }
        return .white
    }

    var body: some View {
        HStack(alignment: .top, spacing: VNSpacing.md) {
            iconTile
            contentColumn
            if !isMemorial { trailingChevron }
        }
        .padding(VNSpacing.xl)
        .background(Color.vnBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.card)
                .stroke(Color.vnAccentImperialGold.opacity(0.28), lineWidth: VNBorderWidth.hairline)
        )
        .shadow(color: VNShadow.folio.color, radius: VNShadow.folio.radius, x: VNShadow.folio.x, y: VNShadow.folio.y)
        .opacity(isPassed ? 0.8 : 1)
        .contentShape(Rectangle())
        .onTapGesture { onEdit() }
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Chỉnh sửa") { onEdit() }
        .contextMenu { cardMenu }
    }

    private var iconTile: some View {
        Image(systemName: tileIcon)
            .font(.system(size: 20))
            .foregroundColor(tileForeground)
            .frame(width: 40, height: 40)
            .background(tileBackground)
            .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
    }

    private var contentColumn: some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            titleRow
            if let role = reminder.relationship, !role.isEmpty {
                Text(role.uppercased())
                    .font(.vnCaption2)
                    .fontWeight(.bold)
                    .tracking(0.6)
                    .foregroundColor(.vnAccentHeritageRed)
                    .padding(.horizontal, VNSpacing.xs)
                    .padding(.vertical, VNSpacing.space2)
                    .background(Color.vnAccentRedSurface)
                    .clipShape(Capsule())
            }
            dateRow
            if let note = reminder.note, !note.isEmpty { noteRow(note) }
            if isMemorial { ritualButton }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var titleRow: some View {
        HStack(spacing: VNSpacing.sm) {
            Text(reminder.title)
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .foregroundColor(.vnTextPrimary)
                .lineLimit(2)
            Spacer(minLength: 4)
            Text(countdownText)
                .font(.vnCaption2)
                .fontWeight(.semibold)
                .foregroundColor(pillForeground)
                .padding(.horizontal, VNSpacing.sm)
                .padding(.vertical, VNSpacing.xs)
                .background(pillBackground)
                .clipShape(Capsule())
        }
    }

    private var dateRow: some View {
        HStack(spacing: VNSpacing.xs) {
            Image(systemName: "calendar").font(.system(size: 11)).accessibilityHidden(true)
            Text(dateText).font(.system(size: 12, weight: .medium)).monospacedDigit()
        }
        .foregroundColor(.vnTextSecondary)
    }

    private func noteRow(_ note: String) -> some View {
        Text(note)
            .font(.system(size: 12, design: .serif))
            .italic()
            .foregroundColor(.vnTextSecondary)
            .lineLimit(1)
    }

    private var ritualButton: some View {
        Button(action: onViewRitual) {
            HStack(spacing: VNSpacing.xs) {
                Image(systemName: "book.pages").font(.system(size: 11)).accessibilityHidden(true)
                Text("Xem Văn Khấn").font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.vnAccentHeritageRed)
            .frame(minHeight: 44)
            .padding(.horizontal, VNSpacing.sm)
            .contentShape(Rectangle())
            .background(Color.vnBackgroundPrimary)
            .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.small))
            .overlay(
                RoundedRectangle(cornerRadius: VNCornerRadius.small)
                    .stroke(Color.vnAccentHeritageRed.opacity(0.3), lineWidth: VNBorderWidth.regular)
            )
        }
        .buttonStyle(.plain)
    }

    private var trailingChevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.vnTextTertiary)
            .padding(.top, VNSpacing.space2)
            .accessibilityHidden(true)
    }

    private var cardMenu: some View {
        Group {
            Button(action: onEdit) { Label("Chỉnh sửa", systemImage: "pencil") }
            if isMemorial {
                Button(action: onViewRitual) { Label("Xem Văn Khấn", systemImage: "book.pages") }
            }
            Divider()
            Button(role: .destructive, action: onDelete) { Label("Xóa ngày nhớ", systemImage: "trash") }
        }
    }

}
