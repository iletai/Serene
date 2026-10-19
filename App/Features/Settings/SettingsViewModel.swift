import SwiftUI
import Observation
import VNCalendarDomain
import VNCalendarData

@Observable
@MainActor
final class SettingsViewModel {
    var isShowingPaywall = false
    var exportText: String = ""
    var isShowingExportSheet = false
    var backupStatusMessage: String?
    var isSyncingContent = false

    private let container: AppContainer

    init(container: AppContainer) {
        self.container = container
    }

    var isPro: Bool {
        container.subscriptionManager.entitlement.isPro
    }

    func syncContent() {
        isSyncingContent = true
        Task {
            await container.syncProverbs()
            do {
                try await container.holidayRepository.synchronizeRemoteContent()
                backupStatusMessage = String(localized: "settings.data.sync_success")
            } catch {
                backupStatusMessage = String(localized: "settings.data.sync_offline")
            }
            isSyncingContent = false
        }
    }

    func exportJSON() {
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

    func exportICS() {
        Task {
            let unlocked = await container.evaluateFeatureGateUseCase.isFeatureAvailable(.batchExportICS)
            guard unlocked else {
                isShowingPaywall = true
                return
            }
            let reminders = (try? await container.reminderRepository.fetchAllReminders()) ?? []
            let ics = await DataBackupEngine.generateICS(reminders: reminders)
            exportText = ics
            isShowingExportSheet = true
            backupStatusMessage = String(localized: "settings.data.ics_done")
        }
    }
}
