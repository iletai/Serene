import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem
import VNCalendarLunar

public struct UpcomingTimelineView: View {
    @Environment(AppContainer.self) private var container
    @State private var viewModel: UpcomingTimelineViewModel?

    public init() {}

    private var activeViewModel: UpcomingTimelineViewModel {
        if let existing = viewModel { return existing }
        let vm = UpcomingTimelineViewModel(
            reminderRepository: container.reminderRepository,
            scheduleReminderUseCase: container.scheduleReminderUseCase,
            evaluateFeatureGateUseCase: container.evaluateFeatureGateUseCase
        )
        return vm
    }

    public var body: some View {
        @Bindable var vm = activeViewModel
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: VNSpacing.md) {
                    headerSection(vm: vm)
                    searchBarSection(vm: vm)
                    MemorialFilterPills(
                        selectedTab: $vm.selectedFilter,
                        countForTab: { tab in
                            vm.reminders.filter { tab.matches(category: $0.category) }.count
                        }
                    )
                    contentSection(vm: vm)
                }
                .padding(.bottom, VNSpacing.xl)
            }
            .background(Color.vnBackgroundPrimary.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $vm.isShowingCreateReminder) {
                ReminderFormView(onSave: { newReminder in
                    vm.save(newReminder)
                })
                .presentationDetents([.fraction(0.92), .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $vm.editingReminder) { item in
                ReminderFormView(existingReminder: item, onSave: { updated in
                    vm.save(updated)
                })
                .presentationDetents([.fraction(0.92), .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: Binding<RitualItem?>(
                get: { vm.selectedRitualTitle.map { RitualItem(title: $0) } },
                set: { vm.selectedRitualTitle = $0?.title }
            )) { ritual in
                RitualPrayerModal(title: ritual.title)
            }
            .sheet(isPresented: $vm.isShowingPaywall) {
                PaywallView()
            }
            .task {
                if viewModel == nil {
                    viewModel = activeViewModel
                }
                await viewModel?.load()
            }
        }
    }

    // MARK: - Header Section
    @ViewBuilder
    private func headerSection(vm: UpcomingTimelineViewModel) -> some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            HStack {
                HStack(spacing: VNSpacing.xs) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.vnAccentHeritageRed)
                    Text("KÍNH NHỚ TỔ TIÊN")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.0)
                        .foregroundColor(.vnAccentHeritageRed)
                }
                .padding(.horizontal, VNSpacing.sm)
                .padding(.vertical, VNSpacing.xs)
                .background(Color.vnAccentRedSurface)
                .clipShape(Capsule())

                Spacer()

                VNButton("Thêm Mới", icon: "plus", variant: .primary, size: .small) {
                    vm.checkAndCreate()
                }
            }

            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: VNSpacing.space2) {
                    Text("Ngày Giỗ & Sự Kiện")
                        .font(.system(size: 26, weight: .bold, design: .serif))
                        .foregroundColor(.vnTextPrimary)

                    Text("Lưu truyền phụng sự đạo hiếu dòng họ gia tộc")
                        .font(.system(size: 13, design: .serif))
                        .italic()
                        .foregroundColor(.vnTextSecondary)
                }

                Spacer()

                if !vm.reminders.isEmpty {
                    Text("\(vm.reminders.count) sự kiện")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.vnAccentHeritageRed)
                        .padding(.horizontal, VNSpacing.sm)
                        .padding(.vertical, VNSpacing.xs)
                        .background(Color.vnAccentRedSurface)
                        .clipShape(Capsule())
                }
            }
            .padding(.top, VNSpacing.space2)
        }
        .padding(.horizontal, VNSpacing.xl)
        .padding(.top, VNSpacing.md)
    }

    // MARK: - Search Bar
    @ViewBuilder
    private func searchBarSection(vm: UpcomingTimelineViewModel) -> some View {
        @Bindable var boundVM = vm
        HStack(spacing: VNSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.vnTextSecondary)
                .font(.system(size: 14))

            TextField("Tìm tên tiền nhân, ngày cúng, dòng họ...", text: $boundVM.searchQuery)
                .font(.system(size: 13))

            if !vm.searchQuery.isEmpty {
                Button {
                    vm.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.vnTextTertiary)
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
                .accessibilityLabel("Xóa tìm kiếm")
            }
        }
        .padding(.horizontal, VNSpacing.md)
        .padding(.vertical, VNSpacing.md)
        .frame(minHeight: 44)
        .background(Color.vnBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.card)
                .stroke(Color.vnBorderSubtle, lineWidth: VNBorderWidth.hairline)
        )
        .padding(.horizontal, VNSpacing.xl)
    }

    // MARK: - Main Content Area
    @ViewBuilder
    private func contentSection(vm: UpcomingTimelineViewModel) -> some View {
        @Bindable var boundVM = vm
        if vm.filteredReminders.isEmpty {
            MemorialEmptyStateView(onAdd: { vm.checkAndCreate() })
                .padding(.horizontal, VNSpacing.xl)
        } else {
            VStack(alignment: .leading, spacing: VNSpacing.md) {
                if vm.searchQuery.isEmpty && vm.selectedFilter == .all, let hero = vm.urgentMemorial {
                    let monthStr = String(format: "%02d", hero.month)
                    let calTypeStr = hero.dateType == .lunar ? "Âm Lịch" : "Dương Lịch"
                    let dateText = "\(hero.day)/\(monthStr) \(calTypeStr)"

                    MemorialHeroCard(
                        reminder: hero,
                        dateText: dateText,
                        countdownText: vm.countdownText(for: hero),
                        onQuickRitual: { vm.selectedRitualTitle = hero.title },
                        onEdit: { boundVM.editingReminder = hero }
                    )

                    MemorialTimelineDivider(title: "DANH SÁCH TIẾP THEO")
                }

                ForEach(vm.filteredReminders) { reminder in
                    let monthStr = String(format: "%02d", reminder.month)
                    let calTypeStr = reminder.dateType == .lunar ? "Âm Lịch" : "Dương Lịch"
                    let dateText = "\(reminder.day)/\(monthStr) \(calTypeStr)"
                    let countdown = vm.countdownText(for: reminder)

                    MemorialTimelineCard(
                        reminder: reminder,
                        dateText: dateText,
                        countdownText: countdown,
                        onViewRitual: { vm.selectedRitualTitle = reminder.title },
                        onEdit: { boundVM.editingReminder = reminder },
                        onDelete: { vm.delete(reminder) }
                    )
                }
            }
            .padding(.horizontal, VNSpacing.xl)
        }
    }
}

private struct RitualItem: Identifiable {
    let id = UUID()
    let title: String
}

private struct RitualPrayerModal: View {
    @Environment(\.dismiss) private var dismiss
    let title: String

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: VNSpacing.lg) {
                    VStack(alignment: .leading, spacing: VNSpacing.xs) {
                        HStack(spacing: VNSpacing.xs) {
                            VNSealBadge.gio(size: .medium)

                            Text("VĂN KHẤN TRUYỀN THỐNG")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.0)
                                .foregroundColor(.vnAccentHeritageRed)
                        }

                        Text(title)
                            .font(.system(size: 24, weight: .bold, design: .serif))
                            .foregroundColor(.vnTextPrimary)

                        Text("Bài văn cúng giỗ chính nhật và tuần tiết gia tiên")
                            .font(.system(size: 13, design: .serif))
                            .italic()
                            .foregroundColor(.vnTextSecondary)
                    }

                    VNRowDivider()

                    VStack(alignment: .leading, spacing: VNSpacing.md) {
                        Text("""
                        Nam mô A Di Đà Phật! (3 lần)

                        Con kính lạy chín phương Trời, mười phương Chư Phật, Chư Phật mười phương.
                        Con kính lạy Hoàng thiên Hậu Thổ chư vị Tôn thần.
                        Con kính lạy ngài Bản cảnh Thành hoàng, ngài Bản xứ Thổ địa, \
                        ngài Bản gia Táo quân cùng chư vị Tôn thần.
                        Con kính lạy Cao Tằng Tổ Khảo, Cao Tằng Tổ Tỷ, Thúc Bá Đệ Huynh, Cô Di Tỷ Muội họ nội họ ngoại.

                        Tín chủ con là: ....................................................
                        Ngụ tại: ................................................................

                        Hôm nay là ngày giỗ chính nhật của: \(title)
                        Thiết nghĩ: Ơn trời biển khó đền, công sinh thành dưỡng dục khôn xiết.
                        Nhớ ngày kỵ nhật, tín chủ con thành tâm sắm sửa phẩm vật hương hoa dâng trước án tọa.

                        Kính cẩn thỉnh mời chân linh tiền nhân quang lâm chứng giám, thụ hưởng lễ vật, \
                        độ trì cho toàn thể gia quyến luôn được an khang thịnh vượng, gia đạo hưng long.

                        Cẩn cáo!
                        Nam mô A Di Đà Phật! (3 lần)
                        """)
                        .font(.system(size: 15, design: .serif))
                        .foregroundColor(.vnTextPrimary)
                        .lineSpacing(7)
                        .padding(VNSpacing.lg)
                        .background(Color.vnBackgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
                        .overlay(
                            RoundedRectangle(cornerRadius: VNCornerRadius.card)
                                .stroke(Color.vnBorderSubtle, lineWidth: VNBorderWidth.hairline)
                        )
                    }
                }
                .padding(VNSpacing.lg)
            }
            .background(Color.vnBackgroundPrimary.ignoresSafeArea())
            .vnNavBar(title: "Văn Khấn Gia Tiên") {
                VNDismissButton(style: .text("Đóng")) { dismiss() }
            }
        }
    }
}
