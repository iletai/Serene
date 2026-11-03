import BaseNavigationStack
import SwiftUI

/// Maps a presented `AppSheet` to its content.
struct AppSheetView: View {
    let sheet: AppSheet
    @Environment(AppContainer.self) private var container

    var body: some View {
        content.presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private var content: some View {
        switch sheet {
        case .reminderForm(let editing, let initialDate):
            ReminderFormView(existingReminder: editing, initialDate: initialDate) { reminder in
                // Errors are dropped, matching the tab ViewModels' existing save paths.
                Task { try? await container.scheduleReminderUseCase.execute(save: reminder) }
            }
            .presentationDetents([.large])
        case .paywall:
            PaywallView()
        case .search:
            OmniSearchView()
        case .settings:
            SettingsSheet()
        case .holiday(let holiday):
            HolidayDetailSheet(holiday: holiday)
        case .ritual:
            // ponytail: RitualPrayerModal is `private` in UpcomingTimelineView.swift; the Timeline
            // Phase 2 task makes it internal and maps it here. Nothing presents `.ritual` yet.
            EmptyView()
        case .share(let text):
            ShareSheet(activityItems: [text])
        }
    }
}

/// Settings owns its own router so its pushes and nested sheets stay inside the sheet.
private struct SettingsSheet: View {
    @State private var router = AppRouter()

    var body: some View {
        BaseNavigationContainer(
            router: router,
            content: { SettingsView() },
            destination: { AppRouteView(route: $0) },
            sheet: { AppSheetView(sheet: $0) },
            cover: { _ in EmptyView() }
        )
    }
}
