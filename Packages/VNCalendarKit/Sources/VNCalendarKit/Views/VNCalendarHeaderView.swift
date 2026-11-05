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
            .accessibilityLabel("calendar.header.accessibility.prev_month")

            VStack(spacing: VNSpacing.space2) {
                Text(headerTitle)
                    .font(.system(size: 19, weight: .bold, design: .serif))
                    .foregroundColor(.vnTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if let subtitle = headerSubtitle {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.vnTextSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .frame(maxWidth: .infinity)
            .layoutPriority(1)

            HStack(spacing: VNSpacing.xs) {
                Button(action: onToday) {
                    Text("action.today")
                        .font(.system(size: 12, weight: .semibold, design: .serif))
                        .lineLimit(1)
                        .fixedSize()
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
                .accessibilityLabel("action.today")

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
                .accessibilityLabel("calendar.header.accessibility.next_month")
            }
        }
        .padding(.horizontal, VNSpacing.screenMargin)
        .padding(.vertical, VNSpacing.xs)
        // Header chrome caps its growth so title/subtitle stay on single lines at xxxl.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    private var headerTitle: String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = VNTime.vietnam
        let month = cal.component(.month, from: monthDate)
        let year = cal.component(.year, from: monthDate)

        switch displayMode {
        case .block:
            let day = cal.component(.day, from: monthDate)
            return String(format: String(localized: "calendar.header.title.block"), day, month, year)
        case .month:
            return String(format: String(localized: "calendar.header.title.month"), month, year)
        case .week:
            let week = cal.component(.weekOfYear, from: monthDate)
            return String(format: String(localized: "calendar.header.title.week"), week, month, year)
        case .year:
            return String(format: String(localized: "calendar.header.title.year"), year)
        }
    }

    private var headerSubtitle: String? {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = VNTime.vietnam
        let solar = SolarDate(from: monthDate, calendar: cal)
        let fullCanChi = LunarAstronomicalEngine.shared.computeCanChi(for: solar)

        switch displayMode {
        case .year:
            return String(format: String(localized: "calendar.header.subtitle.year_canchi"), fullCanChi.year.description)
        case .block, .month, .week:
            return String(format: String(localized: "calendar.header.subtitle.year_month_canchi"), fullCanChi.year.description, fullCanChi.month.description)
        }
    }
}
