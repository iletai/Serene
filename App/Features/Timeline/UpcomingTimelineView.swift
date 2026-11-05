import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem
import VNCalendarLunar

public struct UpcomingTimelineView: View {
    @Environment(AppContainer.self) private var container
    @Environment(AppRouter.self) private var router
    @State private var viewModel: UpcomingTimelineViewModel?
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    // The floating tab pill overlays the scroll view without a safe-area inset; it grows with Dynamic Type.

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
        ScrollView {
            VStack(alignment: .leading, spacing: VNSpacing.md) {
                headerSection(vm: vm)
                searchBarSection(vm: vm)
                MemorialFilterPills(
                    selectedTab: $vm.selectedFilter.animation(reduceMotion ? nil : .smooth(duration: 0.3)),
                    countForTab: { tab in
                        vm.reminders.filter { tab.matches(category: $0.category) }.count
                    }
                )
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                contentSection(vm: vm)
            }
        }
        .background(Color.vnBackgroundPrimary.ignoresSafeArea())
        .task {
            if viewModel == nil {
                viewModel = activeViewModel
            }
            await viewModel?.load()
            await viewModel?.observe()
        }
    }

    private func createReminder(vm: UpcomingTimelineViewModel) {
        VNHaptics.impact(.light, enabled: hapticFeedbackEnabled)
        Task {
            switch await vm.createReminderGate() {
            case .allowed: router.present(sheet: .reminderForm(editing: nil, initialDate: nil))
            case .requiresPro: router.present(sheet: .paywall)
            }
        }
    }

    private func edit(_ reminder: ReminderEvent) {
        VNHaptics.impact(.light, enabled: hapticFeedbackEnabled)
        router.present(sheet: .reminderForm(editing: reminder, initialDate: nil))
    }

    private func showRitual(_ reminder: ReminderEvent) {
        VNHaptics.impact(.light, enabled: hapticFeedbackEnabled)
        router.present(sheet: .ritual(title: reminder.title))
    }

    // MARK: - Header Section
    @ViewBuilder
    private func headerSection(vm: UpcomingTimelineViewModel) -> some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            HStack {
                HStack(spacing: VNSpacing.xs) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .accessibilityHidden(true)
                        .foregroundColor(.vnAccentHeritageRed)
                    Text("KÍNH NHỚ TỔ TIÊN")
                        .font(.caption2.weight(.bold))
                        .tracking(1.0)
                        .foregroundColor(.vnAccentHeritageRed)
                }
                .padding(.horizontal, VNSpacing.sm)
                .padding(.vertical, VNSpacing.xs)
                .background(Color.vnAccentRedSurface)
                .clipShape(Capsule())

                Spacer()

                VNButton("Thêm Mới", icon: "plus", variant: .primary, size: .small) {
                    createReminder(vm: vm)
                }
            }

            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: VNSpacing.space2) {
                    Text("Ngày Giỗ & Sự Kiện")
                        .font(.system(.title, design: .serif).weight(.bold))
                        .foregroundColor(.vnTextPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    Text("Lưu truyền phụng sự đạo hiếu dòng họ gia tộc")
                        .font(.system(.footnote, design: .serif))
                        .italic()
                        .foregroundColor(.vnTextSecondary)
                }

                Spacer()

                if !vm.reminders.isEmpty {
                    Text("\(vm.reminders.count) sự kiện")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.vnAccentHeritageRed)
                        .padding(.horizontal, VNSpacing.sm)
                        .padding(.vertical, VNSpacing.xs)
                        .background(Color.vnAccentRedSurface)
                        .clipShape(Capsule())
                    .contentTransition(.numericText())
                    .animation(reduceMotion ? nil : .snappy, value: vm.reminders.count)
                }
            }
            .padding(.top, VNSpacing.space2)
        }
        .padding(.horizontal, VNSpacing.screenMargin)
        .padding(.top, VNSpacing.md)
        // Same cap as the Calendar header: keeps the title readable instead of filling the screen at XXXL.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    // MARK: - Search Bar
    @ViewBuilder
    private func searchBarSection(vm: UpcomingTimelineViewModel) -> some View {
        @Bindable var boundVM = vm
        HStack(spacing: VNSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.vnTextSecondary)
                .font(.subheadline)
                .accessibilityHidden(true)

            TextField("Tìm tên tiền nhân, ngày cúng, dòng họ...", text: $boundVM.searchQuery)
                .font(.footnote)

            if !vm.searchQuery.isEmpty {
                Button {
                    vm.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.vnTextTertiary)
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
                .frame(minWidth: VNSize.minTapTarget, minHeight: VNSize.minTapTarget)
                .contentShape(Rectangle())
                .accessibilityLabel("Xóa tìm kiếm")
            }
        }
        .padding(.horizontal, VNSpacing.md)
        .padding(.vertical, VNSpacing.md)
        .frame(minHeight: VNSize.minTapTarget)
        .background(Color.vnBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.card)
                .stroke(Color.vnBorderSubtle, lineWidth: VNBorderWidth.hairline)
        )
        .padding(.horizontal, VNSpacing.screenMargin)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    // MARK: - Main Content Area
    @ViewBuilder
    private func contentSection(vm: UpcomingTimelineViewModel) -> some View {
        if vm.filteredReminders.isEmpty {
            VNEmptyState(
                icon: "flame.fill",
                title: "Gìn Giữ Đạo Hiếu Gia Tiên",
                quote: "“Cây có cội mới trổ cành xanh lá\nNước có nguồn mới bủa khắp rạch sông”",
                ctaLabel: "Thêm Ngày Giỗ Đầu Tiên",
                ctaIcon: "plus.circle.fill",
                onCTA: { createReminder(vm: vm) }
            )
                .padding(.horizontal, VNSpacing.screenMargin)
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
                        onQuickRitual: { showRitual(hero) },
                        onEdit: { edit(hero) }
                    )

                    MemorialTimelineDivider(title: "DANH SÁCH TIẾP THEO")
                }

                ForEach(Array(vm.filteredReminders.enumerated()), id: \.element.id) { index, reminder in
                    let monthStr = String(format: "%02d", reminder.month)
                    let calTypeStr = reminder.dateType == .lunar ? "Âm Lịch" : "Dương Lịch"
                    let dateText = "\(reminder.day)/\(monthStr) \(calTypeStr)"
                    let countdown = vm.countdownText(for: reminder)

                    MemorialTimelineCard(
                        reminder: reminder,
                        dateText: dateText,
                        countdownText: countdown,
                        onViewRitual: { showRitual(reminder) },
                        onEdit: { edit(reminder) },
                        onDelete: { vm.delete(reminder) }
                    )
                    .modifier(TimelineCardAppear(index: index, reduceMotion: reduceMotion))
                }
            }
            .padding(.horizontal, VNSpacing.screenMargin)
        }
    }
}

// MARK: - Card appear

/// Staggered fade-up for the first few cards only; later cards just fade in as they scroll into view.
private struct TimelineCardAppear: ViewModifier {
    private static let staggeredCount = 8
    let index: Int
    let reduceMotion: Bool
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared || reduceMotion ? 1 : 0)
            .offset(y: appeared || reduceMotion ? 0 : 12)
            .onAppear {
                guard !appeared else { return }
                guard index < Self.staggeredCount else {
                    appeared = true
                    return
                }
                withAnimation(.smooth(duration: 0.4).delay(Double(index) * 0.05)) { appeared = true }
            }
    }
}
