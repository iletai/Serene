import OSLog
import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem
import VNCalendarKit

private let settingsLogger = Logger(subsystem: "com.iletai.annien", category: "SettingsView")

public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var container = AppContainer.shared
    @State private var isShowingPaywall = false
    @AppStorage("appThemeAppearance") private var appThemeAppearance: Int = 0 // 0: Auto, 1: Rice Paper Light, 2: Lacquer Charcoal Dark
    @AppStorage("appLanguage") private var appLanguage: String = "system"

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: VNSpacing.xl) {
                    membershipCard
                    navigationMenuList
                }
                .padding(.horizontal, VNSpacing.xl)
                .padding(.top, VNSpacing.xl)
                .padding(.bottom, VNSpacing.xxl)
            }
            .background(Color.vnBackgroundPrimary.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.vnBackgroundPrimary.opacity(0.9), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(String(localized: "tab.settings"))
                        .font(.vnTitleCeremonial)
                        .foregroundColor(.vnAccentDeepPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "settings.action.done")) { dismiss() }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
            }
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Membership Banner Card
    private var membershipCard: some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            sectionHeader(String(localized: "settings.membership.header"))
            settingsCard {
                HStack {
                    VStack(alignment: .leading, spacing: VNSpacing.space2) {
                        let proTitle = String(localized: "settings.membership.pro_title")
                        let freeTitle = String(localized: "settings.membership.free_title")
                        Text(subscriptionManager.entitlement.isPro ? proTitle : freeTitle)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.vnTextPrimary)
                        let proSubtitle = String(localized: "settings.membership.pro_subtitle")
                        let freeSubtitle = String(localized: "settings.membership.free_subtitle")
                        Text(subscriptionManager.entitlement.isPro ? proSubtitle : freeSubtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.vnTextSecondary)
                    }
                    Spacer()
                    if !subscriptionManager.entitlement.isPro {
                        Button(String(localized: "settings.action.upgrade")) {
                            isShowingPaywall = true
                        }
                        .font(.vnCaption1)
                        .fontWeight(.bold)
                        .frame(minHeight: 44)
                        .padding(.horizontal, VNSpacing.md)
                        .contentShape(Capsule())
                        .background(Color.vnAccentHeritageRed)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    } else {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.vnAccentHeritageRed)
                            .accessibilityHidden(true)
                    }
                }
                .padding(.horizontal, VNSpacing.lg)
                .padding(.vertical, VNSpacing.md)
            }
        }
    }

    // MARK: - Navigation Menu List
    private var navigationMenuList: some View {
        VStack(alignment: .leading, spacing: VNSpacing.xl) {
            // 1. Calendar & Astronomy Sub-menu
            VStack(alignment: .leading, spacing: VNSpacing.xs) {
                sectionHeader(String(localized: "settings.timezone.header"))
                settingsCard {
                    NavigationLink(destination: CalendarSettingsView()) {
                        menuRow(icon: "calendar.badge.clock", title: String(localized: "settings.calendar.title"), subtitle: String(localized: "settings.calendar.subtitle_desc"), tint: .vnAccentHeritageRed)
                    }
                    .buttonStyle(.plain)
                }
            }

            // 2. Appearance & Language Sub-menu
            VStack(alignment: .leading, spacing: VNSpacing.xs) {
                sectionHeader(String(localized: "settings.appearance.header"))
                settingsCard {
                    NavigationLink(destination: AppearanceLanguageSettingsView()) {
                        menuRow(icon: "paintpalette.fill", title: String(localized: "settings.appearance.mode"), subtitle: appThemeAppearance == 1 ? String(localized: "settings.appearance.light") : (appThemeAppearance == 2 ? String(localized: "settings.appearance.dark") : String(localized: "settings.appearance.auto")), tint: .vnAccentImperialGold)
                    }
                    .buttonStyle(.plain)
                }
            }

            // 3. Data & Sync Sub-menu
            VStack(alignment: .leading, spacing: VNSpacing.xs) {
                sectionHeader(String(localized: "settings.data.header"))
                settingsCard {
                    NavigationLink(destination: DataBackupSettingsView()) {
                        menuRow(icon: "arrow.triangle.2.circlepath.cloud.fill", title: String(localized: "settings.data.header"), subtitle: String(localized: "settings.data.refresh"), tint: .vnStatusSuccess)
                    }
                    .buttonStyle(.plain)
                }
            }

            // 4. Privacy Sub-menu
            VStack(alignment: .leading, spacing: VNSpacing.xs) {
                sectionHeader(String(localized: "settings.privacy.header"))
                settingsCard {
                    NavigationLink(destination: PrivacySecuritySettingsView()) {
                        menuRow(icon: "lock.shield.fill", title: String(localized: "settings.privacy.zero_knowledge_title"), subtitle: "Zero-Knowledge Privacy", tint: .vnAccentDeepPrimary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // 5. About Sub-menu
            VStack(alignment: .leading, spacing: VNSpacing.xs) {
                sectionHeader(String(localized: "settings.about.header"))
                settingsCard {
                    NavigationLink(destination: AboutSettingsView()) {
                        menuRow(icon: "info.circle.fill", title: String(localized: "settings.about.version"), subtitle: "1.0.0 (Build 1)", tint: .vnAccentImperialGold)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func menuRow(icon: String, title: String, subtitle: String, tint: Color) -> some View {
        HStack(spacing: VNSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(tint)
                .frame(width: 40, height: 40)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.vnTextPrimary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.vnTextSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.vnTextSecondary.opacity(0.6))
        }
        .padding(.horizontal, VNSpacing.lg)
        .padding(.vertical, VNSpacing.md)
        .contentShape(Rectangle())
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .medium))
            .tracking(0.7)
            .foregroundColor(.vnOnGoldContainer)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            .accessibilityAddTraits(.isHeader)
    }

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
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
}

// MARK: - Sub-screens for Navigation Menu

public struct AppearanceLanguageSettingsView: View {
    @AppStorage("appThemeAppearance") private var appThemeAppearance: Int = 0
    @AppStorage("appLanguage") private var appLanguage: String = "system"

    public var body: some View {
        ScrollView {
            VStack(spacing: VNSpacing.xl) {
                // Theme Card
                VStack(alignment: .leading, spacing: VNSpacing.xs) {
                    Text(String(localized: "settings.appearance.header").uppercased())
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.vnOnGoldContainer)
                        .padding(.horizontal, 4)

                    VStack(spacing: 0) {
                        Picker(String(localized: "settings.appearance.mode"), selection: $appThemeAppearance) {
                            Text(String(localized: "settings.appearance.auto")).tag(0)
                            Text(String(localized: "settings.appearance.light")).tag(1)
                            Text(String(localized: "settings.appearance.dark")).tag(2)
                        }
                        .pickerStyle(.inline)
                        .padding(VNSpacing.lg)
                    }
                    .background(Color.vnBackgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))
                }

                // Language Card
                VStack(alignment: .leading, spacing: VNSpacing.xs) {
                    Text("NGÔN NGỮ ỨNG DỤNG / APP LANGUAGE".uppercased())
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.vnOnGoldContainer)
                        .padding(.horizontal, 4)

                    VStack(spacing: 0) {
                        Picker("Ngôn ngữ", selection: $appLanguage) {
                            Text("Hệ thống (System)").tag("system")
                            Text("Tiếng Việt").tag("vi")
                            Text("English").tag("en")
                        }
                        .pickerStyle(.inline)
                        .padding(VNSpacing.lg)
                    }
                    .background(Color.vnBackgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))
                }
            }
            .padding(.horizontal, VNSpacing.xl)
            .padding(.top, VNSpacing.xl)
        }
        .background(Color.vnBackgroundPrimary.ignoresSafeArea())
        .navigationTitle(String(localized: "settings.appearance.header"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

public struct DataBackupSettingsView: View {
    @State private var container = AppContainer.shared
    @State private var exportText: String = ""
    @State private var isShowingExportSheet = false
    @State private var backupStatusMessage: String?
    @State private var isSyncingContent = false

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VNSpacing.xl) {
                VStack(alignment: .leading, spacing: VNSpacing.xs) {
                    Text(String(localized: "settings.data.header").uppercased())
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.vnOnGoldContainer)
                        .padding(.horizontal, 4)

                    VStack(spacing: 0) {
                        Button(action: handleRefreshContent) {
                            HStack {
                                Label(String(localized: "settings.data.refresh"), systemImage: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 16))
                                    .foregroundColor(.vnTextPrimary)
                                Spacer()
                                if isSyncingContent { ProgressView().scaleEffect(0.8) }
                            }
                            .padding(.horizontal, VNSpacing.lg)
                            .padding(.vertical, VNSpacing.md)
                        }

                        Divider().background(Color.vnBorderSubtle).padding(.leading, VNSpacing.lg)

                        Button(action: handleExportJSON) {
                            HStack {
                                Label(String(localized: "settings.data.export_json"), systemImage: "square.and.arrow.up")
                                    .font(.system(size: 16))
                                    .foregroundColor(.vnTextPrimary)
                                Spacer()
                            }
                            .padding(.horizontal, VNSpacing.lg)
                            .padding(.vertical, VNSpacing.md)
                        }

                        Divider().background(Color.vnBorderSubtle).padding(.leading, VNSpacing.lg)

                        Button(action: handleExportICS) {
                            HStack {
                                Label(String(localized: "settings.data.export_ics"), systemImage: "calendar.badge.plus")
                                    .font(.system(size: 16))
                                    .foregroundColor(.vnTextPrimary)
                                Spacer()
                            }
                            .padding(.horizontal, VNSpacing.lg)
                            .padding(.vertical, VNSpacing.md)
                        }

                        if let msg = backupStatusMessage {
                            Divider().background(Color.vnBorderSubtle)
                            Text(msg)
                                .font(.system(size: 12))
                                .foregroundColor(.vnStatusSuccess)
                                .padding(.horizontal, VNSpacing.lg)
                                .padding(.vertical, VNSpacing.sm)
                        }
                    }
                    .background(Color.vnBackgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))
                }
            }
            .padding(.horizontal, VNSpacing.xl)
            .padding(.top, VNSpacing.xl)
        }
        .background(Color.vnBackgroundPrimary.ignoresSafeArea())
        .navigationTitle(String(localized: "settings.data.header"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingExportSheet) {
            ShareSheet(activityItems: [exportText])
        }
    }

    private func handleRefreshContent() {
        isSyncingContent = true
        Task {
            do {
                try await container.holidayRepository.synchronizeRemoteContent()
                backupStatusMessage = String(localized: "settings.data.sync_success")
            } catch {
                backupStatusMessage = String(localized: "settings.data.sync_offline")
            }
            isSyncingContent = false
        }
    }

    private func handleExportJSON() {
        Task {
            do {
                let reminders = try await container.reminderRepository.fetchAllReminders()
                let data = try DataBackupEngine.exportJSON(reminders: reminders)
                if let str = String(data: data, encoding: .utf8) {
                    exportText = str
                    isShowingExportSheet = true
                    backupStatusMessage = String(format: String(localized: "settings.data.export_done"), reminders.count)
                }
            } catch {
                backupStatusMessage = String(format: String(localized: "settings.data.export_error"), error.localizedDescription)
            }
        }
    }

    private func handleExportICS() {
        Task {
            let reminders = (try? await container.reminderRepository.fetchAllReminders()) ?? []
            let ics = await DataBackupEngine.generateICS(reminders: reminders)
            exportText = ics
            isShowingExportSheet = true
            backupStatusMessage = String(localized: "settings.data.ics_done")
        }
    }
}

public struct PrivacySecuritySettingsView: View {
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VNSpacing.xl) {
                VStack(alignment: .leading, spacing: VNSpacing.xs) {
                    Text(String(localized: "settings.privacy.header").uppercased())
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.vnOnGoldContainer)
                        .padding(.horizontal, 4)

                    VStack(alignment: .leading, spacing: VNSpacing.md) {
                        Text(String(localized: "settings.privacy.zero_knowledge_title"))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.vnTextPrimary)

                        Text(String(localized: "settings.privacy.zero_knowledge_body"))
                            .font(.system(size: 14))
                            .foregroundColor(.vnTextSecondary)
                            .lineSpacing(4)
                    }
                    .padding(VNSpacing.lg)
                    .background(Color.vnBackgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))
                }
            }
            .padding(.horizontal, VNSpacing.xl)
            .padding(.top, VNSpacing.xl)
        }
        .background(Color.vnBackgroundPrimary.ignoresSafeArea())
        .navigationTitle(String(localized: "settings.privacy.header"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

public struct AboutSettingsView: View {
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VNSpacing.xl) {
                VStack(alignment: .leading, spacing: VNSpacing.xs) {
                    Text(String(localized: "settings.about.header").uppercased())
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.vnOnGoldContainer)
                        .padding(.horizontal, 4)

                    VStack(spacing: 0) {
                        HStack {
                            Text(String(localized: "settings.about.version"))
                                .font(.system(size: 16))
                                .foregroundColor(.vnTextPrimary)
                            Spacer()
                            Text("1.0.0 (Build 1)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.vnTextSecondary)
                        }
                        .padding(.horizontal, VNSpacing.lg)
                        .padding(.vertical, VNSpacing.md)

                        Divider().background(Color.vnBorderSubtle).padding(.leading, VNSpacing.lg)

                        HStack {
                            Text(String(localized: "settings.about.copyright"))
                                .font(.system(size: 16))
                                .foregroundColor(.vnTextPrimary)
                            Spacer()
                            Text("An Niên • iletai")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.vnTextSecondary)
                        }
                        .padding(.horizontal, VNSpacing.lg)
                        .padding(.vertical, VNSpacing.md)
                    }
                    .background(Color.vnBackgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))
                }
            }
            .padding(.horizontal, VNSpacing.xl)
            .padding(.top, VNSpacing.xl)
        }
        .background(Color.vnBackgroundPrimary.ignoresSafeArea())
        .navigationTitle(String(localized: "settings.about.header"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

public struct ShareSheet: UIViewControllerRepresentable {
    public let activityItems: [Any]

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

