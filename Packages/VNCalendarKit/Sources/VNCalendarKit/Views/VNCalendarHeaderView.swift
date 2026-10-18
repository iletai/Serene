import SwiftUI
import VNCalendarDesignSystem
import VNCalendarLunar

public struct VNCalendarHeaderView: View {
    public let displayMode: VNCalendarDisplayMode
    public let monthDate: Date
    public let onPrevious: () -> Void
    public let onNext: () -> Void
    public let onToday: () -> Void

    public init(
        displayMode: VNCalendarDisplayMode = .month,
        monthDate: Date,
        onPrevious: @escaping () -> Void,
        onNext: @escaping () -> Void,
        onToday: @escaping () -> Void
    ) {
        self.displayMode = displayMode
        self.monthDate = monthDate
        self.onPrevious = onPrevious
        self.onNext = onNext
        self.onToday = onToday
    }

    public var body: some View {
        HStack(alignment: .center) {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.vnTextSecondary)
                    .frame(width: 36, height: 36)
                    .background(Color.vnBackgroundSecondary, in: RoundedRectangle(cornerRadius: VNCornerRadius.card))
                    .overlay(
                        RoundedRectangle(cornerRadius: VNCornerRadius.card)
                            .stroke(Color.vnBorderSubtle, lineWidth: VNBorderWidth.hairline)
                    )
            }
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .buttonStyle(.plain)
            .accessibilityLabel("Tháng trước")

            Spacer()

            VStack(spacing: VNSpacing.space2) {
                Text(headerTitle)
                    .font(.system(size: 19, weight: .bold, design: .serif))
                    .foregroundColor(.vnTextPrimary)

                if let subtitle = headerSubtitle {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.vnTextSecondary)
                }
            }

            Spacer()

            HStack(spacing: VNSpacing.xs) {
                Button(action: onToday) {
                    Text("Hôm nay")
                        .font(.system(size: 12, weight: .semibold, design: .serif))
                        .padding(.horizontal, VNSpacing.sm)
                        .padding(.vertical, VNSpacing.xs)
                        .background(Color.vnGoldContainer)
                        .foregroundColor(.vnOnGoldContainer)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.vnAccentImperialGold.opacity(0.4), lineWidth: VNBorderWidth.hairline)
                        )
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
                .buttonStyle(.plain)
                .accessibilityLabel("Hôm nay")

                Button(action: onNext) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.vnTextSecondary)
                        .frame(width: 36, height: 36)
                        .background(Color.vnBackgroundSecondary, in: RoundedRectangle(cornerRadius: VNCornerRadius.card))
                        .overlay(
                            RoundedRectangle(cornerRadius: VNCornerRadius.card)
                                .stroke(Color.vnBorderSubtle, lineWidth: VNBorderWidth.hairline)
                        )
                }
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
                .buttonStyle(.plain)
                .accessibilityLabel("Tháng sau")
            }
        }
        .padding(.horizontal, VNSpacing.xl)
        .padding(.vertical, VNSpacing.xs)
    }

    private var headerTitle: String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? TimeZone(secondsFromGMT: 7 * 3600) ?? .current
        let month = cal.component(.month, from: monthDate)
        let year = cal.component(.year, from: monthDate)

        switch displayMode {
        case .block:
            let day = cal.component(.day, from: monthDate)
            return "Ngày \(day) Tháng \(month), \(year)"
        case .month:
            return "Tháng \(month), \(year)"
        case .week:
            let week = cal.component(.weekOfYear, from: monthDate)
            return "Tuần \(week) • Tháng \(month), \(year)"
        case .year:
            return "Năm \(year)"
        }
    }

    private var headerSubtitle: String? {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? TimeZone(secondsFromGMT: 7 * 3600) ?? .current
        let solar = SolarDate(from: monthDate, calendar: cal)
        let fullCanChi = LunarAstronomicalEngine.shared.computeCanChi(for: solar)

        switch displayMode {
        case .year:
            return "Năm \(fullCanChi.year.description)"
        case .block, .month, .week:
            return "Năm \(fullCanChi.year.description) • Tháng \(fullCanChi.month.description)"
        }
    }
}
