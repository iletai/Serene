# Tầng Dữ Liệu SwiftData & Cơ Chế Đồng Bộ CloudKit (Data Layer & CloudKit Sync)

Tài liệu đặc tả toàn diện tầng dữ liệu lưu trữ nội bộ (Offline Persistence) sử dụng **SwiftData** kết hợp đồng bộ hóa đám mây **iCloud Private Database (CloudKit)** trên nền tảng **iOS 17.0+ / iOS 18.0+**, áp dụng **Swift 6 Concurrency (`@ModelActor`)**, và kiến trúc **Reactive Repository (Combine + AsyncStream)**.

---

## 1. Xác Minh & Tuân Thủ Các Ràng Buộc SwiftData + CloudKit Trên iOS 17/18

Khi kích hoạt tính năng tự động đồng bộ hóa CloudKit qua `ModelConfiguration(cloudKitDatabase: .private(...))`, engine CoreData/CloudKit áp đặt các quy tắc khắt khe về Schema. Việc vi phạm bất kỳ quy tắc nào sẽ dẫn đến lỗi crash `NSPersistentStoreInvalidAttributeException` tại runtime hoặc CloudKit âm thầm vô hiệu hóa tính năng đồng bộ.

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                    BẢNG KIỂM TRA RÀNG BUỘC CLOUDKIT TRÊN SWIFTDATA                      │
├───────────────────────────────┬──────────────────────────────────┬──────────────────────┤
│ Ràng Buộc Hệ Thống           │ Trạng Thái / Hành Vi Lỗi         │ Giải Pháp Kỹ Thuật   │
├───────────────────────────────┼──────────────────────────────────┼──────────────────────┤
│ 1. Không dùng @Attribute(.unique)│ LỖI CRASH: CloudKit không hỗ trợ │ Ứng dụng Deduplication│
│                               │ unique index trên Private Zone   │ Upsert ở tầng App    │
├───────────────────────────────┼──────────────────────────────────┼──────────────────────┤
│ 2. Thuộc tính phải có Default │ LỖI SCHEMA: Không thể decode     │ Khởi tạo giá trị mặc │
│    Value hoặc là Optional (?) │ CKRecord khi nâng cấp phiên bản  │ định cho mọi thuộc tính│
├───────────────────────────────┼──────────────────────────────────┼──────────────────────┤
│ 3. Quan hệ (Relationships)     │ LỖI INTEGRITY: Không thể duy trì │ Khai báo Optional (?)│
│    phải Optional & có Inverse │ tính toàn vẹn khóa ngoại trên mây│ hoặc [] + @Relationship│
├───────────────────────────────┼──────────────────────────────────┼──────────────────────┤
│ 4. Chỉ hỗ trợ Private Container│ LỖI PERMISSION: SwiftData tự     │ Chỉ dùng .private,   │
│                               │ động không hỗ trợ Public/Shared  │ không dùng Shared    │
├───────────────────────────────┼──────────────────────────────────┼──────────────────────┤
│ 5. Kiểu dữ liệu tương thích   │ Kiểu phức tạp không decode được  │ Primitive, Date, UUID│
│                               │ nếu không conform Codable        │ hoặc Data transform  │
└───────────────────────────────┴──────────────────────────────────┴──────────────────────┘
```

### 1.1. Chi Tiết Ràng Buộc & Giải Pháp Thiết Kế

1. **Tuyệt đối không sử dụng `@Attribute(.unique)`**:
   - *Nguyên nhân*: CloudKit lưu trữ các bản ghi dưới dạng `CKRecord` phân tán. Cơ chế đồng bộ không hỗ trợ kiểm tra ràng buộc duy nhất (Unique Constraint) mang tính nguyên tử trên toàn cụm. Khai báo `.unique` khiến SwiftData từ chối đính kèm `NSPersistentCloudKitContainer`.
   - *Giải pháp*: Tạo thuộc tính `id: UUID = UUID()` với giá trị mặc định. Xử lý deduplication (khử trùng lặp) thông qua `FetchDescriptor` và câu truy vấn Predicate trước khi `insert` ở tầng Repository.

2. **Mọi thuộc tính phải có giá trị mặc định (Default Value) hoặc là Optional (`?`)**:
   - *Nguyên nhân*: Khi người dùng cập nhật schema ở phiên bản app mới, các bản ghi cũ được kéo về từ CloudKit sẽ thiếu các trường dữ liệu mới. Nếu không có giá trị mặc định, quá trình giải mã `CKRecord` sẽ thất bại.
   - *Giải pháp*: Toàn bộ stored properties trong `@Model` đều gán giá trị khởi tạo rõ ràng hoặc là `Optional`.

3. **Toàn bộ quan hệ phải là Optional hoặc Mảng rỗng và có `@Relationship(inverse: ...)` tường minh**:
   - *Nguyên nhân*: CloudKit đồng bộ từng record độc lập. Trong khoảng thời gian giữa các gói mạng, quan hệ cha-con có thể bị đứt gãy tạm thời.
   - *Giải pháp*: Mọi quan hệ $1 - N$ hoặc $N - N$ phải có `inverse` trỏ ngược lại và có giá trị mặc định `[]`.

4. **Chỉ sử dụng iCloud Private Container**:
   - SwiftData tích hợp sẵn với CloudKit qua cơ chế `ModelConfiguration(cloudKitDatabase: .private(containerID))`. Không hỗ trợ `public` hay `shared` database thông qua tự động hóa của SwiftData.

---

## 2. Mô Hình Thực Thể SwiftData (Production-Grade Models)

Toàn bộ các thực thể lưu trữ dữ liệu tuân thủ 100% các ràng buộc CloudKit:

### 2.1. Thực Thể `ReminderItemEntity` (Lịch Giỗ Chạp & Ngày Nhớ)

```swift
import Foundation
import SwiftData

/// SwiftData Entity representing a lunar/solar remembrance or memorial event.
/// Strictly adheres to CloudKit constraints: No @Attribute(.unique), all fields have defaults or are optional.
@Model
public final class ReminderItemEntity {
    // Primary identifier (Generated locally, synced via CloudKit)
    public var id: UUID = UUID()
    
    // Core event details
    public var title: String = ""
    public var notes: String? = nil
    
    // Calendar system and date definitions
    public var isLunarCalendar: Bool = true
    public var day: Int = 1
    public var month: Int = 1
    public var baseSolarDate: Date = Date()
    
    // Memorial & recurrence classification
    public var categoryRawValue: String = "memorial" // memorial (giỗ), birthday, ancestral, other
    public var priorityRawValue: String = "critical" // critical (cha mẹ), high, medium, low
    public var isLeapMonthAllowed: Bool = false
    public var fallbackToPrecedingDayIfMissing: Bool = true // Auto-shift 30th lunar to 29th in short months
    
    // Notification & alert preferences
    public var isNotificationEnabled: Bool = true
    public var advanceNoticeDays: [Int] = [0, 1] // Remind on exact day and 1 day prior
    public var reminderTimeHour: Int = 7
    public var reminderTimeMinute: Int = 0
    
    // Metadata & Conflict Resolution
    public var createdAt: Date = Date()
    public var updatedAt: Date = Date()
    public var isDeleted: Bool = false // Soft delete flag for tombstone sync
    
    // Relationships (Optional with explicit inverse)
    @Relationship(deleteRule: .cascade, inverse: \MemoryEventEntity.reminder)
    public var memoryEvents: [MemoryEventEntity]? = []
    
    public init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        isLunarCalendar: Bool = true,
        day: Int,
        month: Int,
        baseSolarDate: Date = Date(),
        categoryRawValue: String = "memorial",
        priorityRawValue: String = "critical",
        isLeapMonthAllowed: Bool = false,
        fallbackToPrecedingDayIfMissing: Bool = true,
        isNotificationEnabled: Bool = true,
        advanceNoticeDays: [Int] = [0, 1],
        reminderTimeHour: Int = 7,
        reminderTimeMinute: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isDeleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.isLunarCalendar = isLunarCalendar
        self.day = day
        self.month = month
        self.baseSolarDate = baseSolarDate
        self.categoryRawValue = categoryRawValue
        self.priorityRawValue = priorityRawValue
        self.isLeapMonthAllowed = isLeapMonthAllowed
        self.fallbackToPrecedingDayIfMissing = fallbackToPrecedingDayIfMissing
        self.isNotificationEnabled = isNotificationEnabled
        self.advanceNoticeDays = advanceNoticeDays
        self.reminderTimeHour = reminderTimeHour
        self.reminderTimeMinute = reminderTimeMinute
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isDeleted = isDeleted
        self.memoryEvents = []
    }
}
```

### 2.2. Thực Thể `MemoryEventEntity` (Dòng Thời Gian & Kỷ Niệm Gia Phả)

```swift
import Foundation
import SwiftData

/// SwiftData Entity tracking historical records or family lineage milestones.
@Model
public final class MemoryEventEntity {
    public var id: UUID = UUID()
    public var eventYear: Int = 2026
    public var recordedNotes: String? = nil
    public var photoLocalPath: String? = nil
    public var createdAt: Date = Date()
    public var updatedAt: Date = Date()
    
    // Inverse relationship (Must be Optional)
    public var reminder: ReminderItemEntity?
    
    public init(
        id: UUID = UUID(),
        eventYear: Int = 2026,
        recordedNotes: String? = nil,
        photoLocalPath: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        reminder: ReminderItemEntity? = nil
    ) {
        self.id = id
        self.eventYear = eventYear
        self.recordedNotes = recordedNotes
        self.photoLocalPath = photoLocalPath
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.reminder = reminder
    }
}
```

### 2.3. Thực Thể `HolidayEntity` & `SyncMetadataEntity`

```swift
import Foundation
import SwiftData

/// Local offline cache for holidays synced from microCMS or bundled fallback JSON.
@Model
public final class HolidayEntity {
    public var id: String = "" // Content ID from microCMS or bundle
    public var title: String = ""
    public var calendarTypeRawValue: String = "lunar" // solar or lunar
    public var day: Int = 1
    public var month: Int = 1
    public var isNationalHoliday: Bool = false
    public var isTraditionHoliday: Bool = true
    public var summary: String = ""
    public var customs: String? = nil
    public var taboos: String? = nil
    public var rituals: String? = nil
    public var updatedAt: Date = Date()
    
    public init(
        id: String,
        title: String,
        calendarTypeRawValue: String = "lunar",
        day: Int,
        month: Int,
        isNationalHoliday: Bool = false,
        isTraditionHoliday: Bool = true,
        summary: String = "",
        customs: String? = nil,
        taboos: String? = nil,
        rituals: String? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.calendarTypeRawValue = calendarTypeRawValue
        self.day = day
        self.month = month
        self.isNationalHoliday = isNationalHoliday
        self.isTraditionHoliday = isTraditionHoliday
        self.summary = summary
        self.customs = customs
        self.taboos = taboos
        self.rituals = rituals
        self.updatedAt = updatedAt
    }
}

/// Metadata tracker for HTTP ETag and CloudKit sync state.
@Model
public final class SyncMetadataEntity {
    public var endpoint: String = ""
    public var etag: String? = nil
    public var lastSyncTimestamp: Date = Date()
    public var schemaVersion: Int = 1
    
    public init(
        endpoint: String,
        etag: String? = nil,
        lastSyncTimestamp: Date = Date(),
        schemaVersion: Int = 1
    ) {
        self.endpoint = endpoint
        self.etag = etag
        self.lastSyncTimestamp = lastSyncTimestamp
        self.schemaVersion = schemaVersion
    }
}
```

---

## 3. Khởi Tạo `ModelContainer` & Giám Sát Vòng Đời CloudKit

`ModelContainerFactory` chịu trách nhiệm khởi tạo `ModelContainer` với cấu hình phân tách giữa môi trường `Development` và `Production`, hỗ trợ lưu trữ trong thư mục dùng chung của **App Group** để Widget Extension có thể đọc dữ liệu trực tiếp.

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                             ModelContainer Configuration                                │
├─────────────────────────────────────────┬───────────────────────────────────────────────┤
│ Scheme: AnNien-Dev                      │ Scheme: AnNien-Prod                           │
│ - Container ID: iCloud.com.iletai.annien.dev│ - Container ID: iCloud.com.iletai.annien  │
│ - App Group: group.com.iletai.annien.dev│ - App Group: group.com.iletai.annien          │
│ - Store URL: .../group.com.iletai.annien.dev/default.store                              │
│ - CloudKit Database: .private           │ - CloudKit Database: .private                 │
└─────────────────────────────────────────┴───────────────────────────────────────────────┘
```

### 3.1. Production Swift Code: `ModelContainerFactory.swift`

```swift
import Foundation
import SwiftData
import CloudKit
import os.log

private let logger = Logger(subsystem: "com.iletai.annien", category: "ModelContainerFactory")

public enum ModelContainerFactory {
    
    /// Creates a production ModelContainer configured for CloudKit private sync and App Group storage.
    @MainActor
    public static func createContainer(
        containerIdentifier: String,
        appGroupIdentifier: String,
        inMemoryOnly: Bool = false
    ) -> ModelContainer {
        let schema = Schema([
            ReminderItemEntity.self,
            MemoryEventEntity.self,
            HolidayEntity.self,
            SyncMetadataEntity.self
        ])
        
        if inMemoryOnly {
            let memoryConfig = ModelConfiguration(
                "InMemoryStore",
                schema: schema,
                isStoredInMemoryOnly: true
            )
            do {
                return try ModelContainer(for: schema, configurations: [memoryConfig])
            } catch {
                fatalError("Failed to create in-memory ModelContainer: \(error.localizedDescription)")
            }
        }
        
        // Resolve shared store directory within App Group container
        guard let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            fatalError("Could not access App Group container URL for: \(appGroupIdentifier)")
        }
        
        let storeURL = groupURL.appendingPathComponent("AnNienDatabase.sqlite")
        
        let cloudKitConfig = ModelConfiguration(
            "AnNienCloudStore",
            schema: schema,
            url: storeURL,
            allowsSave: true,
            cloudKitDatabase: .private(containerIdentifier)
        )
        
        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [cloudKitConfig]
            )
            logger.info("Successfully initialized SwiftData container at: \(storeURL.path)")
            return container
        } catch {
            logger.error("Failed to initialize SwiftData ModelContainer: \(error.localizedDescription)")
            
            // Fallback strategy: Initialize local-only container to prevent app launch crash
            let fallbackConfig = ModelConfiguration(
                "AnNienFallbackLocalStore",
                schema: schema,
                url: storeURL,
                cloudKitDatabase: .none
            )
            do {
                return try ModelContainer(for: schema, configurations: [fallbackConfig])
            } catch {
                fatalError("Critical failure: Cannot initialize fallback local store: \(error.localizedDescription)")
            }
        }
    }
    
    /// Creates an ephemeral container for testing and SwiftUI Previews.
    @MainActor
    public static func createInMemoryContainer() -> ModelContainer {
        createContainer(
            containerIdentifier: "iCloud.mock",
            appGroupIdentifier: "group.mock",
            inMemoryOnly: true
        )
    }
}
```

### 3.2. Giám Sát Trạng Thái iCloud & Sự Kiện Đồng Bộ Từ Xa (`CloudKitSyncMonitor`)

```swift
import Foundation
import Combine
import CloudKit
import SwiftData
import os.log

public enum ICloudAccountStatus: Sendable {
    case available
    case noAccount
    case restricted
    case temporarilyUnavailable
    case unknown
}

/// Actor monitoring iCloud account availability and remote data merge notifications.
public actor CloudKitSyncMonitor {
    private let containerIdentifier: String
    private let logger = Logger(subsystem: "com.iletai.annien", category: "CloudKitSyncMonitor")
    
    private var statusSubject = CurrentValueSubject<ICloudAccountStatus, Never>(.unknown)
    public var statusPublisher: AnyPublisher<ICloudAccountStatus, Never> {
        statusSubject.eraseToAnyPublisher()
    }
    
    public init(containerIdentifier: String) {
        self.containerIdentifier = containerIdentifier
        Task {
            await verifyAccountStatus()
            await setupNotificationObservers()
        }
    }
    
    /// Queries the current iCloud status via CKContainer
    public func verifyAccountStatus() async -> ICloudAccountStatus {
        let container = CKContainer(identifier: containerIdentifier)
        do {
            let status = try await container.accountStatus()
            let resolved: ICloudAccountStatus
            switch status {
            case .available:
                resolved = .available
                logger.info("iCloud account is available and active.")
            case .noAccount:
                resolved = .noAccount
                logger.warning("No iCloud account signed in.")
            case .restricted:
                resolved = .restricted
                logger.warning("iCloud account is restricted (e.g. Parental Controls).")
            case .temporarilyUnavailable:
                resolved = .temporarilyUnavailable
                logger.warning("iCloud account temporarily unavailable.")
            case .couldNotDetermine:
                resolved = .unknown
                logger.error("Could not determine iCloud status.")
            @unknown default:
                resolved = .unknown
            }
            statusSubject.send(resolved)
            return resolved
        } catch {
            logger.error("Error querying iCloud account status: \(error.localizedDescription)")
            statusSubject.send(.unknown)
            return .unknown
        }
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .CKAccountChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { [weak self] in
                await self?.verifyAccountStatus()
            }
        }
        
        // Listen to CoreData/SwiftData Remote Store Sync changes
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NSPersistentStoreRemoteChangeNotification"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.logger.info("Received remote CloudKit change notification. Triggering UI refresh.")
        }
    }
}
```

---

## 4. Tầng Repository Bất Đồng Bộ Với `@ModelActor` (Swift 6 Strict Concurrency)

Để đảm bảo hiệu năng tối đa và không gây nghẽn luồng giao diện chính (`MainActor`), mọi thao tác ghi, cập nhật hàng loạt (batch write), và tính toán khử trùng lặp được thực thi bên trong một `@ModelActor`.

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                               SwiftData Concurrency Flow                                │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│ [MainActor / UI View] ──(Calls async CRUD)──► [SwiftDataReminderRepository]              │
│                                                        │                                │
│                                                        ▼                                │
│                                            [ReminderDataActor (@ModelActor)]            │
│                                            - Isolated Background ModelContext           │
│                                            - Performs Predicate query, Upsert, Delete   │
│                                            - Saves Context safely off Main Thread       │
│                                                        │                                │
│ [MainActor / UI View] ◄──(Streams updates)─── [AsyncStream / Combine Publisher]         │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

### 4.1. Production Swift Code: `ReminderDataActor.swift`

```swift
import Foundation
import SwiftData
import VNCalendarDomain

/// Thread-safe background executor for database mutations using SwiftData ModelActor.
@ModelActor
public actor ReminderDataActor {
    
    // MARK: - Fetch Operations
    
    public func fetchActiveReminders() throws -> [ReminderItem] {
        let descriptor = FetchDescriptor<ReminderItemEntity>(
            predicate: #Predicate { !$0.isDeleted },
            sortBy: [SortDescriptor(\.month), SortDescriptor(\.day)]
        )
        let entities = try modelContext.fetch(descriptor)
        return entities.map { $0.toDomainModel() }
    }
    
    public func fetchReminder(byId id: UUID) throws -> ReminderItem? {
        let descriptor = FetchDescriptor<ReminderItemEntity>(
            predicate: #Predicate { $0.id == id && !$0.isDeleted }
        )
        return try modelContext.fetch(descriptor).first?.toDomainModel()
    }
    
    // MARK: - Upsert Operations (Deduplication Pattern for CloudKit)
    
    public func saveOrUpdate(domainItem: ReminderItem) throws {
        let targetId = domainItem.id
        var descriptor = FetchDescriptor<ReminderItemEntity>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1
        
        let existing = try modelContext.fetch(descriptor).first
        
        if let existing = existing {
            // Last-Writer-Wins timestamp check
            if domainItem.updatedAt >= existing.updatedAt {
                existing.title = domainItem.title
                existing.notes = domainItem.notes
                existing.isLunarCalendar = domainItem.isLunarCalendar
                existing.day = domainItem.day
                existing.month = domainItem.month
                existing.baseSolarDate = domainItem.baseSolarDate
                existing.categoryRawValue = domainItem.category.rawValue
                existing.priorityRawValue = domainItem.priority.rawValue
                existing.isLeapMonthAllowed = domainItem.isLeapMonthAllowed
                existing.fallbackToPrecedingDayIfMissing = domainItem.fallbackToPrecedingDayIfMissing
                existing.isNotificationEnabled = domainItem.isNotificationEnabled
                existing.advanceNoticeDays = domainItem.advanceNoticeDays
                existing.reminderTimeHour = domainItem.reminderTimeHour
                existing.reminderTimeMinute = domainItem.reminderTimeMinute
                existing.updatedAt = domainItem.updatedAt
                existing.isDeleted = false
            }
        } else {
            let newEntity = ReminderItemEntity(
                id: domainItem.id,
                title: domainItem.title,
                notes: domainItem.notes,
                isLunarCalendar: domainItem.isLunarCalendar,
                day: domainItem.day,
                month: domainItem.month,
                baseSolarDate: domainItem.baseSolarDate,
                categoryRawValue: domainItem.category.rawValue,
                priorityRawValue: domainItem.priority.rawValue,
                isLeapMonthAllowed: domainItem.isLeapMonthAllowed,
                fallbackToPrecedingDayIfMissing: domainItem.fallbackToPrecedingDayIfMissing,
                isNotificationEnabled: domainItem.isNotificationEnabled,
                advanceNoticeDays: domainItem.advanceNoticeDays,
                reminderTimeHour: domainItem.reminderTimeHour,
                reminderTimeMinute: domainItem.reminderTimeMinute,
                createdAt: domainItem.createdAt,
                updatedAt: domainItem.updatedAt,
                isDeleted: false
            )
            modelContext.insert(newEntity)
        }
        
        try modelContext.save()
    }
    
    // MARK: - Soft Delete (CloudKit Tombstone Sync)
    
    public func markAsDeleted(id: UUID) throws {
        var descriptor = FetchDescriptor<ReminderItemEntity>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        
        if let existing = try modelContext.fetch(descriptor).first {
            existing.isDeleted = true
            existing.updatedAt = Date()
            try modelContext.save()
        }
    }
    
    // MARK: - Batch Pruning of Tombstones
    
    public func purgeOldDeletedRecords(olderThan date: Date) throws {
        let descriptor = FetchDescriptor<ReminderItemEntity>(
            predicate: #Predicate { $0.isDeleted && $0.updatedAt < date }
        )
        let deletedEntities = try modelContext.fetch(descriptor)
        for entity in deletedEntities {
            modelContext.delete(entity)
        }
        try modelContext.save()
    }
}

// MARK: - Domain Mapping Extension
extension ReminderItemEntity {
    func toDomainModel() -> ReminderItem {
        ReminderItem(
            id: self.id,
            title: self.title,
            notes: self.notes,
            isLunarCalendar: self.isLunarCalendar,
            day: self.day,
            month: self.month,
            baseSolarDate: self.baseSolarDate,
            category: ReminderCategory(rawValue: self.categoryRawValue) ?? .memorial,
            priority: ReminderPriority(rawValue: self.priorityRawValue) ?? .critical,
            isLeapMonthAllowed: self.isLeapMonthAllowed,
            fallbackToPrecedingDayIfMissing: self.fallbackToPrecedingDayIfMissing,
            isNotificationEnabled: self.isNotificationEnabled,
            advanceNoticeDays: self.advanceNoticeDays,
            reminderTimeHour: self.reminderTimeHour,
            reminderTimeMinute: self.reminderTimeMinute,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt
        )
    }
}
```

---

## 5. Reactive Repository Pattern (Combine & AsyncStream)

Tầng giao diện người dùng (SwiftUI Views và ViewModels) nhận luồng dữ liệu cập nhật thời gian thực thông qua protocol `ReminderRepositoryProtocol`.

### 5.1. Production Swift Code: `ReminderRepositoryProtocol.swift`

```swift
import Foundation
import Combine
import VNCalendarDomain

public protocol ReminderRepositoryProtocol: Sendable {
    /// Reactive stream of active reminders using Swift 6 AsyncStream
    func observeReminders() -> AsyncStream<[ReminderItem]>
    
    /// Reactive publisher of active reminders using Combine
    func observeRemindersPublisher() -> AnyPublisher<[ReminderItem], Never>
    
    /// Fetches all active reminders currently stored locally
    func getAllReminders() async throws -> [ReminderItem]
    
    /// Fetches a specific reminder by ID
    func getReminder(byId id: UUID) async throws -> ReminderItem?
    
    /// Inserts or updates a reminder with deduplication
    func saveReminder(_ item: ReminderItem) async throws
    
    /// Soft deletes a reminder (propagates delete tombstone to CloudKit)
    func deleteReminder(byId id: UUID) async throws
}
```

### 5.2. Production Swift Code: `SwiftDataReminderRepository.swift`

```swift
import Foundation
import Combine
import SwiftData
import VNCalendarDomain

public final class SwiftDataReminderRepository: ReminderRepositoryProtocol, @unchecked Sendable {
    private let dataActor: ReminderDataActor
    private let changeSubject = CurrentValueSubject<[ReminderItem], Never>([])
    private var cancellables = Set<AnyCancellable>()
    
    public init(modelContainer: ModelContainer) {
        self.dataActor = ReminderDataActor(modelContainer: modelContainer)
        
        // Initial fetch & subscribe to remote store changes
        Task {
            await refreshMemoryCache()
        }
        
        NotificationCenter.default.publisher(for: NSNotification.Name("NSPersistentStoreRemoteChangeNotification"))
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.refreshMemoryCache()
                }
            }
            .store(in: &cancellables)
    }
    
    private func refreshMemoryCache() async {
        do {
            let items = try await dataActor.fetchActiveReminders()
            changeSubject.send(items)
        } catch {
            // Silently retain previous cache state
        }
    }
    
    // MARK: - Protocol Methods
    
    public func observeReminders() -> AsyncStream<[ReminderItem]> {
        AsyncStream { continuation in
            let cancellable = changeSubject.sink { items in
                continuation.yield(items)
            }
            
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
    
    public func observeRemindersPublisher() -> AnyPublisher<[ReminderItem], Never> {
        changeSubject.eraseToAnyPublisher()
    }
    
    public func getAllReminders() async throws -> [ReminderItem] {
        try await dataActor.fetchActiveReminders()
    }
    
    public func getReminder(byId id: UUID) async throws -> ReminderItem? {
        try await dataActor.fetchReminder(byId: id)
    }
    
    public func saveReminder(_ item: ReminderItem) async throws {
        try await dataActor.saveOrUpdate(domainItem: item)
        await refreshMemoryCache()
    }
    
    public func deleteReminder(byId id: UUID) async throws {
        try await dataActor.markAsDeleted(id: id)
        await refreshMemoryCache()
    }
}
```

---

## 6. Chiến Lược Xử Lý Xung Đột & Ngoại Tuyến (Conflict Resolution & Offline Strategy)

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                      LIFECYCLE XỬ LÝ DỮ LIỆU & ĐỒNG BỘ NGOẠI TUYẾN                      │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                         │
│  [Thiết bị Offline] ──► Ghi vào SQLite Local Store ──► Cập nhật updatedAt = Date()       │
│                                                                                         │
│  [Thiết bị Online]  ──► CloudKit Push/Pull ──► Bắt NSPersistentStoreRemoteChange       │
│                                                                                         │
│  [Xung đột Dữ liệu] ──► Last-Writer-Wins (So khớp trường updatedAt)                     │
│                         - Bản ghi có timestamp lớn hơn sẽ ghi đè thuộc tính             │
│                         - Tombstone (isDeleted = true) được giữ 30 ngày trước khi purge │
│                                                                                         │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

1. **Khả năng hoạt động 100% Offline**: Ứng dụng đọc/ghi trực tiếp vào SQLite cục bộ. SwiftData tự động xếp hàng các thao tác thay đổi vào hàng đợi đồng bộ và tải lên CloudKit ngay khi có kết nối mạng.
2. **Chiến lược Last-Writer-Wins**: So khớp `updatedAt` ở mức trường (field-level) hoặc toàn bộ bản ghi. Nếu thiết bị A sửa lúc 10:00 và thiết bị B sửa lúc 10:05 mà không có mạng, khi cả hai lên mạng, bản ghi lúc 10:05 của thiết bị B sẽ thắng.
3. **Quản lý Tombstone (Xóa mềm)**: Để tránh trường hợp thiết bị A xóa một bản ghi khi offline và thiết bị B tạo lại bản ghi đó từ CloudKit, thao tác xóa được đánh dấu `isDeleted = true`. Một định kỳ dọn dẹp chạy mỗi 30 ngày sẽ xóa hoàn toàn các tombstone đã cũ.

---

## 7. Ma Trận Kiểm Thử Tầng Dữ Liệu (Data Layer QA Matrix)

1. **CloudKit Schema Compatibility**: Chạy test suite khởi tạo `ModelContainer` với tham số `.private(...)`, đảm bảo không xuất hiện bất kỳ crash nào liên quan đến schema.
2. **Offline Data Insertion**: Ngắt kết nối mạng giả lập, thực hiện ghi 100 bản ghi `ReminderItem`, xác minh đọc lại từ SQLite thành công 100%.
3. **AsyncStream Emission**: Kiểm tra `AsyncStream` phát ra sự kiện mới ngay lập tức mỗi khi gọi `saveReminder()` hoặc `deleteReminder()`.
4. **Thread Isolation**: Xác minh toàn bộ thao tác SQL diễn ra trên background actor, luồng `MainActor` luôn duy trì mức tải $0\%$ trong quá trình fetch hàng nghìn bản ghi.
