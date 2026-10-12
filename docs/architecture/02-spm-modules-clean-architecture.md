# Kiến Trúc Module SPM & Clean Architecture (SPM Modules & Clean Architecture)

Tài liệu thiết kế kiến trúc phân rã module bằng Swift Package Manager (SPM), hiện thực Clean Architecture cho dự án **An Niên (Lịch Việt & Ngày Nhớ)** trên nền tảng **iOS 17.0+ (Swift 6 Concurrency)**, cấu hình đa môi trường với **XcodeGen** và mẫu thiết kế **AppContainer Composition Root**.

---

## 1. Triết Lý Kiến Trúc & Phân Tầng Clean Architecture

Hệ thống được thiết kế theo nguyên tắc Clean Architecture (Robert C. Martin), đảm bảo tính độc lập tối đa giữa logic nghiệp vụ thiên văn Âm Dương bản địa, tầng dữ liệu lưu trữ (SwiftData / CloudKit / microCMS), và tầng giao diện người dùng (SwiftUI / WidgetKit).

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        App Layer / Presentation                         │
│   ┌───────────────────────────────┐ ┌───────────────────────────────┐   │
│   │         AnNien (App)          │ │     AnNienWidget (Ext)        │   │
│   │   AppContainer / Navigation   │ │     Lock / Home Widgets       │   │
│   └───────────────┬───────────────┘ └───────────────┬───────────────┘   │
└───────────────────┼─────────────────────────────────┼───────────────────┘
                    ▼                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        Design & UI Adapter Layer                        │
│   ┌───────────────────────────────┐ ┌───────────────────────────────┐   │
│   │    VNCalendarDesignSystem     │ │        VNCalendarKit          │   │
│   │  Tokens, Cells, Icons, Badges │ │ SwiftUICalendarView Adapter   │   │
│   └───────────────┬───────────────┘ └───────────────┬───────────────┘   │
└───────────────────┼─────────────────────────────────┼───────────────────┘
                    ▼                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        Domain & Data Layer                              │
│   ┌───────────────────────────────┐ ┌───────────────────────────────┐   │
│   │        VNCalendarData         │ │       VNCalendarDomain        │   │
│   │ SwiftData, CloudKit, microCMS │ │ UseCases, Models, Repos (Prot)│   │
│   └───────────────┬───────────────┘ └───────────────┬───────────────┘   │
└───────────────────┼─────────────────────────────────┼───────────────────┘
                    ▼                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        Core Astronomy Math                              │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                       VNCalendarLunar                           │   │
│   │   Thuật toán thiên văn Jean Meeus & GS. Hồ Ngọc Đức (GMT+7)     │   │
│   └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

### Nguyên Tắc Phụ Thuộc (Dependency Rule)
1. **Độc lập nền tảng UI**: `VNCalendarLunar` và `VNCalendarDomain` là Pure Swift modules, không import `SwiftUI`, `UIKit`, hay `SwiftData`. Có thể chạy độc lập trên macOS, Linux, watchOS, hoặc Server-Side Swift.
2. **Nghịch đảo phụ thuộc (Dependency Inversion)**: `VNCalendarDomain` định nghĩa các Repository Protocols (`ReminderRepositoryProtocol`, `HolidayRepositoryProtocol`). `VNCalendarData` triển khai cụ thể các protocol này thông qua SwiftData và CloudKit.
3. **Hiệu năng Render $O(1)$**: `VNCalendarKit` đóng vai trò adapter bọc thư viện `iletai/SwiftUICalendarView`, quản lý bộ nhớ đệm `DateKey` (`Int` YYYYMMDD) để tính toán Âm lịch tức thì không gây giật khung hình (120fps ProMotion).

---

## 2. Cấu Trúc Module & Sơ Đồ SPM Dependency Graph

Dự án sử dụng mô hình SPM Monorepo Multi-Package đặt trong thư mục `Packages/`. Mỗi package là một đơn vị biên dịch biệt lập, kiểm soát chặt chẽ phạm vi truy xuất (`public`, `package`, `internal`).

```
Packages/
├── VNCalendarLunar/
│   ├── Package.swift
│   └── Sources/
│       └── VNCalendarLunar/
│           ├── Engine/
│           │   ├── AstronomicalMath.swift
│           │   └── LunarAstronomicalEngine.swift
│           └── Models/
│               ├── CanChi.swift
│               ├── LunarDate.swift
│               ├── MoonPhase.swift
│               ├── SolarDate.swift
│               └── SolarTerm.swift
├── VNCalendarDomain/
│   ├── Package.swift
│   └── Sources/
│       └── VNCalendarDomain/
│           ├── Entities/
│           │   ├── AppConfiguration.swift
│           │   ├── AppFeature.swift
│           │   ├── CulturalArticle.swift
│           │   ├── Holiday.swift
│           │   ├── MemorialEvent.swift
│           │   ├── Prayer.swift
│           │   └── ReminderEvent.swift
│           ├── UseCases/
│           │   ├── EvaluateFeatureGateUseCase.swift
│           │   ├── GetMonthCalendarUseCase.swift
│           │   ├── NaturalSearchUseCase.swift
│           │   └── ScheduleReminderUseCase.swift
│           └── Repositories/
│               ├── CulturalArticleRepositoryProtocol.swift
│               ├── HolidayRepositoryProtocol.swift
│               ├── PrayerRepositoryProtocol.swift
│               ├── ReminderRepositoryProtocol.swift
│               └── SubscriptionRepositoryProtocol.swift
├── VNCalendarData/
│   ├── Package.swift
│   └── Sources/
│       └── VNCalendarData/
│           ├── Actors/
│           │   ├── ArticleDataActor.swift
│           │   ├── HolidayDataActor.swift
│           │   └── ReminderDataActor.swift
│           ├── CloudKit/
│           │   └── CloudKitSyncMonitor.swift
│           ├── Entities/
│           │   ├── CulturalArticleEntity.swift
│           │   ├── HolidayEntity.swift
│           │   ├── ReminderItemEntity.swift
│           │   └── SyncMetadataEntity.swift
│           ├── Network/
│           │   ├── MicroCMSClient.swift        # ETag caching (If-None-Match / 304) lives here
│           │   └── SeedDataLoader.swift
│           ├── Repositories/
│           │   ├── HybridCulturalArticleRepository.swift
│           │   ├── HybridHolidayRepository.swift
│           │   ├── LocalPrayerRepository.swift
│           │   └── SwiftDataReminderRepository.swift
│           ├── Resources/
│           │   ├── bundled_holidays.json
│           │   └── bundled_prayers.json
│           └── SwiftData/
│               └── ModelContainerFactory.swift
├── VNCalendarDesignSystem/
│   ├── Package.swift
│   └── Sources/
│       └── VNCalendarDesignSystem/
│           ├── Tokens/
│           │   ├── AnimationTokens.swift
│           │   ├── ColorTokens.swift
│           │   ├── FontTokens.swift
│           │   └── LayoutTokens.swift
│           ├── Modifiers/
│           │   └── VNCellPressButtonStyle.swift
│           └── Components/
│               ├── VN12HourTimelineView.swift
│               ├── VNBadgeView.swift
│               ├── VNButton.swift
│               ├── VNCalendarModePicker.swift
│               ├── VNCard.swift
│               ├── VNChip.swift
│               ├── VNIndicatorDotsView.swift
│               ├── VNMoonPhaseView.swift
│               ├── VNSealBadge.swift
│               └── VNSectionHeader.swift
└── VNCalendarKit/
    ├── Package.swift
    └── Sources/
        └── VNCalendarKit/
            ├── Cache/
            │   └── VNMonthLunarCache.swift
            ├── Models/
            │   ├── DateKey.swift
            │   ├── VNCalendarDayModel.swift
            │   ├── VNFolkQuote.swift
            │   └── VNYearMonthModel.swift
            ├── ViewModels/
            │   └── VNCalendarAdapterViewModel.swift
            └── Views/
                ├── VNBlockCalendarView.swift
                ├── VNCalendarContainerView.swift   # month grid renders inline via `monthGridView`
                ├── VNCalendarHeaderView.swift
                ├── VNDayCellView.swift
                ├── VNDayDetailBottomSheet.swift
                ├── VNDayDetailComponents.swift
                ├── VNWeekCalendarView.swift
                └── VNYearCalendarView.swift
```

---

## 3. Khai Báo SPM `Package.swift` Đạt Chuẩn Swift 6 Strict Concurrency

### 3.1. `Packages/VNCalendarLunar/Package.swift`
Zero dependencies, tối ưu toán học thiên văn.

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VNCalendarLunar",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "VNCalendarLunar",
            targets: ["VNCalendarLunar"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "VNCalendarLunar",
            dependencies: [],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("AccessLevelOnImport")
            ]
        ),
        .testTarget(
            name: "VNCalendarLunarTests",
            dependencies: ["VNCalendarLunar"]
        )
    ]
)
```

### 3.2. `Packages/VNCalendarDomain/Package.swift`
Tầng nghiệp vụ trung tâm, phụ thuộc `VNCalendarLunar`.

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VNCalendarDomain",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "VNCalendarDomain",
            targets: ["VNCalendarDomain"]
        )
    ],
    dependencies: [
        .package(path: "../VNCalendarLunar")
    ],
    targets: [
        .target(
            name: "VNCalendarDomain",
            dependencies: [
                .product(name: "VNCalendarLunar", package: "VNCalendarLunar")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "VNCalendarDomainTests",
            dependencies: ["VNCalendarDomain"]
        )
    ]
)
```

### 3.3. `Packages/VNCalendarData/Package.swift`
Tầng dữ liệu phụ thuộc `VNCalendarDomain`.

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VNCalendarData",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "VNCalendarData",
            targets: ["VNCalendarData"]
        )
    ],
    dependencies: [
        .package(path: "../VNCalendarDomain"),
        .package(path: "../VNCalendarLunar")
    ],
    targets: [
        .target(
            name: "VNCalendarData",
            dependencies: [
                .product(name: "VNCalendarDomain", package: "VNCalendarDomain"),
                .product(name: "VNCalendarLunar", package: "VNCalendarLunar")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "VNCalendarDataTests",
            dependencies: ["VNCalendarData"]
        )
    ]
)
```

### 3.4. `Packages/VNCalendarDesignSystem/Package.swift`
Hệ thống thiết kế giao diện thuần khiết.

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VNCalendarDesignSystem",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "VNCalendarDesignSystem",
            targets: ["VNCalendarDesignSystem"]
        )
    ],
    dependencies: [
        .package(path: "../VNCalendarDomain")
    ],
    targets: [
        .target(
            name: "VNCalendarDesignSystem",
            dependencies: [
                .product(name: "VNCalendarDomain", package: "VNCalendarDomain")
            ],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        )
    ]
)
```

### 3.5. `Packages/VNCalendarKit/Package.swift`
Adapter gắn kết `iletai/SwiftUICalendarView`.

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VNCalendarKit",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "VNCalendarKit",
            targets: ["VNCalendarKit"]
        )
    ],
    dependencies: [
        .package(path: "../VNCalendarDomain"),
        .package(path: "../VNCalendarLunar"),
        .package(path: "../VNCalendarDesignSystem"),
        .package(url: "https://github.com/iletai/SwiftUICalendarView.git", from: "3.1.0")
    ],
    targets: [
        .target(
            name: "VNCalendarKit",
            dependencies: [
                .product(name: "VNCalendarDomain", package: "VNCalendarDomain"),
                .product(name: "VNCalendarLunar", package: "VNCalendarLunar"),
                .product(name: "VNCalendarDesignSystem", package: "VNCalendarDesignSystem"),
                .product(name: "SwiftUICalendarView", package: "SwiftUICalendarView")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        )
    ]
)
```

---

## 4. Cấu Hình Đa Môi Trường Qua XcodeGen (`project.yml`)

### 4.1. Bảng Ma Trận Phân Tách Môi Trường (Dev vs Prod)

| Thuộc tính | Development (`AnNien-Dev`) | Production (`AnNien-Prod`) |
| :--- | :--- | :--- |
| **Scheme** | `AnNien-Dev` | `AnNien-Prod` |
| **App Bundle ID** | `com.iletai.annien.dev` | `com.iletai.annien` |
| **Widget Bundle ID** | `com.iletai.annien.dev.widget` | `com.iletai.annien.widget` |
| **Display Name** | `An Niên Dev` | `An Niên` |
| **CloudKit Container** | `iCloud.com.iletai.annien.dev` | `iCloud.com.iletai.annien` |
| **App Group ID** | `group.com.iletai.annien.dev` | `group.com.iletai.annien` |
| **Entitlements File** | `Config/Entitlements/AnNien-Dev.entitlements` | `Config/Entitlements/AnNien-Prod.entitlements` |
| **Swift Active Flags** | `DEV` | `PROD` |
| **microCMS Env Key** | `MICROCMS_API_KEY_DEV` | `MICROCMS_API_KEY_PROD` |

### 4.2. File Cấu Hình `project.yml`

```yaml
name: AnNien
options:
  bundleIdPrefix: com.iletai
  xcodeVersion: "16.0"
  deploymentTarget:
    iOS: "17.0"
  createIntermediateGroups: true
  groupSortPosition: top

configs:
  Debug-Development: debug
  Release-Development: release
  Debug-Production: debug
  Release-Production: release

configFiles:
  Debug-Development: Config/Development.xcconfig
  Release-Development: Config/Development.xcconfig
  Debug-Production: Config/Production.xcconfig
  Release-Production: Config/Production.xcconfig

packages:
  CalendarView:
    url: https://github.com/iletai/SwiftUICalendarView.git
    from: 3.1.0
  AppUpdateKit:
    url: https://github.com/iletai/AppUpdateKit.git
    from: 1.1.0
  VNCalendarLunar:
    path: Packages/VNCalendarLunar
  VNCalendarDomain:
    path: Packages/VNCalendarDomain
  VNCalendarData:
    path: Packages/VNCalendarData
  VNCalendarDesignSystem:
    path: Packages/VNCalendarDesignSystem
  VNCalendarKit:
    path: Packages/VNCalendarKit

targets:
  AnNien:
    type: application
    platform: iOS
    deploymentTarget: "17.0"
    sources:
      - path: App
        createIntermediateGroups: true
    settings:
      base:
        CODE_SIGN_ENTITLEMENTS: $(CODE_SIGN_ENTITLEMENTS)
        PRODUCT_BUNDLE_IDENTIFIER: $(PRODUCT_BUNDLE_IDENTIFIER)
        INFOPLIST_KEY_CFBundleDisplayName: $(APP_DISPLAY_NAME)
    dependencies:
      - package: CalendarView
      - package: AppUpdateKit
      - package: VNCalendarLunar
      - package: VNCalendarDomain
      - package: VNCalendarData
      - package: VNCalendarDesignSystem
      - package: VNCalendarKit
      - target: AnNienWidget

  AnNienWidget:
    type: app-extension
    platform: iOS
    deploymentTarget: "17.0"
    sources:
      - path: Extensions/Widget
        createIntermediateGroups: true
    settings:
      base:
        CODE_SIGN_ENTITLEMENTS: $(WIDGET_CODE_SIGN_ENTITLEMENTS)
        PRODUCT_BUNDLE_IDENTIFIER: $(WIDGET_BUNDLE_IDENTIFIER)
        INFOPLIST_KEY_CFBundleDisplayName: $(APP_DISPLAY_NAME) Widget
    dependencies:
      - package: VNCalendarLunar
      - package: VNCalendarDomain
      - package: VNCalendarData
      - package: VNCalendarDesignSystem

  AnNienTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - path: Tests
        createIntermediateGroups: true
    dependencies:
      - target: AnNien

schemes:
  AnNien-Dev:
    build:
      targets:
        AnNien: all
        AnNienWidget: all
        AnNienTests: [test]
    run:
      config: Debug-Development
    test:
      config: Debug-Development
      targets:
        - AnNienTests
    profile:
      config: Release-Development
    analyze:
      config: Debug-Development
    archive:
      config: Release-Development

  AnNien-Prod:
    build:
      targets:
        AnNien: all
        AnNienWidget: all
        AnNienTests: [test]
    run:
      config: Debug-Production
    test:
      config: Debug-Production
      targets:
        - AnNienTests
    profile:
      config: Release-Production
    analyze:
      config: Debug-Production
    archive:
      config: Release-Production
```

### 4.3. Các Tệp `.xcconfig` Quản Lý Thuộc Tính Biên Dịch

#### `Config/Shared.xcconfig`
```ini
// Shared build settings across all configurations
SWIFT_VERSION = 6.0
IPHONEOS_DEPLOYMENT_TARGET = 17.0
TARGETED_DEVICE_FAMILY = 1
MARKETING_VERSION = 1.0.0
CURRENT_PROJECT_VERSION = 1
SWIFT_STRICT_CONCURRENCY = complete
ENABLE_USER_SCRIPT_SANDBOXING = YES
ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon
ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor
GENERATE_INFOPLIST_FILE = YES
INFOPLIST_KEY_CFBundleDisplayName = $(APP_DISPLAY_NAME)
INFOPLIST_KEY_UILaunchScreen_Generation = YES
INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait
```

#### `Config/Development.xcconfig`
```ini
#include "Shared.xcconfig"

PRODUCT_BUNDLE_IDENTIFIER = com.iletai.annien.dev
WIDGET_BUNDLE_IDENTIFIER = com.iletai.annien.dev.widget
APP_DISPLAY_NAME = An Niên Dev
CLOUDKIT_CONTAINER_ID = iCloud.com.iletai.annien.dev
APP_GROUP_ID = group.com.iletai.annien.dev
CODE_SIGN_ENTITLEMENTS = Config/Entitlements/AnNien-Dev.entitlements
WIDGET_CODE_SIGN_ENTITLEMENTS = Config/Entitlements/AnNienWidget-Dev.entitlements
SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) DEV
DEBUG_INFORMATION_FORMAT = dwarf-with-dsym
OTHER_SWIFT_FLAGS = $(inherited) -D DEV
```

#### `Config/Production.xcconfig`
```ini
#include "Shared.xcconfig"

PRODUCT_BUNDLE_IDENTIFIER = com.iletai.annien
WIDGET_BUNDLE_IDENTIFIER = com.iletai.annien.widget
APP_DISPLAY_NAME = An Niên
CLOUDKIT_CONTAINER_ID = iCloud.com.iletai.annien
APP_GROUP_ID = group.com.iletai.annien
CODE_SIGN_ENTITLEMENTS = Config/Entitlements/AnNien-Prod.entitlements
WIDGET_CODE_SIGN_ENTITLEMENTS = Config/Entitlements/AnNienWidget-Prod.entitlements
SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) PROD
DEBUG_INFORMATION_FORMAT = dwarf-with-dsym
OTHER_SWIFT_FLAGS = $(inherited) -D PROD
```

---

## 5. Mẫu Thiết Kế `AppContainer` Composition Root

Tầng `App` sử dụng mẫu `AppContainer` làm Composition Root tập trung. `AppContainer` quản lý vòng đời khởi tạo, khởi tạo các Repository, UseCase, và cung cấp qua SwiftUI Environment.

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           AppContainer (Composition Root)                       │
├─────────────────────────────────────────────────────────────────────────────────┤
│  - modelContainer: ModelContainer (SwiftData + CloudKit Private Store)          │
│  - cloudKitSyncMonitor: CloudKitSyncMonitor                                     │
│  - microCMSClient: MicroCMSClient                                               │
│                                                                                 │
│  Factories:                                                                     │
│  ├── makeReminderRepository() -> any ReminderRepositoryProtocol                 │
│  ├── makeHolidayRepository() -> any HolidayRepositoryProtocol                   │
│  ├── makeArticleRepository() -> any CulturalArticleRepositoryProtocol           │
│  ├── makeSubscriptionService() -> any SubscriptionServiceProtocol               │
│  └── makeNotificationEngine() -> any SmartNotificationEngineProtocol            │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 5.1. Production Swift Code: `AppContainerProtocol.swift`

```swift
import Foundation
import SwiftData
import VNCalendarDomain

/// Protocol defining the composition root interface for dependency injection.
@MainActor
public protocol AppContainerProtocol: Sendable {
    var modelContainer: ModelContainer { get }
    
    // Repositories
    func makeReminderRepository() -> any ReminderRepositoryProtocol
    func makeHolidayRepository() -> any HolidayRepositoryProtocol
    func makeCulturalArticleRepository() -> any CulturalArticleRepositoryProtocol
    
    // Use Cases
    func makeEvaluateFeatureGateUseCase() -> EvaluateFeatureGateUseCase
    func makeGetMonthCalendarUseCase() -> GetMonthCalendarUseCase
    func makeNaturalSearchUseCase() -> NaturalSearchUseCase
    func makeScheduleReminderUseCase() -> ScheduleReminderUseCase
    
    // Services
    func makeNotificationService() -> any SmartNotificationEngineProtocol
    func makeSubscriptionService() -> any SubscriptionServiceProtocol
}
```

### 5.2. Production Swift Code: `AppContainer.swift`

```swift
import Foundation
import SwiftData
import Combine
import VNCalendarDomain
import VNCalendarData
import VNCalendarLunar

/// Concrete production composition root handling lifecycle and dependency resolution.
@MainActor
public final class AppContainer: AppContainerProtocol {
    public let modelContainer: ModelContainer
    private let microCMSClient: MicroCMSClient
    private let appConfiguration: AppConfiguration
    
    // Cached Singletons / Services
    private var reminderRepositoryInstance: (any ReminderRepositoryProtocol)?
    private var holidayRepositoryInstance: (any HolidayRepositoryProtocol)?
    private var articleRepositoryInstance: (any CulturalArticleRepositoryProtocol)?
    
    public init(
        configuration: AppConfiguration = .current,
        inMemoryOnly: Bool = false
    ) {
        self.appConfiguration = configuration
        
        // 1. Initialize SwiftData ModelContainer with CloudKit private database
        self.modelContainer = ModelContainerFactory.createContainer(
            containerIdentifier: configuration.cloudKitContainerIdentifier,
            appGroupIdentifier: configuration.appGroupIdentifier,
            inMemoryOnly: inMemoryOnly
        )
        
        // 2. Initialize Networking & microCMS Client
        self.microCMSClient = MicroCMSClient(
            serviceDomain: configuration.microCMSServiceDomain,
            apiKey: configuration.microCMSApiKey
        )
    }
    
    // MARK: - Repositories
    
    public func makeReminderRepository() -> any ReminderRepositoryProtocol {
        if let existing = reminderRepositoryInstance {
            return existing
        }
        let repository = SwiftDataReminderRepository(modelContainer: modelContainer)
        self.reminderRepositoryInstance = repository
        return repository
    }
    
    public func makeHolidayRepository() -> any HolidayRepositoryProtocol {
        if let existing = holidayRepositoryInstance {
            return existing
        }
        let repository = HybridHolidayRepository(
            modelContainer: modelContainer,
            client: microCMSClient,
            bundle: Bundle.main
        )
        self.holidayRepositoryInstance = repository
        return repository
    }
    
    public func makeCulturalArticleRepository() -> any CulturalArticleRepositoryProtocol {
        if let existing = articleRepositoryInstance {
            return existing
        }
        let repository = HybridCulturalArticleRepository(
            modelContainer: modelContainer,
            client: microCMSClient
        )
        self.articleRepositoryInstance = repository
        return repository
    }
    
    // MARK: - Use Cases

    public func makeEvaluateFeatureGateUseCase() -> EvaluateFeatureGateUseCase {
        EvaluateFeatureGateUseCase(subscriptionRepository: makeSubscriptionService())
    }

    public func makeGetMonthCalendarUseCase() -> GetMonthCalendarUseCase {
        GetMonthCalendarUseCase()
    }

    public func makeNaturalSearchUseCase() -> NaturalSearchUseCase {
        NaturalSearchUseCase()
    }

    public func makeScheduleReminderUseCase() -> ScheduleReminderUseCase {
        ScheduleReminderUseCase()
    }

    // MARK: - Services
    
    public func makeSubscriptionService() -> any SubscriptionServiceProtocol {
        StoreKitSubscriptionService()
    }

    public func makeNotificationService() -> any SmartNotificationEngineProtocol {
        SmartNotificationEngine.shared
    }
}

// MARK: - App Configuration Helper
public struct AppConfiguration: Sendable {
    public let bundleIdentifier: String
    public let appGroupIdentifier: String
    public let cloudKitContainerIdentifier: String
    public let microCMSServiceDomain: String
    public let microCMSApiKey: String
    
    public static var current: AppConfiguration {
        #if DEV
        return AppConfiguration(
            bundleIdentifier: "com.iletai.annien.dev",
            appGroupIdentifier: "group.com.iletai.annien.dev",
            cloudKitContainerIdentifier: "iCloud.com.iletai.annien.dev",
            microCMSServiceDomain: "annien-dev",
            microCMSApiKey: ProcessInfo.processInfo.environment["MICROCMS_API_KEY_DEV"] ?? ""
        )
        #else
        return AppConfiguration(
            bundleIdentifier: "com.iletai.annien",
            appGroupIdentifier: "group.com.iletai.annien",
            cloudKitContainerIdentifier: "iCloud.com.iletai.annien",
            microCMSServiceDomain: "annien-prod",
            microCMSApiKey: ProcessInfo.processInfo.environment["MICROCMS_API_KEY_PROD"] ?? ""
        )
        #endif
    }
}
```

### 5.3. Mock Composition Root Dành Cho Testing & SwiftUI Previews

```swift
import Foundation
import SwiftData
import Combine
import VNCalendarDomain
import VNCalendarData

/// Mock composition root delivering in-memory data for deterministic testing and instant previewing.
@MainActor
public final class MockAppContainer: AppContainerProtocol {
    public let modelContainer: ModelContainer
    
    public init() {
        self.modelContainer = ModelContainerFactory.createInMemoryContainer()
    }
    
    public func makeReminderRepository() -> any ReminderRepositoryProtocol {
        MockReminderRepository()
    }
    
    public func makeHolidayRepository() -> any HolidayRepositoryProtocol {
        MockHolidayRepository()
    }
    
    public func makeCulturalArticleRepository() -> any CulturalArticleRepositoryProtocol {
        MockCulturalArticleRepository()
    }
    
    public func makeEvaluateFeatureGateUseCase() -> EvaluateFeatureGateUseCase {
        EvaluateFeatureGateUseCase(subscriptionRepository: makeSubscriptionService())
    }

    public func makeGetMonthCalendarUseCase() -> GetMonthCalendarUseCase {
        GetMonthCalendarUseCase()
    }

    public func makeNaturalSearchUseCase() -> NaturalSearchUseCase {
        NaturalSearchUseCase()
    }

    public func makeScheduleReminderUseCase() -> ScheduleReminderUseCase {
        ScheduleReminderUseCase()
    }
    
    public func makeNotificationService() -> any SmartNotificationEngineProtocol {
        MockSmartNotificationEngine()
    }
    
    public func makeSubscriptionService() -> any SubscriptionServiceProtocol {
        MockSubscriptionService(isProUnlocked: true)
    }
}
```

### 5.4. Tích Hợp SwiftUI Environment & Entry Point

```swift
import SwiftUI
import SwiftData
import VNCalendarDomain
import VNCalendarDesignSystem

private struct AppContainerEnvironmentKey: EnvironmentKey {
    @MainActor static let defaultValue: any AppContainerProtocol = AppContainer()
}

extension EnvironmentValues {
    public var appContainer: any AppContainerProtocol {
        get { self[AppContainerEnvironmentKey.self] }
        set { self[AppContainerEnvironmentKey.self] = newValue }
    }
}

@main
struct AnNienApp: App {
    @State private var container: AppContainer
    
    init() {
        let appContainer = AppContainer()
        _container = State(wrappedValue: appContainer)
    }
    
    var body: some Scene {
        WindowGroup {
            MainRootView()
                .environment(\.appContainer, container)
                .modelContainer(container.modelContainer)
        }
    }
}
```

---

## 6. Ma Trận Kiểm Thử Tích Hợp Tầng Kiến Trúc

1. **Strict Concurrency Compile**: Kiểm tra toàn bộ target SPM biên dịch ở chế độ `-strict-concurrency=complete`, không xuất hiện data race warning.
2. **Modular Independence**: Kiểm tra `VNCalendarLunar` và `VNCalendarDomain` biên dịch thành công mà không cần link bất kỳ framework Apple UI nào.
3. **DI Container Contract**: Đảm bảo `MockAppContainer` thay thế hoàn toàn `AppContainer` trong toàn bộ unit test suite với thời gian khởi tạo $< 10\text{ms}$.
