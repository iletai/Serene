import SwiftUI
import SwiftData
import UserNotifications
import AppUpdateKit
import VNCalendarDesignSystem
import VNCalendarDomain
import VNCalendarData

@main
struct AnNienApp: App {
    @State private var container = AppContainer.shared
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("appThemeAppearance") private var appThemeAppearance: Int = 0
    @State private var scheduleTask: Task<Void, Never>?
    @State private var updateAction: AppUpdateAction = .none

    init() {
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

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(preferredScheme)
                .task {
                    // Initial permissions & background synchronization
                    _ = try? await container.notificationEngine.requestAuthorization()
                    try? await container.holidayRepository.synchronizeRemoteContent()
                    if let reminders = try? await container.reminderRepository.fetchAllReminders() {
                        try? await container.notificationEngine.pruneAndSchedule(reminders: reminders)
                    }
                    await AppUpdateService.shared.check()
                    updateAction = AppUpdateService.shared.action
                }
                .appUpdateSheet(
                    action: $updateAction,
                    accentColor: Color.vnAccentImperialGold
                )
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
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
