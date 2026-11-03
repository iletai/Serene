import SwiftUI
import VNCalendarDesignSystem

/// Traditional memorial prayer text, presented via `AppSheet.ritual(title:)`.
struct RitualPrayerModal: View {
    @Environment(AppRouter.self) private var router
    let title: String

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: VNSpacing.lg) {
                    VStack(alignment: .leading, spacing: VNSpacing.xs) {
                        HStack(spacing: VNSpacing.xs) {
                            VNSealBadge.gio(size: .medium)

                            Text("VĂN KHẤN TRUYỀN THỐNG")
                                .font(.caption2.weight(.bold))
                                .tracking(1.0)
                                .foregroundColor(.vnAccentHeritageRed)
                        }

                        Text(title)
                            .font(.system(.title2, design: .serif).weight(.bold))
                            .foregroundColor(.vnTextPrimary)

                        Text("Bài văn cúng giỗ chính nhật và tuần tiết gia tiên")
                            .font(.system(.footnote, design: .serif))
                            .italic()
                            .foregroundColor(.vnTextSecondary)
                    }

                    VNRowDivider()

                    VStack(alignment: .leading, spacing: VNSpacing.md) {
                        Text("""
                        Nam mô A Di Đà Phật! (3 lần)

                        Con kính lạy chín phương Trời, mười phương Chư Phật, Chư Phật mười phương.
                        Con kính lạy Hoàng thiên Hậu Thổ chư vị Tôn thần.
                        Con kính lạy ngài Bản cảnh Thành hoàng, ngài Bản xứ Thổ địa, \
                        ngài Bản gia Táo quân cùng chư vị Tôn thần.
                        Con kính lạy Cao Tằng Tổ Khảo, Cao Tằng Tổ Tỷ, Thúc Bá Đệ Huynh, Cô Di Tỷ Muội họ nội họ ngoại.

                        Tín chủ con là: ....................................................
                        Ngụ tại: ................................................................

                        Hôm nay là ngày giỗ chính nhật của: \(title)
                        Thiết nghĩ: Ơn trời biển khó đền, công sinh thành dưỡng dục khôn xiết.
                        Nhớ ngày kỵ nhật, tín chủ con thành tâm sắm sửa phẩm vật hương hoa dâng trước án tọa.

                        Kính cẩn thỉnh mời chân linh tiền nhân quang lâm chứng giám, thụ hưởng lễ vật, \
                        độ trì cho toàn thể gia quyến luôn được an khang thịnh vượng, gia đạo hưng long.

                        Cẩn cáo!
                        Nam mô A Di Đà Phật! (3 lần)
                        """)
                        .font(.system(.subheadline, design: .serif))
                        .foregroundColor(.vnTextPrimary)
                        .lineSpacing(VNSpacing.sm)
                        .padding(VNSpacing.lg)
                        .background(Color.vnBackgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
                        .overlay(
                            RoundedRectangle(cornerRadius: VNCornerRadius.card)
                                .stroke(Color.vnBorderSubtle, lineWidth: VNBorderWidth.hairline)
                        )
                    }
                }
                .padding(VNSpacing.lg)
            }
            .background(Color.vnBackgroundPrimary.ignoresSafeArea())
            .vnNavBar(title: "Văn Khấn Gia Tiên") {
                VNDismissButton(style: .text("Đóng")) { router.dismissModals() }
            }
        }
    }
}
