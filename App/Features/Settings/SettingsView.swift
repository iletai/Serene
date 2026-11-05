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
    @Environment(AppRouter.self) private var router
    @AppStorage("appThemeAppearance") private var appThemeAppearance: Int = 0 // 0: Auto, 1: Rice Paper Light, 2: Lacquer Charcoal Dark
    @AppStorage("appLanguage") private var appLanguage: String = "system"

    public init() {}

    private var isPro: Bool {
        container.subscriptionManager.entitlement.isPro
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: VNSpacing.sectionGap) {
                membershipCard
                navigationMenuList
            }
            .padding(.horizontal, VNSpacing.screenMargin)
            .padding(.top, VNSpacing.xl)
            .padding(.bottom, VNSpacing.xxl)
        }
        .background(Color.vnBackgroundPrimary.ignoresSafeArea())
        .vnNavBar(title: String(localized: "tab.settings")) {
            // Settings is the root of its own sheet container, so the sheet-level dismiss closes it.
            VNDismissButton(style: .text(String(localized: "settings.action.done"))) { dismiss() }
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
                            .font(.callout.weight(.semibold))
                            .foregroundColor(.vnTextPrimary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                        let proSubtitle = String(localized: "settings.membership.pro_subtitle")
                        let freeSubtitle = String(localized: "settings.membership.free_subtitle")
                        Text(isPro ? proSubtitle : freeSubtitle)
                            .font(.caption)
                            .foregroundColor(.vnTextSecondary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }
                    Spacer()
                    if !isPro {
                        VNButton(String(localized: "settings.action.upgrade"), variant: .primary, size: .small) {
                            router.present(sheet: .paywall)
                        }
                    } else {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.vnAccentHeritageRed)
                            .accessibilityHidden(true)
                    }
                }
                .padding(.horizontal, VNSpacing.cardPadding)
                .padding(.vertical, VNSpacing.md)
            }
        }
    }

    // MARK: - Navigation Menu List
    private var navigationMenuList: some View {
        VStack(alignment: .leading, spacing: VNSpacing.sectionGap) {
            // 1. Calendar & Astronomy Sub-menu
            VStack(alignment: .leading, spacing: VNSpacing.xs) {
                VNSectionLabel(String(localized: "settings.timezone.header"))
                VNGroupCard {
                    Button { router.push(.calendarSettings) } label: {
                        VNSettingsRow(icon: "calendar.badge.clock", title: String(localized: "settings.calendar.title"), subtitle: String(localized: "settings.calendar.subtitle_desc"), tint: .vnAccentHeritageRed)
                    }
                    .buttonStyle(VNCellPressButtonStyle(pressedScale: 0.98))
                    .accessibilityIdentifier("settings.calendarSettings")
                }
            }

            // 2. Appearance & Language Sub-menu
            VStack(alignment: .leading, spacing: VNSpacing.xs) {
                VNSectionLabel(String(localized: "settings.appearance.header"))
                VNGroupCard {
                    Button { router.push(.appearanceLanguage) } label: {
                        let modeSubtitle = appThemeAppearance == 1 ? String(localized: "settings.appearance.light") : (appThemeAppearance == 2 ? String(localized: "settings.appearance.dark") : String(localized: "settings.appearance.auto"))
                        VNSettingsRow(icon: "paintpalette.fill", title: String(localized: "settings.appearance.mode"), subtitle: modeSubtitle, tint: .vnAccentGoldText)
                    }
                    .buttonStyle(VNCellPressButtonStyle(pressedScale: 0.98))
                }
            }

            // 3. Data & Sync Sub-menu
            VStack(alignment: .leading, spacing: VNSpacing.xs) {
                VNSectionLabel(String(localized: "settings.data.header"))
                VNGroupCard {
                    Button { router.push(.dataBackup) } label: {
                        VNSettingsRow(icon: "arrow.clockwise.icloud.fill", title: String(localized: "settings.data.header"), subtitle: String(localized: "settings.data.refresh"), tint: .vnStatusSuccess)
                    }
                    .buttonStyle(VNCellPressButtonStyle(pressedScale: 0.98))
                }
            }

            // 4. Privacy Sub-menu
            VStack(alignment: .leading, spacing: VNSpacing.xs) {
                VNSectionLabel(String(localized: "settings.privacy.header"))
                VNGroupCard {
                    Button { router.push(.privacySecurity) } label: {
                        VNSettingsRow(icon: "lock.shield.fill", title: String(localized: "settings.privacy.zero_knowledge_title"), subtitle: String(localized: "settings.privacy.zero_knowledge_subtitle"), tint: .vnAccentDeepPrimary)
                    }
                    .buttonStyle(VNCellPressButtonStyle(pressedScale: 0.98))
                }
            }

            // 5. About Sub-menu
            VStack(alignment: .leading, spacing: VNSpacing.xs) {
                VNSectionLabel(String(localized: "settings.about.header"))
                VNGroupCard {
                    Button { router.push(.about) } label: {
                        VNSettingsRow(icon: "info.circle.fill", title: String(localized: "settings.about.version"), subtitle: "1.0.0 (Build 1)", tint: .vnAccentGoldText)
                    }
                    .buttonStyle(VNCellPressButtonStyle(pressedScale: 0.98))
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
            VStack(spacing: VNSpacing.sectionGap) {
                // Theme Card
                VStack(alignment: .leading, spacing: VNSpacing.xs) {
                    VNSectionLabel(String(localized: "settings.appearance.header"))

                    VStack(spacing: 0) {
                        Picker(String(localized: "settings.appearance.mode"), selection: $appThemeAppearance) {
                            Text(String(localized: "settings.appearance.auto")).tag(0)
                            Text(String(localized: "settings.appearance.light")).tag(1)
                            Text(String(localized: "settings.appearance.dark")).tag(2)
                        }
                        .pickerStyle(.inline)
                        .padding(VNSpacing.cardPadding)
                    }
                    .background(Color.vnBackgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))
                }

                // Language Card
                VStack(alignment: .leading, spacing: VNSpacing.xs) {
                    VNSectionLabel(String(localized: "settings.language.header"))

                    VStack(spacing: 0) {
                        Picker(String(localized: "settings.language.title"), selection: $appLanguage) {
                            Text(String(localized: "settings.language.system")).tag("system")
                            Text("Tiếng Việt").tag("vi")
                            Text("English").tag("en")
                        }
                        .pickerStyle(.inline)
                        .padding(VNSpacing.cardPadding)
                    }
                    .background(Color.vnBackgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))
                }
            }
            .padding(.horizontal, VNSpacing.screenMargin)
            .padding(.top, VNSpacing.xl)
            .padding(.bottom, VNSpacing.xxl)
        }
        .background(Color.vnBackgroundPrimary.ignoresSafeArea())
        .vnNavBar(title: String(localized: "settings.appearance.header"))
    }
}

public struct DataBackupSettingsView: View {
    @Environment(AppContainer.self) private var container
    @Environment(AppRouter.self) private var router
    @State private var viewModel: SettingsViewModel?

    public init() {}

    private var activeViewModel: SettingsViewModel {
        if let existing = viewModel { return existing }
        return SettingsViewModel(container: container)
    }

    public var body: some View {
        let vm = activeViewModel
        ScrollView {
            VStack(alignment: .leading, spacing: VNSpacing.sectionGap) {
                VStack(alignment: .leading, spacing: VNSpacing.xs) {
                    VNSectionLabel(String(localized: "settings.data.header"))

                    VStack(spacing: 0) {
                        Button {
                            vm.syncContent()
                        } label: {
                            actionRow(String(localized: "settings.data.refresh"), icon: "arrow.triangle.2.circlepath") {
                                if vm.isSyncingContent { ProgressView().scaleEffect(0.8) }
                            }
                        }

                        VNRowDivider(leadingInset: VNSpacing.cardPadding)

                        Button {
                            Task { present(await vm.exportJSON()) }
                        } label: {
                            actionRow(String(localized: "settings.data.export_json"), icon: "square.and.arrow.up") { EmptyView() }
                        }

                        VNRowDivider(leadingInset: VNSpacing.cardPadding)

                        Button {
                            Task { present(await vm.exportICS()) }
                        } label: {
                            actionRow(String(localized: "settings.data.export_ics"), icon: "calendar.badge.plus") { EmptyView() }
                        }

                        if let msg = vm.backupStatusMessage {
                            VNRowDivider()
                            Text(msg)
                                .font(.caption)
                                .foregroundColor(.vnStatusSuccess)
                                .padding(.horizontal, VNSpacing.cardPadding)
                                .padding(.vertical, VNSpacing.sm)
                        }
                    }
                    .background(Color.vnBackgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))
                }
            }
            .padding(.horizontal, VNSpacing.screenMargin)
            .padding(.top, VNSpacing.xl)
            .padding(.bottom, VNSpacing.xxl)
        }
        .background(Color.vnBackgroundPrimary.ignoresSafeArea())
        .vnNavBar(title: String(localized: "settings.data.header"))
        .task {
            if viewModel == nil {
                viewModel = activeViewModel
            }
        }
    }

    private func actionRow<Trailing: View>(
        _ title: String,
        icon: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.callout)
                .foregroundColor(.vnTextPrimary)
            Spacer()
            trailing()
        }
        .padding(.horizontal, VNSpacing.cardPadding)
        .padding(.vertical, VNSpacing.md)
        .frame(minHeight: VNSize.minTapTarget)
        .contentShape(Rectangle())
    }

    private func present(_ outcome: SettingsViewModel.ExportOutcome?) {
        switch outcome {
        case .share(let text): router.present(sheet: .share(text: text))
        case .requiresPro: router.present(sheet: .paywall)
        case nil: break
        }
    }
}

public struct PrivacySecuritySettingsView: View {
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VNSpacing.sectionGap) {
                VStack(alignment: .leading, spacing: VNSpacing.xs) {
                    VNSectionLabel(String(localized: "settings.privacy.header"))

                    VStack(alignment: .leading, spacing: VNSpacing.md) {
                        Text(String(localized: "settings.privacy.zero_knowledge_title"))
                            .font(.headline)
                            .foregroundColor(.vnTextPrimary)

                        Text(String(localized: "settings.privacy.zero_knowledge_body"))
                            .font(.subheadline)
                            .foregroundColor(.vnTextSecondary)
                            .lineSpacing(4)
                    }
                    .padding(VNSpacing.cardPadding)
                    .background(Color.vnBackgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))
                }
            }
            .padding(.horizontal, VNSpacing.screenMargin)
            .padding(.top, VNSpacing.xl)
            .padding(.bottom, VNSpacing.xxl)
        }
        .background(Color.vnBackgroundPrimary.ignoresSafeArea())
        .vnNavBar(title: String(localized: "settings.privacy.header"))
    }
}

public struct AboutSettingsView: View {
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VNSpacing.sectionGap) {
                VStack(alignment: .leading, spacing: VNSpacing.xs) {
                    VNSectionLabel(String(localized: "settings.about.header"))

                    VStack(spacing: 0) {
                        infoRow(String(localized: "settings.about.version"), value: "1.0.0 (Build 1)")
                        VNRowDivider(leadingInset: VNSpacing.cardPadding)
                        infoRow(String(localized: "settings.about.copyright"), value: "An Niên • iletai")
                    }
                    .background(Color.vnBackgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))
                }
            }
            .padding(.horizontal, VNSpacing.screenMargin)
            .padding(.top, VNSpacing.xl)
            .padding(.bottom, VNSpacing.xxl)
        }
        .background(Color.vnBackgroundPrimary.ignoresSafeArea())
        .vnNavBar(title: String(localized: "settings.about.header"))
    }

    private func infoRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.callout)
                .foregroundColor(.vnTextPrimary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.vnTextSecondary)
        }
        .padding(.horizontal, VNSpacing.cardPadding)
        .padding(.vertical, VNSpacing.md)
        .accessibilityElement(children: .combine)
    }
}

public struct ShareSheet: UIViewControllerRepresentable {
    public let activityItems: [Any]

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

