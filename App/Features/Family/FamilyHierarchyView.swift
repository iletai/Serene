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
    @Environment(AppRouter.self) private var router
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    @State private var viewModel: FamilyHierarchyViewModel?
    @State private var isCheckingGate = false
    @ScaledMetric(relativeTo: .footnote) private var railBadgeSize: CGFloat = 32
    @ScaledMetric(relativeTo: .footnote) private var memberBadgeSize: CGFloat = VNSize.iconButton

    public init() {}

    private var activeViewModel: FamilyHierarchyViewModel {
        if let existing = viewModel { return existing }
        return FamilyHierarchyViewModel(
            reminderRepository: container.reminderRepository,
            subscriptionManager: container.subscriptionManager,
            evaluateFeatureGateUseCase: container.evaluateFeatureGateUseCase
        )
    }

    public var body: some View {
        let vm = activeViewModel
        VStack(spacing: 0) {
            topBar(vm: vm)

            if vm.isGenealogyUnlocked {
                genealogyContent(vm: vm)
            } else {
                ScrollView { lockedContent }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.vnBackgroundPrimary.ignoresSafeArea())
        .task {
            if viewModel == nil {
                viewModel = activeViewModel
            }
            await viewModel?.load()
            await viewModel?.observe()
        }
    }

    private func createReminder(vm: FamilyHierarchyViewModel) {
        // Double tap guard: the gate is async, so a second tap must not run it again.
        guard !isCheckingGate else { return }
        isCheckingGate = true
        VNHaptics.impact(enabled: hapticFeedbackEnabled)
        Task {
            defer { isCheckingGate = false }
            switch await vm.createReminderGate() {
            case .allowed: router.present(sheet: .reminderForm(editing: nil, initialDate: nil))
            case .requiresPro: router.present(sheet: .paywall)
            }
        }
    }

    // MARK: - Top Bar
    @ViewBuilder
    private func topBar(vm: FamilyHierarchyViewModel) -> some View {
        HStack(spacing: VNSpacing.sm) {
            VStack(alignment: .leading, spacing: VNSpacing.space2) {
                Text("Gia Phả")
                    .font(.system(.headline, design: .serif).weight(.bold))
                    .foregroundColor(Color.vnAccentDeepPrimary)
                Text("Kính tổ phụng gia")
                    .font(.caption2)
                    .foregroundColor(.vnTextSecondary)
            }

            Spacer()

            Button {
                createReminder(vm: vm)
            } label: {
                Image(systemName: "plus")
                    .font(.body.weight(.bold))
                    .foregroundColor(.vnOnAccent)
                    .frame(width: VNSize.minTapTarget, height: VNSize.minTapTarget)
                    .background(Color.vnAccentHeritageRed, in: RoundedRectangle(cornerRadius: VNCornerRadius.card))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Thêm tiền nhân")
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .padding(.horizontal, VNSpacing.screenMargin)
        .padding(.vertical, VNSpacing.sm)
        .vnTopBarBackground()
        .overlay(alignment: .bottom) {
            Color.vnBorderSubtle.frame(height: VNBorderWidth.hairline)
        }
    }

    // MARK: - Genealogy Content (Pro)
    private func genealogyContent(vm: FamilyHierarchyViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VNSpacing.sectionGap) {
                headerSection(vm: vm)

                if vm.reminders.isEmpty {
                    emptyStateSection(vm: vm)
                } else {
                    genealogyTreeSection(vm: vm)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, VNSpacing.sectionGap)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Locked State (free tier)
    private var lockedContent: some View {
        VStack(spacing: VNSpacing.md) {
            Image(systemName: "lock.fill")
                .font(.largeTitle.weight(.semibold))
                .foregroundColor(.vnAccentGoldText)
                .padding(.top, VNSpacing.xxl)
                .accessibilityHidden(true)

            Text("Chế Độ Gia Phả Pro")
                .font(.system(.title2, design: .serif).weight(.semibold))
                .foregroundColor(.vnTextPrimary)
                .multilineTextAlignment(.center)

            Text("Mở khoá cây gia phả nhiều thế hệ, vai vế tổ tiên và sơ đồ phụng thờ dòng tộc.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.vnTextSecondary)
                .lineSpacing(VNSpacing.xs)
                .padding(.horizontal, VNSpacing.screenMargin)

            VNButton("Nâng Cấp Pro", icon: "crown.fill", variant: .primary, size: .medium) {
                router.present(sheet: .paywall)
            }
            .padding(.top, VNSpacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, VNSpacing.screenMargin)
        .padding(.bottom, VNSpacing.xxl)
    }

    // MARK: - Header Section
    @ViewBuilder
    private func headerSection(vm: FamilyHierarchyViewModel) -> some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            HStack {
                Text("KÍNH TỔ PHỤNG GIA")
                    .font(.caption2.weight(.bold))
                    .tracking(0.66)
                    .foregroundColor(.vnAccentGoldText)

                Spacer()

                if !vm.reminders.isEmpty {
                    Text("\(vm.reminders.count) tiền nhân")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.vnOnGoldContainer)
                        .padding(.horizontal, VNSpacing.sm)
                        .padding(.vertical, VNSpacing.xs)
                        .background(Color.vnGoldContainer)
                        .clipShape(Capsule())
                }
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .padding(.horizontal, VNSpacing.screenMargin)
        .padding(.top, VNSpacing.md)
    }

    // MARK: - Empty State
    @ViewBuilder
    private func emptyStateSection(vm: FamilyHierarchyViewModel) -> some View {
        VStack(spacing: VNSpacing.md) {
            Image(systemName: "person.3.sequence.fill")
                .font(.largeTitle)
                .foregroundColor(.vnAccentGoldText)
                .padding(.top, VNSpacing.xl)
                .accessibilityHidden(true)

            Text("Khởi Tạo Cây Gia Phả")
                .font(.system(.title2, design: .serif).weight(.semibold))
                .foregroundColor(.vnTextPrimary)
                .multilineTextAlignment(.center)

            Text("Nhập thông tin người thân và vai vế gia đình để tự động xây dựng sơ đồ phụng thờ & kỵ giỗ dòng tộc trang nghiêm.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.vnTextSecondary)
                .lineSpacing(VNSpacing.xs)

            VNButton("Thêm Tiền Nhân Gia Tộc", icon: "plus", variant: .primary, size: .medium) {
                createReminder(vm: vm)
            }
            .padding(.top, VNSpacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, VNSpacing.cardPadding)
        .padding(.vertical, VNSpacing.xxl)
        .background(Color.vnBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.card)
                .stroke(Color.vnAccentImperialGold.opacity(0.28), lineWidth: VNBorderWidth.regular)
        )
        .shadow(color: VNShadow.folio.color, radius: VNShadow.folio.radius, x: VNShadow.folio.x, y: VNShadow.folio.y)
        .padding(.horizontal, VNSpacing.screenMargin)
    }

    // MARK: - Genealogy Tree Section
    @ViewBuilder
    private func genealogyTreeSection(vm: FamilyHierarchyViewModel) -> some View {
        VStack(alignment: .leading, spacing: VNSpacing.sectionGap) {
            ForEach(vm.groupedGenerations) { group in
                generationBand(group)
            }
        }
    }

    // MARK: - Generation Band
    @ViewBuilder
    private func generationBand(_ group: FamilyMemberGroup) -> some View {
        HStack(alignment: .top, spacing: VNSpacing.md) {
            generationRail(rank: group.generationRank)

            VStack(alignment: .leading, spacing: VNSpacing.sm) {
                HStack(spacing: VNSpacing.sm) {
                    Text(group.generationRank)
                        .font(.caption2.weight(.bold))
                        .tracking(0.66)
                        .foregroundColor(.vnAccentGoldText)

                    Text(group.generationTitle)
                        .font(.system(.headline, design: .serif).weight(.bold))
                        .foregroundColor(.vnTextPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    Spacer()

                    Text("\(group.members.count) vị")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.vnTextSecondary)
                }
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)

                ForEach(group.members) { member in
                    memberBranch(member)
                }
            }
        }
        .padding(.horizontal, VNSpacing.screenMargin)
    }

    private func generationRail(rank: String) -> some View {
        VStack(spacing: VNSpacing.sm) {
            Text(rankLetter(from: rank))
                .font(.system(.footnote, design: .serif).weight(.bold))
                .foregroundColor(.vnAccentHeritageRed)
                .frame(width: railBadgeSize, height: railBadgeSize)
                .background(Color.vnAccentRedSurface)
                .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.micro))
                .overlay(
                    RoundedRectangle(cornerRadius: VNCornerRadius.micro)
                        .stroke(Color.vnAccentHeritageRed.opacity(0.4), lineWidth: VNBorderWidth.hairline)
                )
                .accessibilityHidden(true)

            Rectangle()
                .fill(Color.vnAccentImperialGold.opacity(0.45))
                .frame(width: VNBorderWidth.regular)
                .frame(maxHeight: .infinity)
                .accessibilityHidden(true)
        }
        .frame(width: railBadgeSize)
    }

    @ViewBuilder
    private func memberBranch(_ member: ReminderEvent) -> some View {
        HStack(alignment: .top, spacing: VNSpacing.sm) {
            Rectangle()
                .fill(Color.vnAccentImperialGold.opacity(0.45))
                .frame(width: VNSpacing.sm, height: VNBorderWidth.regular)
                .padding(.top, VNSpacing.space32)
                .accessibilityHidden(true)

            Button {
                VNHaptics.impact(enabled: hapticFeedbackEnabled)
                router.present(sheet: .reminderForm(editing: member, initialDate: nil))
            } label: {
                memberCard(member: member)
                    .frame(minHeight: VNSize.minTapTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(VNCellPressButtonStyle(pressedScale: 0.98))
            .accessibilityElement(children: .combine)
            .accessibilityLabel([member.title, member.relationship ?? ""].filter { !$0.isEmpty }.joined(separator: ", "))
            .accessibilityValue("\(anniversaryText(member)), \(statusText(member))")
            .accessibilityHint("Chỉnh sửa chi tiết tiền nhân")
        }
    }

    private func isWorshipped(_ member: ReminderEvent) -> Bool {
        member.category == .deathAnniversary || member.category == .ancestral
    }

    private func anniversaryText(_ member: ReminderEvent) -> String {
        "Giỗ \(member.day)/\(member.month) \(member.dateType == .lunar ? "ÂL" : "Dương")"
    }

    private func statusText(_ member: ReminderEvent) -> String {
        isWorshipped(member) ? "Đã thờ" : "Còn sống"
    }

    private func rankLetter(from rank: String) -> String {
        let last = rank.split(separator: " ").last.map(String.init) ?? String(rank.prefix(1))
        return String(last.prefix(1))
    }

    // MARK: - Member Card
    private func memberCard(member: ReminderEvent) -> some View {
        let isDeath = isWorshipped(member)
        return HStack(spacing: VNSpacing.md) {
            if member.category == .deathAnniversary {
                VNSealBadge.gio(size: .small)
            } else {
                Text("TỘC")
                    .font(.system(.footnote, design: .serif).weight(.bold))
                    .foregroundColor(Color.vnAccentGoldText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(width: memberBadgeSize, height: memberBadgeSize)
                    .background(Color.vnBackgroundTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
            }

            VStack(alignment: .leading, spacing: VNSpacing.space2) {
                Text(member.title)
                    .font(.system(.subheadline, design: .serif).weight(.semibold))
                    .foregroundColor(.vnTextPrimary)
                    .minimumScaleFactor(0.8)

                HStack(spacing: VNSpacing.xs) {
                    if let rel = member.relationship, !rel.isEmpty {
                        Text(rel)
                            .font(.caption)
                            .foregroundColor(.vnTextSecondary)
                    }

                    Text("• \(anniversaryText(member))")
                        .font(.caption)
                        .foregroundColor(.vnTextSecondary)
                }

                if let y = member.year {
                    Text("Năm \(y)")
                        .font(.caption)
                        .foregroundColor(.vnTextSecondary)
                }
            }

            Spacer()

            Text(statusText(member))
                .font(.vnCaption2)
                .fontWeight(.semibold)
                .foregroundColor(isDeath ? .vnOnAccent : .vnTextSecondary)
                .padding(.horizontal, VNSpacing.sm)
                .padding(.vertical, VNSpacing.space2)
                .background(isDeath ? Color.vnAccentDeepPrimary : Color.vnBackgroundTertiary)
                .clipShape(Capsule())

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundColor(.vnTextTertiary)
                .accessibilityHidden(true)
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .padding(VNSpacing.cardPadding)
        .background(Color.vnBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.card)
                .stroke(Color.vnAccentImperialGold.opacity(0.28), lineWidth: VNBorderWidth.regular)
        )
        .shadow(color: VNShadow.folio.color, radius: VNShadow.folio.radius, x: VNShadow.folio.x, y: VNShadow.folio.y)
    }
}
