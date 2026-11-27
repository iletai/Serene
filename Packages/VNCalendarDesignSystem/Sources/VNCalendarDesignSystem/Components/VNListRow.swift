import SwiftUI

/// Prototype `button.row:hover .i-*` glyph motions, fired when the host toggles `trigger`.
public enum VNListRowIconEffect: Sendable {
    case none
    /// `nudge`: share / download glyphs.
    case nudge
    /// `spin-once`: gear / update glyphs.
    case spinOnce
}

/// Inset-group row used by Settings, the timeline and the reminder form.
///
/// Mirrors the prototype's `.row` / `.ico` / `.row-text` / `.row-value` pattern:
/// a 30pt solid colour tile, a title + optional subtitle stack, an optional value
/// and a trailing chevron, on a 52pt minimum row height.
public struct VNListRow<Trailing: View>: View {
    public let icon: String?
    public let iconTint: Color
    public let title: String
    public let subtitle: String?
    public let titleColor: Color
    public let showsChevron: Bool
    public let trailing: () -> Trailing
    private var iconEffect: VNListRowIconEffect = .none
    private var iconEffectTrigger = false

    /// Plays `effect` on the icon glyph every time `trigger` changes (no-op under Reduce Motion).
    public func iconEffect(_ effect: VNListRowIconEffect, trigger: Bool) -> Self {
        var copy = self
        copy.iconEffect = effect
        copy.iconEffectTrigger = trigger
        return copy
    }

    /// Icon-less row with a trailing view.
    public init(
        title: String,
        subtitle: String? = nil,
        titleColor: Color = .vnTextPrimary,
        showsChevron: Bool = false,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.icon = nil
        self.iconTint = .vnAccentSky
        self.title = title
        self.subtitle = subtitle
        self.titleColor = titleColor
        self.showsChevron = showsChevron
        self.trailing = trailing
    }

    /// Row with a colour tile, no trailing view.
    public init(
        icon: String,
        iconTint: Color = .vnAccentSky,
        title: String,
        subtitle: String? = nil,
        titleColor: Color = .vnTextPrimary,
        showsChevron: Bool = true
    ) where Trailing == EmptyView {
        self.icon = icon
        self.iconTint = iconTint
        self.title = title
        self.subtitle = subtitle
        self.titleColor = titleColor
        self.showsChevron = showsChevron
        self.trailing = { EmptyView() }
    }

    /// Row with a colour tile and a trailing view.
    public init(
        icon: String,
        iconTint: Color = .vnAccentSky,
        title: String,
        subtitle: String? = nil,
        titleColor: Color = .vnTextPrimary,
        showsChevron: Bool = false,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.icon = icon
        self.iconTint = iconTint
        self.title = title
        self.subtitle = subtitle
        self.titleColor = titleColor
        self.showsChevron = showsChevron
        self.trailing = trailing
    }

    @ViewBuilder
    private func glyph(_ icon: String) -> some View {
        let image = Image(systemName: icon)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.vnOnAccent)
        switch iconEffect {
        case .none: image
        case .nudge: image.vnNudge(trigger: iconEffectTrigger)
        case .spinOnce: image.vnSpinOnce(trigger: iconEffectTrigger)
        }
    }

    public var body: some View {
        HStack(spacing: VNSpacing.md) {
            if let icon {
                glyph(icon)
                    .frame(width: VNSize.listRowIcon, height: VNSize.listRowIcon)
                    .background(iconTint)
                    .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.micro, style: .continuous))
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: VNSpacing.space2) {
                Text(title)
                    .font(.vnDisplay(.body, weight: .regular))
                    .foregroundColor(titleColor)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitle {
                    Text(subtitle)
                        .font(.vnDisplay(.footnote))
                        .foregroundColor(.vnTextSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            trailing()

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.vnTextTertiary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, VNSpacing.lg)
        .padding(.vertical, VNSpacing.md)
        .frame(minHeight: VNSize.listRow)
        .contentShape(Rectangle())
    }
}
