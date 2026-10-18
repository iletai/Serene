import WidgetKit
import SwiftUI
import VNCalendarDesignSystem

public struct LunarWidgetEntryView: View {
    public let entry: LunarWidgetEntry
    @Environment(\.widgetFamily) var family

    public var body: some View {
        switch family {
        case .systemSmall:
            smallWidgetView
        case .systemMedium:
            mediumWidgetView
        case .accessoryInline:
            inlineLockScreenView
        case .accessoryCircular:
            circularLockScreenView
        case .accessoryRectangular:
            rectangularLockScreenView
        default:
            smallWidgetView
        }
    }

    private var smallWidgetView: some View {
        VStack(alignment: .leading, spacing: VNSpacing.space2) {
            HStack {
                Text(entry.weekdayName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.vnTextSecondary)
                Spacer()
                Text("\(entry.solarMonth)/\(entry.solarYear)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color.vnTextSecondary)
            }

            Spacer()

            Text("\(entry.solarDay)")
                .font(.system(size: 40, weight: .bold, design: .serif))
                .foregroundColor(Color.vnTextPrimary)

            Spacer()

            HStack {
                VStack(alignment: .leading, spacing: VNSpacing.space2) {
                    Text("\(entry.lunarDayText) ÂL")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.vnAccentHeritageRed)
                    Text(entry.lunarYearCanChi)
                        .font(.system(size: 10))
                        .foregroundColor(Color.vnTextSecondary)
                }
                Spacer()
                if let term = entry.solarTermName {
                    Text(term)
                        .font(.system(size: 9, weight: .semibold))
                        .padding(.horizontal, VNSpacing.xs)
                        .padding(.vertical, VNSpacing.space2)
                        .background(Color.vnAccentImperialGold.opacity(0.15))
                        .foregroundColor(Color.vnAccentImperialGold)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(VNSpacing.md)
        .background(Color.vnBackgroundPrimary)
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.card)
                .stroke(Color.vnBorderSubtle.opacity(0.4), lineWidth: VNBorderWidth.hairline)
        )
    }

    private var mediumWidgetView: some View {
        HStack(spacing: VNSpacing.lg) {
            // Left: Date Info
            VStack(alignment: .leading, spacing: VNSpacing.xs) {
                Text("\(entry.weekdayName), \(entry.solarDay)/\(entry.solarMonth)/\(entry.solarYear)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.vnTextSecondary)

                Text("\(entry.lunarDayText) ÂL")
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundColor(Color.vnAccentHeritageRed)

                Text("Năm \(entry.lunarYearCanChi)")
                    .font(.system(size: 11))
                    .foregroundColor(Color.vnTextSecondary)

                if let term = entry.solarTermName {
                    Text("Tiết \(term)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color.vnAccentImperialGold)
                }
            }

            Divider()
                .background(Color.vnBorderSubtle.opacity(0.4))

            // Right: Upcoming Reminders / Info
            VStack(alignment: .leading, spacing: VNSpacing.xs) {
                Text("NGÀY NHỚ SẮP TỚI")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color.vnTextSecondary)

                if let title = entry.nextMemorialTitle, let days = entry.nextMemorialDaysLeft {
                    HStack {
                        Circle()
                            .fill(Color.vnAccentHeritageRed)
                            .frame(width: 4, height: 4)
                        Text(title)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.vnTextPrimary)
                        Spacer()
                        Text("Còn \(days) ngày")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.vnAccentHeritageRed)
                    }
                } else {
                    Text("Không có ngày giỗ trong 7 ngày tới.")
                        .font(.system(size: 11))
                        .foregroundColor(Color.vnTextTertiary)
                }
            }
        }
        .padding(VNSpacing.lg)
        .background(Color.vnBackgroundPrimary)
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.card)
                .stroke(Color.vnBorderSubtle.opacity(0.4), lineWidth: VNBorderWidth.hairline)
        )
    }

    private var inlineLockScreenView: some View {
        Text("\(entry.lunarDay)/\(entry.lunarMonth) ÂL • \(entry.lunarYearCanChi)")
    }

    private var circularLockScreenView: some View {
        VStack(spacing: VNSpacing.space2) {
            Text("\(entry.lunarDay)")
                .font(.system(size: 16, weight: .bold))
            Text("ÂL")
                .font(.system(size: 9, weight: .semibold))
        }
    }

    private var rectangularLockScreenView: some View {
        VStack(alignment: .leading, spacing: VNSpacing.space2) {
            Text("\(entry.weekdayName), \(entry.solarDay)/\(entry.solarMonth)")
                .font(.system(size: 11, weight: .bold))
            Text("Âm Lịch: \(entry.lunarDayText) • \(entry.lunarYearCanChi)")
                .font(.system(size: 11))
            if let term = entry.solarTermName {
                Text("Tiết \(term)")
                    .font(.system(size: 10))
            }
        }
    }
}

public struct LunarDateWidget: Widget {
    public let kind: String = "LunarDateWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LunarTimelineProvider()) { entry in
            LunarWidgetEntryView(entry: entry)
                .containerBackground(Color.vnBackgroundPrimary, for: .widget)
        }
        .configurationDisplayName("Lịch Âm An Niên")
        .description("Xem ngày Âm lịch, Can Chi, Tiết khí và ngày giỗ gia đình.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryInline,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}
