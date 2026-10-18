import SwiftUI
import VNCalendarDesignSystem

struct MemorialEmptyStateView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: VNSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.vnAccentRedSurface)
                    .frame(width: 84, height: 84)

                Image(systemName: "flame.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.vnAccentHeritageRed)
            }
            .padding(.top, VNSpacing.xl)

            Text("Gìn Giữ Đạo Hiếu Gia Tiên")
                .font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundColor(.vnTextPrimary)

            Text("“Cây có cội mới trổ cành xanh lá\nNước có nguồn mới bủa khắp rạch sông”")
                .font(.system(size: 13, design: .serif))
                .italic()
                .multilineTextAlignment(.center)
                .foregroundColor(.vnTextSecondary)
                .lineSpacing(4)
                .padding(.horizontal, VNSpacing.xl)

            VNButton("Thêm Ngày Giỗ Đầu Tiên", icon: "plus.circle.fill", variant: .primary, size: .medium, action: onAdd)
                .padding(.top, VNSpacing.sm)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, VNSpacing.xl)
    }
}
