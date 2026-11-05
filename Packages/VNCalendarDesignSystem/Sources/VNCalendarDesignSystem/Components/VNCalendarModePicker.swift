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
        HStack(spacing: VNSpacing.xs) {
            ForEach(modes) { mode in
                let isSelected = selectedMode == mode
                Button {
                    withAnimation(VNAnimation.cellSelection) {
                        selectedMode = mode
                    }
                } label: {
                    Text(mode.title)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .medium, design: .serif))
                        .foregroundColor(isSelected ? .vnBackgroundPrimary : .vnTextSecondary)
                        .padding(.horizontal, VNSpacing.sm)
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
        .padding(VNSpacing.xs)
        .background(Color.vnBackgroundSecondary)
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.card)
                .stroke(Color.vnBorderSubtle, lineWidth: VNBorderWidth.hairline)
        )
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
    }
}
