import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem
import VNCalendarData

public struct FamilyMemberGroup: Identifiable {
    public let id: String
    public let generationTitle: String
    public let generationRank: String
    public let members: [ReminderEvent]

    /// Rail badge text: the numeral of a rank like "ĐỜI II" ("II"); works for any length (I...X+).
    public static func badgeText(fromRank rank: String) -> String {
        rank.split(separator: " ").last.map(String.init) ?? rank
    }
}

public struct FamilyHierarchyView: View {
    @Environment(AppContainer.self) private var container
    @Environment(AppRouter.self) private var router
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    @State private var viewModel: FamilyHierarchyViewModel?
    @State private var isCheckingGate = false
    @State private var pendingReminder: ReminderEvent?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
        .sheet(
            item: Binding(get: { vm.selectedMember }, set: { vm.selectedMember = $0 }),
            onDismiss: openPendingReminder
        ) { member in
            FamilyMemberProfileView(
                member: member,
                info: vm.info(for: member),
                memorialOrdinal: vm.memorialOrdinal(for: member),
                onOpenReminder: {
                    pendingReminder = member
                    vm.selectedMember = nil
                },
                onClose: { vm.selectedMember = nil }
            )
            .presentationDetents([.fraction(0.82), .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
            .presentationBackground(Color.vnBackgroundPrimary)
        }
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

    /// The reminder form lives on the router's sheet, so it opens only once the profile sheet is gone.
    private func openPendingReminder() {
        guard let member = pendingReminder else { return }
        pendingReminder = nil
        router.present(sheet: .reminderForm(editing: member, initialDate: nil))
    }

    // MARK: - Top Bar
    @ViewBuilder
    private func topBar(vm: FamilyHierarchyViewModel) -> some View {
        HStack(spacing: VNSpacing.sm) {
            VStack(alignment: .leading, spacing: VNSpacing.space2) {
                Text("family.title")
                    .font(.vnDisplay(.headline, weight: .bold))
                    .foregroundColor(Color.vnAccentDeepPrimary)
                Text("family.subtitle")
                    .font(.vnDisplay(.caption2))
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
            .accessibilityLabel("family.a11y_add")
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

            Text("family.locked_title")
                .font(.vnDisplay(.title2, weight: .semibold))
                .foregroundColor(.vnTextPrimary)
                .multilineTextAlignment(.center)

            Text("family.locked_body")
                .font(.vnDisplay(.subheadline))
                .multilineTextAlignment(.center)
                .foregroundColor(.vnTextSecondary)
                .lineSpacing(VNSpacing.xs)
                .padding(.horizontal, VNSpacing.screenMargin)

            VNButton(String(localized: "family.upgrade_cta"), icon: "crown.fill", variant: .primary, size: .medium) {
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
                Text("family.eyebrow")
                    .font(.vnDisplay(.caption2, weight: .bold))
                    .tracking(0.66)
                    .foregroundColor(.vnAccentGoldText)

                Spacer()

                if !vm.reminders.isEmpty {
                    Text(String(format: String(localized: "family.count_ancestors"), vm.reminders.count))
                        .contentTransition(.numericText())
                        .animation(reduceMotion ? nil : .snappy, value: vm.reminders.count)
                        .font(.vnDisplay(.caption2, weight: .semibold))
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

            Text("family.empty_title")
                .font(.vnDisplay(.title2, weight: .semibold))
                .foregroundColor(.vnTextPrimary)
                .multilineTextAlignment(.center)

            Text("family.empty_body")
                .font(.vnDisplay(.subheadline))
                .multilineTextAlignment(.center)
                .foregroundColor(.vnTextSecondary)
                .lineSpacing(VNSpacing.xs)

            VNButton(String(localized: "family.empty_cta"), icon: "plus", variant: .primary, size: .medium) {
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
                .stroke(Color.vnBorderSubtle, lineWidth: VNBorderWidth.regular)
        )
        .shadow(color: VNShadow.folio.color, radius: VNShadow.folio.radius, x: VNShadow.folio.x, y: VNShadow.folio.y)
        .padding(.horizontal, VNSpacing.screenMargin)
    }

    // MARK: - Genealogy Tree Section
    @ViewBuilder
    private func genealogyTreeSection(vm: FamilyHierarchyViewModel) -> some View {
        let groups = vm.groupedGenerations
        VStack(alignment: .leading, spacing: VNSpacing.md) {
            VStack(alignment: .leading, spacing: VNSpacing.space2) {
                VNGroupHeader(String(localized: "family.ring.title"))
                Text(ringHint(vm: vm))
                    .font(.vnDisplay(.footnote, weight: .medium))
                    .foregroundColor(.vnAccentGoldText)
                    .padding(.horizontal, VNSpacing.xs)
            }
            .padding(.horizontal, VNSpacing.screenMargin)

            FamilyLunarRingView(
                months: vm.ringMonths,
                currentMonth: vm.currentLunarMonth,
                nextMonth: vm.nextRingMonth,
                highlightedMonth: vm.highlightedMonth
            ) { month in
                withAnimation(reduceMotion ? VNAnimation.reduced : VNMotion.Easing.card) { vm.toggleMonth(month) }
            }
            .vnRise(index: 1)

            FamilyTreeCanvas(
                groups: groups,
                layout: FamilyTreeLayout(memberCounts: groups.map(\.members.count)),
                emphasis: { member in
                    switch vm.isHighlighted(member) {
                    case nil: .normal
                    case true?: .highlighted
                    case false?: .dimmed
                    }
                },
                info: { vm.info(for: $0) },
                focusMemberID: vm.focusMemberID,
                homeMemberID: vm.nextMemorial?.id,
                onSelect: { member in
                    VNHaptics.impact(enabled: hapticFeedbackEnabled)
                    vm.selectedMember = member
                }
            )
            .padding(.horizontal, VNSpacing.md)
            .vnRise(index: 2)

            Text("family.tree_tip")
                .font(.vnDisplay(.footnote))
                .foregroundColor(.vnTextSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, VNSpacing.screenMargin)
        }
    }

    private func ringHint(vm: FamilyHierarchyViewModel) -> String {
        guard let next = vm.nextMemorial else { return String(localized: "family.ring.hint") }
        return String(format: String(localized: "family.ring.hint_next"), next.title, vm.info(for: next).countdownText)
    }
}
