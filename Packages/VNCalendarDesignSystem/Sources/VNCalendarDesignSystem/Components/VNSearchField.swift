import SwiftUI

/// A heritage-themed search field — replaces the ad-hoc search HStack in
/// `OmniSearchView` and `PrayerLibraryView`.
/// Features: magnify icon, focus-aware red tint on leading icon/bottom rule, clear button.
///
/// Usage:
/// ```swift
/// VNSearchField(text: $searchText, placeholder: "Tìm giỗ ông, 15/8 âm…")
/// ```
public struct VNSearchField: View {
    @Binding public var text: String
    public let placeholder: String

    @FocusState private var isFocused: Bool

    public init(text: Binding<String>, placeholder: String = "Tìm kiếm…") {
        self._text = text
        self.placeholder = placeholder
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: VNSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15))
                    .foregroundColor(isFocused ? .vnAccentHeritageRed : .vnTextTertiary)
                    .animation(VNAnimation.cellSelection, value: isFocused)
                    .accessibilityHidden(true)

                TextField(
                    "",
                    text: $text,
                    prompt: Text(placeholder)
                        .foregroundColor(.vnTextTertiary)
                )
                .font(.system(size: 15))
                .foregroundColor(.vnTextPrimary)
                .focused($isFocused)
                .submitLabel(.search)

                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.vnTextTertiary)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(VNSpacing.md)
            .background(Color.vnBackgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous)
                    .stroke(
                        isFocused ? Color.vnAccentHeritageRed.opacity(0.5) : Color.vnAccentImperialGold.opacity(0.28),
                        lineWidth: isFocused ? VNBorderWidth.active : VNBorderWidth.hairline
                    )
            )
            .animation(VNAnimation.cellSelection, value: isFocused)
        }
    }
}
