import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public enum VNHapticStyle: Sendable { case light, medium, success }

/// Settings-aware haptics. Callers pass the `hapticFeedbackEnabled` app setting as `enabled`.
public enum VNHaptics {
    /// `@AppStorage` key of the Settings toggle.
    public static let settingKey = "hapticFeedbackEnabled"

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

private struct VNFeedbackModifier<T: Equatable>: ViewModifier {
    @AppStorage(VNHaptics.settingKey) private var hapticsOn = true
    let feedback: SensoryFeedback
    let trigger: T

    func body(content: Content) -> some View {
        content.sensoryFeedback(trigger: trigger) { _, _ in hapticsOn ? feedback : nil }
    }
}

public extension View {
    /// Selection tick when `trigger` changes (pickers, chips, toggles). Honors the haptics setting.
    func vnSelectionFeedback<T: Equatable>(trigger: T) -> some View {
        modifier(VNFeedbackModifier(feedback: .selection, trigger: trigger))
    }

    /// Light impact when `trigger` changes (button taps). Honors the haptics setting.
    func vnImpactFeedback<T: Equatable>(trigger: T) -> some View {
        modifier(VNFeedbackModifier(feedback: .impact(weight: .light), trigger: trigger))
    }

    /// Success notification haptic when `trigger` changes (save done). Honors the haptics setting.
    func vnSuccessFeedback<T: Equatable>(trigger: T) -> some View {
        modifier(VNFeedbackModifier(feedback: .success, trigger: trigger))
    }
}
