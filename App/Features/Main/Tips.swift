import SwiftUI
import TipKit

/// First-run tip anchored on the add-reminder button via `.popoverTip(AddReminderTip())`.
struct AddReminderTip: Tip {
    var title: Text { Text("tip.add_reminder.title") }
    var message: Text? { Text("tip.add_reminder.message") }
    var image: Image? { Image(systemName: "plus.circle.fill") }
}

/// First-run tip anchored on the Family tab via `.popoverTip(FamilyTabTip())`.
struct FamilyTabTip: Tip {
    var title: Text { Text("tip.family_tab.title") }
    var message: Text? { Text("tip.family_tab.message") }
    var image: Image? { Image(systemName: "person.3.fill") }
}
