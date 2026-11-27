import OSLog
import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem
import VNCalendarKit
import VNCalendarData

private extension Bundle {
    /// "1.0.1 (Build 12)" from Info.plist; keeps Settings and About in sync with the shipped build.
    var appVersionDescription: String {
        let version = object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
        let build = object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "-"
        return "\(version) (Build \(build))"
    }
}

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
            VStack(alignment: .leading, spacing: VNSpacing.sectionGap) {
                profileGroup
                    .vnRise(index: 0, baseDelay: 0.02)
                membershipCard
                    .vnRise(index: 1, baseDelay: 0.02)
                commonSection
                    .vnRise(index: 2, baseDelay: 0.02)
                infoSection
                    .vnRise(index: 3, baseDelay: 0.02)
                footer
                    .vnRise(index: 4, baseDelay: 0.02)
            }
            .padding(.horizontal, VNSpacing.screenMargin)
            .padding(.top, VNSpacing.md)
            .padding(.bottom, VNSpacing.xxl)
        }
        .background(Color.vnBackgroundPrimary.ignoresSafeArea())
        .vnNavBar(title: String(localized: "tab.settings")) {
            // Settings is the root of its own sheet container, so the sheet-level dismiss closes it.
            VNDismissButton(style: .text(String(localized: "settings.action.done"))) { dismiss() }
        }
    }

    // MARK: - Profile

    private var profileGroup: some View {
        VNGroupCard {
            Button { router.push(.about) } label: {
                HStack(spacing: VNSpacing.md) {
                    Image(systemName: "calendar")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.vnOnAccent)
                        .frame(width: 56, height: 56)
                        .background(Color.vnAccentHeritageRed)
                        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: VNSpacing.space2) {
                        Text("settings.profile.name")
                            .font(.vnDisplay(.headline, weight: .bold))
                            .foregroundColor(.vnTextPrimary)
                        Text("settings.profile.tagline")
                            .font(.vnDisplay(.footnote))
                            .foregroundColor(.vnTextSecondary)
                        Text(verbatim: "\(String(localized: "settings.about.version")) \(Bundle.main.appVersionDescription)")
                            .font(.vnDisplay(.caption2))
                            .foregroundColor(.vnTextTertiary)
                    }

                    Spacer(minLength: VNSpacing.xs)

                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.vnTextTertiary)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, VNSpacing.cardPadding)
                .padding(.vertical, VNSpacing.md)
                .contentShape(Rectangle())
            }
            .buttonStyle(VNCellPressButtonStyle(pressedScale: 0.98))
        }
    }

    // MARK: - Membership Banner Card
    private var membershipCard: some View {
        VNGroupCard {
            HStack(spacing: VNSpacing.md) {
                VStack(alignment: .leading, spacing: VNSpacing.space2) {
                    let proTitle = String(localized: "settings.membership.pro_title")
                    let freeTitle = String(localized: "settings.membership.free_title")
                    Text(isPro ? proTitle : freeTitle)
                        .font(.vnDisplay(.callout, weight: .semibold))
                        .foregroundColor(.vnTextPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    let proSubtitle = String(localized: "settings.membership.pro_subtitle")
                    let freeSubtitle = String(localized: "settings.membership.free_subtitle")
                    Text(isPro ? proSubtitle : freeSubtitle)
                        .font(.vnDisplay(.caption))
                        .foregroundColor(.vnTextSecondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: VNSpacing.xs)
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

    // MARK: - Chung

    private var commonSection: some View {
        VStack(alignment: .leading, spacing: VNSpacing.sm) {
            VNGroupHeader(String(localized: "settings.group.common"))

            VNGroupCard {
                Button { router.push(.appearanceLanguage) } label: {
                    VNListRow(
                        icon: "paintpalette.fill",
                        iconTint: .vnAccentSky,
                        title: String(localized: "settings.display.title"),
                        subtitle: nil
                    ) {
                        Text(themeLabel)
                            .font(.vnDisplay(.footnote))
                            .foregroundColor(.vnTextSecondary)
                            .lineLimit(1)
                    }
                }
                .buttonStyle(VNCellPressButtonStyle(pressedScale: 0.98))

                VNRowDivider(leadingInset: VNSpacing.cardPadding)

                Button { router.push(.calendarSettings) } label: {
                    VNListRow(
                        icon: "calendar.badge.clock",
                        iconTint: .vnAccentHeritageRed,
                        title: String(localized: "settings.calendar.title"),
                        subtitle: String(localized: "settings.calendar.subtitle")
                    )
                }
                .buttonStyle(VNCellPressButtonStyle(pressedScale: 0.98))
                .accessibilityIdentifier("settings.calendarSettings")

                VNRowDivider(leadingInset: VNSpacing.cardPadding)

                Button { router.push(.dataBackup) } label: {
                    VNListRow(
                        icon: "arrow.clockwise.icloud.fill",
                        iconTint: .vnAccentJade,
                        title: String(localized: "settings.data.header"),
                        subtitle: nil
                    )
                }
                .buttonStyle(VNCellPressButtonStyle(pressedScale: 0.98))
            }
        }
    }

    // MARK: - Thông tin

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: VNSpacing.sm) {
            VNGroupHeader(String(localized: "settings.group.info"))

            VNGroupCard {
                Button { router.push(.about) } label: {
                    VNListRow(
                        icon: "info.circle.fill",
                        iconTint: .vnTextSecondary,
                        title: String(localized: "settings.about.version"),
                        subtitle: nil
                    ) {
                        Text(Bundle.main.appVersionDescription)
                            .font(.vnDisplay(.footnote))
                            .foregroundColor(.vnTextSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
                .buttonStyle(VNCellPressButtonStyle(pressedScale: 0.98))

                VNRowDivider(leadingInset: VNSpacing.cardPadding)

                Button { router.push(.privacySecurity) } label: {
                    VNListRow(
                        icon: "lock.shield.fill",
                        iconTint: .vnAccentSky,
                        title: String(localized: "settings.privacy.zero_knowledge_title"),
                        subtitle: String(localized: "settings.privacy.zero_knowledge_subtitle")
                    )
                }
                .buttonStyle(VNCellPressButtonStyle(pressedScale: 0.98))
            }
        }
    }

    private var footer: some View {
        VNGroupFooter(
            String(
                format: String(localized: "settings.footer.version_local_only"),
                Bundle.main.appVersionDescription
            ),
            isCentered: true
        )
    }

    private var themeLabel: String {
        switch appThemeAppearance {
        case 1: return String(localized: "settings.appearance.light")
        case 2: return String(localized: "settings.appearance.dark")
        default: return String(localized: "settings.appearance.auto")
        }
    }
}

// MARK: - Sub-screens for Navigation Menu

public struct AppearanceLanguageSettingsView: View {
    @AppStorage("appThemeAppearance") private var appThemeAppearance: Int = 0
    @AppStorage("appLanguage") private var appLanguage: String = "system"

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VNSpacing.sectionGap) {
                VStack(alignment: .leading, spacing: VNSpacing.sm) {
                    VNGroupHeader(String(localized: "settings.appearance.header"))
                    VNGroupCard {
                        themeRow(0, title: String(localized: "settings.appearance.auto"))
                        VNRowDivider(leadingInset: VNSpacing.cardPadding)
                        themeRow(1, title: String(localized: "settings.appearance.light"))
                        VNRowDivider(leadingInset: VNSpacing.cardPadding)
                        themeRow(2, title: String(localized: "settings.appearance.dark"))
                    }
                }

                VStack(alignment: .leading, spacing: VNSpacing.sm) {
                    VNGroupHeader(String(localized: "settings.language.header"))
                    VNGroupCard {
                        languageRow("system", title: String(localized: "settings.language.system"))
                        VNRowDivider(leadingInset: VNSpacing.cardPadding)
                        languageRow("vi", title: "Tiếng Việt")
                        VNRowDivider(leadingInset: VNSpacing.cardPadding)
                        languageRow("en", title: "English")
                    }
                    VNGroupFooter(String(localized: "settings.language.footer"))
                }
            }
            .padding(.horizontal, VNSpacing.screenMargin)
            .padding(.top, VNSpacing.md)
            .padding(.bottom, VNSpacing.xxl)
        }
        .background(Color.vnBackgroundPrimary.ignoresSafeArea())
        .vnNavBar(title: String(localized: "settings.display.title"))
    }

    private func themeRow(_ value: Int, title: String) -> some View {
        Button {
            appThemeAppearance = value
        } label: {
            VNListRow(title: title, showsChevron: false) {
                if appThemeAppearance == value {
                    Image(systemName: "checkmark")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.vnAccentSky)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(VNCellPressButtonStyle(pressedScale: 0.98))
        .accessibilityAddTraits(appThemeAppearance == value ? [.isSelected] : [])
    }

    private func languageRow(_ value: String, title: String) -> some View {
        Button {
            appLanguage = value
        } label: {
            VNListRow(title: title, showsChevron: false) {
                if appLanguage == value {
                    Image(systemName: "checkmark")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.vnAccentSky)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(VNCellPressButtonStyle(pressedScale: 0.98))
        .accessibilityAddTraits(appLanguage == value ? [.isSelected] : [])
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
                VStack(alignment: .leading, spacing: VNSpacing.sm) {
                    VNGroupHeader(String(localized: "settings.data.header"))

                    VNGroupCard {
                        Button {
                            vm.syncContent()
                        } label: {
                            VNListRow(
                                icon: "arrow.triangle.2.circlepath",
                                iconTint: .vnAccentJade,
                                title: String(localized: "settings.data.refresh")
                            ) {
                                if vm.isSyncingContent {
                                    ProgressView().scaleEffect(0.8)
                                }
                            }
                        }
                        .buttonStyle(VNCellPressButtonStyle(pressedScale: 0.98))

                        VNRowDivider(leadingInset: VNSpacing.cardPadding)

                        Button {
                            Task { present(await vm.exportJSON()) }
                        } label: {
                            VNListRow(
                                icon: "square.and.arrow.up",
                                iconTint: .vnAccentSky,
                                title: String(localized: "settings.data.export_json")
                            )
                        }
                        .buttonStyle(VNCellPressButtonStyle(pressedScale: 0.98))

                        VNRowDivider(leadingInset: VNSpacing.cardPadding)

                        Button {
                            Task { present(await vm.exportICS()) }
                        } label: {
                            VNListRow(
                                icon: "calendar.badge.plus",
                                iconTint: .vnAccentSky,
                                title: String(localized: "settings.data.export_ics")
                            )
                        }
                        .buttonStyle(VNCellPressButtonStyle(pressedScale: 0.98))

                        if let msg = vm.backupStatusMessage {
                            VNRowDivider()
                            Text(msg)
                                .font(.vnDisplay(.caption))
                                .foregroundColor(.vnStatusSuccess)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, VNSpacing.cardPadding)
                                .padding(.vertical, VNSpacing.sm)
                        }
                    }

                    VNGroupFooter(String(localized: "settings.data.footer_local_only"))
                }
            }
            .padding(.horizontal, VNSpacing.screenMargin)
            .padding(.top, VNSpacing.md)
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
                VStack(alignment: .leading, spacing: VNSpacing.sm) {
                    VNGroupHeader(String(localized: "settings.privacy.header"))

                    VStack(alignment: .leading, spacing: VNSpacing.md) {
                        Text(String(localized: "settings.privacy.zero_knowledge_title"))
                            .font(.vnDisplay(.headline))
                            .foregroundColor(.vnTextPrimary)

                        Text(String(localized: "settings.privacy.zero_knowledge_body"))
                            .font(.vnDisplay(.subheadline))
                            .foregroundColor(.vnTextSecondary)
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(VNSpacing.cardPadding)
                    .background(Color.vnBackgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))
                }
            }
            .padding(.horizontal, VNSpacing.screenMargin)
            .padding(.top, VNSpacing.md)
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
                VStack(alignment: .leading, spacing: VNSpacing.sm) {
                    VNGroupHeader(String(localized: "settings.about.header"))

                    VNGroupCard {
                        infoRow(String(localized: "settings.about.version"), value: Bundle.main.appVersionDescription)
                        VNRowDivider(leadingInset: VNSpacing.cardPadding)
                        infoRow(String(localized: "settings.about.copyright"), value: "An Niên • iletai")
                    }
                }
            }
            .padding(.horizontal, VNSpacing.screenMargin)
            .padding(.top, VNSpacing.md)
            .padding(.bottom, VNSpacing.xxl)
        }
        .background(Color.vnBackgroundPrimary.ignoresSafeArea())
        .vnNavBar(title: String(localized: "settings.about.header"))
    }

    private func infoRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.vnDisplay(.callout))
                .foregroundColor(.vnTextPrimary)
            Spacer()
            Text(value)
                .font(.vnDisplay(.subheadline, weight: .medium))
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
