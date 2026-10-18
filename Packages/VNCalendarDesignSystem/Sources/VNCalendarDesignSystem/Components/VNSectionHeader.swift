import SwiftUI

/// Editorial section header embodying the "Vietnamese Lunar Editorial" aesthetic.
/// Features a vertical Cinnabar accent bar or calligraphy seal icon alongside New York Serif typography.
public struct VNSectionHeader: View {
    /// Canonical accent-bar geometry (DESIGN §4). No spacing token matches 3.5/18pt.
    /// nonisolated: enum-case default args live outside MainActor, and `View` is MainActor-isolated.
    public nonisolated static let accentBarWidth: CGFloat = 3.5
    public nonisolated static let accentBarHeight: CGFloat = 18

    public enum AccentStyle: Sendable, Equatable {
        case verticalBar(
            color: Color = .vnAccentDeepPrimary,
            width: CGFloat = VNSectionHeader.accentBarWidth,
            height: CGFloat = VNSectionHeader.accentBarHeight
        )
        case seal(text: String = "ẤN", color: Color = .vnAccentDeepPrimary)
        case icon(systemName: String, color: Color = .vnAccentImperialGold)
        case none
    }

    public let title: String
    public let subtitle: String?
    public let accent: AccentStyle
    public let actionTitle: String?
    public let action: (@Sendable () -> Void)?

    public init(
        title: String,
        subtitle: String? = nil,
        accent: AccentStyle = .verticalBar(),
        actionTitle: String? = nil,
        action: (@Sendable () -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.accent = accent
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        HStack(alignment: subtitle != nil ? .top : .center, spacing: VNSpacing.sm) {
            leadingAccentView

            VStack(alignment: .leading, spacing: VNSpacing.space2) {
                Text(title)
                    .font(.vnSectionHeaderSerif)
                    .foregroundColor(.vnTextPrimary)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.vnCaption2)
                        .fontWeight(.medium)
                        .tracking(0.66)
                        .foregroundColor(.vnTextSecondary)
                }
            }

            Spacer(minLength: VNSpacing.sm)

            if let actionTitle, let action {
                Button(action: action) {
                    HStack(spacing: VNSpacing.xs) {
                        Text(actionTitle)
                            .font(.vnCaption1)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.vnAccentDeepPrimary)
                    .padding(VNSpacing.xs)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(minHeight: 44)
            }
        }
    }

    @ViewBuilder
    private var leadingAccentView: some View {
        switch accent {
        case .verticalBar(let color, let width, let height):
            RoundedRectangle(cornerRadius: width / 2)
                .fill(color)
                .frame(width: width, height: height)
        case .seal(let text, let color):
            Text(text)
                .font(.system(size: 9, weight: .bold, design: .serif))
                .foregroundColor(.vnRicePaperWhite)
                .padding(.horizontal, VNSpacing.xs)
                .padding(.vertical, VNSpacing.space2)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.small))
        case .icon(let systemName, let color):
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 18, height: 18)
        case .none:
            EmptyView()
        }
    }
}
