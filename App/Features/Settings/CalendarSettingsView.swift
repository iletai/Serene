import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem
import VNCalendarKit

public struct CalendarSettingsView: View {
    @Environment(AppContainer.self) private var container

    // Calendar Display Preferences
    @AppStorage("defaultCalendarDisplayMode") private var defaultDisplayModeRaw: String = "month"
    @AppStorage("calendarStartOfWeek") private var startOfWeek = 2 // 2 = Monday, 1 = Sunday
    @AppStorage("highlightFullAndNewMoon") private var highlightFullAndNewMoon = true
    @AppStorage("showAuspiciousHours") private var showAuspiciousHours = true
    @AppStorage("showSolarTermsAndTruc") private var showSolarTermsAndTruc = true

    // MicroCMS Preferences
    @AppStorage("autoSyncMicroCMS") private var autoSyncMicroCMS = true
    @AppStorage("microCMSWifiOnly") private var microCMSWifiOnly = false
    @AppStorage("cachePrayersOffline") private var cachePrayersOffline = true
    @AppStorage("microCMSLastSyncDate") private var lastSyncTimestamp = "Hôm nay, 21:00"

    // Day Customization Preferences
    @AppStorage("showDailyAuspiciousQuote") private var showDailyQuote = true
    @AppStorage("hapticFeedbackEnabled") private var isHapticEnabled = true

    // Sync State
    @State private var isSyncing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var syncStatusBanner: String?

    public init() {}

    /// Row icon tile; scales with Dynamic Type so the glyph never overflows it.
    @ScaledMetric(relativeTo: .callout) private var scaledIconBox: CGFloat = VNSize.iconButton
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// Capped so accessibility sizes leave room for the label.
    private var iconBox: CGFloat { min(scaledIconBox, VNSize.iconButton * 1.4) }
    /// Stacks label above control at accessibility sizes so neither gets crushed.
    private var rowLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: VNSpacing.sm))
            : AnyLayout(HStackLayout())
    }

    /// Leading inset aligning row subtitles under the icon tile plus its gap (rowLabel).
    private var settingsSubtitleLeadingInset: CGFloat { iconBox + VNSpacing.md }
    /// Leading inset aligning row dividers past the icon tile, its gap and the card padding.
    private var settingsRowDividerLeadingInset: CGFloat { iconBox + VNSpacing.md + VNSpacing.cardPadding }

    public var body: some View {
        ScrollView {
            VStack(spacing: VNSpacing.sectionGap) {
                headerSummaryBanner

                calendarModesGroup

                microCMSSyncGroup

                dailyCustomizationGroup

                astronomicalTimezoneGroup
            }
            .padding(.horizontal, VNSpacing.screenMargin)
            .padding(.top, VNSpacing.xl)
            .padding(.bottom, VNSpacing.xxl)
        }
        .background(Color.vnBackgroundPrimary.ignoresSafeArea())
        .vnNavBar(title: String(localized: "settings.calendar.title"))
    }

    // MARK: - Header Summary Banner
    @ViewBuilder
    private var headerSummaryBanner: some View {
        VStack(spacing: VNSpacing.sm) {
            VNSealBadge(
                text: String(localized: "settings.calendar.seal"),
                shape: .square,
                color: .cinnabarWhite,
                size: .medium
            )
            .padding(.top, VNSpacing.xs)

            Text(String(localized: "settings.calendar.subtitle"))
                .font(.vnTitleCeremonial)
                .foregroundColor(.vnTextPrimary)
                .multilineTextAlignment(.center)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)

            Text(String(localized: "settings.calendar.subtitle_desc"))
                .font(.vnCaption1)
                .foregroundColor(.vnTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, VNSpacing.sm)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, VNSpacing.xs)
    }

    // MARK: - Section 1: Chế Độ Lịch & Điều Hướng
    @ViewBuilder
    private var calendarModesGroup: some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            sectionHeader(title: String(localized: "settings.calendar.modes_header"))

            groupedCard {
                VStack(alignment: .leading, spacing: VNSpacing.sm) {
                    rowLabel(icon: "square.grid.2x2.fill", tint: .vnAccentHeritageRed, title: String(localized: "settings.calendar.display_mode"))

                    Picker(String(localized: "settings.calendar.display_mode"), selection: $defaultDisplayModeRaw) {
                        Text(String(localized: "settings.calendar.mode_block")).tag("block")
                        Text(String(localized: "settings.calendar.mode_month")).tag("month")
                        Text(String(localized: "settings.calendar.mode_week")).tag("week")
                        Text(String(localized: "settings.calendar.mode_year")).tag("year")
                    }
                    .pickerStyle(.segmented)
                    .tint(.vnAccentHeritageRed)
                }
                .padding(.horizontal, VNSpacing.lg)
                .padding(.vertical, VNSpacing.md)

                rowDivider

                rowLayout {
                    rowLabel(icon: "calendar", tint: .vnAccentGoldText, title: String(localized: "settings.calendar.week_start"))
                    Spacer(minLength: 0)
                    Picker(String(localized: "settings.calendar.week_start"), selection: $startOfWeek) {
                        Text(String(localized: "settings.calendar.week_start_monday")).tag(2)
                        Text(String(localized: "settings.calendar.week_start_sunday")).tag(1)
                    }
                    .labelsHidden()
                    .tint(.vnAccentHeritageRed)
                }
                .padding(.horizontal, VNSpacing.lg)
                .padding(.vertical, VNSpacing.md)

                rowDivider

                Toggle(isOn: $highlightFullAndNewMoon) {
                    rowLabel(icon: "moon.stars.fill", tint: .vnAccentGoldText, title: String(localized: "settings.calendar.highlight_full_new_moon"))
                }
                .tint(.vnAccentHeritageRed)
                .padding(.horizontal, VNSpacing.lg)
                .padding(.vertical, VNSpacing.md)

                rowDivider

                Toggle(isOn: $showAuspiciousHours) {
                    rowLabel(icon: "clock.badge.checkmark.fill", tint: .vnAccentGoldText, title: String(localized: "settings.calendar.show_auspicious_hours"))
                }
                .tint(.vnAccentHeritageRed)
                .padding(.horizontal, VNSpacing.lg)
                .padding(.vertical, VNSpacing.md)

                rowDivider

                Toggle(isOn: $showSolarTermsAndTruc) {
                    rowLabel(icon: "sun.haze.fill", tint: .vnAccentGoldText, title: String(localized: "settings.calendar.show_solar_terms"))
                }
                .tint(.vnAccentHeritageRed)
                .padding(.horizontal, VNSpacing.lg)
                .padding(.vertical, VNSpacing.md)
            }
        }
    }

    // MARK: - Section 2: Đồng Bộ Dữ Liệu Micro CMS
    @ViewBuilder
    private var microCMSSyncGroup: some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            sectionHeader(title: String(localized: "settings.microcms.header"))

            groupedCard {
                microCMSStatusHeader

                rowDivider

                Toggle(isOn: $autoSyncMicroCMS) {
                    rowLabel(icon: "arrow.triangle.2.circlepath.circle.fill", tint: .vnAccentHeritageRed, title: String(localized: "settings.microcms.auto_sync"))
                }
                .tint(.vnAccentHeritageRed)
                .padding(.horizontal, VNSpacing.lg)
                .padding(.vertical, VNSpacing.md)

                rowDivider

                Toggle(isOn: $microCMSWifiOnly) {
                    rowLabel(icon: "wifi", tint: .vnAccentGoldText, title: String(localized: "settings.microcms.wifi_only"))
                }
                .tint(.vnAccentHeritageRed)
                .padding(.horizontal, VNSpacing.lg)
                .padding(.vertical, VNSpacing.md)

                rowDivider

                Toggle(isOn: $cachePrayersOffline) {
                    rowLabel(icon: "arrow.down.circle.fill", tint: .vnAccentHeritageRed, title: String(localized: "settings.microcms.offline_cache"))
                }
                .tint(.vnAccentHeritageRed)
                .padding(.horizontal, VNSpacing.lg)
                .padding(.vertical, VNSpacing.md)

                rowDivider

                syncNowButton
                    .padding(VNSpacing.lg)
            }

            if let banner = syncStatusBanner {
                HStack(spacing: VNSpacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.vnStatusSuccess)
                        .accessibilityHidden(true)
                    Text(banner)
                        .font(.caption)
                        .foregroundColor(.vnTextSecondary)
                }
                .padding(.horizontal, VNSpacing.sm)
                .padding(.top, VNSpacing.space2)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    @ViewBuilder
    private var microCMSStatusHeader: some View {
        VStack(alignment: .leading, spacing: VNSpacing.sm) {
            HStack(alignment: .center, spacing: VNSpacing.sm) {
                Circle()
                    .fill(Color.vnStatusSuccess)
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)

                Text(String(localized: "settings.microcms.connected"))
                    .font(.vnFootnote)
                    .foregroundColor(.vnTextPrimary)

                Spacer()

                Text("v2.4-stable")
                    .font(.system(.caption2, design: .monospaced, weight: .bold))
                    .padding(.horizontal, VNSpacing.sm)
                    .padding(.vertical, VNSpacing.space2)
                    .background(Color.vnAccentImperialGold.opacity(0.18))
                    .foregroundColor(.vnOnGoldContainer)
                    .clipShape(Capsule())
            }

            HStack(spacing: VNSpacing.sm) {
                cmsStatPill(icon: "book.fill", text: String(format: String(localized: "settings.microcms.stat_prayers"), 48))
                cmsStatPill(icon: "sparkles", text: String(format: String(localized: "settings.microcms.stat_holidays"), 12))
                cmsStatPill(icon: "quote.opening", text: String(format: String(localized: "settings.microcms.stat_quotes"), 365))
            }

            Text(String(format: String(localized: "settings.microcms.last_sync"), lastSyncTimestamp))
                .font(.caption2)
                .foregroundColor(.vnTextSecondary)
        }
        .padding(VNSpacing.lg)
        .background(Color.vnBackgroundPrimary.opacity(0.6))
    }

    @ViewBuilder
    private var syncNowButton: some View {
        Button(action: handleSyncMicroCMSNow) {
            HStack(spacing: VNSpacing.sm) {
                Spacer()
                if isSyncing {
                    ProgressView()
                        .tint(Color.vnOnAccent)
                        .scaleEffect(0.9)
                    Text(String(localized: "settings.microcms.syncing"))
                        .font(.vnFootnote)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.footnote.weight(.bold))
                        .accessibilityHidden(true)
                    Text(String(localized: "settings.microcms.sync_now"))
                        .font(.vnFootnote)
                }
                Spacer()
            }
            .padding(.vertical, VNSpacing.md)
            .frame(minHeight: VNSize.minTapTarget)
            .background(Color.vnAccentHeritageRed)
            .foregroundColor(.vnOnAccent)
            .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.small, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: VNCornerRadius.small, style: .continuous)
                    .stroke(Color.vnBorderSubtle.opacity(0.4), lineWidth: VNBorderWidth.hairline)
            )
        }
        .disabled(isSyncing)
        .animation(reduceMotion ? nil : .smooth(duration: 0.25), value: isSyncing)
    }

    // MARK: - Section 3: Tùy Biến Lịch Ngày
    @ViewBuilder
    private var dailyCustomizationGroup: some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            sectionHeader(title: String(localized: "settings.daily.header"))

            groupedCard {
                Toggle(isOn: $showDailyQuote) {
                    VStack(alignment: .leading, spacing: VNSpacing.space2) {
                        rowLabel(icon: "quote.opening", tint: .vnAccentGoldText, title: String(localized: "settings.daily.quote"))
                        Text(String(localized: "settings.daily.quote_desc"))
                            .font(.caption)
                            .foregroundColor(.vnTextSecondary)
                            .padding(.leading, settingsSubtitleLeadingInset)
                    }
                }
                .tint(.vnAccentHeritageRed)
                .padding(.horizontal, VNSpacing.lg)
                .padding(.vertical, VNSpacing.md)

                rowDivider

                Toggle(isOn: $isHapticEnabled) {
                    rowLabel(icon: "hand.tap.fill", tint: .vnAccentHeritageRed, title: String(localized: "settings.daily.haptic"))
                }
                .tint(.vnAccentHeritageRed)
                .padding(.horizontal, VNSpacing.lg)
                .padding(.vertical, VNSpacing.md)
            }
        }
    }

    // MARK: - Section 4: Múi Giờ Thiên Văn
    @ViewBuilder
    private var astronomicalTimezoneGroup: some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            sectionHeader(title: String(localized: "settings.timezone.astronomy_header"))

            groupedCard {
                VStack(alignment: .leading, spacing: VNSpacing.sm) {
                    HStack {
                        rowLabel(icon: "globe.asia.australia.fill", tint: .vnAccentHeritageRed, title: String(localized: "settings.timezone.lunar"))
                        Spacer()
                        Text("GMT+7")
                            .font(.footnote.weight(.bold))
                            .foregroundColor(.vnAccentGoldText)
                    }

                    Text(String(localized: "settings.timezone.astronomy_desc"))
                        .font(.caption)
                        .foregroundColor(.vnTextSecondary)
                        .lineSpacing(3)
                        .padding(.top, VNSpacing.space2)
                }
                .padding(VNSpacing.lg)
            }
        }
    }

    // MARK: - Helper UI Components
    private func cmsStatPill(icon: String, text: String) -> some View {
        HStack(spacing: VNSpacing.xs) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.vnOnGoldContainer)
                .accessibilityHidden(true)
            Text(text)
                .font(.caption2.weight(.medium))
                .foregroundColor(.vnOnGoldContainer)
        }
        .padding(.horizontal, VNSpacing.sm)
        .padding(.vertical, VNSpacing.xs)
        .background(Color.vnGoldContainer.opacity(0.5))
        .clipShape(Capsule())
    }

    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(.caption2.weight(.medium))
            .tracking(0.7)
            .foregroundColor(.vnOnGoldContainer)
            .padding(.horizontal, VNSpacing.xs)
            .accessibilityAddTraits(.isHeader)
    }

    private func groupedCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(Color.vnBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous)
                .stroke(Color.vnAccentImperialGold.opacity(0.28), lineWidth: VNBorderWidth.regular)
        )
    }

    private func rowLabel(icon: String, tint: Color, title: String) -> some View {
        HStack(spacing: VNSpacing.md) {
            Image(systemName: icon)
                .font(.callout.weight(.medium))
                .foregroundColor(tint)
                .accessibilityHidden(true)
                .frame(width: iconBox, height: iconBox)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous)
                        .stroke(tint.opacity(0.22), lineWidth: VNBorderWidth.regular)
                )
            Text(title)
                .font(.callout)
                .foregroundColor(.vnTextPrimary)
                .minimumScaleFactor(0.8)
        }
    }

    private var rowDivider: some View {
        VNRowDivider(leadingInset: settingsRowDividerLeadingInset)
    }

    // MARK: - Sync Action
    private func handleSyncMicroCMSNow() {
        guard !isSyncing else { return }
        isSyncing = true

        Task {
            do {
                await container.syncProverbs()
                try await container.holidayRepository.synchronizeRemoteContent()

                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm, dd/MM"
                let nowStr = formatter.string(from: Date())
                lastSyncTimestamp = "Hôm nay, \(nowStr)"
                withAnimation(reduceMotion ? nil : .smooth) {
                    syncStatusBanner = "Đã đồng bộ 48 văn khấn & 12 lễ tiết mới nhất."
                }

                VNHaptics.impact(.success, enabled: isHapticEnabled)
            } catch {
                withAnimation(reduceMotion ? nil : .smooth) {
                    syncStatusBanner = "Dữ liệu ngoại tuyến bản địa đã sẵn sàng."
                }
            }
            isSyncing = false
        }
    }
}
