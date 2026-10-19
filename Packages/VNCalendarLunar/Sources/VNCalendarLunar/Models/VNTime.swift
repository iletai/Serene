import Foundation

/// Fixed GMT+7 time basis for all lunar/calendar computations.
/// Spec: 01-lunar-engine.md §8 — never fall back to device-local timezone.
public enum VNTime {
    /// Vietnam standard time (ICT, UTC+7). Identifier lookup first; fixed
    /// offset fallback never returns nil so `.current` is unreachable.
    public static let vietnam = TimeZone(identifier: "Asia/Ho_Chi_Minh")
        ?? TimeZone(secondsFromGMT: 7 * 3600)
        ?? .gmt

    /// Gregorian calendar pinned to GMT+7. Create locally or reuse; Calendar
    /// is a value type so sharing is safe but mutation must stay copy-on-write.
    public static var vietnamCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = vietnam
        return cal
    }
}
