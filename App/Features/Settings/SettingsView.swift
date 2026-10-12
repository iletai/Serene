import OSLog
import SwiftUI
import VNCalendarData
import VNCalendarDomain
import VNCalendarDesignSystem

private let settingsLogger = Logger(subsystem: "com.iletai.annien", category: "SettingsView")

public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var container = AppContainer.shared
    @State private var isShowingPaywall = false
    @State private var exportText: String = ""
    @State private var isShowingExportSheet = false
    @State private var backupStatusMessage: String?
    @State private var isSyncingContent = false
    @AppStorage("appThemeAppearance") private var appThemeAppearance: Int = 0 // 0: Auto, 1: Rice Paper Light, 2: Lacquer Charcoal Dark

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: VNSpacing.xl) {
                    membershipSection
                    appearanceSection
                    dataSection
                    timezoneSection
                    privacySection
                    aboutSection
                }
                .padding(.horizontal, VNSpacing.xl)
                .padding(.top, VNSpacing.xl)
                .padding(.bottom, VNSpacing.xxl)
            }
            .background(Color.vnBackgroundPrimary.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.vnBackgroundPrimary.opacity(0.9), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Cài Đặt")
                        .font(.vnTitleCeremonial)
                        .foregroundColor(.vnAccentDeepPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Xong") { dismiss() }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
            }
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $isShowingExportSheet) {
                ShareSheet(activityItems: [exportText])
            }
        }
    }

    // MARK: - Sections
    private var membershipSection: some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            sectionHeader("Gói Thành Viên")
            settingsCard {
                HStack {
                    VStack(alignment: .leading, spacing: VNSpacing.space2) {
                        let proTitle = "An Niên Gia Tộc Pro"
                        let freeTitle = "Bản Tiêu Chuẩn (Miễn Phí)"
                        Text(subscriptionManager.entitlement.isPro ? proTitle : freeTitle)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.vnTextPrimary)
                        let proSubtitle = "Không giới hạn ngày nhớ & Đồng bộ iCloud"
                        let freeSubtitle = "Tối đa 5 ngày nhớ gia đình"
                        Text(subscriptionManager.entitlement.isPro ? proSubtitle : freeSubtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.vnTextSecondary)
                    }
                    Spacer()
                    if !subscriptionManager.entitlement.isPro {
                        Button("Nâng Cấp") {
                            isShowingPaywall = true
                        }
                        .font(.vnCaption1)
                        .fontWeight(.bold)
                        .frame(minHeight: 44)
                        .padding(.horizontal, VNSpacing.md)
                        .contentShape(Capsule())
                        .background(Color.vnAccentHeritageRed)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    } else {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.vnAccentHeritageRed)
                            .accessibilityHidden(true)
                    }
                }
                .padding(.horizontal, VNSpacing.lg)
                .padding(.vertical, VNSpacing.md)
            }
        }
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            sectionHeader("Giao Diện & Bản Sắc")
            settingsCard {
                HStack {
                    Text("Chế độ hiển thị")
                        .font(.system(size: 16))
                        .foregroundColor(.vnTextPrimary)
                    Spacer()
                    Picker("Chế độ hiển thị", selection: $appThemeAppearance) {
                        Text("Tự động theo hệ thống").tag(0)
                        Text("Giấy Dó (Sáng)").tag(1)
                        Text("Than Mài (Tối)").tag(2)
                    }
                    .labelsHidden()
                    .tint(.vnAccentHeritageRed)
                }
                .padding(.horizontal, VNSpacing.lg)
                .padding(.vertical, VNSpacing.md)
            }
        }
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            sectionHeader("Dữ Liệu & Đồng Bộ")
            settingsCard {
                Button(action: handleRefreshContent) {
                    HStack {
                        Label("Làm mới Phong tục & Ngày lễ", systemImage: "arrow.triangle.2.circlepath")
                            .font(.system(size: 16))
                            .foregroundColor(.vnTextPrimary)
                        Spacer()
                        if isSyncingContent {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
                .disabled(isSyncingContent)
                .padding(.horizontal, VNSpacing.lg)
                .padding(.vertical, VNSpacing.md)
                rowDivider
                Button(action: handleExportJSON) {
                    HStack {
                        Label("Xuất Bản Sao Lưu (JSON)", systemImage: "square.and.arrow.up")
                            .font(.system(size: 16))
                            .foregroundColor(.vnTextPrimary)
                        Spacer()
                    }
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
                .padding(.horizontal, VNSpacing.lg)
                .padding(.vertical, VNSpacing.md)
                rowDivider
                Button(action: handleExportICS) {
                    HStack {
                        Label("Đồng Bộ Apple Calendar (ICS)", systemImage: "calendar.badge.plus")
                            .font(.system(size: 16))
                            .foregroundColor(.vnTextPrimary)
                        Spacer()
                    }
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
                .padding(.horizontal, VNSpacing.lg)
                .padding(.vertical, VNSpacing.md)
                if let msg = backupStatusMessage {
                    rowDivider
                    Text(msg)
                        .font(.system(size: 12))
                        .foregroundColor(.vnStatusSuccess)
                        .padding(.horizontal, VNSpacing.lg)
                        .padding(.vertical, VNSpacing.sm)
                }
            }
        }
    }

    private var timezoneSection: some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            sectionHeader("Cài Đặt Lịch & Múi Giờ")
            settingsCard {
                HStack {
                    Text("Múi Giờ Tính Lịch Âm")
                        .font(.system(size: 16))
                        .foregroundColor(.vnTextPrimary)
                    Spacer()
                    Text("GMT+7 (Hà Nội)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.vnAccentHeritageRed)
                }
                .padding(.horizontal, VNSpacing.lg)
                .padding(.vertical, VNSpacing.md)
                rowDivider
                HStack {
                    Text("Ngày Bắt Đầu Tuần")
                        .font(.system(size: 16))
                        .foregroundColor(.vnTextPrimary)
                    Spacer()
                    Text("Thứ Hai")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.vnAccentHeritageRed)
                }
                .padding(.horizontal, VNSpacing.lg)
                .padding(.vertical, VNSpacing.md)
            }
        }
    }

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            sectionHeader("Quyền Riêng Tư & An Toàn Dữ Liệu")
            settingsCard {
                VStack(alignment: .leading, spacing: VNSpacing.xs) {
                    Text("Cam kết Zero-Knowledge Privacy")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.vnTextPrimary)
                    Text("Tất cả ngày giỗ, tên người thân và thông tin gia tộc chỉ lưu trữ trên thiết bị của bạn " +
                         "và tài khoản iCloud cá nhân. Ứng dụng không sử dụng máy chủ trung gian.")
                        .font(.system(size: 12))
                        .foregroundColor(.vnTextSecondary)
                }
                .padding(.horizontal, VNSpacing.lg)
                .padding(.vertical, VNSpacing.md)
            }
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            sectionHeader("Thông Tin Ứng Dụng")
            settingsCard {
                HStack {
                    Text("Phiên Bản")
                        .font(.system(size: 16))
                        .foregroundColor(.vnTextPrimary)
                    Spacer()
                    Text("1.0.0 (Build 1)")
                        .font(.system(size: 12))
                        .foregroundColor(.vnTextSecondary)
                }
                .padding(.horizontal, VNSpacing.lg)
                .padding(.vertical, VNSpacing.md)
                rowDivider
                HStack {
                    Text("Bản Quyền")
                        .font(.system(size: 16))
                        .foregroundColor(.vnTextPrimary)
                    Spacer()
                    Text("An Niên • iletai")
                        .font(.system(size: 12))
                        .foregroundColor(.vnTextSecondary)
                }
                .padding(.horizontal, VNSpacing.lg)
                .padding(.vertical, VNSpacing.md)
            }
        }
    }

    // MARK: - Canonical helpers (presentation only)
    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .medium))
            .tracking(0.7)
            .foregroundColor(.vnOnGoldContainer)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            .accessibilityAddTraits(.isHeader)
    }

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(Color.vnBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous)
                .stroke(Color.vnAccentImperialGold.opacity(0.28), lineWidth: VNBorderWidth.regular)
        )
    }

    private var rowDivider: some View {
        Divider()
            .background(Color.vnBorderSubtle)
            .padding(.leading, VNSpacing.lg)
    }

    private func handleRefreshContent() {
        isSyncingContent = true
        Task {
            do {
                try await container.holidayRepository.synchronizeRemoteContent()
                backupStatusMessage = "Đã cập nhật dữ liệu phong tục & ngày lễ mới nhất."
            } catch MicroCMSError.configurationMissing {
                settingsLogger.info("MicroCMS key missing, skip remote sync.")
            } catch {
                backupStatusMessage = "Đã sử dụng dữ liệu bản địa ngoại tuyến."
            }
            isSyncingContent = false
        }
    }

    private func handleExportJSON() {
        Task {
            do {
                let reminders = try await container.reminderRepository.fetchAllReminders()
                let data = try DataBackupEngine.exportJSON(reminders: reminders)
                if let str = String(data: data, encoding: .utf8) {
                    exportText = str
                    isShowingExportSheet = true
                    backupStatusMessage = "Đã xuất \(reminders.count) sự kiện."
                }
            } catch {
                backupStatusMessage = "Lỗi xuất sao lưu: \(error.localizedDescription)"
            }
        }
    }

    private func handleExportICS() {
        Task {
            let reminders = (try? await container.reminderRepository.fetchAllReminders()) ?? []
            let ics = await DataBackupEngine.generateICS(reminders: reminders)
            exportText = ics
            isShowingExportSheet = true
            backupStatusMessage = "Đã tạo file iCalendar (ICS)."
        }
    }
}

public struct ShareSheet: UIViewControllerRepresentable {
    public let activityItems: [Any]

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
