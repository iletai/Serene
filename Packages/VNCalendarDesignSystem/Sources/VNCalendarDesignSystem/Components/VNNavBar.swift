import SwiftUI

/// A standardised dismiss / close button for sheets and presented modals.
/// Matches the top-bar 36pt icon frame + 44pt min hit-target pattern from DESIGN §4.
///
/// Usage:
/// ```swift
/// // Xmark style (for sheets without a title)
/// VNDismissButton(style: .xmark) { dismiss() }
///
/// // Text "Đóng" style (for NavigationStack sheets with .inline title)
/// VNDismissButton(style: .text("Đóng")) { dismiss() }
///
/// // "Xong" confirmation style
/// VNDismissButton(style: .done) { dismiss() }
/// ```
public struct VNDismissButton: View {
    public enum Style {
        /// Circular xmark icon — standard for modally-presented sheets.
        case xmark
        /// Plain text button — matches SettingsView "Xong" / OmniSearchView "Đóng".
        case text(String)
        /// Filled red "Xong" confirmation — for primary commit actions.
        case done
    }

    public let style: Style
    public let action: () -> Void

    public init(style: Style = .xmark, action: @escaping () -> Void) {
        self.style = style
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            label
        }
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var label: some View {
        switch style {
        case .xmark:
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.vnTextPrimary)
                .frame(width: 36, height: 36)
                .background(
                    Color.vnBackgroundSecondary,
                    in: RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous)
                        .stroke(Color.vnAccentImperialGold.opacity(0.28), lineWidth: VNBorderWidth.hairline)
                )

        case .text(let label):
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.vnAccentDeepPrimary)

        case .done:
            Text("Xong")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, VNSpacing.md)
                .padding(.vertical, VNSpacing.xs)
                .background(Color.vnAccentHeritageRed)
                .clipShape(Capsule())
        }
    }

    private var accessibilityLabel: String {
        switch style {
        case .xmark: return "Đóng"
        case .text(let t): return t
        case .done: return "Xong"
        }
    }
}

// MARK: - NavigationStack Toolbar Convenience Modifier

public extension View {
    /// Attaches the canonical An Niên navigation bar — translucent rice-paper background,
    /// serif red principal title, optional subtitle, and a dismiss button.
    ///
    /// Replaces 30+ lines of `.toolbar { ... } .toolbarBackground(...)` boilerplate
    /// scattered across OmniSearchView, ReminderFormView, SettingsView, etc.
    ///
    /// ```swift
    /// .vnNavBar(title: "Tra Cứu Thông Minh") {
    ///     VNDismissButton(style: .text("Đóng")) { dismiss() }
    /// }
    /// ```
    func vnNavBar<Trailing: View>(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) -> some View {
        #if os(iOS)
        self
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.vnBackgroundPrimary.opacity(0.9), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    // Title/subtitle pair uses the same tight stack gap as VNSectionHeader.
                    // Canonical top-bar type scale (canonical.html): serif red 18/600 + label 11/500.
                    VStack(spacing: VNSpacing.space2) {
                        Text(title)
                            .font(.system(size: 18, weight: .semibold, design: .serif))
                            .foregroundColor(.vnAccentDeepPrimary)
                        if let subtitle {
                            Text(subtitle)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.vnTextSecondary)
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    trailing()
                }
            }
        #else
        self
        #endif
    }
}
