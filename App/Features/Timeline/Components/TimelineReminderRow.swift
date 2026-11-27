import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem

/// One memorial in the timeline: 44pt date column + title/lunar/note column + countdown.
/// Mirrors the prototype's `.row` with `dateCol`, inside a month group.
struct TimelineReminderRow: View {
    let row: TimelineRowModel
    let onEdit: () -> Void
    let onViewRitual: () -> Void
    let onDelete: () -> Void

    private var isMemorial: Bool {
        row.reminder.category == .deathAnniversary || row.reminder.category == .ancestral
    }

    private var isPassed: Bool { row.countdown.hasPrefix(String(localized: "timeline.passed")) }

    private var categoryTone: Color {
        switch row.reminder.category {
        case .deathAnniversary, .ancestral: .vnAccentHeritageRed
        case .worship: .vnAccentGoldText
        case .birthday, .wedding: .vnAccentJade
        case .other: .vnTextTertiary
        }
    }

    var body: some View {
        Button(action: onEdit) {
            content
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityActions {
            if isMemorial { Button("action.view_prayer", action: onViewRitual) }
            Button("timeline.action_delete", role: .destructive, action: onDelete)
        }
        .contextMenu {
            Button(action: onEdit) { Label("timeline.action_edit", systemImage: "pencil") }
            if isMemorial {
                Button(action: onViewRitual) { Label("action.view_prayer", systemImage: "book.pages") }
            }
            Divider()
            Button(role: .destructive, action: onDelete) { Label("timeline.action_delete", systemImage: "trash") }
        }
        .opacity(isPassed ? 0.72 : 1)
    }

    private var content: some View {
        HStack(alignment: .top, spacing: VNSpacing.md) {
            dateColumn
            textColumn
            Spacer(minLength: VNSpacing.xs)
            trailingColumn
        }
        .padding(.horizontal, VNSpacing.lg)
        .padding(.vertical, VNSpacing.md)
        .frame(minHeight: VNSize.listRow)
    }

    private var dateColumn: some View {
        VStack(spacing: 0) {
            Text("\(row.solarDay)")
                .font(.vnDisplay(size: 22, weight: .semibold))
                .monospacedDigit()
                .foregroundColor(.vnTextPrimary)
            Text(row.weekday)
                .font(.vnDisplay(size: 11, weight: .semibold))
                .tracking(0.6)
                .foregroundColor(.vnTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(width: 44)
        .accessibilityHidden(true)
    }

    private var textColumn: some View {
        VStack(alignment: .leading, spacing: VNSpacing.space2) {
            Text(row.reminder.title)
                .font(.vnDisplay(.body, weight: .semibold))
                .foregroundColor(.vnTextPrimary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)

            HStack(spacing: VNSpacing.xs) {
                Circle()
                    .fill(categoryTone)
                    .frame(width: 6, height: 6)
                    .accessibilityHidden(true)
                Text(row.reminder.category.title)
                    .font(.vnDisplay(.footnote))
                    .foregroundColor(.vnTextSecondary)
                Text(verbatim: "· \(row.lunarLabel)")
                    .font(.vnDisplay(.footnote))
                    .foregroundColor(.vnTextSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            if let relationship = row.reminder.relationship, !relationship.isEmpty {
                Text(relationship.uppercased())
                    .font(.vnDisplay(.caption2, weight: .semibold))
                    .tracking(0.6)
                    .foregroundColor(.vnAccentDeepPrimary)
            }

            if let note = row.reminder.note, !note.isEmpty {
                Text(note)
                    .font(.vnDisplay(.footnote))
                    .foregroundColor(.vnTextSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var trailingColumn: some View {
        HStack(spacing: VNSpacing.xs) {
            Text(row.countdown)
                .font(.vnDisplay(.footnote, weight: .semibold))
                .monospacedDigit()
                .foregroundColor(row.isSoon ? .vnAccentDeepPrimary : .vnTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundColor(.vnTextTertiary)
                .accessibilityHidden(true)
        }
        .padding(.top, VNSpacing.space2)
    }
}
