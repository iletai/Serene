# Tích Hợp microCMS & Cơ Chế Phân Phối Dữ Liệu Ngoại Tuyến (microCMS & Offline Content Distribution)

Tài liệu thiết kế kiến trúc tích hợp hệ thống Headless CMS (**microCMS**), cơ chế lưu bộ nhớ đệm có điều kiện theo tiêu chuẩn RFC 7232 qua HTTP **ETag (`If-None-Match`)**, cơ chế nạp sẵn dữ liệu gốc đóng gói (**Bundled Fallback JSON**), và mẫu thiết kế **Hybrid Repository** đảm bảo ứng dụng **An Niên (Lịch Việt & Ngày Nhớ)** hoạt động mượt mà $100\%$ không phụ thuộc đường truyền mạng.

---

## 1. Tổng Quan Kiến Trúc Đồng Bộ & Phân Phối Nội Dung (3-Tier Architecture)

Dữ liệu ngày lễ truyền thống (`holidays`) và bài viết phong tục tập quán (`cultural_articles`) được quản lý linh hoạt qua microCMS nhưng được phân phối qua mô hình 3 tầng ưu tiên (3-Tier Data Fallback):

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                 3-TIER CONTENT PIPELINE                                 │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                         │
│  TẦNG 1: SwiftData Local Cache (Tốc độ $O(1)$, 0 network latency, tức thì)              │
│  └── Truy vấn ngay từ cơ sở dữ liệu SQLite cục bộ để render UI tức thì.                 │
│                                                                                         │
│  TẦNG 2: microCMS Remote Sync với HTTP ETag (Kiểm tra cập nhật nền)                    │
│  └── Gửi header `If-None-Match: <etag>`.                                                │
│      ├── Trả về `304 Not Modified`: Không tốn băng thông, giữ nguyên local cache.       │
│      └── Trả về `200 OK`: Giải mã JSON mới, lưu ETag mới, upsert vào SwiftData.         │
│                                                                                         │
│  TẦNG 3: Bundled Fallback JSON (`bundled_holidays.json` trong App Bundle)               │
│  └── Trong lần mở ứng dụng đầu tiên (First Launch) khi chưa có mạng, tự động nạp       │
│      dữ liệu ngày lễ bản địa đầy đủ từ App Bundle vào SwiftData.                         │
│                                                                                         │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Đặc Tả Schema microCMS REST API

### 2.1. Endpoint 1: `holidays` (List API)
Cung cấp danh mục các ngày lễ Dương lịch và Âm lịch, ngày Tết, Tiết Khí, và các ngày kỷ niệm văn hóa dân gian Việt Nam.

#### JSON Schema Đặc Tả:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "HolidayContent",
  "type": "object",
  "properties": {
    "id": { "type": "string", "description": "Unique Content ID từ microCMS" },
    "title": { "type": "string", "description": "Tên ngày lễ (VD: Tết Nguyên Đán, Giỗ Tổ Hùng Vương)" },
    "calendarType": { "type": "string", "enum": ["solar", "lunar"], "description": "Hệ lịch" },
    "day": { "type": "integer", "minimum": 1, "maximum": 31, "description": "Ngày trong tháng" },
    "month": { "type": "integer", "minimum": 1, "maximum": 12, "description": "Tháng trong năm" },
    "isNationalHoliday": { "type": "boolean", "description": "Nghỉ lễ theo Luật Lao động" },
    "isTraditionHoliday": { "type": "boolean", "description": "Lễ hội phong tục tập quán truyền thống" },
    "summary": { "type": "string", "description": "Tóm tắt ý nghĩa ngày lễ" },
    "customs": { "type": "string", "description": "Phong tục tập quán (HTML / Rich text)" },
    "taboos": { "type": "string", "description": "Điều kiêng kỵ dân gian (HTML / Rich text)" },
    "rituals": { "type": "string", "description": "Nghi thức, bài cúng và văn khấn (HTML / Rich text)" },
    "createdAt": { "type": "string", "format": "date-time" },
    "updatedAt": { "type": "string", "format": "date-time" },
    "publishedAt": { "type": "string", "format": "date-time" }
  },
  "required": ["id", "title", "calendarType", "day", "month", "isNationalHoliday", "isTraditionHoliday", "summary"]
}
```

#### Ví Dụ Payload Trả Về Từ `GET /api/v1/holidays`:
```json
{
  "contents": [
    {
      "id": "tet-nguyen-dan",
      "title": "Tết Nguyên Đán (Mùng 1 Tết)",
      "calendarType": "lunar",
      "day": 1,
      "month": 1,
      "isNationalHoliday": true,
      "isTraditionHoliday": true,
      "summary": "Ngày đầu tiên của năm mới Âm lịch, thời khắc thiêng liêng sum họp gia đình và hướng về nguồn cội.",
      "customs": "<p>Chúc Tết ông bà, mừng tuổi đầu năm, xuất hành hướng cát lợi.</p>",
      "taboos": "<p>Kiêng quét nhà, kiêng làm vỡ chén đĩa, kiêng nói lời xui xẻo.</p>",
      "rituals": "<p>Văn khấn mùng 1 Tết tại gia kính cáo Thổ Công và Gia Tiên tiền tổ.</p>",
      "createdAt": "2026-01-01T00:00:00.000Z",
      "updatedAt": "2026-01-15T08:30:00.000Z",
      "publishedAt": "2026-01-01T00:00:00.000Z"
    },
    {
      "id": "gio-to-hung-vuong",
      "title": "Giỗ Tổ Hùng Vương",
      "calendarType": "lunar",
      "day": 10,
      "month": 3,
      "isNationalHoliday": true,
      "isTraditionHoliday": true,
      "summary": "Ngày hội tụ truyền thống dân tộc, tưởng nhớ công lao dựng nước của các Vua Hùng.",
      "customs": "<p>Dâng hương tại Đền Hùng và các đền thờ thần linh trên toàn quốc.</p>",
      "taboos": null,
      "rituals": "<p>Nghi thức rước kiệu và dâng hương Quốc Giỗ.</p>",
      "createdAt": "2026-01-01T00:00:00.000Z",
      "updatedAt": "2026-02-10T11:00:00.000Z",
      "publishedAt": "2026-01-01T00:00:00.000Z"
    }
  ],
  "totalCount": 2,
  "offset": 0,
  "limit": 50
}
```

---

### 2.2. Endpoint 2: `cultural_articles` (List API)
Cung cấp các bài viết chuyên sâu về phong tục, ẩm thực, nghi lễ văn hóa dân tộc.

#### JSON Schema Đặc Tả:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "CulturalArticleContent",
  "type": "object",
  "properties": {
    "id": { "type": "string", "description": "Content ID" },
    "title": { "type": "string", "description": "Tiêu đề bài viết" },
    "slug": { "type": "string", "description": "Đường dẫn định danh duy nhất" },
    "category": {
      "type": "string",
      "enum": ["tet", "le_hoi", "phong_tuc", "am_thuc"]
    },
    "coverImage": {
      "type": "object",
      "properties": {
        "url": { "type": "string", "format": "uri" },
        "width": { "type": "integer" },
        "height": { "type": "integer" }
      },
      "required": ["url"]
    },
    "content": { "type": "string", "description": "Nội dung bài viết chi tiết (HTML / Markdown)" },
    "publishedAt": { "type": "string", "format": "date-time" },
    "updatedAt": { "type": "string", "format": "date-time" }
  },
  "required": ["id", "title", "slug", "category", "content", "publishedAt"]
}
```

---

## 3. Động Cơ Lưu Đệm ETag (`MicroCMSClient`)

Cơ chế lưu đệm tuân thủ chuẩn **RFC 7232 (Conditional Requests)** — toàn bộ nằm trong actor `MicroCMSClient` (`Packages/VNCalendarData/Sources/VNCalendarData/Network/MicroCMSClient.swift`). Không tồn tại type riêng `ETagCacheStorage`: ETag được lưu trực tiếp vào `UserDefaults` với key `microcms_etag_<endpoint>`:
1. Mỗi khi gửi request, client đọc `ETag` đã lưu từ `UserDefaults` (`microcms_etag_<endpoint>`).
2. Đính kèm header `If-None-Match: "<stored_etag>"`.
3. Nếu server trả về `HTTP 304 Not Modified`, trả về `.notModified` mà không cần tải hay phân tích dữ liệu, tiết kiệm $100\%$ dung lượng băng thông.
4. Nếu server trả về `HTTP 200 OK`, giải mã JSON, lưu giá trị `ETag` mới vào `UserDefaults` và trả về `.success(data:eTag:)`.

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                   ETag Flow Diagram                                     │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                         │
│   [App / Client]                                                   [microCMS CDN]       │
│         │                                                                │              │
│         ├─── GET /api/v1/holidays (If-None-Match: "etag_v1") ───────────►│              │
│         │                                                                │              │
│         │◄── HTTP 304 Not Modified (No Body) ────────────────────────────┤ (Data Same)  │
│         │    [Sử dụng dữ liệu SwiftData hiện tại, 0 byte payload]         │              │
│         │                                                                │              │
│         │                                                                │              │
│         ├─── GET /api/v1/cultural_articles (If-None-Match: "etag_old") ──►│              │
│         │                                                                │              │
│         │◄── HTTP 200 OK (New Body + ETag: "etag_new") ──────────────────┤ (Data New)   │
│         │    [Cập nhật ETag trong UserDefaults & ghi đè SwiftData]       │              │
│         │                                                                │              │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

### 3.1. Production Swift Code: `MicroCMSClient.swift`

```swift
import Foundation
import OSLog

private let logger = Logger(subsystem: "com.iletai.annien", category: "MicroCMSClient")

public enum MicroCMSResponse<T: Decodable & Sendable>: Sendable {
    case success(data: T, eTag: String?)
    case notModified
}

public enum MicroCMSError: Error, Sendable {
    /// Thrown when serviceDomain/apiKey are missing so callers never mistake
    /// a misconfigured client for "no remote changes".
    case configurationMissing
}

public actor MicroCMSClient {
    private let serviceDomain: String
    private let apiKey: String
    private let session: URLSession
    private let defaults: UserDefaults

    public init(
        serviceDomain: String,
        apiKey: String,
        session: URLSession = .shared,
        /// Resolved inside the actor because `UserDefaults` is not `Sendable`.
        defaultsSuiteName: String? = nil
    ) {
        self.serviceDomain = serviceDomain
        self.apiKey = apiKey
        self.session = session
        if let suite = defaultsSuiteName {
            self.defaults = UserDefaults(suiteName: suite) ?? .standard
        } else {
            self.defaults = .standard
        }
    }

    public func fetchList<T: Decodable & Sendable>(
        endpoint: String,
        limit: Int = 100
    ) async throws -> MicroCMSResponse<T> {
        guard !serviceDomain.isEmpty, !apiKey.isEmpty else {
            throw MicroCMSError.configurationMissing
        }

        guard var components = URLComponents(string: "https://\(serviceDomain).microcms.io/api/v1/\(endpoint)") else {
            throw URLError(.badURL)
        }
        components.queryItems = [URLQueryItem(name: "limit", value: "\(limit)")]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-MICROCMS-API-KEY")
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let eTagKey = "microcms_etag_\(endpoint)"
        if let savedETag = defaults.string(forKey: eTagKey) {
            request.setValue(savedETag, forHTTPHeaderField: "If-None-Match")
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode == 304 {
            logger.info("Endpoint \(endpoint) returned 304 Not Modified.")
            return .notModified
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            logger.error("Endpoint \(endpoint) failed with status \(httpResponse.statusCode)")
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(T.self, from: data)

        let newETag = httpResponse.value(forHTTPHeaderField: "Etag")
        if let newETag {
            defaults.set(newETag, forKey: eTagKey)
        }

        return .success(data: decoded, eTag: newETag)
    }
}
```

---

## 4. Dữ Liệu Đóng Gói Sẵn Trong App (`bundled_holidays.json`) & Bộ Nạp Seed

Để cam kết ứng dụng hoạt động tức thì ngay sau khi tải từ App Store mà không cần chờ đợi mạng, tệp `bundled_holidays.json` được đóng gói trong target resources.

### 4.1. Cấu Trúc Tệp `bundled_holidays.json`
```json
[
  {
    "id": "tet-nguyen-dan-mung-1",
    "title": "Tết Nguyên Đán (Mùng 1 Tết)",
    "calendarType": "lunar",
    "day": 1,
    "month": 1,
    "isNationalHoliday": true,
    "isTraditionHoliday": true,
    "summary": "Ngày đầu năm mới Âm lịch, khởi đầu năm cát tường vạn sự như ý.",
    "customs": "Lễ gia tiên, chúc Tết ông bà, mừng tuổi.",
    "taboos": "Kiêng quét rác, kiêng nói gở.",
    "rituals": "Văn khấn đầu năm mới tại gia."
  },
  {
    "id": "tet-nguyen-dan-mung-2",
    "title": "Tết Nguyên Đán (Mùng 2 Tết)",
    "calendarType": "lunar",
    "day": 2,
    "month": 1,
    "isNationalHoliday": true,
    "isTraditionHoliday": true,
    "summary": "Mùng 2 Tết mẹ, viếng thăm và chúc Tết họ ngoại.",
    "customs": "Chúc Tết nhà ngoại, đi lễ chùa.",
    "taboos": null,
    "rituals": null
  },
  {
    "id": "gio-to-hung-vuong",
    "title": "Giỗ Tổ Hùng Vương",
    "calendarType": "lunar",
    "day": 10,
    "month": 3,
    "isNationalHoliday": true,
    "isTraditionHoliday": true,
    "summary": "Tưởng nhớ công ơn các Vua Hùng dựng nước.",
    "customs": "Lễ dâng hương Đền Hùng.",
    "taboos": null,
    "rituals": "Văn khấn Quốc Giỗ."
  },
  {
    "id": "quoc-khanh-viet-nam",
    "title": "Quốc Khánh Nước CHXHCN Việt Nam",
    "calendarType": "solar",
    "day": 2,
    "month": 9,
    "isNationalHoliday": true,
    "isTraditionHoliday": false,
    "summary": "Kỷ niệm Chủ tịch Hồ Chí Minh đọc Tuyên ngôn Độc lập tại Quảng trường Ba Đình (1945).",
    "customs": "Treo cờ Tổ quốc, mít tinh.",
    "taboos": null,
    "rituals": null
  }
]
```

### 4.2. Bộ Nạp Khởi Tạo Dữ Liệu Seed (`SeedDataLoader.swift`)

```swift
import Foundation
import SwiftData
import os.log

private let logger = Logger(subsystem: "com.iletai.annien", category: "SeedDataLoader")

public enum SeedDataLoader {
    
    /// Seeds the database with bundled holidays if the database has not been seeded yet.
    @MainActor
    public static func seedInitialHolidaysIfNeeded(
        modelContext: ModelContext,
        bundle: Bundle = .main
    ) {
        var countDescriptor = FetchDescriptor<HolidayEntity>()
        countDescriptor.fetchLimit = 1
        
        do {
            let existingCount = try modelContext.fetchCount(countDescriptor)
            if existingCount > 0 {
                logger.info("Database already contains holiday records (\(existingCount)). Skipping bundle seed.")
                return
            }
            
            guard let fileURL = bundle.url(forResource: "bundled_holidays", withExtension: "json") else {
                logger.warning("bundled_holidays.json not found in bundle resources.")
                return
            }
            
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let bundledHolidays = try decoder.decode([BundledHolidayDTO].self, from: data)
            
            for dto in bundledHolidays {
                let entity = HolidayEntity(
                    id: dto.id,
                    title: dto.title,
                    calendarTypeRawValue: dto.calendarType,
                    day: dto.day,
                    month: dto.month,
                    isNationalHoliday: dto.isNationalHoliday,
                    isTraditionHoliday: dto.isTraditionHoliday,
                    summary: dto.summary,
                    customs: dto.customs,
                    taboos: dto.taboos,
                    rituals: dto.rituals,
                    updatedAt: Date()
                )
                modelContext.insert(entity)
            }
            
            try modelContext.save()
            logger.info("Successfully seeded \(bundledHolidays.count) holidays from bundled JSON.")
        } catch {
            logger.error("Failed to seed initial holidays: \(error.localizedDescription)")
        }
    }
}

// MARK: - Bundled DTO Definition
public struct BundledHolidayDTO: Codable, Sendable {
    public let id: String
    public let title: String
    public let calendarType: String
    public let day: Int
    public let month: Int
    public let isNationalHoliday: Bool
    public let isTraditionHoliday: Bool
    public let summary: String
    public let customs: String?
    public let taboos: String?
    public let rituals: String?
}
```

---

## 5. Tầng Hybrid Repository (Kết Hợp SwiftData + microCMS + Fallback)

### 5.1. Production Swift Code: `HolidayRepositoryProtocol.swift`

```swift
import Foundation
import Combine
import VNCalendarDomain

public protocol HolidayRepositoryProtocol: Sendable {
    /// Gets all holidays, fetching local cache immediately and synchronizing with remote in background
    func getHolidays() async throws -> [Holiday]
    
    /// Finds holidays occurring in a specific solar or lunar month
    func getHolidays(month: Int, isLunar: Bool) async throws -> [Holiday]
    
    /// Triggers remote sync with microCMS using ETag
    func synchronizeRemoteContent() async throws
}
```

### 5.2. Production Swift Code: `HybridHolidayRepository.swift`

```swift
import Foundation
import SwiftData
import VNCalendarDomain
import os.log

private let logger = Logger(subsystem: "com.iletai.annien", category: "HybridHolidayRepository")

// microCMS List API Response Structure
public struct MicroCMSHolidayListResponse: Codable, Sendable {
    public let contents: [MicroCMSHolidayDTO]
    public let totalCount: Int
    public let offset: Int
    public let limit: Int
}

public struct MicroCMSHolidayDTO: Codable, Sendable {
    public let id: String
    public let title: String
    public let calendarType: String
    public let day: Int
    public let month: Int
    public let isNationalHoliday: Bool
    public let isTraditionHoliday: Bool
    public let summary: String
    public let customs: String?
    public let taboos: String?
    public let rituals: String?
    public let updatedAt: Date?
}

public final class HybridHolidayRepository: HolidayRepositoryProtocol, @unchecked Sendable {
    private let modelContainer: ModelContainer
    private let client: MicroCMSClient
    private let bundle: Bundle
    
    public init(
        modelContainer: ModelContainer,
        client: MicroCMSClient,
        bundle: Bundle = .main
    ) {
        self.modelContainer = modelContainer
        self.client = client
        self.bundle = bundle
        
        // Seed bundled data immediately on initialization
        Task { @MainActor in
            SeedDataLoader.seedInitialHolidaysIfNeeded(
                modelContext: modelContainer.mainContext,
                bundle: bundle
            )
        }
    }
    
    public func getHolidays() async throws -> [Holiday] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<HolidayEntity>(
            sortBy: [SortDescriptor(\.month), SortDescriptor(\.day)]
        )
        let entities = try context.fetch(descriptor)
        return entities.map { $0.toDomainHoliday() }
    }
    
    public func getHolidays(month: Int, isLunar: Bool) async throws -> [Holiday] {
        let calendarType = isLunar ? "lunar" : "solar"
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<HolidayEntity>(
            predicate: #Predicate { $0.month == month && $0.calendarTypeRawValue == calendarType },
            sortBy: [SortDescriptor(\.day)]
        )
        let entities = try context.fetch(descriptor)
        return entities.map { $0.toDomainHoliday() }
    }
    
    public func synchronizeRemoteContent() async throws {
        let response: MicroCMSResponse<MicroCMSHolidayListResponse>
        do {
            response = try await client.fetchList(endpoint: "holidays", limit: 100)
        } catch {
            logger.warning("Remote microCMS sync failed. Retaining local cache: \(error.localizedDescription)")
            return
        }
        
        switch response {
        case .notModified:
            logger.info("Holiday content is up to date (304 Not Modified).")
            
        case .success(let payload, _):
            logger.info("Received \(payload.contents.count) updated holidays from microCMS. Updating local store.")
            let context = ModelContext(modelContainer)
            
            for item in payload.contents {
                let targetId = item.id
                var descriptor = FetchDescriptor<HolidayEntity>(
                    predicate: #Predicate { $0.id == targetId }
                )
                descriptor.fetchLimit = 1
                
                if let existing = try context.fetch(descriptor).first {
                    existing.title = item.title
                    existing.calendarTypeRawValue = item.calendarType
                    existing.day = item.day
                    existing.month = item.month
                    existing.isNationalHoliday = item.isNationalHoliday
                    existing.isTraditionHoliday = item.isTraditionHoliday
                    existing.summary = item.summary
                    existing.customs = item.customs
                    existing.taboos = item.taboos
                    existing.rituals = item.rituals
                    existing.updatedAt = item.updatedAt ?? Date()
                } else {
                    let newEntity = HolidayEntity(
                        id: item.id,
                        title: item.title,
                        calendarTypeRawValue: item.calendarType,
                        day: item.day,
                        month: item.month,
                        isNationalHoliday: item.isNationalHoliday,
                        isTraditionHoliday: item.isTraditionHoliday,
                        summary: item.summary,
                        customs: item.customs,
                        taboos: item.taboos,
                        rituals: item.rituals,
                        updatedAt: item.updatedAt ?? Date()
                    )
                    context.insert(newEntity)
                }
            }
            try context.save()
        }
    }
}

// MARK: - Domain Mapping Extension
extension HolidayEntity {
    func toDomainHoliday() -> Holiday {
        Holiday(
            id: self.id,
            title: self.title,
            calendarType: self.calendarTypeRawValue == "lunar" ? .lunar : .solar,
            day: self.day,
            month: self.month,
            isNationalHoliday: self.isNationalHoliday,
            isTraditionHoliday: self.isTraditionHoliday,
            summary: self.summary,
            customs: self.customs,
            taboos: self.taboos,
            rituals: self.rituals
        )
    }
}
```

---

## 6. Ma Trận Kiểm Thử Tích Hợp microCMS & Offline Fallback

1. **First Launch Zero-Network**: Xóa sạch ứng dụng, tắt toàn bộ Wi-Fi và Cellular data. Mở app và xác minh danh sách ngày Tết và ngày lễ dân tộc hiển thị đầy đủ ngay từ lần mở đầu tiên qua `bundled_holidays.json`.
2. **ETag 304 Validation**: Gửi request 2 lần liên tiếp. Lần thứ hai phải trả về status code `304 Not Modified`, `0 bytes` payload tải về từ mạng.
3. **Data Integrity Upsert**: Khi cập nhật tiêu đề ngày lễ trên microCMS, client đồng bộ và cập nhật chính xác thuộc tính mà không làm trùng lặp bản ghi trong SwiftData.
