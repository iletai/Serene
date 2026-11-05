import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem

enum MemorialFilterTab: CaseIterable, Identifiable {
    case all
    case deathAnniversary
    case ancestral
    case worship
    case other

    var id: Self { self }

    var title: String {
        switch self {
        case .all: String(localized: "timeline.filter_all")
        case .deathAnniversary: String(localized: "timeline.filter_death_anniversary")
        case .ancestral: String(localized: "timeline.filter_ancestral")
        case .worship: String(localized: "timeline.filter_worship")
        case .other: String(localized: "timeline.filter_other")
        }
    }

    func matches(category: ReminderCategory) -> Bool {
        switch self {
        case .all:
            return true
        case .deathAnniversary:
            return category == .deathAnniversary
        case .ancestral:
            return category == .ancestral
        case .worship:
            return category == .worship
        case .other:
            return category == .birthday || category == .wedding || category == .other
        }
    }
}

struct MemorialFilterPills: View {
    @Binding var selectedTab: MemorialFilterTab
    let countForTab: (MemorialFilterTab) -> Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: VNSpacing.xs) {
                ForEach(MemorialFilterTab.allCases) { tab in
                    let isSelected = selectedTab == tab
                    let itemCount = countForTab(tab)

                    Button(
                        action: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedTab = tab
                            }
                        },
                        label: {
                            HStack(spacing: VNSpacing.xs) {
                                Text(tab.title)
                                    .font(.caption.weight(isSelected ? .semibold : .medium))
                                    .frame(minHeight: VNSize.minTapTarget)

                                if itemCount > 0 {
                                    Text("(\(itemCount))")
                                        .font(.caption2)
                                        .monospacedDigit()
                                }
                            }
                            .foregroundColor(isSelected ? .vnAccentDeepPrimary : .vnTextSecondary)
                            .padding(.horizontal, VNSpacing.md)
                            .background(isSelected ? Color.vnAccentRedSurface : Color.clear)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(
                                        isSelected
                                            ? Color.vnAccentHeritageRed.opacity(0.25)
                                            : Color.vnBorderSubtle,
                                        lineWidth: VNBorderWidth.regular
                                    )
                            )
                        }
                    )
                    .contentShape(Capsule())
                    .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
                }
            }
            .padding(.horizontal, VNSpacing.screenMargin)
        }
    }
}
