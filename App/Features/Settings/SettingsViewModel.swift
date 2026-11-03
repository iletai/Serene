import SwiftUI
import Observation
import VNCalendarDomain
import VNCalendarData

@Observable
@MainActor
final class SettingsViewModel {
    /// What the View should present after an export; keeps the ViewModel router-free.
    enum ExportOutcome: Equatable { case share(String), requiresPro }

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

    func exportJSON() async -> ExportOutcome? {
        do {
            let reminders = try await container.reminderRepository.fetchAllReminders()
            let data = try DataBackupEngine.exportJSON(reminders: reminders)
            guard let str = String(data: data, encoding: .utf8) else { return nil }
            backupStatusMessage = String(format: String(localized: "settings.data.export_done"), reminders.count)
            return .share(str)
        } catch {
            backupStatusMessage = String(format: String(localized: "settings.data.export_error"), error.localizedDescription)
            return nil
        }
    }

    func exportICS() async -> ExportOutcome {
        guard await container.evaluateFeatureGateUseCase.isFeatureAvailable(.batchExportICS) else {
            return .requiresPro
        }
        let reminders = (try? await container.reminderRepository.fetchAllReminders()) ?? []
        let ics = await DataBackupEngine.generateICS(reminders: reminders)
        backupStatusMessage = String(localized: "settings.data.ics_done")
        return .share(ics)
    }
}
