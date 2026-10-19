import OSLog
import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem
import VNCalendarKit
import VNCalendarData

private let settingsLogger = Logger(subsystem: "com.iletai.annien", category: "SettingsView")

public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppContainer.self) private var container
    @State private var isShowingPaywall = false
    @AppStorage("appThemeAppearance") private var appThemeAppearance: Int = 0 // 0: Auto, 1: Rice Paper Light, 2: Lacquer Charcoal Dark
    @AppStorage("appLanguage") private var appLanguage: String = "system"

    public init() {}

    private var isPro: Bool {
        container.subscriptionManager.entitlement.isPro
    }

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
            .vnNavBar(title: String(localized: "tab.settings")) {
                VNDismissButton(style: .text(String(localized: "settings.action.done"))) { dismiss() }
            }
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Membership Banner Card
    private var membershipCard: some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            VNSectionLabel(String(localized: "settings.membership.header"))
            VNGroupCard {
                HStack {
                    VStack(alignment: .leading, spacing: VNSpacing.space2) {
                        let proTitle = String(localized: "settings.membership.pro_title")
                        let freeTitle = String(localized: "settings.membership.free_title")
                        Text(isPro ? proTitle : freeTitle)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.vnTextPrimary)
                        let proSubtitle = String(localized: "settings.membership.pro_subtitle")
                        let freeSubtitle = String(localized: "settings.membership.free_subtitle")
                        Text(isPro ? proSubtitle : freeSubtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.vnTextSecondary)
                    }
                    Spacer()
                    if !isPro {
                        VNButton(String(localized: "settings.action.upgrade"), variant: .primary, size: .small) {
                            isShowingPaywall = true
                        }
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
                VNSectionLabel(String(localized: "settings.timezone.header"))
                VNGroupCard {
                    NavigationLink(destination: CalendarSettingsView()) {
                        VNSettingsRow(icon: "calendar.badge.clock", title: String(localized: "settings.calendar.title"), subtitle: String(localized: "settings.calendar.subtitle_desc"), tint: .vnAccentHeritageRed)
                    }
                    .buttonStyle(.plain)
                }
            }

            // 2. Appearance & Language Sub-menu
            VStack(alignment: .leading, spacing: VNSpacing.xs) {
                VNSectionLabel(String(localized: "settings.appearance.header"))
                VNGroupCard {
                    NavigationLink(destination: AppearanceLanguageSettingsView()) {
                        let modeSubtitle = appThemeAppearance == 1 ? String(localized: "settings.appearance.light") : (appThemeAppearance == 2 ? String(localized: "settings.appearance.dark") : String(localized: "settings.appearance.auto"))
                        VNSettingsRow(icon: "paintpalette.fill", title: String(localized: "settings.appearance.mode"), subtitle: modeSubtitle, tint: .vnAccentImperialGold)
                    }
                    .buttonStyle(.plain)
                }
            }

            // 3. Data & Sync Sub-menu
            VStack(alignment: .leading, spacing: VNSpacing.xs) {
                VNSectionLabel(String(localized: "settings.data.header"))
                VNGroupCard {
                    NavigationLink(destination: DataBackupSettingsView()) {
                        VNSettingsRow(icon: "arrow.triangle.2.circlepath.cloud.fill", title: String(localized: "settings.data.header"), subtitle: String(localized: "settings.data.refresh"), tint: .vnStatusSuccess)
                    }
                    .buttonStyle(.plain)
                }
            }

            // 4. Privacy Sub-menu
            VStack(alignment: .leading, spacing: VNSpacing.xs) {
                VNSectionLabel(String(localized: "settings.privacy.header"))
                VNGroupCard {
                    NavigationLink(destination: PrivacySecuritySettingsView()) {
                        VNSettingsRow(icon: "lock.shield.fill", title: String(localized: "settings.privacy.zero_knowledge_title"), subtitle: "Zero-Knowledge Privacy", tint: .vnAccentDeepPrimary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // 5. About Sub-menu
            VStack(alignment: .leading, spacing: VNSpacing.xs) {
                VNSectionLabel(String(localized: "settings.about.header"))
                VNGroupCard {
                    NavigationLink(destination: AboutSettingsView()) {
                        VNSettingsRow(icon: "info.circle.fill", title: String(localized: "settings.about.version"), subtitle: "1.0.0 (Build 1)", tint: .vnAccentImperialGold)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
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
                        .padding(.horizontal, VNSpacing.xs)

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
                        .padding(.horizontal, VNSpacing.xs)

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
        .vnNavBar(title: String(localized: "settings.appearance.header"))
    }
}

public struct DataBackupSettingsView: View {
    @Environment(AppContainer.self) private var container
    @State private var viewModel: SettingsViewModel?

    public init() {}

    private var activeViewModel: SettingsViewModel {
        if let existing = viewModel { return existing }
        return SettingsViewModel(container: container)
    }

    public var body: some View {
        @Bindable var vm = activeViewModel
        ScrollView {
            VStack(alignment: .leading, spacing: VNSpacing.xl) {
                VStack(alignment: .leading, spacing: VNSpacing.xs) {
                    Text(String(localized: "settings.data.header").uppercased())
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.vnOnGoldContainer)
                        .padding(.horizontal, VNSpacing.xs)

                    VStack(spacing: 0) {
                        Button {
                            vm.syncContent()
                        } label: {
                            HStack {
                                Label(String(localized: "settings.data.refresh"), systemImage: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 16))
                                    .foregroundColor(.vnTextPrimary)
                                Spacer()
                                if vm.isSyncingContent { ProgressView().scaleEffect(0.8) }
                            }
                            .padding(.horizontal, VNSpacing.lg)
                            .padding(.vertical, VNSpacing.md)
                        }

                        VNRowDivider(leadingInset: VNSpacing.lg)

                        Button {
                            vm.exportJSON()
                        } label: {
                            HStack {
                                Label(String(localized: "settings.data.export_json"), systemImage: "square.and.arrow.up")
                                    .font(.system(size: 16))
                                    .foregroundColor(.vnTextPrimary)
                                Spacer()
                            }
                            .padding(.horizontal, VNSpacing.lg)
                            .padding(.vertical, VNSpacing.md)
                        }

                        VNRowDivider(leadingInset: VNSpacing.lg)

                        Button {
                            vm.exportICS()
                        } label: {
                            HStack {
                                Label(String(localized: "settings.data.export_ics"), systemImage: "calendar.badge.plus")
                                    .font(.system(size: 16))
                                    .foregroundColor(.vnTextPrimary)
                                Spacer()
                            }
                            .padding(.horizontal, VNSpacing.lg)
                            .padding(.vertical, VNSpacing.md)
                        }

                        if let msg = vm.backupStatusMessage {
                            VNRowDivider()
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
        .vnNavBar(title: String(localized: "settings.data.header"))
        .sheet(isPresented: $vm.isShowingExportSheet) {
            ShareSheet(activityItems: [vm.exportText])
        }
        .sheet(isPresented: $vm.isShowingPaywall) {
            PaywallView()
        }
        .task {
            if viewModel == nil {
                viewModel = activeViewModel
            }
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
                        .padding(.horizontal, VNSpacing.xs)

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
        .vnNavBar(title: String(localized: "settings.privacy.header"))
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
                        .padding(.horizontal, VNSpacing.xs)

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

                        VNRowDivider(leadingInset: VNSpacing.lg)

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
        .vnNavBar(title: String(localized: "settings.about.header"))
    }
}

public struct ShareSheet: UIViewControllerRepresentable {
    public let activityItems: [Any]

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

