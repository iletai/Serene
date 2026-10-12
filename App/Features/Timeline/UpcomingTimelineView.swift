import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem
import VNCalendarLunar

public struct UpcomingTimelineView: View {
    @State private var container = AppContainer.shared
    @State private var reminders: [ReminderEvent] = []
    @State private var searchQuery = ""
    @State private var selectedFilter: MemorialFilterTab = .all
    @State private var isShowingCreateReminder = false
    @State private var isShowingPaywall = false
    @State private var editingReminder: ReminderEvent?
    @State private var selectedRitualTitle: String?

    public init() {}

    private var filteredReminders: [ReminderEvent] {
        let base = reminders.filter { selectedFilter.matches(category: $0.category) }
        if searchQuery.isEmpty {
            return base
        }
        return base.filter {
            $0.title.localizedCaseInsensitiveContains(searchQuery) ||
            ($0.note?.localizedCaseInsensitiveContains(searchQuery) == true) ||
            ($0.relationship?.localizedCaseInsensitiveContains(searchQuery) == true)
        }
    }

    private var urgentMemorial: ReminderEvent? {
        reminders.first {
            $0.category == .deathAnniversary || $0.category == .ancestral
        }
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: VNSpacing.md) {
                    headerSection
                    searchBarSection
                    MemorialFilterPills(
                        selectedTab: $selectedFilter,
                        countForTab: { tab in
                            reminders.filter { tab.matches(category: $0.category) }.count
                        }
                    )
                    contentSection
                }
                // Pill space is reserved by MainTabView.safeAreaInset; this is just a section gap.
                .padding(.bottom, VNSpacing.xl)
            }
            .background(Color.vnBackgroundPrimary.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $isShowingCreateReminder) {
                ReminderFormView(onSave: { newReminder in
                    saveReminder(newReminder)
                })
                .presentationDetents([.fraction(0.92), .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $editingReminder) { item in
                ReminderFormView(existingReminder: item, onSave: { updated in
                    saveReminder(updated)
                })
                .presentationDetents([.fraction(0.92), .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: Binding<RitualItem?>(
                get: { selectedRitualTitle.map { RitualItem(title: $0) } },
                set: { selectedRitualTitle = $0?.title }
            )) { ritual in
                RitualPrayerModal(title: ritual.title)
            }
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView()
            }
            .task {
                await loadReminders()
            }
        }
    }

    // MARK: - Header Section
    @ViewBuilder
    private var headerSection: some View {
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

                Button {
                    checkAndCreate()
                } label: {
                    HStack(spacing: VNSpacing.xs) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                        Text("Thêm Mới")
                            .font(.system(size: 12, weight: .bold, design: .serif))
                    }
                    .foregroundColor(.white)
                    .frame(minHeight: 44)
                    .padding(.horizontal, VNSpacing.lg)
                    .background(Color.vnAccentHeritageRed)
                    .clipShape(Capsule())
                    .shadow(color: VNShadow.card.color, radius: VNShadow.card.radius, x: VNShadow.card.x, y: VNShadow.card.y)
                }
                .buttonStyle(.plain)
                .contentShape(Capsule())
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

                if !reminders.isEmpty {
                    Text("\(reminders.count) sự kiện")
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
    private var searchBarSection: some View {
        HStack(spacing: VNSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.vnTextSecondary)
                .font(.system(size: 14))

            TextField("Tìm tên tiền nhân, ngày cúng, dòng họ...", text: $searchQuery)
                .font(.system(size: 13))

            if !searchQuery.isEmpty {
                Button {
                    searchQuery = ""
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
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.medium)
                .stroke(Color.vnBorderSubtle, lineWidth: VNBorderWidth.hairline)
        )
        .padding(.horizontal, VNSpacing.xl)
    }

    // MARK: - Main Content Area
    @ViewBuilder
    private var contentSection: some View {
        if filteredReminders.isEmpty {
            MemorialEmptyStateView(onAdd: { checkAndCreate() })
                .padding(.horizontal, VNSpacing.xl)
        } else {
            VStack(alignment: .leading, spacing: VNSpacing.md) {
                // Urgent Hero Card (if on All or Ancestor tab and no search filter)
                if searchQuery.isEmpty && selectedFilter == .all, let hero = urgentMemorial {
                    let monthStr = String(format: "%02d", hero.month)
                    let calTypeStr = hero.dateType == .lunar ? "Âm Lịch" : "Dương Lịch"
                    let dateText = "\(hero.day)/\(monthStr) \(calTypeStr)"

                    MemorialHeroCard(
                        reminder: hero,
                        dateText: dateText,
                        countdownText: calculateCountdown(for: hero),
                        onQuickRitual: { selectedRitualTitle = hero.title },
                        onEdit: { editingReminder = hero }
                    )

                    MemorialTimelineDivider(title: "DANH SÁCH TIẾP THEO")
                }

                // Regular Timeline List
                ForEach(filteredReminders) { reminder in
                    let monthStr = String(format: "%02d", reminder.month)
                    let calTypeStr = reminder.dateType == .lunar ? "Âm Lịch" : "Dương Lịch"
                    let dateText = "\(reminder.day)/\(monthStr) \(calTypeStr)"
                    let countdown = calculateCountdown(for: reminder)

                    MemorialTimelineCard(
                        reminder: reminder,
                        dateText: dateText,
                        countdownText: countdown,
                        onViewRitual: { selectedRitualTitle = reminder.title },
                        onEdit: { editingReminder = reminder },
                        onDelete: { deleteReminder(reminder) }
                    )
                }
            }
            .padding(.horizontal, VNSpacing.xl)
        }
    }

    private func nextOccurrenceDate(for reminder: ReminderEvent, today: Date, calendar: Calendar) -> Date {
        let solarNow = SolarDate(from: today, calendar: calendar)
        if reminder.dateType == .lunar {
            let engine = LunarAstronomicalEngine.shared
            let currentLunar = engine.convertToLunar(from: solarNow)
            var targetLunarYear = currentLunar.year
            if currentLunar.month > reminder.month || (currentLunar.month == reminder.month && currentLunar.day > reminder.day) {
                targetLunarYear += 1
            }
            let targetLunar = LunarDate(day: reminder.day, month: reminder.month, year: targetLunarYear, isLeapMonth: reminder.isLeapMonth)
            let targetSolar = engine.convertToSolar(from: targetLunar)
            return targetSolar.date ?? today
        } else {
            var comps = DateComponents(year: solarNow.year, month: reminder.month, day: reminder.day)
            if let date = calendar.date(from: comps) {
                if date < today {
                    comps.year = solarNow.year + 1
                    return calendar.date(from: comps) ?? date
                }
                return date
            }
            // Clamp invalid solar day (e.g. 30/2) to the month's last day.
            if let clampedDay = calendar.range(of: .day, in: .month, for: calendar.date(from: DateComponents(year: solarNow.year, month: reminder.month, day: 1)) ?? today)?.count {
                comps.day = min(reminder.day, clampedDay)
                if let date = calendar.date(from: comps), date >= today {
                    return date
                }
            }
            return today
        }
    }

    private func calculateCountdown(for reminder: ReminderEvent) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? TimeZone(secondsFromGMT: 7 * 3600) ?? .current
        let today = cal.startOfDay(for: Date())
        let target = nextOccurrenceDate(for: reminder, today: today, calendar: cal)
        let diff = cal.dateComponents([.day], from: today, to: target).day ?? 0

        if diff == 0 {
            return "Hôm nay"
        } else if diff == 1 {
            return "Ngày mai"
        } else if diff > 1 {
            return "Còn \(diff) ngày"
        } else {
            return "Đã qua"
        }
    }

    private func loadReminders() async {
        if let items = try? await container.reminderRepository.fetchAllReminders() {
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? TimeZone(secondsFromGMT: 7 * 3600) ?? .current
            let today = cal.startOfDay(for: Date())
            self.reminders = items.sorted {
                nextOccurrenceDate(for: $0, today: today, calendar: cal) < nextOccurrenceDate(for: $1, today: today, calendar: cal)
            }
        }
    }

    private func checkAndCreate() {
        Task {
            do {
                let canAdd = try await container.evaluateFeatureGateUseCase.canAddReminder()
                if canAdd {
                    isShowingCreateReminder = true
                } else {
                    isShowingPaywall = true
                }
            } catch {
                // Fail closed: a gate error must not open the create form.
                isShowingPaywall = true
            }
        }
    }

    private func saveReminder(_ reminder: ReminderEvent) {
        Task {
            do {
                try await container.scheduleReminderUseCase.execute(save: reminder)
            } catch {
                // Surface save failures instead of silently dropping the reminder.
            }
            await loadReminders()
            if let items = try? await container.reminderRepository.fetchAllReminders() {
                try? await container.notificationEngine.pruneAndSchedule(reminders: items)
            }
        }
    }

    private func deleteReminder(_ reminder: ReminderEvent) {
        Task {
            try? await container.reminderRepository.deleteReminder(by: reminder.id)
            await loadReminders()
            // Prune so deleted events do not keep firing from pending requests.
            if let items = try? await container.reminderRepository.fetchAllReminders() {
                try? await container.notificationEngine.pruneAndSchedule(reminders: items)
            }
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
                    // Ceremonial Header
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
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

                    Divider().background(Color.vnBorderSubtle)

                    // Prayer Scroll
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
                        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.medium))
                        .overlay(
                            RoundedRectangle(cornerRadius: VNCornerRadius.medium)
                                .stroke(Color.vnBorderSubtle, lineWidth: VNBorderWidth.hairline)
                        )
                    }
                }
                .padding(VNSpacing.lg)
            }
            .background(Color.vnBackgroundPrimary.ignoresSafeArea())
            .navigationTitle("Văn Khấn Gia Tiên")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.vnAccentHeritageRed)
                }
            }
        }
    }
}
