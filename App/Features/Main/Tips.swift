import SwiftUI
import TipKit

/// First-run tip anchored on the add-reminder button via `.popoverTip(AddReminderTip())`.
struct AddReminderTip: Tip {
    var title: Text { Text("Thêm ngày nhớ") }
    var message: Text? { Text("Lưu ngày giỗ, sinh nhật theo âm hoặc dương lịch và nhận nhắc trước.") }
    var image: Image? { Image(systemName: "plus.circle.fill") }
}

/// First-run tip anchored on the Family tab via `.popoverTip(FamilyTabTip())`.
struct FamilyTabTip: Tip {
    var title: Text { Text("Gia phả & ngày giỗ") }
    var message: Text? { Text("Xem các ngày nhớ theo từng thành viên trong gia đình.") }
    var image: Image? { Image(systemName: "person.3.fill") }
}
