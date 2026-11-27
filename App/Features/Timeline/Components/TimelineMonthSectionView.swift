import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem

/// A month block of the memorial timeline: header + inset group of rows.
struct TimelineMonthSectionView: View {
    let section: TimelineMonthSection
    let onEdit: (ReminderEvent) -> Void
    let onViewRitual: (ReminderEvent) -> Void
    let onDelete: (ReminderEvent) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: VNSpacing.sm) {
            header
            VNGroupCard {
                ForEach(Array(section.rows.enumerated()), id: \.element.id) { index, row in
                    if index > 0 {
                        VNRowDivider(leadingInset: 44 + VNSpacing.lg * 2)
                    }
                    TimelineReminderRow(
                        row: row,
                        onEdit: { onEdit(row.reminder) },
                        onViewRitual: { onViewRitual(row.reminder) },
                        onDelete: { onDelete(row.reminder) }
                    )
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: VNSpacing.xs) {
            Text(section.title.uppercased())
                .font(.vnDisplay(.footnote, weight: .semibold))
                .tracking(0.8)
                .foregroundColor(.vnTextSecondary)

            if let lunarSubtitle = section.lunarSubtitle {
                Text(verbatim: "· \(lunarSubtitle)")
                    .font(.vnDisplay(.footnote))
                    .foregroundColor(.vnTextSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, VNSpacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}
