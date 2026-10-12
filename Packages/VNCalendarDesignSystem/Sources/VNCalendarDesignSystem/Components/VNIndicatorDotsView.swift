import SwiftUI

public struct VNIndicatorDotsView: View {
    public let hasAncestorDeath: Bool
    public let hasFestival: Bool
    public let hasPersonalEvent: Bool

    public init(
        hasAncestorDeath: Bool = false,
        hasFestival: Bool = false,
        hasPersonalEvent: Bool = false
    ) {
        self.hasAncestorDeath = hasAncestorDeath
        self.hasFestival = hasFestival
        self.hasPersonalEvent = hasPersonalEvent
    }

    public var body: some View {
        HStack(spacing: VNSpacing.space2) {
            if hasAncestorDeath {
                Circle()
                    .fill(Color.vnAccentDeepPrimary)
                    .frame(width: VNSpacing.xs, height: VNSpacing.xs)
            }
            if hasFestival {
                Circle()
                    .fill(Color.vnAccentImperialGold)
                    .frame(width: VNSpacing.xs, height: VNSpacing.xs)
            }
            if hasPersonalEvent {
                Circle()
                    .fill(Color.vnTextTertiary)
                    .frame(width: VNSpacing.xs, height: VNSpacing.xs)
            }
        }
        .frame(height: 5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Có giỗ, lễ hội")
        .accessibilityHidden(!hasAncestorDeath && !hasFestival && !hasPersonalEvent)
    }
}
