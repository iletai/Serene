import SwiftUI

/// Reusable settings/navigation list row.
/// Replaces the duplicated `menuRow(icon:title:subtitle:tint:)` pattern in `SettingsView`
/// and the `Label + Spacer + value + chevron` HStack pattern in the settings sub-screens.
///
/// Usage:
/// ```swift
/// // Navigation row (with chevron)
/// NavigationLink(destination: CalendarSettingsView()) {
///     VNSettingsRow(icon: "calendar.badge.clock", title: "Lịch", subtitle: "Múi giờ", tint: .vnAccentHeritageRed)
/// }
/// .buttonStyle(.plain)
///
/// // Action row (disclosure button, custom trailing)
/// VNSettingsRow(icon: "arrow.clockwise", title: "Làm mới", tint: .vnStatusSuccess)
///
/// // Value display row
/// VNSettingsRow(icon: "info.circle.fill", title: "Phiên bản", tint: .vnAccentImperialGold,
///               trailing: { Text("1.0.0").font(.vnCaption1).foregroundColor(.vnTextSecondary) })
/// ```
public struct VNSettingsRow<Trailing: View>: View {
    public let icon: String?
    public let title: String
    public let subtitle: String?
    public let tint: Color
    public let showChevron: Bool
    public let trailing: () -> Trailing

    // MARK: - Convenience init without trailing view
    public init(
        icon: String? = nil,
        title: String,
        subtitle: String? = nil,
        tint: Color = .vnAccentImperialGold,
        showChevron: Bool = true
    ) where Trailing == EmptyView {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.tint = tint
        self.showChevron = showChevron
        self.trailing = { EmptyView() }
    }

    // MARK: - Full init with custom trailing
    public init(
        icon: String? = nil,
        title: String,
        subtitle: String? = nil,
        tint: Color = .vnAccentImperialGold,
        showChevron: Bool = false,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.tint = tint
        self.showChevron = showChevron
        self.trailing = trailing
    }

    public var body: some View {
        HStack(spacing: VNSpacing.md) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(tint)
                    .frame(width: 36, height: 36)
                    .background(tint.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: VNSpacing.space2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.vnTextPrimary)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.vnTextSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            trailing()

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.vnTextTertiary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, VNSpacing.lg)
        .padding(.vertical, VNSpacing.md)
        .contentShape(Rectangle())
        .frame(minHeight: 44)
    }
}
