import SwiftUI

/// Calendar display mode enum representing primary view modes in An Niên.
public enum VNCalendarMode: String, CaseIterable, Identifiable, Sendable {
    case block
    case month
    case week
    case year

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .block:
            String(localized: "ds.calendar.mode.block")
        case .month:
            String(localized: "ds.calendar.mode.month")
        case .week:
            String(localized: "ds.calendar.mode.week")
        case .year:
            String(localized: "ds.calendar.mode.year")
        }
    }

    public var icon: String {
        switch self {
        case .block:
            "doc.text.fill"
        case .month:
            "calendar"
        case .week:
            "calendar.day.timeline.left"
        case .year:
            "calendar.badge.clock"
        }
    }
}

/// An elegant segmented control embodying the Vietnamese Lunar Editorial design.
/// Features a smooth sliding indicator in Cinnabar Red over an ancient sand / secondary surface.
public struct VNCalendarModePicker: View {
    @Binding public var selectedMode: VNCalendarMode
    @Namespace private var modeAnimationNamespace

    public var modes: [VNCalendarMode]

    public init(
        selectedMode: Binding<VNCalendarMode>,
        modes: [VNCalendarMode] = VNCalendarMode.allCases
    ) {
        self._selectedMode = selectedMode
        self.modes = modes
    }

    public var body: some View {
        // Titles never wrap: when they cannot fit on one line, fall back to icon-only segments.
        ViewThatFits(in: .horizontal) {
            segments(showTitles: true)
            segments(showTitles: false)
        }
        .padding(VNSpacing.xs)
        .background(Color.vnBackgroundSecondary)
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.card)
                .stroke(Color.vnBorderSubtle, lineWidth: VNBorderWidth.hairline)
        )
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
    }

    private func segments(showTitles: Bool) -> some View {
        HStack(spacing: VNSpacing.xs) {
            ForEach(modes) { mode in
                let isSelected = selectedMode == mode
                Button {
                    withAnimation(VNAnimation.cellSelection) {
                        selectedMode = mode
                    }
                } label: {
                    segmentLabel(mode, showTitle: showTitles)
                        .font(.vnDisplay(size: 13, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? .vnBackgroundPrimary : .vnTextSecondary)
                        .padding(.horizontal, VNSpacing.xs)
                        .padding(.vertical, VNSpacing.sm)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: VNCornerRadius.small)
                                    .fill(Color.vnAccentHeritageRed)
                                    .matchedGeometryEffect(id: "activeSegmentIndicator", in: modeAnimationNamespace)
                            }
                        }
                        .contentShape(Rectangle())
                        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
                        .accessibilityValue(isSelected ? String(localized: "ds.a11y.selected") : "")
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func segmentLabel(_ mode: VNCalendarMode, showTitle: Bool) -> some View {
        if showTitle {
            // Equal-width cells + hidden wrapping: ViewThatFits rejects this variant if the title would need 2 lines.
            Text(mode.title)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        } else {
            Image(systemName: mode.icon)
                .accessibilityLabel(mode.title)
        }
    }
}
