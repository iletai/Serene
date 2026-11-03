#if DEV
import Foundation
import SwiftData
import TipKit
import VNCalendarData
import VNCalendarDomain

/// Launch-argument hooks for `UIGalleryTests`. Compiled only where `DEV` is set
/// (Debug-/Release-Development via `Config/Development.xcconfig`); Production configs never see it.
///
/// - `-UITestSeed 1`: in-memory store (the on-disk/App Group store is never opened),
///   deterministic sample reminders, Pro pinned, TipKit popovers hidden.
/// - `-UITestRoute <name>`: tab or sheet opened at launch through `DeepLinkCenter`.
///   Names: the `annien://` hosts (calendar, memorial, rituals, family, settings, paywall, search)
///   plus `reminderForm`, `holiday`, `ritual`.
@MainActor
enum UITestSupport {
    /// Seeded container when `-UITestSeed` is passed; nil means a normal launch.
    static func makeContainerIfRequested() -> AppContainer? {
        let defaults = UserDefaults.standard  // launch arguments land in the argument domain
        if let route = defaults.string(forKey: "UITestRoute") {
            DeepLinkCenter.shared.pendingAction = action(for: route)
        }
        guard defaults.bool(forKey: "UITestSeed") else { return nil }

        Tips.hideAllTipsForTesting()  // must precede Tips.configure() in AnNienApp.init
        SubscriptionManager.shared.pinProForUITests()
        let container = AppContainer(inMemory: true)
        let context = container.modelContainer.mainContext
        sampleReminders.forEach { context.insert(ReminderItemEntity(from: $0)) }
        try? context.save()
        return container
    }

    static func action(for route: String) -> DeepLinkHandler.Action? {
        switch route {
        case "reminderForm": return .present(tab: .calendar, sheet: .reminderForm(editing: nil, initialDate: nil))
        case "holiday": return .present(tab: .rituals, sheet: .holiday(sampleHoliday))
        case "ritual": return .present(tab: .memorial, sheet: .ritual(title: "Giỗ Cụ Ông Nguyễn Văn Phúc"))
        default: return URL(string: "annien://\(route)").flatMap(DeepLinkHandler().action(for:))
        }
    }

    // Relationships cover every generation bucket in FamilyHierarchyViewModel.
    private static let sampleReminders: [ReminderEvent] = [
        ReminderEvent(title: "Giỗ Cụ Ông Nguyễn Văn Phúc", day: 12, month: 3, relationship: "Cụ Ông Nội"),
        ReminderEvent(title: "Giỗ Cụ Bà Trần Thị Lộc", day: 8, month: 9, relationship: "Cụ Bà Nội"),
        ReminderEvent(title: "Giỗ Ông Nội Nguyễn Văn Thọ", day: 15, month: 7, relationship: "Ông Nội"),
        ReminderEvent(title: "Giỗ Bà Ngoại Lê Thị Hoa", day: 2, month: 11, relationship: "Bà Ngoại"),
        ReminderEvent(title: "Giỗ Bác Cả Nguyễn Văn Minh", day: 20, month: 5, relationship: "Bác Cả"),
        ReminderEvent(title: "Chạp Họ Nguyễn", category: .ancestral, day: 10, month: 12, relationship: "Dòng họ"),
        ReminderEvent(
            title: "Sinh nhật Mẹ", category: .birthday, dateType: .solar,
            day: 24, month: 6, year: 1965, relationship: "Mẹ"
        ),
        ReminderEvent(
            title: "Kỷ niệm ngày cưới", category: .wedding, dateType: .solar,
            day: 14, month: 2, year: 2015, relationship: "Vợ chồng"
        )
    ]

    private static let sampleHoliday = Holiday(
        id: "ui-test-tet",
        title: "Tết Nguyên Đán",
        calendarType: .lunar,
        day: 1,
        month: 1,
        isNationalHoliday: true,
        isTraditionHoliday: true,
        summary: "Ngày đầu năm âm lịch, dịp sum họp gia đình và tưởng nhớ tổ tiên.",
        customs: "Cúng giao thừa, xông đất, chúc Tết, lì xì.",
        taboos: "Kiêng quét nhà, cãi vã, vay mượn trong ngày mùng Một.",
        rituals: "Lễ cúng gia tiên với mâm ngũ quả, bánh chưng."
    )
}
#endif
