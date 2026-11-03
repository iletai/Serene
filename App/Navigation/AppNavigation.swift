import BaseNavigationStack
import Foundation
import VNCalendarDomain

enum AppRoute: Hashable, Sendable {
    case calendarSettings, appearanceLanguage, dataBackup, privacySecurity, about
}

enum AppSheet: Identifiable, Sendable {
    case reminderForm(editing: ReminderEvent?, initialDate: Date?)
    case paywall
    case search
    case settings
    case holiday(Holiday)
    case ritual(title: String)
    case share(text: String)

    var id: String {
        switch self {
        case .reminderForm(let editing, let date):
            return "reminderForm-\(editing?.id.uuidString ?? "new")-\(date?.timeIntervalSince1970 ?? 0)"
        case .paywall: return "paywall"
        case .search: return "search"
        case .settings: return "settings"
        case .holiday(let holiday): return "holiday-\(holiday.id)"
        case .ritual(let title): return "ritual-\(title)"
        case .share(let text): return "share-\(text)"
        }
    }
}

// Hashable by id only: ReminderEvent/Holiday are not Hashable.
extension AppSheet: Hashable {
    static func == (lhs: AppSheet, rhs: AppSheet) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// Placeholder: no full-screen covers yet, but the router requires a Cover type.
enum AppCover: Identifiable, Hashable, Sendable {
    case unused
    var id: String { "unused" }
}

typealias AppRouter = NavigationRouter<AppRoute, AppSheet, AppCover>

/// Result the Views route on; keeps ViewModels router-free.
enum CreateReminderGate: Sendable { case allowed, requiresPro }
