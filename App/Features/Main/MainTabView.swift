import BaseNavigationStack
import SwiftUI
import TipKit
import VNCalendarDesignSystem

public enum MainTab: Int, CaseIterable, Identifiable, Sendable {
    case calendar = 0
    case memorial = 1
    case family = 2

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .calendar:
            return "Lịch Ngày"
        case .memorial:
            return "Ngày Giỗ"
        case .family:
            return "Gia Tộc"
        }
    }

    public func icon(isSelected: Bool) -> String {
        switch self {
        case .calendar:
            // No filled SF Symbol for plain calendar; active state rides color + weight.
            return "calendar"
        case .memorial:
            return isSelected ? "flame.fill" : "flame"
        case .family:
            return isSelected ? "person.3.fill" : "person.3"
        }
    }
}

public struct MainTabView: View {
    @Binding private var pendingDeepLink: DeepLinkHandler.Action?
    @State private var selectedTab: MainTab = .calendar
    /// One router per tab, indexed by `MainTab.rawValue` (0..<allCases.count), created once so each
    /// tab keeps its stack and sheet across switches.
    @State private var routers: [AppRouter]
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true

    init(pendingDeepLink: Binding<DeepLinkHandler.Action?> = .constant(nil)) {
        _pendingDeepLink = pendingDeepLink
        _routers = State(initialValue: MainTab.allCases.map { _ in AppRouter() })
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(MainTab.allCases) { tab in
                tabContainer(for: tab)
                    .tag(tab)
                    .toolbar(.hidden, for: .tabBar)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        // safeAreaInset reserves pill height in every tab's scroll content,
        // so nothing can scroll under the floating pill (ZStack overlay never did).
        .safeAreaInset(edge: .bottom, spacing: 0) {
            customBottomTabBar
        }
        .onChange(of: pendingDeepLink, initial: true) { _, action in
            guard let action else { return }
            handle(action)
            pendingDeepLink = nil
        }
    }

    private func handle(_ action: DeepLinkHandler.Action) {
        // A sheet on the current tab would otherwise stay up over the newly selected tab.
        routers[selectedTab.rawValue].dismissModals()
        switch action {
        case .select(let tab):
            selectedTab = tab
        case .present(let tab, let sheet):
            selectedTab = tab
            routers[tab.rawValue].present(sheet: sheet)
        }
    }

    private func tabContainer(for tab: MainTab) -> some View {
        BaseNavigationContainer(
            router: routers[tab.rawValue],
            content: { tabRoot(for: tab) },
            destination: { AppRouteView(route: $0) },
            sheet: { AppSheetView(sheet: $0) },
            cover: { _ in EmptyView() }
        )
    }

    /// Tab roots draw their own header; the container's navigation bar stays hidden.
    @ViewBuilder
    private func tabRoot(for tab: MainTab) -> some View {
        Group {
            switch tab {
            case .calendar: CalendarMainView()
            case .memorial: UpcomingTimelineView()
            case .family: FamilyHierarchyView()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Floating Pill Tab Bar
    private var customBottomTabBar: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases) { tab in
                if tab == .family {
                    tabButton(for: tab).popoverTip(FamilyTabTip(), arrowEdge: .bottom)
                } else {
                    tabButton(for: tab)
                }
            }
        }
        .padding(.horizontal, VNSpacing.lg)
        .padding(.vertical, VNSpacing.md)
        .frame(maxWidth: VNLayout.tabBarMaxWidth)
        // Bar chrome caps its growth like the system tab bar so labels never truncate.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .background {
            Capsule()
                .fill(Color.vnSurfaceElevated.opacity(0.85))
                .background(.ultraThinMaterial, in: Capsule())
        }
        .overlay(Capsule().stroke(Color.vnBorderSubtle.opacity(0.4), lineWidth: VNBorderWidth.hairline))
        // Canonical float shadow (DESIGN §4): red-tinted float, not folio card shadow.
        .shadow(color: VNShadow.floating.color, radius: VNShadow.floating.radius,
                x: VNShadow.floating.x, y: VNShadow.floating.y)
        .padding(.horizontal, VNSpacing.lg)
        .padding(.bottom, VNLayout.tabBarBottomInset)
    }

    private func tabButton(for tab: MainTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            VNHaptics.impact(enabled: hapticFeedbackEnabled)
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: VNSpacing.space2) {
                Image(systemName: tab.icon(isSelected: isSelected))
                    // title2 is 22pt at default size and, unlike @ScaledMetric, honours the bar's type-size cap.
                    .font(.title2.weight(isSelected ? .semibold : .regular))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(isSelected ? .vnAccentHeritageRed : .vnTextSecondary)
                    .scaleEffect(isSelected ? 1.08 : 1.0)

                Text(tab.title)
                    .font(.caption2.weight(isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .vnAccentHeritageRed : .vnTextSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: VNLayout.tabBarItemHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
