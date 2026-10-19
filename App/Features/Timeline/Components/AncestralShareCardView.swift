import SwiftUI
import VNCalendarDesignSystem
import VNCalendarDomain
import VNCalendarLunar

public struct AncestralShareCardView: View {
    public let reminder: ReminderEvent
    @Environment(\.dismiss) private var dismiss
    @State private var renderedImage: Image?
    @State private var isShowingShareSheet = false

    public init(reminder: ReminderEvent) {
        self.reminder = reminder
    }

    private var nextDateString: String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = VNTime.vietnam
        let today = cal.startOfDay(for: Date())
        let solarNow = SolarDate(from: today, calendar: cal)

        let nextDate: Date
        if reminder.dateType == .lunar {
            let engine = LunarAstronomicalEngine.shared
            let currentLunar = engine.convertToLunar(from: solarNow)
            var targetLunarYear = currentLunar.year
            if currentLunar.month > reminder.month
                || (currentLunar.month == reminder.month && currentLunar.day > reminder.day) {
                targetLunarYear += 1
            }
            let targetLunar = LunarDate(
                day: reminder.day, month: reminder.month,
                year: targetLunarYear, isLeapMonth: reminder.isLeapMonth
            )
            nextDate = engine.convertToSolar(from: targetLunar).date ?? today
        } else {
            var comps = DateComponents(year: solarNow.year, month: reminder.month, day: reminder.day)
            var date = cal.date(from: comps) ?? today
            if date < today {
                comps.year = solarNow.year + 1
                date = cal.date(from: comps) ?? date
            }
            nextDate = date
        }

        let occ = SolarDate(from: nextDate, calendar: cal)
        return "Ngày \(occ.day) tháng \(occ.month) năm \(occ.year)"
    }

    private var lunarDateString: String {
        "Ngày \(reminder.day) tháng \(reminder.month) Âm Lịch"
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: VNSpacing.lg) {
                // The Visual Shareable Card Canvas
                shareCardCanvas
                    .padding(.horizontal, VNSpacing.xl)
                    .padding(.top, VNSpacing.md)

                Spacer()

                // Actions: Share to Zalo / iMessage
                VStack(spacing: VNSpacing.sm) {
                    VNButton(
                        "Chia Sẻ Thiệp Báo Giỗ Cho Gia Tộc",
                        icon: "square.and.arrow.up",
                        variant: .primary,
                        size: .large,
                        isFullWidth: true
                    ) {
                        shareInvitation()
                    }

                    Button("Đóng") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.vnTextSecondary)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .padding(.horizontal, VNSpacing.xl)
                .padding(.bottom, VNSpacing.xl)
            }
            .background(Color.vnBackgroundPrimary.ignoresSafeArea())
            .vnNavBar(title: "Thiệp Báo Kỵ Nhật")
        }
    }

    // MARK: - Share Card Canvas (Thiệp Báo Giỗ)

    private var shareCardCanvas: some View {
        VStack(spacing: VNSpacing.md) {
            // Top Ceremonial Ribbon
            HStack {
                Spacer()
                VNSealBadge(
                    text: reminder.category == .deathAnniversary ? "KỴ NHẬT" : "HIẾU ĐẠO",
                    shape: .rounded(),
                    color: .cinnabarGold,
                    size: .medium
                )
                Spacer()
            }
            .padding(.top, VNSpacing.sm)

            // Header Title
            VStack(spacing: VNSpacing.xs) {
                Text("THÔNG BÁO NGÀY GIỖ GIA TIÊN")
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .foregroundColor(.vnAccentHeritageRed)
                    .tracking(2.0)

                Text("Kính cáo toàn thể dòng họ & con cháu nội ngoại")
                    .font(.system(size: 11, design: .serif).italic())
                    .foregroundColor(.vnTextSecondary)
            }

            Rectangle()
                .fill(Color.vnOldRiceBorder)
                .frame(height: 1)
                .padding(.horizontal, VNSpacing.md)

            // Member Info
            VStack(spacing: VNSpacing.xs) {
                if let rel = reminder.relationship, !rel.isEmpty {
                    Text(rel.uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.vnAccentImperialGold)
                        .padding(.horizontal, VNSpacing.sm)
                        .padding(.vertical, VNSpacing.space2)
                        .background(Color.vnAccentGoldSurface)
                        .clipShape(Capsule())
                }

                Text(reminder.title)
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundColor(.vnTextPrimary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, VNSpacing.xs)

            // Date Cluster Box
            VStack(spacing: VNSpacing.sm) {
                HStack(spacing: VNSpacing.md) {
                    VStack(alignment: .leading, spacing: VNSpacing.space2) {
                        Text("NGÀY ÂM LỊCH")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.vnTextSecondary)
                        Text(lunarDateString)
                            .font(.system(size: 14, weight: .bold, design: .serif))
                            .foregroundColor(.vnAccentHeritageRed)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: VNSpacing.space2) {
                        Text("DƯƠNG LỊCH NĂM NAY")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.vnTextSecondary)
                        Text(nextDateString)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.vnTextPrimary)
                    }
                }
                .padding(VNSpacing.md)
                .background(Color.vnBackgroundPrimary)
                .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: VNCornerRadius.card)
                        .strokeBorder(Color.vnBorderSubtle, lineWidth: VNBorderWidth.hairline)
                )
            }
            .padding(.horizontal, VNSpacing.sm)

            if let note = reminder.note, !note.isEmpty {
                Text("Địa điểm / Lời dặn: \(note)")
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .foregroundColor(.vnTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, VNSpacing.md)
            }

            // Footer Stamp
            HStack {
                Text("AN NIÊN • LỊCH VIỆT & NGÀY NHỚ")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.vnTextTertiary)
                    .tracking(1.0)

                Spacer()

                VNSealBadge(text: "AN NIÊN", shape: .square, color: .cinnabarWhite, size: .small)
            }
            .padding(.horizontal, VNSpacing.md)
            .padding(.top, VNSpacing.xs)
            .padding(.bottom, VNSpacing.sm)
        }
        .padding(VNSpacing.xl)
        .background(Color.vnBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.card)
                .strokeBorder(Color.vnAccentImperialGold.opacity(0.4), lineWidth: VNBorderWidth.active)
        )
        .shadow(color: VNShadow.card.color, radius: VNShadow.card.radius, x: VNShadow.card.x, y: VNShadow.card.y)
    }

    private func shareInvitation() {
        let text = """
        [THÔNG BÁO NGÀY GIỖ GIA TIÊN]
        Kính nhớ: \(reminder.title) (\(reminder.relationship ?? "Tiền nhân"))
        • Ngày Âm lịch: \(lunarDateString)
        • Ngày Dương lịch năm nay: \(nextDateString)
        \(reminder.note.map { "• Lời dặn: \($0)" } ?? "")
        Kính mời toàn thể gia tộc tề tựu phụng sự đạo hiếu.
        — Ứng dụng An Niên (Lịch Việt & Ngày Nhớ)
        """

        #if canImport(UIKit)
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
        #endif
    }
}
