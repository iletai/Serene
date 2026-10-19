import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem
import VNCalendarData

public struct FamilyMemberGroup: Identifiable {
    public let id: String
    public let generationTitle: String
    public let generationRank: String
    public let members: [ReminderEvent]
}

public struct FamilyHierarchyView: View {
    @Environment(AppContainer.self) private var container
    @State private var viewModel: FamilyHierarchyViewModel?
    @State private var pressedMemberID: UUID?

    public init() {}

    private var activeViewModel: FamilyHierarchyViewModel {
        if let existing = viewModel { return existing }
        return FamilyHierarchyViewModel(
            reminderRepository: container.reminderRepository,
            subscriptionManager: container.subscriptionManager,
            scheduleReminderUseCase: container.scheduleReminderUseCase,
            evaluateFeatureGateUseCase: container.evaluateFeatureGateUseCase
        )
    }

    public var body: some View {
        @Bindable var vm = activeViewModel
        NavigationStack {
            VStack(spacing: 0) {
                topBar(vm: vm)

                if vm.isGenealogyUnlocked {
                    genealogyContent(vm: vm)
                } else {
                    lockedContent(vm: vm)
                }
            }
            .background(Color.vnBackgroundPrimary.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $vm.isShowingCreateReminder) {
                ReminderFormView(onSave: { newEvent in
                    vm.saveMember(newEvent)
                })
                .presentationDetents([.fraction(0.92), .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $vm.selectedReminder) { item in
                ReminderFormView(existingReminder: item, onSave: { updated in
                    vm.saveMember(updated)
                })
                .presentationDetents([.fraction(0.92), .large])
                .presentationDragIndicator(.visible)
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

    // MARK: - Top Bar
    @ViewBuilder
    private func topBar(vm: FamilyHierarchyViewModel) -> some View {
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
                vm.checkAndCreate()
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

    // MARK: - Genealogy Content (Pro)
    private func genealogyContent(vm: FamilyHierarchyViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VNSpacing.xl) {
                headerSection(vm: vm)

                if vm.reminders.isEmpty {
                    emptyStateSection(vm: vm)
                } else {
                    genealogyTreeSection(vm: vm)
                }
            }
            .padding(.bottom, VNSpacing.xl)
        }
    }

    // MARK: - Locked State (free tier)
    private func lockedContent(vm: FamilyHierarchyViewModel) -> some View {
        @Bindable var boundVM = vm
        return VStack(spacing: VNSpacing.md) {
            Image(systemName: "lock.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundColor(.vnAccentImperialGold)
                .padding(.top, VNSpacing.xxl)

            Text("Chế Độ Gia Phả Pro")
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundColor(.vnTextPrimary)

            Text("Mở khoá cây gia phả nhiều thế hệ, vai vế tổ tiên và sơ đồ phụng thờ dòng tộc.")
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .foregroundColor(.vnTextSecondary)
                .lineSpacing(4)
                .padding(.horizontal, VNSpacing.xl)

            VNButton("Nâng Cấp Pro", icon: "crown.fill", variant: .primary, size: .medium) {
                boundVM.isShowingPaywall = true
            }
            .padding(.top, VNSpacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, VNSpacing.xl)
        .padding(.bottom, VNSpacing.xxl)
    }

    // MARK: - Header Section
    @ViewBuilder
    private func headerSection(vm: FamilyHierarchyViewModel) -> some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            HStack {
                Text("KÍNH TỔ PHỤNG GIA")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.66)
                    .foregroundColor(.vnAccentImperialGold)

                Spacer()

                if !vm.reminders.isEmpty {
                    Text("\(vm.reminders.count) tiền nhân")
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
    private func emptyStateSection(vm: FamilyHierarchyViewModel) -> some View {
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

            VNButton("Thêm Tiền Nhân Gia Tộc", icon: "plus", variant: .primary, size: .medium) {
                vm.checkAndCreate()
            }
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
    private func genealogyTreeSection(vm: FamilyHierarchyViewModel) -> some View {
        VStack(alignment: .leading, spacing: VNSpacing.xl) {
            ForEach(vm.groupedGenerations) { group in
                generationBand(group, vm: vm)
            }
        }
    }

    // MARK: - Generation Band
    @ViewBuilder
    private func generationBand(_ group: FamilyMemberGroup, vm: FamilyHierarchyViewModel) -> some View {
        HStack(alignment: .top, spacing: VNSpacing.md) {
            generationRail(rank: group.generationRank)

            VStack(alignment: .leading, spacing: VNSpacing.sm) {
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

                ForEach(group.members) { member in
                    memberBranch(member, vm: vm)
                }
            }
        }
        .padding(.horizontal, VNSpacing.xl)
    }

    private func generationRail(rank: String) -> some View {
        VStack(spacing: VNSpacing.sm) {
            Text(rankLetter(from: rank))
                .font(.system(size: 13, weight: .bold, design: .serif))
                .foregroundColor(.vnAccentHeritageRed)
                .frame(width: 32, height: 32)
                .background(Color.vnAccentRedSurface)
                .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.micro))
                .overlay(
                    RoundedRectangle(cornerRadius: VNCornerRadius.micro)
                        .stroke(Color.vnAccentHeritageRed.opacity(0.4), lineWidth: 1)
                )
                .accessibilityHidden(true)

            Rectangle()
                .fill(Color.vnAccentImperialGold.opacity(0.45))
                .frame(width: VNBorderWidth.regular)
                .frame(maxHeight: .infinity)
                .accessibilityHidden(true)
        }
        .frame(width: 32)
    }

    @ViewBuilder
    private func memberBranch(_ member: ReminderEvent, vm: FamilyHierarchyViewModel) -> some View {
        HStack(alignment: .top, spacing: VNSpacing.sm) {
            Rectangle()
                .fill(Color.vnAccentImperialGold.opacity(0.45))
                .frame(width: VNSpacing.sm, height: VNBorderWidth.regular)
                .padding(.top, 28)
                .accessibilityHidden(true)

            memberCard(member: member)
                .overlay(
                    RoundedRectangle(cornerRadius: VNCornerRadius.card)
                        .stroke(
                            Color.vnAccentHeritageRed.opacity(pressedMemberID == member.id ? 0.5 : 0),
                            lineWidth: VNBorderWidth.focus
                        )
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    pressedMemberID = member.id
                    vm.selectedReminder = member
                }
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Chỉnh sửa chi tiết tiền nhân")
        }
    }

    private func rankLetter(from rank: String) -> String {
        let last = rank.split(separator: " ").last.map(String.init) ?? String(rank.prefix(1))
        return String(last.prefix(1))
    }

    // MARK: - Member Card
    private func memberCard(member: ReminderEvent) -> some View {
        let isDeath = member.category == .deathAnniversary || member.category == .ancestral
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
}
