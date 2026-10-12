# Kiến Trúc StoreKit 2 & Quản Lý Thuê Bao (StoreKit 2 Monetization & Paywall Engine)

Tài liệu thiết kế kiến trúc hệ thống thương mại hóa và quản lý thuê bao (In-App Purchases & Subscriptions) cho ứng dụng **An Niên (Lịch Việt & Ngày Nhớ)** trên nền tảng **iOS 17.0+ / iOS 18.0+**, hiện thực hóa bằng **StoreKit 2**, **Swift 6 Concurrency (`@MainActor`, `AsyncSequence`)**, mô hình quan sát **`@Observable`**, và giải thuật kiểm soát tính năng **`FeatureGatePolicy`**.

---

## 1. Xác Minh & Chuẩn Hóa StoreKit 2 APIs Trên iOS 17/18

StoreKit 2 cung cấp kiến trúc bất đồng bộ (Modern Async/Await API), mã hóa an toàn bằng chữ ký JWS (JSON Web Signature) trên từng giao dịch, loại bỏ hoàn toàn sự phụ thuộc vào việc xác thực biên lai (Receipt Validation) qua máy chủ trung gian phức tạp đối với mô hình Local-First & Zero-Server Cost.

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                        STOREKIT 2 TRANSACTION & VERIFICATION FLOW                       │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                         │
│   App Launch / Background                 StoreKit Engine (Apple Daemon)                │
│             │                                           │                               │
│             ├─────── 1. Task.detached (App Launch) ────►│ Transaction.updates           │
│             │          listenForTransactions()          │ (Real-time stream)            │
│             │                                           │                               │
│             │◄────── 2. VerificationResult<Transaction> ┤                               │
│             │                                           │                               │
│   ┌─────────┴─────────┐                                 │                               │
│   │ checkVerified()   │                                 │                               │
│   │ JWS Verification  │                                 │                               │
│   └─────────┬─────────┘                                 │                               │
│             │                                           │                               │
│             ├─────── 3. Update Entitlement State ──────►│ Memory / @Observable State    │
│             │                                           │                               │
│             ├─────── 4. await transaction.finish() ────►│ Acknowledge to Apple Server   │
│             │                                           │                               │
│   User Purchase Flow                                    │                               │
│             │                                           │                               │
│             ├─────── 5. product.purchase(options:) ────►│ Apple Payment Sheet           │
│             │                                           │                               │
│             │◄────── 6. PurchaseResult ─────────────────┤ .success / .userCancelled     │
│             │           (.success(VerificationResult))  │                               │
│             │                                           │                               │
│             ├─────── 7. await transaction.finish() ────►│ Finish Transaction            │
│             │                                           │                               │
│   Restore Purchases Flow                                │                               │
│             │                                           │                               │
│             ├─────── 8. AppStore.sync() ───────────────►│ Re-authenticate with Apple ID │
│             │                                           │                               │
│             ├─────── 9. Transaction.currentEntitlements►│ Retrieve Active Purchases    │
│             │                                           │                               │
└─────────────┴───────────────────────────────────────────┴───────────────────────────────┘
```

### 1.1. Bảng Đối Chiếu API StoreKit 2 Cốt Lõi

| StoreKit 2 API | Vai Trò Kỹ Thuật | Đặc Điểm Vận Hành Trên iOS 17/18 |
|---|---|---|
| `Transaction.updates` | `AsyncSequence` lắng nghe mọi biến động giao dịch ngoài ứng dụng (Gia hạn, Hủy gói, Ask to Buy, Refund, Billing Retry). | Phải khởi chạy một `Task` tách rời (`Task.detached` hoặc trong `init` của Actor/Manager) ngay khi app khởi động để không bỏ lỡ giao dịch. |
| `Transaction.currentEntitlements` | `AsyncSequence` duyệt qua toàn bộ các giao dịch còn hiệu lực (Active Subscriptions & Non-Consumables). | Tự động loại bỏ các giao dịch đã hết hạn hoặc bị thu hồi (`revocationDate != nil`). Dùng để khôi phục trạng thái Pro khi mở app. |
| `Product.products(for:)` | Tải thông tin danh mục sản phẩm từ App Store Connect dựa trên Product ID set. | Hỗ trợ tải bất đồng bộ với cơ chế cache tự động của hệ điều hành. Xử lý fallback ngoại tuyến mượt mà. |
| `product.purchase(options:)` | Kích hoạt giao diện thanh toán gốc của Apple. Trả về `Product.PurchaseResult`. | Xử lý 3 trạng thái: `.success`, `.userCancelled`, và `.pending` (áp dụng cho tài khoản trẻ em chờ phụ huynh duyệt hoặc xác thực thẻ ngân hàng 3D Secure). |
| `AppStore.sync()` | Đồng bộ cưỡng bức biên lai và giao dịch từ máy chủ Apple StoreKit. | Kích hoạt khi người dùng nhấn "Khôi phục gói mua" (Restore Purchases) hoặc khi phát sinh bất đồng bộ dữ liệu. Có thể hiển thị popup yêu cầu nhập mật khẩu Apple ID. |
| `transaction.finish()` | Xác nhận ứng dụng đã cấp phát quyền lợi (Entitlement) thành công cho người dùng. | Bắt buộc phải gọi sau khi xử lý giao dịch. Nếu không gọi, Apple sẽ coi giao dịch thất bại và gửi lại giao dịch trong `Transaction.updates` ở lần khởi động sau. |
| `product.subscription?.status` | Kiểm tra trạng thái chi tiết của nhóm thuê bao tự động gia hạn. | Kiểm tra các trạng thái biên: `.subscribed`, `.expired`, `.inGracePeriod` (cho phép dùng tiếp khi thẻ lỗi), `.inBillingRetryPeriod`, `.revoked`. |

---

## 2. Danh Mục Sản Phẩm & Cấu Hình `Products.storekit`

### 2.1. Cấu Trúc Gói Cước An Niên (Pricing & Product Matrix)

| Tên Gói | Product Identifier | Loại Sản Phẩm | Giá Tham Chiếu | Quyền Lợi & Ưu Đãi |
|---|---|---|---|---|
| **Gói Tháng** (Monthly) | `com.iletai.annien.sub.monthly` | Auto-Renewable Subscription | $1.99 / tháng (49.000 đ) | Mở khóa toàn bộ tính năng Pro theo từng tháng. |
| **Gói Năm** (Yearly) | `com.iletai.annien.sub.yearly` | Auto-Renewable Subscription | $14.99 / năm (379.000 đ) | Tiết kiệm 37%, tặng **7 ngày dùng thử miễn phí (Free Trial)**. |
| **Trọn Đời** (Lifetime) | `com.iletai.annien.nonconsumable.lifetime` | Non-Consumable | $39.99 (999.000 đ) | Thanh toán 1 lần duy nhất, sở hữu vĩnh viễn không giới hạn. |

- **Subscription Group Identifier**: `21489012` (Tên nhóm: `AnNienProSubscriptions`). // xác minh lại với App Store Connect trước khi dùng — `Config/Products.storekit` cục bộ có thể lệch với ASC.
- Cả 2 gói Tháng và Năm cùng thuộc một Subscription Group để người dùng có thể nâng cấp/hạ cấp tự do trong cài đặt iOS Settings.

### 2.2. File Cấu Hình StoreKit Testing (`Products.storekit`)

File cấu hình tiêu chuẩn dùng để kiểm thử cục bộ trong Xcode Simulator mà không cần kết nối mạng hoặc tài khoản Sandbox:

```json
{
  "identifier" : "AnNien_Subscriptions",
  "nonConsumableProducts" : [
    {
      "displayPrice" : "39.99",
      "familyShareable" : true,
      "internalID" : "com.iletai.annien.nonconsumable.lifetime",
      "localizations" : [
        {
          "description" : "Truy cập trọn đời tất cả tính năng Pro của An Niên",
          "displayName" : "An Niên Vĩnh Viễn",
          "locale" : "vi"
        }
      ],
      "productID" : "com.iletai.annien.nonconsumable.lifetime",
      "type" : "NonConsumable"
    }
  ],
  "products" : [ ],
  "settings" : {
    "_failTransactionsEnabled" : false,
    "_storeKitErrors" : [ ]
  },
  "subscriptionGroups" : [
    {
      "id" : "21489012",   // xác minh lại với App Store Connect trước khi dùng
      "localizations" : [
        {
          "description" : "Gói thành viên An Niên Pro",
          "displayName" : "An Niên Pro",
          "locale" : "vi"
        }
      ],
      "name" : "AnNienProSubscriptions",
      "subscriptions" : [
        {
          "adHocOffers" : [ ],
          "codeOffers" : [ ],
          "displayPrice" : "1.99",
          "familyShareable" : true,
          "groupNumber" : 2,
          "internalID" : "com.iletai.annien.sub.monthly",
          "introductoryOffer" : null,
          "localizations" : [
            {
              "description" : "Mở khóa toàn bộ tính năng theo tháng",
              "displayName" : "Gói Tháng Pro",
              "locale" : "vi"
            }
          ],
          "productID" : "com.iletai.annien.sub.monthly",
          "recurringSubscriptionPeriod" : "P1M",
          "type" : "RecurringSubscription"
        },
        {
          "adHocOffers" : [ ],
          "codeOffers" : [ ],
          "displayPrice" : "14.99",
          "familyShareable" : true,
          "groupNumber" : 1,
          "internalID" : "com.iletai.annien.sub.yearly",
          "introductoryOffer" : {
            "internalID" : "intro_7days_free",
            "paymentMode" : "freeTrial",
            "subscriptionPeriod" : "P7D"
          },
          "localizations" : [
            {
              "description" : "Mở khóa toàn bộ tính năng 1 năm (Dùng thử 7 ngày)",
              "displayName" : "Gói Năm Pro",
              "locale" : "vi"
            }
          ],
          "productID" : "com.iletai.annien.sub.yearly",
          "recurringSubscriptionPeriod" : "P1Y",
          "type" : "RecurringSubscription"
        }
      ]
    }
  ],
  "version" : {
    "major" : 3,
    "minor" : 0
  }
}
```

> **Chưa verify được từ repo**: trial 7 ngày của gói Năm chỉ tồn tại ở file test cục bộ `Config/Products.storekit` (`intro_7days_free`, `P7D`). Gói thật trên App Store Connect (introductory offer, giá, group ID) phải đối chiếu trực tiếp trên ASC trước khi phát hành — repo không chứa dữ liệu ASC.

---

## 3. Mô Hình Thực Thể & Trạng Thái Thuê Bao (Domain Models)

```swift
import Foundation
import StoreKit

// MARK: - Subscription Tier Definition

/// Cấp độ quyền lợi người dùng trong hệ sinh thái An Niên.
public enum SubscriptionTier: String, Sendable, Codable, Equatable, Comparable {
    case free = "free"
    case pro = "pro"

    private var sortOrder: Int {
        switch self {
        case .free: return 0
        case .pro: return 1
        }
    }

    public static func < (lhs: SubscriptionTier, rhs: SubscriptionTier) -> Bool {
        return lhs.sortOrder < rhs.sortOrder
    }
}

// MARK: - Product Identifier Constants

public enum ProductIdentifier: String, CaseIterable, Sendable {
    case monthly = "com.iletai.annien.sub.monthly"
    case yearly = "com.iletai.annien.sub.yearly"
    case lifetime = "com.iletai.annien.nonconsumable.lifetime"

    public static var allIDs: Set<String> {
        return Set(allCases.map { $0.rawValue })
    }
}

// MARK: - Purchase Result State

public enum PurchaseState: Sendable, Equatable {
    case idle
    case purchasing(productID: String)
    case success(productID: String)
    case cancelled
    case pending
    case failed(StoreKitManagerError)
}

// MARK: - StoreKit Errors

public enum StoreKitManagerError: LocalizedError, Sendable, Equatable {
    case productNotFound
    case failedVerification(String)
    case systemError(String)
    case purchasePending
    case userCancelled
    case networkUnavailable

    public var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Không tìm thấy thông tin sản phẩm trên App Store."
        case .failedVerification(let reason):
            return "Xác thực chữ ký giao dịch thất bại: \(reason)"
        case .systemError(let message):
            return "Lỗi hệ thống thanh toán: \(message)"
        case .purchasePending:
            return "Giao dịch đang chờ duyệt từ gia đình hoặc ngân hàng."
        case .userCancelled:
            return "Giao dịch đã được hủy bởi người dùng."
        case .networkUnavailable:
            return "Không thể kết nối máy chủ App Store. Vui lòng kiểm tra kết nối mạng."
        }
    }
}
```

---

## 4. Quản Lý Thuê Bao Toàn Diện (`SubscriptionManager`)

`SubscriptionManager` tuân thủ Swift 6 Concurrency, đánh dấu `@MainActor`, quản lý transaction lifecycle qua `Task.detached` để đón nhận các sự kiện mua ngoài app (như đổi gói trong iOS Settings hoặc phụ huynh đồng ý mua qua Family Sharing).

```swift
import Foundation
import StoreKit
import Observation
import OSLog

private let logger = Logger(subsystem: "com.iletai.annien", category: "SubscriptionManager")

/// Quản lý thanh toán và trạng thái thuê bao StoreKit 2 cho An Niên.
@Observable
@MainActor
public final class SubscriptionManager: Sendable {
    // MARK: - Observable States
    
    public private(set) var currentTier: SubscriptionTier = .free
    public private(set) var purchasedProductIDs: Set<String> = []
    public private(set) var availableProducts: [Product] = []
    public private(set) var purchaseState: PurchaseState = .idle
    public private(set) var isLoadingProducts: Bool = false
    public private(set) var isRestoringPurchases: Bool = false
    public private(set) var expirationDate: Date? = nil

    // MARK: - Private Properties
    
    private var updateListenerTask: Task<Void, Never>? = nil
    
    // MARK: - Initializer & Deinitializer
    
    public init() {
        // Khởi động listener lắng nghe giao dịch nền
        self.updateListenerTask = listenForTransactions()
        
        // Khởi tạo tải sản phẩm và kiểm tra quyền lợi hiện tại
        Task {
            await loadProducts()
            await updateCustomerProductStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Transaction Listener (Background Stream)
    
    /// Lắng nghe liên tục luồng giao dịch thời gian thực từ Apple
    private func listenForTransactions() -> Task<Void, Never> {
        return Task.detached(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try await self?.checkVerified(result)
                    if let transaction {
                        await self?.handle(verifiedTransaction: transaction)
                        await transaction.finish()
                        logger.info("Hoàn tất xử lý giao dịch cập nhật: \(transaction.productID)")
                    }
                } catch {
                    logger.error("Lỗi xác thực giao dịch trong luồng updates: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Product Catalog Loading
    
    /// Tải danh mục sản phẩm từ App Store Connect
    public func loadProducts() async {
        guard !isLoadingProducts else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        
        do {
            logger.info("Đang tải danh mục sản phẩm StoreKit 2...")
            let products = try await Product.products(for: ProductIdentifier.allIDs)
            
            // Sắp xếp sản phẩm theo thứ tự: Tuần tự Lifetime, Năm (ưu tiên), Tháng
            self.availableProducts = products.sorted { p1, p2 in
                if p1.type == .nonConsumable { return false }
                if p2.type == .nonConsumable { return true }
                return p1.id > p2.id
            }
            logger.info("Tải thành công \(products.count) sản phẩm từ App Store.")
        } catch {
            logger.error("Lỗi tải danh mục sản phẩm: \(error.localizedDescription)")
        }
    }

    // MARK: - Purchase Flow
    
    /// Thực hiện mua sản phẩm
    /// - Parameter product: Sản phẩm StoreKit được chọn
    /// - Returns: Bool biểu thị việc mua thành công và kích hoạt Pro
    @discardableResult
    public func purchase(_ product: Product) async throws -> Bool {
        purchaseState = .purchasing(productID: product.id)
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await handle(verifiedTransaction: transaction)
                await transaction.finish()
                
                purchaseState = .success(productID: product.id)
                logger.info("Mua hàng thành công sản phẩm: \(product.id)")
                return true
                
            case .userCancelled:
                purchaseState = .cancelled
                logger.info("Người dùng hủy giao diện thanh toán.")
                return false
                
            case .pending:
                purchaseState = .pending
                logger.warning("Giao dịch rơi vào trạng thái chờ duyệt (Ask to Buy / 3DS).")
                return false
                
            @unknown default:
                purchaseState = .failed(.systemError("Trạng thái thanh toán không xác định."))
                return false
            }
        } catch let error as StoreKitManagerError {
            purchaseState = .failed(error)
            throw error
        } catch {
            let managerError = StoreKitManagerError.systemError(error.localizedDescription)
            purchaseState = .failed(managerError)
            throw managerError
        }
    }

    // MARK: - Restore Purchases
    
    /// Khôi phục giao dịch đã mua trước đó
    public func restorePurchases() async throws {
        isRestoringPurchases = true
        defer { isRestoringPurchases = false }
        
        do {
            logger.info("Đang đồng bộ giao dịch từ AppStore.sync()...")
            try await AppStore.sync()
            await updateCustomerProductStatus()
            logger.info("Đồng bộ và khôi phục giao dịch thành công.")
        } catch {
            logger.error("Lỗi khi gọi AppStore.sync(): \(error.localizedDescription)")
            throw StoreKitManagerError.systemError(error.localizedDescription)
        }
    }

    // MARK: - Customer Status & Entitlements Update
    
    /// Quét toàn bộ currentEntitlements để cập nhật trạng thái gói cước hiện thời
    public func updateCustomerProductStatus() async {
        var purchasedIDs: Set<String> = []
        var latestExpiration: Date? = nil
        var hasActivePro = false
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // Kiểm tra xem giao dịch có bị Apple thu hồi (Refund) hay không
                if transaction.revocationDate == nil {
                    purchasedIDs.insert(transaction.productID)
                    hasActivePro = true
                    
                    if let expDate = transaction.expirationDate {
                        if latestExpiration == nil || expDate > latestExpiration! {
                            latestExpiration = expDate
                        }
                    }
                } else {
                    logger.warning("Giao dịch \(transaction.productID) đã bị thu hồi vào ngày: \(String(describing: transaction.revocationDate))")
                }
            } catch {
                logger.error("Giao dịch trong currentEntitlements không hợp lệ: \(error.localizedDescription)")
            }
        }
        
        self.purchasedProductIDs = purchasedIDs
        self.expirationDate = latestExpiration
        self.currentTier = hasActivePro ? .pro : .free
        
        logger.info("Cập nhật quyền lợi hoàn tất. Current Tier: \(self.currentTier.rawValue), Active IDs: \(purchasedIDs)")
    }

    // MARK: - Private Helpers
    
    /// Cập nhật state nội bộ khi có một transaction hợp lệ
    private func handle(verifiedTransaction transaction: Transaction) {
        if transaction.revocationDate == nil {
            purchasedProductIDs.insert(transaction.productID)
            currentTier = .pro
            if let expDate = transaction.expirationDate {
                expirationDate = expDate
            }
        } else {
            purchasedProductIDs.remove(transaction.productID)
            if purchasedProductIDs.isEmpty {
                currentTier = .free
            }
        }
    }
    
    /// Xác thực chữ ký mã hóa JWS của Apple
    public nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let verificationError):
            logger.error("Xác thực JWS thất bại: \(verificationError.localizedDescription)")
            throw StoreKitManagerError.failedVerification(verificationError.localizedDescription)
        case .verified(let safeValue):
            return safeValue
        }
    }
}
```

---

## 5. Chính Sách Khóa Tính Năng (`FeatureGatePolicy`)

Hệ thống phân quyền tính năng tuân theo nguyên tắc `Pure Logic - Zero Dependency`, kiểm soát ranh giới giữa bản Miễn Phí (Standard) và Bản Pro (Family Heritage).

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                           FEATURE GATE MATRIX & ENFORCEMENT                             │
├───────────────────────────────┬────────────────────────────┬────────────────────────────┤
│ Tính Năng (Feature)           │ Bản Miễn Phí (Free)        │ Bản Pro / Family Heritage  │
├───────────────────────────────┼────────────────────────────┼────────────────────────────┤
│ Số lượng Ngày Nhớ / Giỗ Chạp  │ Tối đa 5 sự kiện           │ Không giới hạn (Unlimited) │
│ Kích cỡ Widget Hỗ Trợ        │ Chỉ Widget Nhỏ (Small)     │ Small, Medium, Lock Screen │
│ Thời gian nhắc nhở sớm        │ Đúng ngày & Trước 1 ngày   │ Tùy chỉnh: 3, 7, 14, 30 ngày│
│ Đồng bộ CloudKit Đa Thiết Bị  │ Không (Chỉ lưu máy cục bộ) │ Đồng bộ tự động iCloud     │
│ Chế độ Gia Phả & Dòng Họ      │ Bị khóa                    │ Mở khóa toàn diện          │
│ Xuất file PDF Văn Khấn & Lịch │ Bị khóa                    │ Xuất file chất lượng cao   │
└───────────────────────────────┴────────────────────────────┴────────────────────────────┘
```

### 5.1. Hiện Thực `FeatureGatePolicy`

```swift
import Foundation

/// Định nghĩa các giới hạn và quy tắc nghiệp vụ theo cấp độ tài khoản
public struct FeatureGatePolicy: Sendable {
    public let tier: SubscriptionTier
    
    public init(tier: SubscriptionTier) {
        self.tier = tier
    }
    
    // MARK: - Quota Constants
    
    public static let maxFreeRemindersLimit: Int = 5
    public static let defaultFreeNotificationOffsets: [Int] = [0, 1]
    public static let allProNotificationOffsets: [Int] = [0, 1, 3, 7, 14, 30]
    
    // MARK: - Policy Evaluators
    
    /// Kiểm tra người dùng có được phép tạo thêm sự kiện Ngày Nhớ mới hay không
    /// - Parameter currentCount: Số lượng sự kiện hiện có trong cơ sở dữ liệu
    public func canAddReminder(currentCount: Int) -> Bool {
        switch tier {
        case .pro:
            return true
        case .free:
            return currentCount < Self.maxFreeRemindersLimit
        }
    }
    
    /// Số lượng sự kiện tối đa được phép lưu trữ
    public var maxRemindersLimit: Int {
        switch tier {
        case .pro:
            return Int.max
        case .free:
            return Self.maxFreeRemindersLimit
        }
    }
    
    /// Kiểm tra kích cỡ Widget có được phép hiển thị dữ liệu đầy đủ hay không
    /// - Parameter family: Phân loại widget (small, medium, accessoryRectangular, accessoryInline)
    public func isWidgetFamilySupported(_ familyIdentifier: String) -> Bool {
        switch tier {
        case .pro:
            return true
        case .free:
            // Miễn phí chỉ hỗ trợ widget nhỏ (systemSmall)
            return familyIdentifier == "systemSmall"
        }
    }
    
    /// Kiểm tra offset ngày nhắc nhở trước có hợp lệ với gói cước hiện tại
    /// - Parameter days: Số ngày nhắc trước (VD: 0 = đúng ngày, 1 = trước 1 ngày, 7 = trước 1 tuần)
    public func isNotificationOffsetAllowed(days: Int) -> Bool {
        switch tier {
        case .pro:
            return Self.allProNotificationOffsets.contains(days)
        case .free:
            return Self.defaultFreeNotificationOffsets.contains(days)
        }
    }
    
    /// Quyền sử dụng tính năng đồng bộ đám mây CloudKit
    public var isCloudKitSyncEnabled: Bool {
        return tier == .pro
    }
    
    /// Quyền truy cập Chế độ Gia Phả (Genealogy Tree)
    public var isGenealogyModeEnabled: Bool {
        return tier == .pro
    }
    
    /// Quyền xuất bản biểu PDF Lịch Gia Tộc & Văn Khấn
    public var isExportPDFEnabled: Bool {
        return tier == .pro
    }
}
```

---

## 6. Điểm Kích Hoạt Paywall & Giao Diện Người Dùng (Paywall Triggers & UI)

### 6.1. Ma Trận Điểm Kích Hoạt Paywall (Trigger Points)

1. **Trigger A (Reminder Quota Overflow)**: Người dùng nhấn nút "Thêm Ngày Giỗ / Ngày Nhớ" khi danh sách đã đạt 5 mục.
2. **Trigger B (Advanced Notification Selection)**: Người dùng chọn tùy chọn nhắc trước "3 ngày", "7 ngày", "14 ngày" hoặc "30 ngày" trong form tạo sự kiện.
3. **Trigger C (Pro Widget Configuration)**: Người dùng thêm Widget Medium hoặc Lock Screen ngoài màn hình chính.
4. **Trigger D (CloudKit / Backup Settings)**: Người dùng bật công tắc "Đồng bộ iCloud đa thiết bị" trong phần Cài đặt.
5. **Trigger E (Genealogy / Heritage Navigation)**: Người dùng chuyển sang tab "Gia Phả Gia Tộc".
6. **Trigger F (Navigation Bar Pro Badge)**: Người dùng nhấn trực tiếp vào huy hiệu "Nâng cấp Pro" mạ vàng (Imperial Gold) tại Header chính.

### 6.2. Giao Diện Paywall Phong Cách Cổ Truyền Việt Nam (`PaywallView`)

```swift
import SwiftUI
import StoreKit

/// Giao diện Paywall đậm chất văn hóa Việt Nam (Gạo Mới, Mực Nho, Đỏ Chu, Hoàng Cúc)
public struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionManager.self) private var subscriptionManager
    
    @State private var selectedProduct: Product? = nil
    @State private var errorMessage: String? = nil
    @State private var isProcessing: Bool = false
    
    public let triggerSource: String
    
    public init(triggerSource: String = "general") {
        self.triggerSource = triggerSource
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Nền Gạo Mới
                Color(hex: "FAF8F5")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header & Biểu tượng Tôn vinh Truyền Thống
                        headerSection
                        
                        // Danh sách Đặc Quyền Pro
                        featuresListSection
                        
                        // Danh sách gói cước StoreKit 2
                        pricingSection
                        
                        // Nút Mua & Hành động
                        actionButtonSection
                        
                        // Footer Pháp lý & Khôi phục
                        footerLegalSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color(hex: "736E65"))
                    }
                }
            }
            .alert("Thông Báo", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("Đồng Ý", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "")
            }
            .onAppear {
                // Mặc định chọn gói Năm (tốt nhất)
                if let yearly = subscriptionManager.availableProducts.first(where: { $0.id == ProductIdentifier.yearly.rawValue }) {
                    selectedProduct = yearly
                } else {
                    selectedProduct = subscriptionManager.availableProducts.first
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color(hex: "C69214")) // Hoàng Cúc
                .padding(.top, 8)
            
            Text("An Niên — Gia Tộc Hưng Thịnh")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundStyle(Color(hex: "1A1A1A")) // Mực Nho
            
            Text("Lưu giữ trọn vẹn hiếu nghĩa, ngày giỗ chạp tổ tiên và phong tục ngàn đời cho con cháu.")
                .font(.system(size: 15))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(hex: "736E65")) // Tro Bếp
                .padding(.horizontal, 16)
        }
    }
    
    private var featuresListSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            featureRow(icon: "infinity", title: "Không giới hạn Ngày Nhớ & Lịch Giỗ", desc: "Tự do lưu trữ ngày tưởng nhớ không giới hạn 5 mục.")
            featureRow(icon: "bell.badge.fill", title: "Nhắc nhở sớm 30, 14, 7 ngày", desc: "Đủ thời gian chuẩn bị lễ vật và họp mặt đại gia đình.")
            featureRow(icon: "icloud.fill", title: "Đồng bộ iCloud tự động", desc: "Bảo toàn dữ liệu gia phả xuyên suốt các thiết bị iOS.")
            featureRow(icon: "square.grid.2x2.fill", title: "Toàn bộ Widget Vừa & Màn hình khóa", desc: "Theo dõi ngày âm lịch và giỗ chạp ngay tại màn hình chính.")
            featureRow(icon: "person.3.sequence.fill", title: "Cây Gia Phả & Xuất Bản In Ấn", desc: "Sơ đồ dòng tộc trực quan, in biểu mẫu văn khấn chuẩn mực.")
        }
        .padding(18)
        .background(Color(hex: "F0ECE1")) // Vải Xô
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func featureRow(icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(hex: "9E2A2B")) // Đỏ Chu
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(hex: "1A1A1A"))
                Text(desc)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "736E65"))
            }
        }
    }
    
    private var pricingSection: some View {
        VStack(spacing: 12) {
            ForEach(subscriptionManager.availableProducts, id: \.id) { product in
                let isSelected = selectedProduct?.id == product.id
                let isYearly = product.id == ProductIdentifier.yearly.rawValue
                
                Button {
                    selectedProduct = product
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(product.displayName)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(Color(hex: "1A1A1A"))
                                
                                if isYearly {
                                    Text("TIẾT KIỆM 37%")
                                        .font(.system(size: 10, weight: .heavy))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color(hex: "9E2A2B"))
                                        .foregroundStyle(.white)
                                        .clipShape(Capsule())
                                }
                            }
                            
                            Text(product.description)
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: "736E65"))
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(product.displayPrice)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(Color(hex: "9E2A2B"))
                            
                            if isYearly {
                                Text("7 ngày miễn phí")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Color(hex: "C69214"))
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color(hex: "9E2A2B") : Color(hex: "E3DDD2"), lineWidth: isSelected ? 2 : 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var actionButtonSection: some View {
        VStack(spacing: 10) {
            Button {
                guard let product = selectedProduct else { return }
                Task {
                    isProcessing = true
                    defer { isProcessing = false }
                    do {
                        let success = try await subscriptionManager.purchase(product)
                        if success {
                            dismiss()
                        }
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            } label: {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .tint(.white)
                            .padding(.trailing, 8)
                    }
                    Text(buttonTitle)
                        .font(.system(size: 17, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color(hex: "9E2A2B")) // Đỏ Chu
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isProcessing || selectedProduct == nil)
        }
    }
    
    private var buttonTitle: String {
        if selectedProduct?.id == ProductIdentifier.yearly.rawValue {
            return "Bắt Đầu 7 Ngày Dùng Thử Miễn Phí"
        } else if selectedProduct?.type == .nonConsumable {
            return "Sở Hữu Trọn Đời Ngay"
        } else {
            return "Đăng Ký Ngay"
        }
    }
    
    private var footerLegalSection: some View {
        VStack(spacing: 8) {
            Button {
                Task {
                    isProcessing = true
                    defer { isProcessing = false }
                    do {
                        try await subscriptionManager.restorePurchases()
                        if subscriptionManager.currentTier == .pro {
                            dismiss()
                        } else {
                            errorMessage = "Không tìm thấy giao dịch hợp lệ nào để khôi phục."
                        }
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            } label: {
                Text("Khôi Phục Gói Đã Mua (Restore Purchases)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(hex: "736E65"))
            }
            
            HStack(spacing: 16) {
                Link("Điều Khoản Sử Dụng (EULA)", destination: URL(string: "https://annien.app/terms")!)
                Text("•")
                Link("Chính Sách Bảo Mật", destination: URL(string: "https://annien.app/privacy")!)
            }
            .font(.system(size: 11))
            .foregroundStyle(Color(hex: "736E65"))
        }
        .padding(.top, 8)
    }
}
```

---

## 7. Kiểm Thử Đơn Vị & Tích Hợp StoreKit 2 (`StoreKitTest`)

Sử dụng framework chính thức `StoreKitTest` kết hợp `XCTest` / `Swift Testing` để kiểm thử toàn bộ các kịch bản mua hàng, hoàn tiền, hủy gia hạn và kiểm tra logic `FeatureGatePolicy`.

```swift
import XCTest
import StoreKitTest
@testable import AnNien

@MainActor
final class StoreKit2MonetizationTests: XCTestCase {
    var session: SKTestSession!
    var subscriptionManager: SubscriptionManager!

    override func setUp() async throws {
        try await super.setUp()
        
        // Khởi tạo SKTestSession liên kết với file Products.storekit cục bộ
        session = try SKTestSession(configurationFileNamed: "Products")
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()
        
        subscriptionManager = SubscriptionManager()
    }

    override func tearDown() async throws {
        session.clearTransactions()
        session = nil
        subscriptionManager = nil
        try await super.tearDown()
    }

    // MARK: - Test Cases
    
    func testInitialStateIsFreeTier() async {
        XCTAssertEqual(subscriptionManager.currentTier, .free)
        XCTAssertTrue(subscriptionManager.purchasedProductIDs.isEmpty)
        
        let policy = FeatureGatePolicy(tier: subscriptionManager.currentTier)
        XCTAssertTrue(policy.canAddReminder(currentCount: 4))
        XCTAssertFalse(policy.canAddReminder(currentCount: 5))
        XCTAssertFalse(policy.isCloudKitSyncEnabled)
    }

    func testPurchaseMonthlySubscriptionSuccess() async throws {
        // Tải danh mục
        await subscriptionManager.loadProducts()
        
        let monthlyProduct = try XCTUnwrap(
            subscriptionManager.availableProducts.first(where: { $0.id == ProductIdentifier.monthly.rawValue })
        )
        
        // Thực hiện mua
        let success = try await subscriptionManager.purchase(monthlyProduct)
        XCTAssertTrue(success)
        
        // Xác minh trạng thái sau mua
        await subscriptionManager.updateCustomerProductStatus()
        XCTAssertEqual(subscriptionManager.currentTier, .pro)
        XCTAssertTrue(subscriptionManager.purchasedProductIDs.contains(ProductIdentifier.monthly.rawValue))
        
        let policy = FeatureGatePolicy(tier: subscriptionManager.currentTier)
        XCTAssertTrue(policy.canAddReminder(currentCount: 100))
        XCTAssertTrue(policy.isCloudKitSyncEnabled)
        XCTAssertTrue(policy.isWidgetFamilySupported("systemMedium"))
    }

    func testPurchaseLifetimeNonConsumableSuccess() async throws {
        await subscriptionManager.loadProducts()
        
        let lifetimeProduct = try XCTUnwrap(
            subscriptionManager.availableProducts.first(where: { $0.id == ProductIdentifier.lifetime.rawValue })
        )
        
        let success = try await subscriptionManager.purchase(lifetimeProduct)
        XCTAssertTrue(success)
        
        await subscriptionManager.updateCustomerProductStatus()
        XCTAssertEqual(subscriptionManager.currentTier, .pro)
        XCTAssertTrue(subscriptionManager.purchasedProductIDs.contains(ProductIdentifier.lifetime.rawValue))
    }

    func testRefundAndRevocationDowngradesToFreeTier() async throws {
        await subscriptionManager.loadProducts()
        let monthlyProduct = try XCTUnwrap(
            subscriptionManager.availableProducts.first(where: { $0.id == ProductIdentifier.monthly.rawValue })
        )
        
        _ = try await subscriptionManager.purchase(monthlyProduct)
        await subscriptionManager.updateCustomerProductStatus()
        XCTAssertEqual(subscriptionManager.currentTier, .pro)
        
        // Giả lập hoàn tiền từ Apple (Refund / Revoke)
        let transactions = session.allTransactions()
        if let lastTransaction = transactions.last {
            try session.refundTransaction(identifier: UInt(lastTransaction.identifier))
        }
        
        // Cập nhật lại quyền lợi
        await subscriptionManager.updateCustomerProductStatus()
        XCTAssertEqual(subscriptionManager.currentTier, .free)
        XCTAssertFalse(subscriptionManager.purchasedProductIDs.contains(ProductIdentifier.monthly.rawValue))
    }

    func testRestorePurchasesFlow() async throws {
        // Mua trên session gốc
        try session.buyProduct(productIdentifier: ProductIdentifier.yearly.rawValue)
        
        // Khởi động restore
        try await subscriptionManager.restorePurchases()
        
        XCTAssertEqual(subscriptionManager.currentTier, .pro)
        XCTAssertTrue(subscriptionManager.purchasedProductIDs.contains(ProductIdentifier.yearly.rawValue))
    }
}
```
