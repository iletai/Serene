import Foundation

/// `@AppStorage` keys shared by the Settings screen and the calendar views that honour them.
public enum VNCalendarPreferenceKey {
    public static let defaultDisplayMode = "defaultCalendarDisplayMode"
    public static let startOfWeek = "calendarStartOfWeek"
    public static let highlightFullAndNewMoon = "highlightFullAndNewMoon"
    public static let showAuspiciousHours = "showAuspiciousHours"
    public static let showSolarTermsAndTruc = "showSolarTermsAndTruc"
    public static let showDailyQuote = "showDailyAuspiciousQuote"
}
