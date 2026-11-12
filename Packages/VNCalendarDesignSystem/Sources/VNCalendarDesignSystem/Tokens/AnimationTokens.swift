import SwiftUI

public enum VNAnimation {
    // Chuyển Tháng Lưới Lịch (Smooth Horizontal Paging)
    public static let monthTransition = Animation.spring(
        response: 0.45,
        dampingFraction: 0.82,
        blendDuration: 0.1
    )

    // Chạm Chọn Ô Lịch (Snappy Day Selection Pulse)
    public static let cellSelection = Animation.spring(
        response: 0.28,
        dampingFraction: 0.70,
        blendDuration: 0
    )

    // Trượt Bottom Sheet (Bouncy Sheet Detents)
    public static let sheetSpring = Animation.spring(
        response: 0.45,
        dampingFraction: 0.78,
        blendDuration: 0.15
    )

    // Mở Thẻ Thông Tin Mở Rộng
    public static let cardExpansion = Animation.snappy(
        duration: 0.35,
        extraBounce: 0.08
    )

    // MARK: - Motion tokens (see docs/architecture/10-motion.md). Interactive motion is over within 0.6s.

    /// Press release: springs back with a slight overshoot.
    public static let press = Animation.spring(response: 0.42, dampingFraction: 0.55)
    /// Press down: 0.10s ease-out, immediate and non-bouncy so touch feels instant.
    public static let pressDown = Animation.easeOut(duration: 0.10)
    /// Selection / focus / toggle state change: snappy 0.30s with bounce.
    public static let selection = Animation.snappy(duration: 0.30, extraBounce: 0.25)
    /// Content entrance (fade + 16pt rise).
    public static let appear = Animation.spring(response: 0.52, dampingFraction: 0.85)
    /// Layout change (insert/remove/reorder, text swap): smooth 0.3s.
    public static let layout = Animation.smooth(duration: 0.3)
    /// Expand / collapse of a container: snappy 0.35s with a slight bounce.
    public static let expand = Animation.snappy(duration: 0.35, extraBounce: 0.08)
    /// Reduce Motion fallback: a short 0.15s fade, never movement.
    public static let reduced = Animation.easeOut(duration: 0.15)
}
