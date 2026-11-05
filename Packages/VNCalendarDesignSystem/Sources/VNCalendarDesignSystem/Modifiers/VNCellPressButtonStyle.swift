import SwiftUI

/// Press feedback for tappable cells, cards and rows: scale + dim, springy release.
/// Respects Reduce Motion (opacity only). Pass `haptic: true` for a light impact on press,
/// gated by the `hapticFeedbackEnabled` setting.
/// Use the default scale for grid cells; pass a subtler scale (e.g. 0.98) for full-width cards/rows.
public struct VNCellPressButtonStyle: ButtonStyle {
    private let pressedScale: CGFloat
    private let haptic: Bool

    public init(pressedScale: CGFloat = 0.94, haptic: Bool = false) {
        self.pressedScale = pressedScale
        self.haptic = haptic
    }

    public func makeBody(configuration: Configuration) -> some View {
        VNPressBody(isPressed: configuration.isPressed, scale: pressedScale, haptic: haptic, label: configuration.label)
    }
}

/// Row press feedback: tinted highlight, no scale. For list rows inside `VNGroupCard`.
public struct VNRowPressButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Color.vnBackgroundTertiary.opacity(configuration.isPressed ? 0.7 : 0))
            .vnAnimation(configuration.isPressed ? VNAnimation.pressDown : VNAnimation.press, value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == VNCellPressButtonStyle {
    /// `.buttonStyle(.vnPress)`
    static var vnPress: VNCellPressButtonStyle { VNCellPressButtonStyle() }
    /// `.buttonStyle(.vnPress(scale: 0.98, haptic: true))`
    static func vnPress(scale: CGFloat, haptic: Bool = false) -> VNCellPressButtonStyle {
        VNCellPressButtonStyle(pressedScale: scale, haptic: haptic)
    }
}

public extension ButtonStyle where Self == VNRowPressButtonStyle {
    static var vnRowPress: VNRowPressButtonStyle { VNRowPressButtonStyle() }
}

private struct VNPressBody<Label: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(VNHaptics.settingKey) private var hapticsOn = true
    let isPressed: Bool
    let scale: CGFloat
    let haptic: Bool
    let label: Label

    var body: some View {
        label
            .scaleEffect(isPressed && !reduceMotion ? scale : 1)
            .opacity(isPressed ? 0.88 : 1)
            .animation(animation, value: isPressed)
            .sensoryFeedback(trigger: isPressed) { _, pressed in
                haptic && hapticsOn && pressed ? .impact(weight: .light) : nil
            }
    }

    private var animation: Animation {
        reduceMotion ? VNAnimation.reduced : (isPressed ? VNAnimation.pressDown : VNAnimation.press)
    }
}
