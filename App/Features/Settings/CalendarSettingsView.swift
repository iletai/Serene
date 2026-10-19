import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem
import VNCalendarKit

public struct CalendarSettingsView: View {
    @State private var container = AppContainer.shared

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
    @State private var syncStatusBanner: String?

    public init() {}

    /// Leading inset aligning row subtitles under the 40pt icon plus its 12pt gap (rowLabel).
    private static let settingsSubtitleLeadingInset: CGFloat = 52
    /// Leading inset aligning row dividers past the 40pt icon, 12pt gap and 16pt card padding.
    private static let settingsRowDividerLeadingInset: CGFloat = 68

    public var body: some View {
        ScrollView {
            VStack(spacing: VNSpacing.xl) {
                headerSummaryBanner

                calendarModesGroup

                microCMSSyncGroup

                dailyCustomizationGroup

                astronomicalTimezoneGroup
            }
            .padding(.horizontal, VNSpacing.xl)
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

                HStack {
                    rowLabel(icon: "calendar", tint: .vnAccentImperialGold, title: String(localized: "settings.calendar.week_start"))
                    Spacer()
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
                    rowLabel(icon: "moon.stars.fill", tint: .vnAccentImperialGold, title: String(localized: "settings.calendar.highlight_full_new_moon"))
                }
                .tint(.vnAccentHeritageRed)
                .padding(.horizontal, VNSpacing.lg)
                .padding(.vertical, VNSpacing.md)

                rowDivider

                Toggle(isOn: $showAuspiciousHours) {
                    rowLabel(icon: "clock.badge.checkmark.fill", tint: .vnAccentImperialGold, title: String(localized: "settings.calendar.show_auspicious_hours"))
                }
                .tint(.vnAccentHeritageRed)
                .padding(.horizontal, VNSpacing.lg)
                .padding(.vertical, VNSpacing.md)

                rowDivider

                Toggle(isOn: $showSolarTermsAndTruc) {
                    rowLabel(icon: "sun.haze.fill", tint: .vnAccentImperialGold, title: String(localized: "settings.calendar.show_solar_terms"))
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
                    rowLabel(icon: "wifi", tint: .vnAccentImperialGold, title: String(localized: "settings.microcms.wifi_only"))
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
                        .font(.system(size: 12))
                        .foregroundColor(.vnStatusSuccess)
                    Text(banner)
                        .font(.system(size: 12))
                        .foregroundColor(.vnTextSecondary)
                }
                .padding(.horizontal, VNSpacing.sm)
                .padding(.top, VNSpacing.space2)
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
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
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
                .font(.system(size: 11))
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
                        .tint(.white)
                        .scaleEffect(0.9)
                    Text(String(localized: "settings.microcms.syncing"))
                        .font(.vnFootnote)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 13, weight: .bold))
                    Text(String(localized: "settings.microcms.sync_now"))
                        .font(.vnFootnote)
                }
                Spacer()
            }
            .padding(.vertical, VNSpacing.md)
            .background(Color.vnAccentHeritageRed)
            .foregroundColor(.vnRicePaperWhite)
            .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.small, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: VNCornerRadius.small, style: .continuous)
                    .stroke(Color.vnBorderSubtle.opacity(0.4), lineWidth: VNBorderWidth.hairline)
            )
        }
        .disabled(isSyncing)
    }

    // MARK: - Section 3: Tùy Biến Lịch Ngày
    @ViewBuilder
    private var dailyCustomizationGroup: some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            sectionHeader(title: String(localized: "settings.daily.header"))

            groupedCard {
                Toggle(isOn: $showDailyQuote) {
                    VStack(alignment: .leading, spacing: VNSpacing.space2) {
                        rowLabel(icon: "quote.opening", tint: .vnAccentImperialGold, title: String(localized: "settings.daily.quote"))
                        Text(String(localized: "settings.daily.quote_desc"))
                            .font(.system(size: 12))
                            .foregroundColor(.vnTextSecondary)
                            .padding(.leading, Self.settingsSubtitleLeadingInset)
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
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.vnAccentImperialGold)
                    }

                    Text(String(localized: "settings.timezone.astronomy_desc"))
                        .font(.system(size: 12))
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
                .font(.system(size: 11))
                .foregroundColor(.vnOnGoldContainer)
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.vnOnGoldContainer)
        }
        .padding(.horizontal, VNSpacing.sm)
        .padding(.vertical, VNSpacing.xs)
        .background(Color.vnGoldContainer.opacity(0.5))
        .clipShape(Capsule())
    }

    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .medium))
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
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(tint)
                .accessibilityHidden(true)
                .frame(width: 40, height: 40)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous)
                        .stroke(tint.opacity(0.22), lineWidth: VNBorderWidth.regular)
                )
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.vnTextPrimary)
        }
    }

    private var rowDivider: some View {
        VNRowDivider(leadingInset: Self.settingsRowDividerLeadingInset)
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
                syncStatusBanner = "Đã đồng bộ 48 văn khấn & 12 lễ tiết mới nhất."

                if isHapticEnabled {
                    #if os(iOS)
                    let feedback = UINotificationFeedbackGenerator()
                    feedback.notificationOccurred(.success)
                    #endif
                }
            } catch {
                syncStatusBanner = "Dữ liệu ngoại tuyến bản địa đã sẵn sàng."
            }
            isSyncing = false
        }
    }
}
