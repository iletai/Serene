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
            return String(localized: "tab.calendar")
        case .memorial:
            return String(localized: "tab.memorials")
        case .family:
            return String(localized: "tab.family")
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(AdsManager.self) private var ads: AdsManager?
    @Namespace private var pillNamespace
    /// Tabs shown at least once; unvisited tabs stay unbuilt (TabView's lazy behaviour) while visited ones keep state.
    @State private var visitedTabs: Set<MainTab> = [.calendar]
    /// Measured pill height, published to tab roots and pushed screens via `vnTabBarHeight`.
    @State private var tabBarHeight: CGFloat = 0

    init(pendingDeepLink: Binding<DeepLinkHandler.Action?> = .constant(nil)) {
        _pendingDeepLink = pendingDeepLink
        _routers = State(initialValue: MainTab.allCases.map { _ in AppRouter() })
    }

    public var body: some View {
        // ZStack instead of TabView: TabView swaps instantly with no hook for a transition.
        ZStack {
            ForEach(MainTab.allCases) { tab in
                if visitedTabs.contains(tab) {
                    tabContainer(for: tab)
                        .opacity(selectedTab == tab ? 1 : 0)
                        .offset(x: reduceMotion || selectedTab == tab ? 0 : slideOffset(for: tab))
                        .allowsHitTesting(selectedTab == tab)
                        .accessibilityHidden(selectedTab != tab)
                        .zIndex(selectedTab == tab ? 1 : 0)
                }
            }
        }
        .animation(tabAnimation, value: selectedTab)
        .onChange(of: selectedTab, initial: true) { _, tab in visitedTabs.insert(tab) }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        // Overlay + measured height: safeAreaInset does not reliably reach content hosted inside NavigationStack,
        // so each tab/pushed screen applies vnTabBarClearance() (contentMargins) from this environment value.
        .overlay(alignment: .bottom) {
            VStack(spacing: 0) {
                if ads?.canShowAds == true {
                    BannerAdView().frame(width: 320, height: BannerAdView.height)
                }
                customBottomTabBar
            }
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { tabBarHeight = $0 }
        }
        .environment(\.vnTabBarHeight, tabBarHeight)
        .onChange(of: pendingDeepLink, initial: true) { _, action in
            guard let action else { return }
            handle(action)
            pendingDeepLink = nil
        }
    }

    private var tabAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.15) : .smooth(duration: 0.3)
    }

    /// Inactive tabs rest slightly to the side of the selected one so switching reads as a gentle slide.
    private func slideOffset(for tab: MainTab) -> CGFloat {
        tab.rawValue < selectedTab.rawValue ? -Self.slideDistance : Self.slideDistance
    }

    private static let slideDistance: CGFloat = 24

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
            // Pill stays visible on push, so pushed screens keep the clearance; sheets cover the pill and skip it.
            destination: { AppRouteView(route: $0).vnTabBarClearance() },
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
        .vnTabBarClearance()
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
        .padding(.vertical, VNSpacing.sm)
        .frame(maxWidth: VNLayout.tabBarMaxWidth)
        // Bar chrome caps its growth like the system tab bar so labels never truncate.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .background {
            Capsule()
                .fill(Color.vnSurfaceElevated.opacity(0.85))
                .background(.ultraThinMaterial, in: Capsule())
        }
        .overlay(Capsule().stroke(Color.vnBorderSubtle.opacity(0.4), lineWidth: VNBorderWidth.hairline))
        // Floating bar shadow, not the folio card shadow.
        .shadow(color: VNShadow.floating.color, radius: VNShadow.floating.radius,
                x: VNShadow.floating.x, y: VNShadow.floating.y)
        .padding(.horizontal, VNSpacing.lg)
        .padding(.bottom, VNLayout.tabBarBottomInset)
    }

    private func tabButton(for tab: MainTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            VNHaptics.impact(enabled: hapticFeedbackEnabled)
            withAnimation(tabAnimation) {
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
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, value: reduceMotion ? false : isSelected)

                Text(tab.title)
                    .font(.vnDisplay(.caption2, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .vnAccentDeepPrimary : .vnTextSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: VNLayout.tabBarItemHeight)
            .contentShape(Rectangle())
            .background {
                if isSelected {
                    Capsule()
                        .fill(Color.vnAccentRedSurface)
                        .matchedGeometryEffect(id: "selectedPill", in: pillNamespace)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
