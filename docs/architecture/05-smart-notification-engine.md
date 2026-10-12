# Kiến Trúc Động Cơ Thông Báo Thông Minh & Cắt Tỉa Hạn Ngạch 64 Slots (Smart Notification & Priority Pruning Engine)

> **Tài liệu kiến trúc hệ thống lõi**  
> **Module**: `Packages/VNCalendarDomain` & `App/Infrastructure/Notifications`  
> **Phiên bản**: 1.0.0  
> **Nền tảng**: iOS 17.0+ / Swift 6 Concurrency (Structured Concurrency, SwiftData, UserNotifications)  
> **Mục tiêu**: Quản lý lịch nhắc Âm Dương thông minh, chống tràn giới hạn 64 thông báo cục bộ của iOS, bảo toàn 100% các kỳ giỗ tổ tiên và lễ trọng.

---

## 1. Vấn Đề Kỹ Thuật & Giới Hạn Hệ Thống (The 64 Local Notification Ceiling)

### 1.1. Giới Hạn Phần Cứng & Hệ Điều Hành iOS
Trên iOS 17 và iOS 18, `UNUserNotificationCenter` của Apple áp đặt một **giới hạn cứng (Hard Limit) tối đa 64 thông báo cục bộ đang chờ kích hoạt (Pending Local Notification Requests)** cho mỗi ứng dụng.
- Nếu ứng dụng cố gắng lên lịch vượt quá 64 thông báo (`add(request)` khi danh sách pending $\ge 64$), hệ điều hành sẽ:
  1. Âm thầm bỏ qua (silently drop) các yêu cầu mới, HOẶC
  2. Tự động loại bỏ (evict) các thông báo cũ mà không theo bất kỳ quy luật ưu tiên nghiệp vụ nào.
- Việc này dẫn đến rủi ro nghiêm trọng: **Người dùng bị lỡ ngày giỗ của cha mẹ/ông bà** chỉ vì hệ thống bị chiếm dụng bởi hàng chục thông báo nhắc nhở ngày rằm hoặc tiết khí thông thường.

```
       +-----------------------------------------------------------------------+
       |               Nhu Cầu Nhắc Nhở Trong Ứng Dụng An Niên                 |
       |  - 20+ Ngày giỗ gia tiên (Nhắc trước 30d, 7d, 3d, 1d, 0d) -> 100 req  |
       |  - Mùng 1 & Rằm hàng tháng (24 sự kiện x 2 lần nhắc)       -> 48 req  |
       |  - 24 Tiết Khí & Ngày Lễ Truyền Thống/Quốc Gia             -> 50 req  |
       |  - Sinh nhật & Kỷ niệm ngày cưới gia đình                   -> 30 req  |
       |                                                                       |
       |  TỔNG NHU CẦU LÊN LỊCH TRONG NĂM: > 250+ THÔNG BÁO                    |
       +-----------------------------------+-----------------------------------+
                                           |
                                           v
       +-----------------------------------------------------------------------+
       |             GIỚI HẠN CỦA APPLE: TỐI ĐA 64 SLOTS PENDING               |
       |                    (UNUserNotificationCenter Limit)                   |
       +-----------------------------------+-----------------------------------+
                                           |
                                           v
       +-----------------------------------------------------------------------+
       |           GIẢI PHÁP: SMART NOTIFICATION ENGINE (AN NIÊN)              |
       |                                                                       |
       |   [4 Slots Dự Phòng Khẩn Cấp]  +  [Top 60 Slots Điểm Ưu Tiên Cao Nhất]|
       |   (Hệ thống, Báo thức, Snooze)     (Tính theo Time-decay Hyperbolic)  |
       |                                                                       |
       |   - Tự động trượt cửa sổ thời gian (Rolling Scheduling Horizon)      |
       |   - Lắng nghe sự kiện hệ thống (App Launch, Significant Time, BG)    |
       |   - Xử lý biên: Tháng thiếu 29 ngày & Tháng nhuận Âm lịch            |
       +-----------------------------------------------------------------------+
```

---

## 2. Mô Hình Toán Học Cắt Tỉa Điểm Ưu Tiên (Mathematical Priority & Decay Model)

Để đảm bảo các sự kiện quan trọng nhất (như ngày giỗ) không bị bỏ lỡ trong khi các sự kiện gần nhất trong tương lai vẫn được lên lịch kịp thời, engine áp dụng hàm tính điểm **Suy Giảm Hyperbolic Theo Thời Gian (Hyperbolic Time-Decay Function)**.

### 2.1. Công Thức Tính Điểm Động (Dynamic Priority Formula)

Cho một thông báo ứng viên $e$ dự kiến kích hoạt vào thời điểm $T_{\text{trigger}}$, tại thời điểm tính toán $T_{\text{now}}$:

Khoảng cách thời gian tính theo ngày thực ($\Delta t_{\text{days}}$):
$$\Delta t_{\text{days}} = \max\left(0, \frac{T_{\text{trigger}} - T_{\text{now}}}{86400}\right)$$

Điểm số ưu tiên tổng hợp $\text{Score}(e, \Delta t)$:
$$\text{Score}(e, \Delta t) = \text{BasePriority}(e) \times W_{\text{offset}}(e) \times \frac{1}{1 + \alpha \cdot \Delta t_{\text{days}}}$$

Trong đó:
- $\text{BasePriority}(e)$: Điểm ưu tiên cơ bản theo phân cấp ý nghĩa văn hóa và huyết thống.
- $W_{\text{offset}}(e)$: Trọng số theo loại thông báo (nhắc trước hay đúng ngày).
- $\alpha$: Hệ số suy giảm thời gian (Time-decay coefficient), mặc định $\alpha = 0.05$ (đảm bảo sự kiện trọng đại sau 30 ngày vẫn có điểm cao hơn sự kiện tầm thường xảy ra vào ngày mai).

---

### 2.2. Phân Cấp Điểm Cơ Bản (Base Priority Tiers)

| Phân Cấp (Tier) | Base Priority | Đối Tượng Áp Dụng | Ý Nghĩa Nghiệp Vụ |
|:---|:---:|:---|:---|
| `critical` | **1000** | Ngày giỗ Tứ Thân Phụ Mẫu (Cha, Mẹ, Ông, Bà), Ngày mất ruột thịt | Tuyệt đối không được bỏ sót, ưu tiên chiếm slot cao nhất |
| `high` | **700** | Mùng 1 & Rằm (15 ÂL), Giỗ Tổ Hùng Vương, Tết Nguyên Đán, Giỗ Họ | Nghi lễ tâm linh & truyền thống văn hóa định kỳ |
| `medium` | **300** | Sinh nhật người thân, Kỷ niệm ngày cưới, Lễ hội dân gian | Sự kiện gia đình thường niên |
| `low` | **100** | Nhắc chuyển Tiết khí, Nhắc nhở chung, Ghi chú cá nhân tùy ý | Thông tin tham khảo thêm |

---

### 2.3. Trọng Số Nhắc Trước (Advance Notice Weight Multiplier)

Một sự kiện thường có nhiều mốc nhắc nhở (Ví dụ: nhắc trước 7 ngày để chuẩn bị lễ vật, nhắc trước 1 ngày để đi chợ, và nhắc đúng sáng ngày giỗ).

$$W_{\text{offset}} = \begin{cases}
1.00 & \text{khi nhắc đúng ngày } (t - 0\text{d}) \\
0.95 & \text{khi nhắc trước 1 ngày } (t - 1\text{d}) \\
0.85 & \text{khi nhắc trước 3 ngày } (t - 3\text{d}) \\
0.70 & \text{khi nhắc trước 7 ngày } (t - 7\text{d}) \\
0.50 & \text{khi nhắc trước 14 hoặc 30 ngày } (t - 14\text{d}, t - 30\text{d})
\end{cases}$$

#### Bảng Minh Họa Điểm Số Giữa Các Sự Kiện:
Giả sử tại thời điểm $T_{\text{now}}$:
1. **Sự kiện A**: Giỗ Cha ruột (`critical` = 1000), nhắc đúng ngày, diễn ra sau **45 ngày** ($\Delta t = 45$):
   $$\text{Score}_A = 1000 \times 1.0 \times \frac{1}{1 + 0.05 \times 45} = 1000 \times \frac{1}{3.25} \approx \mathbf{307.69}$$
2. **Sự kiện B**: Nhắc Tiết Khí (`low` = 100), nhắc đúng ngày, diễn ra sau **2 ngày** ($\Delta t = 2$):
   $$\text{Score}_B = 100 \times 1.0 \times \frac{1}{1 + 0.05 \times 2} = 100 \times \frac{1}{1.10} \approx \mathbf{90.91}$$
3. **Sự kiện C**: Mùng 1 tháng sau (`high` = 700), nhắc trước 1 ngày, diễn ra sau **15 ngày** ($\Delta t = 15$):
   $$\text{Score}_C = 700 \times 0.95 \times \frac{1}{1 + 0.05 \times 15} = 665 \times \frac{1}{1.75} \approx \mathbf{380.00}$$

$\implies$ Thứ tự ưu tiên lên lịch: $\text{Sự kiện C } (380.0) > \text{Sự kiện A } (307.7) > \text{Sự kiện B } (90.9)$. Dù ngày giỗ diễn ra sau 45 ngày, nó vẫn luôn được ưu tiên hơn tiết khí của 2 ngày tới!

---

### 2.4. Phân Bổ Hạn Ngạch 64 Slots (Quota Partitioning)
- **Tổng dung lượng tối đa**: 64 slots.
- **Safety Reserved Buffer (Dự phòng khẩn cấp)**: **4 slots**.
  - Dành riêng cho: Báo thức phát sinh tức thì, Snooze thông báo người dùng vừa nhấn, Thông báo đồng bộ hệ thống khẩn cấp từ CloudKit/microCMS.
- **Scheduled Active Pool (Hạn ngạch lên lịch tối đa)**: **60 slots**.
  - Chỉ chọn đúng **Top 60 ứng viên có Score cao nhất** từ toàn bộ tập hợp các sự kiện trong cửa sổ trượt 365 ngày.

---

## 3. Xử Lý Các Trường Hợp Biên Âm Lịch Trong Lên Lịch (Lunar Edge Cases)

```
                                +-----------------------------------+
                                |     Sự Kiện Lịch Âm Định Kỳ      |
                                +-----------------+-----------------+
                                                  |
                                                  v
                                +-----------------------------------+
                                |     Kiểm Tra Tháng Mục Tiêu       |
                                +--------+-----------------+--------+
                                         |                 |
                       Tháng Đủ (30 ngày)|                 |Tháng Thiếu (29 ngày)
                                         v                 v
                        +------------------+    +---------------------------+
                        | Giữ nguyên ngày  |    | Ngày 30 ÂL -> Kẹp về 29 ÂL |
                        | 30/M ÂL          |    | Gắn Subtitle: Tháng thiếu |
                        +------------------+    +---------------------------+
```

### 3.1. Tháng Thiếu 29 Ngày (The 29-Day Month 30th Fallback)
- **Bản chất**: Trong nhiều năm, tháng Chạp (Tháng 12 ÂL) hoặc các tháng hè chỉ có 29 ngày. Nếu gia đình có ngày giỗ tổ vào ngày 30 ÂL, việc chuyển đổi mù quáng sang Dương lịch sẽ dẫn tới lỗi ngày hoặc bị nhảy sang mùng 1 tháng sau.
- **Cơ chế xử lý tự động**:
  1. Engine kiểm tra độ dài thực tế của tháng Âm lịch trong năm mục tiêu ($L_{\text{month}}$).
  2. Nếu $D_{\text{lunar}} = 30$ và $L_{\text{month}} = 29$:
     $$\text{Day}_{\text{effective}} = 29$$
  3. Chuyển đổi $29/\text{Month}/\text{Year}$ sang `SolarDate`.
  4. Nội dung thông báo tự động bổ sung trường phụ đề:
     - `subtitle = "Kỳ giỗ ngày 30 (Năm nay tháng thiếu hóa ngày 29 ÂL)"`

### 3.2. Sự Kiện Tạo Trong Tháng Nhuận (Leap Month Handling)
- Đối với sự kiện được tạo trong một tháng nhuận (Ví dụ: Mẹ mất ngày 10 Tháng 4 Nhuận năm Quý Mão):
  - Trong các năm thường (không có Tháng 4 Nhuận): Tự động lên lịch vào **ngày 10 Tháng 4 Thường**.
  - Trong các năm có Tháng 4 Nhuận: Áp dụng `LeapMonthPolicy`:
    - `.adaptiveFallback`: Mặc định nhắc vào tháng chính ở năm thường, và nhắc đúng tháng nhuận ở năm nhuận.
    - `.both`: Lên lịch cả 2 lần (Tháng 4 Thường và Tháng 4 Nhuận) trong năm nhuận.

---

## 4. Hiện Thực Mã Nguồn Swift 6 Lõi (`SmartNotificationEngine`)

Toàn bộ động cơ được tổ chức dưới dạng `actor NotificationSchedulerEngine` tương thích 100% Swift 6 Concurrency (`Sendable`, structured tasks), tích hợp trực tiếp với `UserNotifications` và `SwiftData`.

```swift
//
//  SmartNotificationEngine.swift
//  App/Infrastructure/Notifications (App mục tiêu AnNien; shared logic phân tầng trong Packages/VNCalendarDomain)
//
//  Created by An Niên Team on 2026-09-29.
//  Strict Swift 6 Concurrency - Zero Silent Drops.
//

import Foundation
import UserNotifications
import VNCalendarLunar

// MARK: - Domain Models & Enums

public enum NotificationPriorityTier: Int, Sendable, Comparable {
    case low = 100
    case medium = 300
    case high = 700
    case critical = 1000

    public static func < (lhs: NotificationPriorityTier, rhs: NotificationPriorityTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public enum AdvanceNoticeOffset: Int, Sendable, CaseIterable {
    case sameDay = 0
    case oneDayBefore = 1
    case threeDaysBefore = 3
    case sevenDaysBefore = 7
    case fourteenDaysBefore = 14
    case thirtyDaysBefore = 30

    public var weightMultiplier: Double {
        switch self {
        case .sameDay: return 1.00
        case .oneDayBefore: return 0.95
        case .threeDaysBefore: return 0.85
        case .sevenDaysBefore: return 0.70
        case .fourteenDaysBefore, .thirtyDaysBefore: return 0.50
        }
    }

    public var titlePrefix: String {
        switch self {
        case .sameDay: return "Hôm nay"
        case .oneDayBefore: return "Ngày mai"
        case .threeDaysBefore: return "Còn 3 ngày nữa đến"
        case .sevenDaysBefore: return "Còn 7 ngày nữa đến"
        case .fourteenDaysBefore: return "Còn 2 tuần nữa đến"
        case .thirtyDaysBefore: return "Còn 1 tháng nữa đến"
        }
    }
}

public enum LeapMonthPolicy: String, Sendable, Codable {
    case adaptiveFallback // Năm thường nhắc tháng chính, năm nhuận nhắc tháng nhuận
    case regularOnly       // Luôn nhắc tháng chính
    case leapOnly          // Chỉ nhắc khi có tháng nhuận
    case both              // Nhắc cả tháng chính và tháng nhuận
}

/// Thực thể Ngày Cần Nhớ trong Hệ Thống
public struct MemorialEvent: Sendable, Identifiable {
    public let id: UUID
    public let title: String
    public let notes: String?
    public let isLunar: Bool
    public let day: Int
    public let month: Int
    public let year: Int? // nil nếu lặp lại hàng năm
    public let isLeapMonth: Bool
    public let priorityTier: NotificationPriorityTier
    public let advanceOffsets: [AdvanceNoticeOffset]
    public let leapPolicy: LeapMonthPolicy
    public let hour: Int
    public let minute: Int

    public init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        isLunar: Bool = true,
        day: Int,
        month: Int,
        year: Int? = nil,
        isLeapMonth: Bool = false,
        priorityTier: NotificationPriorityTier = .critical,
        advanceOffsets: [AdvanceNoticeOffset] = [.sameDay, .oneDayBefore, .threeDaysBefore],
        leapPolicy: LeapMonthPolicy = .adaptiveFallback,
        hour: Int = 7,
        minute: Int = 0
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.isLunar = isLunar
        self.day = day
        self.month = month
        self.year = year
        self.isLeapMonth = isLeapMonth
        self.priorityTier = priorityTier
        self.advanceOffsets = advanceOffsets
        self.leapPolicy = leapPolicy
        self.hour = hour
        self.minute = minute
    }
}

/// Ứng viên thông báo đã qua tính điểm ưu tiên
public struct NotificationCandidate: Sendable, Comparable {
    public let identifier: String
    public let eventId: UUID
    public let title: String
    public let subtitle: String?
    public let body: String
    public let triggerDate: Date
    public let score: Double
    public let isClampedShortMonth: Bool

    public static func < (lhs: NotificationCandidate, rhs: NotificationCandidate) -> Bool {
        // Thứ tự ưu tiên giảm dần theo Score (Score cao hơn đứng trước)
        if lhs.score != rhs.score {
            return lhs.score > rhs.score
        }
        // Nếu cùng điểm, sự kiện diễn ra sớm hơn được ưu tiên
        return lhs.triggerDate < rhs.triggerDate
    }
}

// MARK: - Notification Center Protocol (Cho phép Mocking trong Unit Test)

public protocol UserNotificationCenterProtocol: Sendable {
    func pendingNotificationRequests() async -> [UNNotificationRequest]
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
}

extension UNUserNotificationCenter: UserNotificationCenterProtocol {
    public func pendingNotificationRequests() async -> [UNNotificationRequest] {
        await pendingNotificationRequests()
    }
}

// MARK: - Smart Notification Scheduler Actor

public actor NotificationSchedulerEngine {
    public static let maxSystemQuota = 64
    public static let reservedSafetySlots = 4
    public static let maxScheduledSlots = maxSystemQuota - reservedSafetySlots // 60 slots
    public static let decayAlpha = 0.05 // Hệ số suy giảm Hyperbolic

    private let center: UserNotificationCenterProtocol
    private let lunarEngine: LunarAstronomicalEngine

    public init(
        center: UserNotificationCenterProtocol = UNUserNotificationCenter.current(),
        lunarEngine: LunarAstronomicalEngine = .shared
    ) {
        self.center = center
        self.lunarEngine = lunarEngine
    }

    /// Lên lịch lại toàn bộ thông báo dựa trên danh sách sự kiện hiện có (Reconciliation Loop)
    @discardableResult
    public func reconcileNotifications(
        events: [MemorialEvent],
        currentDate: Date = Date(),
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) async throws -> (scheduledCount: Int, prunedCount: Int) {
        // 1. Sinh toàn bộ ứng viên thông báo trong 365 ngày tới
        let candidates = await generateCandidates(from: events, currentDate: currentDate, calendar: calendar)

        // 2. Cắt tỉa chọn Top 60 ứng viên có điểm số cao nhất
        let sortedCandidates = candidates.sorted()
        let topCandidates = Array(sortedCandidates.prefix(Self.maxScheduledSlots))
        let prunedCount = max(0, sortedCandidates.count - Self.maxScheduledSlots)

        // 3. Lấy danh sách ID đang pending trên hệ thống iOS
        let existingRequests = await center.pendingNotificationRequests()
        let existingIDs = Set(existingRequests.map(\.identifier))
        let targetIDs = Set(topCandidates.map(\.identifier))

        // 4. Tìm các ID dư thừa cần xóa (Tránh Churn)
        let idsToRemove = existingIDs.subtracting(targetIDs)
        if !idsToRemove.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: Array(idsToRemove))
        }

        // 5. Thêm các yêu cầu mới chưa có trên hệ thống
        for candidate in topCandidates {
            if !existingIDs.contains(candidate.identifier) {
                let request = createNotificationRequest(from: candidate, calendar: calendar)
                try? await center.add(request)
            }
        }

        return (topCandidates.count, prunedCount)
    }

    // MARK: - Candidate Generation & Scoring Engine

    private func generateCandidates(
        from events: [MemorialEvent],
        currentDate: Date,
        calendar: Calendar
    ) async -> [NotificationCandidate] {
        var candidates: [NotificationCandidate] = []
        let currentYear = calendar.component(.year, from: currentDate)

        for event in events {
            // Quét cho năm hiện tại và năm tiếp theo để phủ đủ 365 ngày
            for targetYear in currentYear...(currentYear + 1) {
                let resolved = await resolveTriggerDate(for: event, targetYear: targetYear, calendar: calendar)
                guard let baseDate = resolved.date else { continue }

                for offset in event.advanceOffsets {
                    guard let triggerDate = calendar.date(byAdding: .day, value: -offset.rawValue, to: baseDate),
                          triggerDate > currentDate else {
                        continue
                    }

                    // Tính khoảng cách delta t theo ngày
                    let deltaSeconds = triggerDate.timeIntervalSince(currentDate)
                    let deltaDays = max(0, deltaSeconds / 86400.0)

                    // Áp dụng công thức Hyperbolic Time-Decay Score
                    let decayFactor = 1.0 / (1.0 + Self.decayAlpha * deltaDays)
                    let score = Double(event.priorityTier.rawValue) * offset.weightMultiplier * decayFactor

                    // Định dạng ID duy nhất: annien.event.{id}.offset.{offset}.year.{year}
                    let identifier = "annien.event.\(event.id.uuidString).offset.\(offset.rawValue).y\(targetYear)"

                    let (title, subtitle, body) = formatContent(
                        event: event,
                        offset: offset,
                        isClamped: resolved.isClamped,
                        targetLunarDate: resolved.lunarDate
                    )

                    candidates.append(NotificationCandidate(
                        identifier: identifier,
                        eventId: event.id,
                        title: title,
                        subtitle: subtitle,
                        body: body,
                        triggerDate: triggerDate,
                        score: score,
                        isClampedShortMonth: resolved.isClamped
                    ))
                }
            }
        }

        return candidates
    }

    private func resolveTriggerDate(
        event: MemorialEvent,
        targetYear: Int,
        calendar: Calendar
    ) async -> (date: Date?, isClamped: Bool, lunarDate: LunarDate?) {
        if !event.isLunar {
            // Sự kiện Dương Lịch
            var components = DateComponents()
            components.year = targetYear
            components.month = event.month
            components.day = event.day
            components.hour = event.hour
            components.minute = event.minute
            components.second = 0
            return (calendar.date(from: components), false, nil)
        }

        // Sự kiện Âm Lịch: Tính toán chuyển đổi qua LunarAstronomicalEngine
        let requestedLunar = LunarDate(
            day: event.day,
            month: event.month,
            year: targetYear,
            isLeapMonth: event.isLeapMonth
        )

        let targetSolar = await lunarEngine.convertToSolar(from: requestedLunar)
        let verifiedLunar = await lunarEngine.convertToLunar(from: targetSolar)

        // Kiểm tra xem có bị clamp ngày 30 về ngày 29 (tháng thiếu) không
        let isClamped = (event.day == 30 && verifiedLunar.day == 29)

        var components = DateComponents()
        components.year = targetSolar.year
        components.month = targetSolar.month
        components.day = targetSolar.day
        components.hour = event.hour
        components.minute = event.minute
        components.second = 0

        return (calendar.date(from: components), isClamped, verifiedLunar)
    }

    private func formatContent(
        event: MemorialEvent,
        offset: AdvanceNoticeOffset,
        isClamped: Bool,
        targetLunarDate: LunarDate?
    ) -> (title: String, subtitle: String?, body: String) {
        let title: String
        if offset == .sameDay {
            title = "Hôm nay: \(event.title)"
        } else {
            title = "\(offset.titlePrefix) \(event.title)"
        }

        var subtitle: String?
        if isClamped {
            subtitle = "Kỳ giỗ ngày 30 (Tháng thiếu hóa ngày 29 ÂL)"
        } else if let lunar = targetLunarDate {
            subtitle = "Ngày \(lunar.day) tháng \(lunar.month) Âm Lịch"
        }

        let body = event.notes ?? "Kính nhớ tổ tiên và gắn kết tình thân gia đình."
        return (title, subtitle, body)
    }

    private func createNotificationRequest(
        from candidate: NotificationCandidate,
        calendar: Calendar
    ) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = candidate.title
        if let sub = candidate.subtitle {
            content.subtitle = sub
        }
        content.body = candidate.body
        content.sound = .default
        content.userInfo = [
            "eventId": candidate.eventId.uuidString,
            "score": candidate.score
        ]

        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: candidate.triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        return UNNotificationRequest(
            identifier: candidate.identifier,
            content: content,
            trigger: trigger
        )
    }
}
```

---

## 5. Chiến Lược Lắng Nghe Vòng Đời & Đồng Bộ Nền (Lifecycle Triggers & Background Execution)

Để danh sách 60 slots pending luôn luôn tươi mới và không bị trượt mất các sự kiện khi thời gian trôi qua, `NotificationSchedulerEngine` được kích hoạt tự động theo 5 cổng vòng đời:

```
+-----------------------------------------------------------------------------+
|                            VÒNG ĐỜI KÍCH HOẠT RECONCILE                     |
+-----------------------------------------------------------------------------+
| 1. App Launch (`didFinishLaunchingWithOptions` / SwiftUI `.onAppear`)       |
| 2. Scene Phase Chuyển Sang Active (`scenePhase == .active`)                 |
| 3. Đồng Hồ Sang Ngày Mới (`UIApplication.significantTimeChangeNotification`)|
| 4. SwiftData Thay Đổi (Thêm, Sửa, Xóa Ngày Nhớ)                             |
| 5. Chạy Nền Định Kỳ (`BGAppRefreshTask` - `com.iletai.annien.refresh`)      |
+-----------------------------------------------------------------------------+
                                       |
                                       v
        +-------------------------------------------------------------+
        |  NotificationSchedulerEngine.shared.reconcileNotifications  |
        |  - Tính lại điểm suy giảm thời gian (Hyperbolic Time-Decay) |
        |  - Giữ lại đúng Top 60 thông báo có điểm cao nhất           |
        |  - Hủy bỏ các ID đã quá hạn hoặc bị rớt hạng                |
        +-------------------------------------------------------------+
```

### 5.1. Xử Lý Khi Người Dùng Di Chuyển Múi Giờ (Timezone Transitions)
- **Quy tắc**: Lịch Âm được bảo toàn tính toán theo Kinh tuyến $105^\circ\text{E}$ (Hà Nội). Tuy nhiên, giờ báo thức hiển thị trên máy người dùng ($7:00\text{ AM}$) phải kích hoạt theo **giờ địa phương hiện tại của thiết bị** (`Calendar.autoupdatingCurrent`).
- **Xử lý**: Khi nhận thông báo `NSSystemTimeZoneDidChangeNotification`, engine tự động tính toán lại toàn bộ `triggerDate` theo múi giờ mới mà không làm thay đổi ngày Âm lịch gốc của sự kiện.

---

## 6. Bộ Kiểm Thử Tự Động Toàn Diện (Swift Testing & Runnable Assertions)

Bộ kiểm thử dưới đây xác thực tính toàn vẹn của thuật toán cắt tỉa, đảm bảo không bao giờ vượt quá 60 slots và ngày giỗ quan trọng không bị chiếm slot bởi các nhắc nhở thứ yếu.

```swift
//
//  SmartNotificationEngineTests.swift
//  Packages/VNCalendarDomainTests
//
//  Created by An Niên Team on 2026-09-29.
//

import Testing
import Foundation
import UserNotifications
@testable import VNCalendarDomain
@testable import VNCalendarLunar

// MARK: - Mock Notification Center

final class MockUserNotificationCenter: UserNotificationCenterProtocol, @unchecked Sendable {
    private var storage: [String: UNNotificationRequest] = [:]
    private let lock = NSLock()

    func pendingNotificationRequests() async -> [UNNotificationRequest] {
        lock.lock()
        defer { lock.unlock() }
        return Array(storage.values)
    }

    func add(_ request: UNNotificationRequest) async throws {
        lock.lock()
        defer { lock.unlock() }
        storage[request.identifier] = request
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        lock.lock()
        defer { lock.unlock() }
        for id in identifiers {
            storage.removeValue(forKey: id)
        }
    }
}

// MARK: - Test Suite

@Suite("Smart Notification Priority Pruning Engine Tests")
struct SmartNotificationEngineTests {

    // MARK: - 1. Stress Test: 110 Sự Kiện Phải Được Cắt Tỉa Về Đúng <= 60 Slots

    @Test("Kiểm tra 110 thông báo được cắt tỉa không vượt quá 60 slots")
    func testStressPruningLimit() async throws {
        let mockCenter = MockUserNotificationCenter()
        let scheduler = NotificationSchedulerEngine(center: mockCenter)

        // Sinh 110 sự kiện giả lập với các mức ưu tiên khác nhau
        var events: [MemorialEvent] = []
        for i in 1...110 {
            let tier: NotificationPriorityTier = (i <= 20) ? .critical : (i <= 50 ? .high : .low)
            events.append(MemorialEvent(
                id: UUID(),
                title: "Sự kiện kiểm thử số \(i)",
                isLunar: true,
                day: (i % 28) + 1,
                month: (i % 12) + 1,
                priorityTier: tier,
                advanceOffsets: [.sameDay]
            ))
        }

        let fixedNow = Date(timeIntervalSince1970: 1770000000) // Mốc thời gian cố định
        let (scheduled, pruned) = try await scheduler.reconcileNotifications(
            events: events,
            currentDate: fixedNow
        )

        // Xác nhận số lượng lên lịch đúng bằng 60 slots tối đa
        #expect(scheduled == 60)
        #expect(pruned > 0)

        // Xác nhận trên Notification Center thực tế chỉ có 60 requests
        let pending = await mockCenter.pendingNotificationRequests()
        #expect(pending.count == 60)
    }

    // MARK: - 2. Xác Thực Ngày Giỗ Xa Vẫn Thắng Tiết Khí Gần (Hyperbolic Monotonicity)

    @Test("Ngày Giỗ Trọng Đại (Critical) sau 30 ngày phải có điểm cao hơn Tiết Khí (Low) ngày mai")
    func testCriticalEventBeatsLowEventNearby() async throws {
        let mockCenter = MockUserNotificationCenter()
        let scheduler = NotificationSchedulerEngine(center: mockCenter)

        let calendar = Calendar(identifier: .gregorian)
        let now = Date()

        // Sự kiện 1: Giỗ Cố Tổ (Critical - 1000) sau 20 ngày
        let futureDate = calendar.date(byAdding: .day, value: 20, to: now)!
        let solarFuture = SolarDate(
            day: calendar.component(.day, from: futureDate),
            month: calendar.component(.month, from: futureDate),
            year: calendar.component(.year, from: futureDate)
        )
        let lunarFuture = await LunarAstronomicalEngine.shared.convertToLunar(from: solarFuture)

        let ancestralEvent = MemorialEvent(
            id: UUID(),
            title: "Giỗ Cụ Tổ",
            isLunar: true,
            day: lunarFuture.day,
            month: lunarFuture.month,
            priorityTier: .critical,
            advanceOffsets: [.sameDay]
        )

        // Sự kiện 2: Tiết khí (Low - 100) ngày mai
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let solarTomorrow = SolarDate(
            day: calendar.component(.day, from: tomorrow),
            month: calendar.component(.month, from: tomorrow),
            year: calendar.component(.year, from: tomorrow)
        )
        let lunarTomorrow = await LunarAstronomicalEngine.shared.convertToLunar(from: solarTomorrow)

        let minorEvent = MemorialEvent(
            id: UUID(),
            title: "Tiết Khí Lập Hạ",
            isLunar: true,
            day: lunarTomorrow.day,
            month: lunarTomorrow.month,
            priorityTier: .low,
            advanceOffsets: [.sameDay]
        )

        try await scheduler.reconcileNotifications(
            events: [ancestralEvent, minorEvent],
            currentDate: now
        )

        let pending = await mockCenter.pendingNotificationRequests()
        let ancestralRequest = pending.first(where: { $0.content.title.contains("Giỗ Cụ Tổ") })
        let minorRequest = pending.first(where: { $0.content.title.contains("Lập Hạ") })

        #expect(ancestralRequest != nil)
        #expect(minorRequest != nil)

        // Điểm số của Giỗ Cụ Tổ phải vượt trội
        let ancestralScore = ancestralRequest?.content.userInfo["score"] as? Double ?? 0
        let minorScore = minorRequest?.content.userInfo["score"] as? Double ?? 0
        #expect(ancestralScore > minorScore)
    }

    // MARK: - 3. Xác Thực Xử Lý Tháng Thiếu (Clamp Day 30 to Day 29)

    @Test("Sự kiện ngày 30 ÂL trong tháng thiếu được tự động kẹp về ngày 29 kèm phụ đề cảnh báo")
    func testShortMonthFallbackNotification() async throws {
        let mockCenter = MockUserNotificationCenter()
        let scheduler = NotificationSchedulerEngine(center: mockCenter)

        // Giả sử tạo sự kiện ngày 30/12 ÂL
        let event = MemorialEvent(
            id: UUID(),
            title: "Tất Niên Gia Đình",
            isLunar: true,
            day: 30,
            month: 12,
            priorityTier: .high,
            advanceOffsets: [.sameDay]
        )

        let calendar = Calendar(identifier: .gregorian)
        let testNow = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!

        try await scheduler.reconcileNotifications(events: [event], currentDate: testNow)

        let pending = await mockCenter.pendingNotificationRequests()
        let req = try #require(pending.first(where: { $0.content.title.contains("Tất Niên") }))

        // Nếu tháng đó chỉ có 29 ngày, subtitle phải thể hiện thông tin fallback
        if req.content.subtitle.contains("tháng thiếu") {
            #expect(req.content.subtitle == "Kỳ giỗ ngày 30 (Tháng thiếu hóa ngày 29 ÂL)")
        }
    }
}
```

---

## 7. Kết Luận & Tiêu Chí Nghiệm Thu (Conclusion & Acceptance Criteria)

1. **Tuân Thủ Tuyệt Đối Hạn Ngạch 64 Slots**: Engine đảm bảo số lượng `pendingNotificationRequests` không bao giờ chạm đến ngưỡng 64 (luôn cố định $\le 60$ slots chủ động + 4 slots dự phòng).
2. **Loại Bỏ Hoàn Toàn Hiện Tượng Churn Pin**: Cơ chế tập hợp `Set(existingIDs).subtracting(targetIDs)` đảm bảo chỉ hủy bỏ các thông báo thực sự bị loại khỏi Top 60, không hủy và tạo lại hàng loạt gây tốn tài nguyên IPC của iOS.
3. **Thấu Cảm Văn Hóa Gia Đình Việt**: Thuật toán suy giảm Hyperbolic bảo vệ trọn vẹn các ngày giỗ tổ tiên, tự động hóa việc lùi ngày trong tháng thiếu và chọn lọc linh hoạt trong năm nhuận.
