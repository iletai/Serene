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
        // Spec: gold tint for seasonal / rite tiles
        case .worship: return .vnAccentGoldSurface
        default: return .vnBackgroundTertiary
        }
    }

    private var tileForeground: Color {
        if isPassed { return .vnTextSecondary }
        switch reminder.category {
        case .deathAnniversary, .ancestral: return .vnAccentHeritageRed
        case .worship: return .vnAccentGoldText
        default: return .vnTextSecondary
        }
    }

    // Spec: tile border matches tint (red / gold)
    private var tileBorder: Color {
        if isPassed || reminder.category == .other ||
            reminder.category == .birthday || reminder.category == .wedding {
            return .clear
        }
        return tileForeground.opacity(0.25)
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
        // Spec: "Còn N ngày" solid red, "Hôm nay" gold container
        if isToday { return .vnGoldContainer }
        return .vnAccentHeritageRed
    }

    private var pillForeground: Color {
        if isPassed { return .vnTextSecondary }
        if isToday { return .vnOnGoldContainer }
        return .vnOnAccent
    }

    var body: some View {
        // Nested ritual VNButton keeps its own tap; the card body opens the editor.
        Button(action: onEdit) {
            cardContent
        }
        .buttonStyle(VNCellPressButtonStyle(pressedScale: 0.98))
        .accessibilityElement(children: .combine)
        .accessibilityActions {
            if isMemorial { Button("action.view_prayer", action: onViewRitual) }
            Button("timeline.action_delete", role: .destructive, action: onDelete)
        }
        .contextMenu { cardMenu }
    }

    private var cardContent: some View {
        HStack(alignment: .top, spacing: VNSpacing.md) {
            iconTile
            contentColumn
            if !isMemorial { trailingChevron }
        }
        .padding(VNSpacing.cardPadding)
        .background(Color.vnBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.card)
                .stroke(Color.vnBorderSubtle, lineWidth: VNBorderWidth.hairline)
        )
        .shadow(color: VNShadow.folio.color, radius: VNShadow.folio.radius, x: VNShadow.folio.x, y: VNShadow.folio.y)
        .opacity(isPassed ? 0.8 : 1)
        .contentShape(Rectangle())
    }

    private var iconTile: some View {
        Image(systemName: tileIcon)
            .font(.title3)
            .foregroundColor(tileForeground)
            .frame(width: VNSize.iconButton, height: VNSize.iconButton)
            .accessibilityHidden(true)
            .background(tileBackground)
            .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: VNCornerRadius.card)
                    .strokeBorder(tileBorder, lineWidth: VNBorderWidth.hairline)
            )
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
                .font(.vnDisplay(.callout, weight: .semibold))
                .foregroundColor(.vnTextPrimary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Spacer(minLength: VNSpacing.xs)
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
            Image(systemName: "calendar").font(.caption2).accessibilityHidden(true)
            Text(dateText).font(.vnDisplay(.caption, weight: .medium)).monospacedDigit()
        }
        .foregroundColor(.vnTextSecondary)
    }

    private func noteRow(_ note: String) -> some View {
        Text(note)
            .font(.vnDisplay(.caption))
            .italic()
            .foregroundColor(.vnTextSecondary)
            .lineLimit(1)
    }

    private var ritualButton: some View {
        VNButton(String(localized: "action.view_prayer"), icon: "book.pages", variant: .secondary, size: .small, action: onViewRitual)
    }

    private var trailingChevron: some View {
        Image(systemName: "chevron.right")
            .font(.footnote.weight(.semibold))
            .foregroundColor(.vnTextTertiary)
            .padding(.top, VNSpacing.space2)
            .accessibilityHidden(true)
    }

    private var cardMenu: some View {
        Group {
            Button(action: onEdit) { Label("timeline.action_edit", systemImage: "pencil") }
            if isMemorial {
                Button(action: onViewRitual) { Label("action.view_prayer", systemImage: "book.pages") }
            }
            Divider()
            Button(role: .destructive, action: onDelete) { Label("timeline.action_delete", systemImage: "trash") }
        }
    }

}
