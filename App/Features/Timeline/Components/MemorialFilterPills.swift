import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem

enum MemorialFilterTab: String, CaseIterable, Identifiable {
    case all = "Tất cả"
    case deathAnniversary = "Giỗ Gia Tiên"
    case ancestral = "Chạp Họ / Kỵ"
    case worship = "Lễ Tiết & Vía"
    case other = "Khác"

    var id: String { rawValue }

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
                                Text(tab.rawValue)
                                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                                    .frame(minHeight: 44)

                                if itemCount > 0 {
                                    Text("(\(itemCount))")
                                        .font(.system(size: 11, weight: .regular))
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
            .padding(.horizontal, VNSpacing.xl)
        }
    }
}
