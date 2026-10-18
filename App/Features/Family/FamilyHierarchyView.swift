import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem

public struct FamilyMemberGroup: Identifiable {
    public let id: String
    public let generationTitle: String
    public let generationRank: String
    public let members: [ReminderEvent]
}

public struct FamilyHierarchyView: View {
    @State private var container = AppContainer.shared
    @State private var reminders: [ReminderEvent] = []
    @State private var isShowingCreateReminder = false
    @State private var isShowingPaywall = false
    @State private var selectedReminder: ReminderEvent?

    public init() {}

    public var groupedGenerations: [FamilyMemberGroup] {
        let gen1 = reminders.filter { $0.relationship?.contains("Cụ") == true }
        let gen1IDs = Set(gen1.map(\.id))

        let gen2 = reminders.filter { item in
            guard !gen1IDs.contains(item.id) else { return false }
            return item.relationship?.contains("Ông") == true || item.relationship?.contains("Bà") == true
        }
        let gen2IDs = Set(gen2.map(\.id))

        let gen3Keys = ["Cha", "Bố", "Mẹ", "Bác", "Chú", "Cô", "Dì"]
        let gen3 = reminders.filter { item in
            guard !gen1IDs.contains(item.id), !gen2IDs.contains(item.id) else { return false }
            guard let rel = item.relationship else { return false }
            return gen3Keys.contains(where: { rel.contains($0) })
        }
        let gen3IDs = Set(gen3.map(\.id))

        let others = reminders.filter { !gen1IDs.contains($0.id) && !gen2IDs.contains($0.id) && !gen3IDs.contains($0.id) }

        var groups: [FamilyMemberGroup] = []
        if !gen1.isEmpty {
            groups.append(FamilyMemberGroup(
                id: "gen1",
                generationTitle: "Thế Hệ Tiên Tổ",
                generationRank: "ĐỜI I",
                members: gen1
            ))
        }
        if !gen2.isEmpty {
            groups.append(FamilyMemberGroup(
                id: "gen2",
                generationTitle: "Thế Hệ Ông Bà",
                generationRank: "ĐỜI II",
                members: gen2
            ))
        }
        if !gen3.isEmpty {
            groups.append(FamilyMemberGroup(
                id: "gen3",
                generationTitle: "Thế Hệ Cha Mẹ & Cô Chú",
                generationRank: "ĐỜI III",
                members: gen3
            ))
        }
        if !others.isEmpty {
            groups.append(FamilyMemberGroup(
                id: "others",
                generationTitle: "Họ Hàng & Kỷ Niệm Khác",
                generationRank: "HẬU DUỆ",
                members: others
            ))
        }
        return groups
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                topBar

                ScrollView {
                    VStack(alignment: .leading, spacing: VNSpacing.xl) {
                        headerSection

                        if reminders.isEmpty {
                            emptyStateSection
                        } else {
                            genealogyTreeSection
                        }
                    }
                    .padding(.bottom, VNSpacing.xl)
                }
            }
            .background(Color.vnBackgroundPrimary.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $isShowingCreateReminder) {
                ReminderFormView(onSave: { newEvent in
                    saveMember(newEvent)
                })
                .presentationDetents([.fraction(0.92), .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedReminder) { item in
                ReminderFormView(existingReminder: item, onSave: { updated in
                    saveMember(updated)
                })
                .presentationDetents([.fraction(0.92), .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView()
            }
            .task {
                await loadMembers()
            }
        }
    }

    // MARK: - Top Bar (canonical translucent bar)
    @ViewBuilder
    private var topBar: some View {
        HStack(spacing: VNSpacing.sm) {
            VStack(alignment: .leading, spacing: VNSpacing.space2) {
                Text("Gia Phả")
                    .font(.system(size: 17, weight: .bold, design: .serif))
                    .foregroundColor(Color.vnAccentDeepPrimary)
                Text("Kính tổ phụng gia")
                    .font(.system(size: 11))
                    .foregroundColor(.vnTextSecondary)
            }

            Spacer()

            Button {
                checkAndAddMember()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.vnAccentHeritageRed, in: RoundedRectangle(cornerRadius: VNCornerRadius.card))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Thêm tiền nhân")
        }
        .padding(.horizontal, VNSpacing.xl)
        .padding(.vertical, VNSpacing.sm)
        .background(Color.vnBackgroundPrimary.opacity(0.9))
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Color.vnBorderSubtle.frame(height: VNBorderWidth.hairline)
        }
    }

    // MARK: - Header Section
    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            HStack {
                Text("KÍNH TỔ PHỤNG GIA")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.66)
                    .foregroundColor(.vnAccentImperialGold)

                Spacer()

                if !reminders.isEmpty {
                    Text("\(reminders.count) tiền nhân")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.vnOnGoldContainer)
                        .padding(.horizontal, VNSpacing.sm)
                        .padding(.vertical, VNSpacing.xs)
                        .background(Color.vnGoldContainer)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, VNSpacing.xl)
        .padding(.top, VNSpacing.md)
    }

    // MARK: - Empty State
    @ViewBuilder
    private var emptyStateSection: some View {
        VStack(spacing: VNSpacing.md) {
            Image(systemName: "person.3.sequence.fill")
                .font(.system(size: 48))
                .foregroundColor(.vnAccentImperialGold)
                .padding(.top, VNSpacing.xl)

            Text("Khởi Tạo Cây Gia Phả")
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundColor(.vnTextPrimary)

            Text("Nhập thông tin người thân và vai vế gia đình để tự động xây dựng sơ đồ phụng thờ & kỵ giỗ dòng tộc trang nghiêm.")
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .foregroundColor(.vnTextSecondary)
                .lineSpacing(4)
                .padding(.horizontal, VNSpacing.xl)

            VNButton("Thêm Tiền Nhân Gia Tộc", icon: "plus", variant: .primary, size: .medium, action: checkAndAddMember)
                .padding(.top, VNSpacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, VNSpacing.xl)
        .padding(.vertical, VNSpacing.xxl)
        .background(Color.vnBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.card)
                .stroke(Color.vnAccentImperialGold.opacity(0.28), lineWidth: VNBorderWidth.regular)
        )
        .shadow(color: VNShadow.folio.color, radius: VNShadow.folio.radius, x: VNShadow.folio.x, y: VNShadow.folio.y)
        .padding(.horizontal, VNSpacing.xl)
    }

    // MARK: - Genealogy Tree Section
    @ViewBuilder
    private var genealogyTreeSection: some View {
        VStack(alignment: .leading, spacing: VNSpacing.lg) {
            ForEach(groupedGenerations) { group in
                VStack(alignment: .leading, spacing: VNSpacing.sm) {
                    // Generation Tier Header
                    HStack(spacing: VNSpacing.sm) {
                        Text(group.generationRank)
                            .font(.system(size: 11, weight: .bold))
                            .tracking(0.66)
                            .foregroundColor(.vnAccentImperialGold)

                        Text(group.generationTitle)
                            .font(.system(size: 17, weight: .bold, design: .serif))
                            .foregroundColor(.vnTextPrimary)

                        Spacer()

                        Text("\(group.members.count) vị")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.vnTextSecondary)
                    }

                    // Members in Generation Tier
                    VStack(spacing: VNSpacing.xs) {
                        ForEach(group.members) { member in
                            memberCard(member: member)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedReminder = member
                                }
                                .accessibilityAddTraits(.isButton)
                                .accessibilityHint("Chỉnh sửa chi tiết tiền nhân")
                        }
                    }
                }
                .padding(.horizontal, VNSpacing.xl)
            }
        }
    }

    // MARK: - Member Card
    private func memberCard(member: ReminderEvent) -> some View {
        let isDeath = member.category == .deathAnniversary || member.category == .ancestral
        let accentColor = isDeath ? Color.vnAccentDeepPrimary : Color.vnAccentImperialGold

        return HStack(spacing: VNSpacing.md) {
            if member.category == .deathAnniversary {
                VNSealBadge.gio(size: .small)
            } else {
                Text("TỘC")
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .foregroundColor(Color.vnAccentImperialGold)
                    .frame(width: 40, height: 40)
                    .background(Color.vnBackgroundTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
            }

            VStack(alignment: .leading, spacing: VNSpacing.space2) {
                Text(member.title)
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundColor(.vnTextPrimary)

                HStack(spacing: VNSpacing.xs) {
                    if let rel = member.relationship, !rel.isEmpty {
                        Text(rel)
                            .font(.system(size: 12))
                            .foregroundColor(.vnTextSecondary)
                    }

                    Text("• Giỗ \(member.day)/\(member.month) \(member.dateType == .lunar ? "ÂL" : "Dương")")
                        .font(.system(size: 12))
                        .foregroundColor(.vnTextSecondary)
                }

                if let y = member.year {
                    Text("Năm \(y)")
                        .font(.system(size: 12))
                        .foregroundColor(.vnTextSecondary)
                }
            }

            Spacer()

            Text(member.category == .deathAnniversary || member.category == .ancestral ? "Đã thờ" : "Còn sống")
                .font(.vnCaption2)
                .fontWeight(.semibold)
                .foregroundColor(isDeath ? .white : .vnTextSecondary)
                .padding(.horizontal, VNSpacing.sm)
                .padding(.vertical, VNSpacing.space2)
                .background(isDeath ? Color.vnAccentDeepPrimary : Color.vnBackgroundTertiary)
                .clipShape(Capsule())

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.vnTextTertiary)
                .accessibilityHidden(true)
        }
        .padding(VNSpacing.xl)
        .background(Color.vnBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.card)
                .stroke(Color.vnAccentImperialGold.opacity(0.28), lineWidth: VNBorderWidth.regular)
        )
        .shadow(color: VNShadow.folio.color, radius: VNShadow.folio.radius, x: VNShadow.folio.x, y: VNShadow.folio.y)
    }

    private func loadMembers() async {
        if let items = try? await container.reminderRepository.fetchAllReminders() {
            self.reminders = items
        }
    }

    private func checkAndAddMember() {
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

    private func saveMember(_ member: ReminderEvent) {
        Task {
            do {
                try await container.scheduleReminderUseCase.execute(save: member)
            } catch {
                // Surface save failures instead of silently dropping the reminder.
            }
            await loadMembers()
            if let items = try? await container.reminderRepository.fetchAllReminders() {
                try? await container.notificationEngine.pruneAndSchedule(reminders: items)
            }
        }
    }
}
