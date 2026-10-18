import SwiftUI

/// Centralised empty state view for the "Vietnamese Lunar Editorial" aesthetic.
/// Replaces the bespoke `MemorialEmptyStateView` and any future one-off empty states
/// with a consistent icon-in-circle + title + quote + optional CTA pattern.
///
/// Usage:
/// ```swift
/// // With CTA button
/// VNEmptyState(
///     icon: "flame.fill",
///     iconBackground: .vnAccentRedSurface,
///     iconForeground: .vnAccentHeritageRed,
///     title: "Gìn Giữ Đạo Hiếu Gia Tiên",
///     quote: ""Cây có cội mới trổ cành xanh lá\nNước có nguồn mới bủa khắp rạch sông"",
///     ctaLabel: "Thêm Ngày Giỗ Đầu Tiên",
///     ctaIcon: "plus.circle.fill",
///     onCTA: { ... }
/// )
///
/// // No CTA — info-only (e.g. search with no results)
/// VNEmptyState(
///     icon: "magnifyingglass",
///     iconBackground: .vnBackgroundTertiary,
///     iconForeground: .vnTextTertiary,
///     title: "Không tìm thấy kết quả"
/// )
/// ```
public struct VNEmptyState: View {
    // Fixed icon geometry: 84pt circle with 36pt glyph (DESIGN §4 editorial empty state).
    private static let iconCircleSize: CGFloat = 84
    private static let iconGlyphSize: CGFloat = 36

    public let icon: String
    public let iconBackground: Color
    public let iconForeground: Color
    public let title: String
    public let quote: String?
    public let ctaLabel: String?
    public let ctaIcon: String?
    public let onCTA: (() -> Void)?

    public init(
        icon: String,
        iconBackground: Color = Color.vnAccentRedSurface,
        iconForeground: Color = Color.vnAccentHeritageRed,
        title: String,
        quote: String? = nil,
        ctaLabel: String? = nil,
        ctaIcon: String? = nil,
        onCTA: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.iconBackground = iconBackground
        self.iconForeground = iconForeground
        self.title = title
        self.quote = quote
        self.ctaLabel = ctaLabel
        self.ctaIcon = ctaIcon
        self.onCTA = onCTA
    }

    public var body: some View {
        VStack(spacing: VNSpacing.md) {
            ZStack {
                Circle()
                    .fill(iconBackground)
                    .frame(width: Self.iconCircleSize, height: Self.iconCircleSize)

                Image(systemName: icon)
                    .font(.system(size: Self.iconGlyphSize))
                    .foregroundColor(iconForeground)
            }
            .padding(.top, VNSpacing.xl)
            .accessibilityHidden(true)

            Text(title)
                .font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundColor(.vnTextPrimary)
                .multilineTextAlignment(.center)

            if let quote {
                Text(quote)
                    .font(.system(size: 13, design: .serif))
                    .italic()
                    .multilineTextAlignment(.center)
                    .foregroundColor(.vnTextSecondary)
                    .lineSpacing(VNSpacing.xs)
                    .padding(.horizontal, VNSpacing.xl)
            }

            if let ctaLabel, let onCTA {
                Button(action: onCTA) {
                    HStack(spacing: VNSpacing.xs) {
                        if let ctaIcon {
                            Image(systemName: ctaIcon)
                                .font(.system(size: 14))
                                .accessibilityHidden(true)
                        }
                        Text(ctaLabel)
                            .font(.system(size: 14, weight: .bold, design: .serif))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, VNSpacing.xl)
                    .padding(.vertical, VNSpacing.md)
                    .frame(minHeight: 44) // HIG minimum touch target.
                    .background(Color.vnAccentHeritageRed)
                    .clipShape(Capsule())
                    .shadow(
                        color: VNShadow.card.color,
                        radius: VNShadow.card.radius,
                        x: VNShadow.card.x,
                        y: VNShadow.card.y
                    )
                }
                .padding(.top, VNSpacing.sm)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, VNSpacing.xl)
    }
}
