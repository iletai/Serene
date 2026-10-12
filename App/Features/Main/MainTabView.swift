import SwiftUI
import VNCalendarDesignSystem

public enum MainTab: Int, CaseIterable, Identifiable {
    case calendar = 0
    case memorial = 1
    case rituals = 2
    case family = 3

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .calendar:
            return "Lịch Ngày"
        case .memorial:
            return "Ngày Giỗ"
        case .rituals:
            return "Văn Khấn"
        case .family:
            return "Gia Tộc"
        }
    }

    public func icon(isSelected: Bool) -> String {
        switch self {
        case .calendar:
            return isSelected ? "calendar.circle.fill" : "calendar"
        case .memorial:
            return isSelected ? "flame.fill" : "flame"
        case .rituals:
            return isSelected ? "book.pages.fill" : "book.closed"
        case .family:
            return isSelected ? "person.3.sequence.fill" : "person.3.sequence"
        }
    }
}

public struct MainTabView: View {
    @State private var selectedTab = 0

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            CalendarMainView()
                .tag(0)
                .toolbar(.hidden, for: .tabBar)

            UpcomingTimelineView()
                .tag(1)
                .toolbar(.hidden, for: .tabBar)

            CulturalArticlesView()
                .tag(2)
                .toolbar(.hidden, for: .tabBar)

            FamilyHierarchyView()
                .tag(3)
                .toolbar(.hidden, for: .tabBar)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        // safeAreaInset reserves pill height in every tab's scroll content,
        // so nothing can scroll under the floating pill (ZStack overlay never did).
        .safeAreaInset(edge: .bottom, spacing: 0) {
            customBottomTabBar
        }
    }

    // MARK: - Floating Pill Tab Bar
    private var customBottomTabBar: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, VNSpacing.lg)
        .padding(.vertical, VNSpacing.md)
        .frame(maxWidth: 520)
        .background(Color.vnSurfaceElevated.opacity(0.85), in: Capsule())
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color.vnBorderSubtle.opacity(0.4), lineWidth: VNBorderWidth.hairline))
        .shadow(color: VNShadow.floating.color, radius: VNShadow.floating.radius,
                x: VNShadow.floating.x, y: VNShadow.floating.y)
        .padding(.horizontal, VNSpacing.lg)
        .padding(.bottom, VNSpacing.md)
    }

    private func tabButton(for tab: MainTab) -> some View {
        let isSelected = selectedTab == tab.rawValue

        return Button {
            triggerHaptic()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                selectedTab = tab.rawValue
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: tab.icon(isSelected: isSelected))
                    .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(isSelected ? .vnAccentHeritageRed : .vnTextSecondary)
                    .scaleEffect(isSelected ? 1.08 : 1.0)

                Text(tab.title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .vnAccentHeritageRed : .vnTextSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func triggerHaptic() {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }
}
