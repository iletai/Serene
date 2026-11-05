import SwiftUI

private struct VNTabBarHeightKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

public extension EnvironmentValues {
    /// Measured height of the floating tab bar, including its bottom gap (excludes the device safe area).
    var vnTabBarHeight: CGFloat {
        get { self[VNTabBarHeightKey.self] }
        set { self[VNTabBarHeightKey.self] = newValue }
    }
}

private struct VNTabBarClearanceModifier: ViewModifier {
    @Environment(\.vnTabBarHeight) private var tabBarHeight

    func body(content: Content) -> some View {
        // Scroll-content margin (not padding) keeps indicators reaching the screen edge.
        content.contentMargins(.bottom, tabBarHeight, for: .scrollContent)
    }
}

public extension View {
    /// Lets every descendant ScrollView scroll its last row clear of the floating tab bar.
    func vnTabBarClearance() -> some View {
        modifier(VNTabBarClearanceModifier())
    }
}
