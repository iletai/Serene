#if canImport(UIKit)
import UIKit
#endif

public enum VNHapticStyle: Sendable { case light, medium, success }

/// Settings-aware haptics. Callers pass the `hapticFeedbackEnabled` app setting as `enabled`.
public enum VNHaptics {
    /// Pure gate so the setting can be unit tested without UIKit.
    public static func shouldFire(enabled: Bool) -> Bool { enabled }

    @MainActor
    public static func impact(_ style: VNHapticStyle = .light, enabled: Bool) {
        guard shouldFire(enabled: enabled) else { return }
        #if canImport(UIKit)
        switch style {
        case .light: UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium: UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .success: UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        #endif
    }
}
