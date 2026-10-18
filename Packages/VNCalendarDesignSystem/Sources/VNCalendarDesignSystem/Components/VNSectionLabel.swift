import SwiftUI

/// Uppercase kicker / section-label used above every grouped card.
/// Matches the 11pt uppercase tracking pattern from DESIGN §4.
/// Replaces the ad-hoc `sectionHeader()` private functions scattered across Settings,
/// ReminderCategoryGrid, and PrayerLibraryView.
public struct VNSectionLabel: View {
    public enum Style {
        /// Gold kicker — default for content sections (Hoàng Cúc).
        case gold
        /// Red kicker — for heritage / memorial sections (Đỏ Son).
        case heritage
        /// Neutral kicker — muted metadata label.
        case muted
    }

    public let text: String
    public let style: Style

    public init(_ text: String, style: Style = .gold) {
        self.text = text
        self.style = style
    }

    public var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .medium))
            .tracking(0.7)
            .foregroundColor(labelColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, VNSpacing.xs)
            .accessibilityAddTraits(.isHeader)
    }

    private var labelColor: Color {
        switch style {
        case .gold:    return .vnOnGoldContainer
        case .heritage: return .vnAccentDeepPrimary
        case .muted:   return .vnTextTertiary
        }
    }
}
