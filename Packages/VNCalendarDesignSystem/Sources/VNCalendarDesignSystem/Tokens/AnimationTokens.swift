import SwiftUI

public enum VNAnimation {
    // Chuyển Tháng Lưới Lịch (Smooth Horizontal Paging)
    public static let monthTransition = Animation.spring(
        response: 0.38,
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
}
