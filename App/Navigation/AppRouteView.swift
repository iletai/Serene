import SwiftUI

/// Maps a pushed `AppRoute` to its screen.
struct AppRouteView: View {
    let route: AppRoute

    var body: some View {
        switch route {
        case .calendarSettings: CalendarSettingsView()
        case .appearanceLanguage: AppearanceLanguageSettingsView()
        case .dataBackup: DataBackupSettingsView()
        case .privacySecurity: PrivacySecuritySettingsView()
        case .about: AboutSettingsView()
        }
    }
}
