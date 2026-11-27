import SwiftUI

/// Uppercase group heading for inset grouped lists.
///
/// Mirrors the prototype's `.group-header` (13pt uppercase, +0.06em, secondary ink)
/// that sits above a `VNGroupCard`. Pair with `VNGroupFooter` below the card.
public struct VNGroupHeader: View {
    public let title: String

    public init(_ title: String) {
        self.title = title
    }

    public var body: some View {
        Text(title.uppercased())
            .font(.vnDisplay(.footnote, weight: .regular))
            .tracking(0.8)
            .foregroundColor(.vnTextSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, VNSpacing.xs)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Small footnote under a grouped list (`.group-footer` in the prototype).
public struct VNGroupFooter: View {
    public let text: String
    public let isCentered: Bool

    public init(_ text: String, isCentered: Bool = false) {
        self.text = text
        self.isCentered = isCentered
    }

    public var body: some View {
        Text(text)
            .font(.vnDisplay(.footnote))
            .foregroundColor(.vnTextSecondary)
            .multilineTextAlignment(isCentered ? .center : .leading)
            .frame(maxWidth: .infinity, alignment: isCentered ? .center : .leading)
            .padding(.horizontal, VNSpacing.xs)
    }
}
