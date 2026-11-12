import SwiftUI
import SwiftData
import TipKit
import UserNotifications
import AppUpdateKit
import VNCalendarDesignSystem
import VNCalendarDomain
import VNCalendarData

@main
struct AnNienApp: App {
    @State private var container = AppContainer.shared
    @State private var ads = AdsManager(subscriptionManager: AppContainer.shared.subscriptionManager)
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("appThemeAppearance") private var appThemeAppearance: Int = 0
    @AppStorage("appLanguage") private var appLanguage: String = "system"
    @State private var scheduleTask: Task<Void, Never>?
    @State private var updateAction: AppUpdateAction = .none
    @State private var deepLinks = DeepLinkCenter.shared

    init() {
        // Must be set before launch finishes so a cold-start notification tap is delivered.
        UNUserNotificationCenter.current().delegate = DeepLinkCenter.shared
        try? Tips.configure()
        // Register local notification categories at startup
        Task { @MainActor in
            await SmartNotificationEngine.shared.registerCategories()
        }
    }

    private var preferredScheme: ColorScheme? {
        switch appThemeAppearance {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }

    private var selectedLocale: Locale {
        switch appLanguage {
        case "vi": return Locale(identifier: "vi")
        case "en": return Locale(identifier: "en")
        default: return .autoupdatingCurrent
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView(pendingDeepLink: $deepLinks.pendingAction)
                .environment(container)
                .environment(ads)
                .onOpenURL { deepLinks.open($0) }
                .preferredColorScheme(preferredScheme)
                .environment(\.locale, selectedLocale)
                .task {
                    // Initial permissions & background synchronization
                    _ = try? await container.notificationEngine.requestAuthorization()
                    if await ContentSyncPolicy.autoSyncAllowed() {
                        try? await container.syncRemoteContent()
                    }
                    if let reminders = try? await container.reminderRepository.fetchAllReminders() {
                        try? await container.notificationEngine.pruneAndSchedule(reminders: reminders)
                    }
                    await AppUpdateService.shared.check()
                    updateAction = AppUpdateService.shared.action
                }
                .appUpdateSheet(
                    action: $updateAction,
                    accentColor: Color.vnCinnabarLacquerRed
                )
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        Task { await ads.start() }
                        // Serialize schedule runs so reconcile-then-add does not interleave.
                        scheduleTask?.cancel()
                        scheduleTask = Task {
                            // Refresh entitlements so Pro state is current after offline purchase.
                            await container.subscriptionManager.refreshEntitlements()
                            if let reminders = try? await container.reminderRepository.fetchAllReminders() {
                                try? await container.notificationEngine.pruneAndSchedule(reminders: reminders)
                            }
                            await AppUpdateService.shared.check()
                            updateAction = AppUpdateService.shared.action
                        }
                    }
                }
        }
        .modelContainer(container.modelContainer)
    }
}
