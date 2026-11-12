import WidgetKit
import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem

public struct LunarWidgetEntryView: View {
    public let entry: LunarWidgetEntry
    @Environment(\.widgetFamily) var family

    public var body: some View {
        // Spec 06-storekit §FeatureGatePolicy: free tier is small-only. Gate at
        // the view level, NOT via supportedFamilies — that descriptor is cached
        // by SpringBoard, so shrinking it on expiry strands/loses the widget.
        if !LunarDateWidget.isPro && family != .systemSmall {
            lockedWidgetView
        } else {
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
    }

    private var lockedWidgetView: some View {
        VStack(spacing: VNSpacing.sm) {
            Image(systemName: "lock.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(Color.vnAccentGoldText)
            Text("widget.upgrade_title")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.vnTextPrimary)
            Text("widget.upgrade_subtitle")
                .font(.system(size: 10))
                .multilineTextAlignment(.center)
                .foregroundColor(Color.vnTextSecondary)
        }
        .padding(VNSpacing.sm)
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
                .font(.vnDisplay(size: 40, weight: .bold))
                .foregroundColor(Color.vnTextPrimary)

            Spacer()

            HStack {
                VStack(alignment: .leading, spacing: VNSpacing.space2) {
                    Text(String(format: String(localized: "widget.lunar_day_text"), entry.lunarDayText))
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
                        .background(Color.vnAccentJadeSurface)
                        .foregroundColor(Color.vnAccentJade)
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

                Text(String(format: String(localized: "widget.lunar_day_text"), entry.lunarDayText))
                    .font(.vnDisplay(size: 24, weight: .bold))
                    .foregroundColor(Color.vnAccentHeritageRed)

                Text(String(format: String(localized: "widget.year_can_chi"), entry.lunarYearCanChi))
                    .font(.system(size: 11))
                    .foregroundColor(Color.vnTextSecondary)

                if let term = entry.solarTermName {
                    Text(String(format: String(localized: "widget.solar_term_prefix"), term))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color.vnAccentJade)
                }
            }

            Divider()
                .background(Color.vnBorderSubtle.opacity(0.4))

            // Right: Upcoming Reminders / Info
            VStack(alignment: .leading, spacing: VNSpacing.xs) {
                Text("widget.upcoming_header")
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
                        Text(String(format: String(localized: "widget.days_left"), days))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.vnAccentHeritageRed)
                    }
                } else {
                    Text("widget.no_memorial")
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
        Text(String(format: String(localized: "widget.inline_format"), entry.lunarDay, entry.lunarMonth, entry.lunarYearCanChi))
    }

    private var circularLockScreenView: some View {
        VStack(spacing: VNSpacing.space2) {
            Text("\(entry.lunarDay)")
                .font(.system(size: 16, weight: .bold))
            Text("widget.lunar_abbrev")
                .font(.system(size: 9, weight: .semibold))
        }
    }

    private var rectangularLockScreenView: some View {
        VStack(alignment: .leading, spacing: VNSpacing.space2) {
            Text("\(entry.weekdayName), \(entry.solarDay)/\(entry.solarMonth)")
                .font(.system(size: 11, weight: .bold))
            Text(String(format: String(localized: "widget.rectangular_lunar_format"), entry.lunarDayText, entry.lunarYearCanChi))
                .font(.system(size: 11))
            if let term = entry.solarTermName {
                Text(String(format: String(localized: "widget.solar_term_prefix"), term))
                    .font(.system(size: 10))
            }
        }
    }
}

public struct LunarDateWidget: Widget {
    public let kind: String = "LunarDateWidget"

    // Contract shared with SubscriptionManager (App target):
    //   suite = AppConfiguration.current.appGroupIdentifier
    //   key   = "subscription_entitlement" (ProTierType rawValue; absent = free)
    static var isPro: Bool {
        guard let defaults = UserDefaults(suiteName: AppConfiguration.current.appGroupIdentifier) else {
            return false
        }
        return defaults.string(forKey: "subscription_entitlement") != nil
    }

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LunarTimelineProvider()) { entry in
            LunarWidgetEntryView(entry: entry)
                .containerBackground(Color.vnBackgroundPrimary, for: .widget)
        }
        .configurationDisplayName("widget.display_name")
        .description("widget.description")
        // Every family is declared so an expiring subscription never leaves a
        // widget the OS can no longer render. Pro gating happens in the view.
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryInline,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}
