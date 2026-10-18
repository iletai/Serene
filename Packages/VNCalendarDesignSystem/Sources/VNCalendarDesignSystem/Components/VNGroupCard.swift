import SwiftUI

/// A grouped container for settings list rows, matching the `settingsCard` pattern
/// from SettingsView — rice-paper secondary background, gold hairline border.
///
/// Usage:
/// ```swift
/// VNGroupCard {
///     VNSettingsRow(icon: "calendar", title: "Lịch", tint: .vnAccentHeritageRed)
///     VNDivider()
///     VNSettingsRow(icon: "bell", title: "Thông báo", tint: .vnAccentImperialGold)
/// }
/// ```
public struct VNGroupCard<Content: View>: View {
    public let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(Color.vnBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous)
                .stroke(Color.vnAccentImperialGold.opacity(0.28), lineWidth: VNBorderWidth.hairline)
        )
    }
}

/// A hairline divider tuned for list rows — uses `vnBorderSubtle` with optional leading inset.
/// Replaces bare `Divider().background(Color.vnBorderSubtle)` usage across the codebase.
public struct VNRowDivider: View {
    public let leadingInset: CGFloat

    public init(leadingInset: CGFloat = 0) {
        self.leadingInset = leadingInset
    }

    public var body: some View {
        Color.vnBorderSubtle
            .frame(height: VNBorderWidth.hairlineThin)
            .padding(.leading, leadingInset)
    }
}
