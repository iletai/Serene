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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .footnote) private var railBadgeScaled: CGFloat = 32
    @ScaledMetric(relativeTo: .footnote) private var memberBadgeSize: CGFloat = VNSize.iconButton

    public init() {}

    /// Capped so the rail never steals card width at large Dynamic Type.
    private var railBadgeWidth: CGFloat { min(railBadgeScaled, VNSize.iconButton + VNSpacing.sm) }

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
                Text("family.title")
                    .font(.vnDisplay(.headline, weight: .bold))
                    .foregroundColor(Color.vnAccentDeepPrimary)
                Text("family.subtitle")
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
                .font(.subheadline)
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
                    .font(.caption2.weight(.bold))
                    .tracking(0.66)
                    .foregroundColor(.vnAccentGoldText)

                Spacer()

                if !vm.reminders.isEmpty {
                    Text(String(format: String(localized: "family.count_ancestors"), vm.reminders.count))
                        .contentTransition(.numericText())
                        .animation(reduceMotion ? nil : .snappy, value: vm.reminders.count)
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

            Text("family.empty_title")
                .font(.vnDisplay(.title2, weight: .semibold))
                .foregroundColor(.vnTextPrimary)
                .multilineTextAlignment(.center)

            Text("family.empty_body")
                .font(.subheadline)
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
        let reduceMotion = reduceMotion // capture: scrollTransition closure is Sendable
        return VStack(alignment: .leading, spacing: VNSpacing.sectionGap) {
            ForEach(vm.groupedGenerations) { group in
                generationBand(group, vm: vm)
                    .scrollTransition(.animated(.smooth), axis: .vertical) { content, phase in
                        content
                            .opacity(reduceMotion || phase.isIdentity ? 1 : 0.4)
                            .offset(y: reduceMotion ? 0 : phase.value * 12)
                    }
            }
        }
    }

    // MARK: - Generation Band
    @ViewBuilder
    private func generationBand(_ group: FamilyMemberGroup, vm: FamilyHierarchyViewModel) -> some View {
        HStack(alignment: .top, spacing: VNSpacing.sm) {
            generationRail(rank: group.generationRank)

            VStack(alignment: .leading, spacing: VNSpacing.sm) {
                generationHeader(group, vm: vm)

                if vm.isExpanded(group.id) {
                    VStack(alignment: .leading, spacing: VNSpacing.sm) {
                        ForEach(Array(group.members.enumerated()), id: \.element.id) { index, member in
                            memberBranch(member)
                                .vnAppear(delay: Double(min(index, 7)) * 0.05)
                        }
                    }
                    .clipped()
                    .vnTransition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(.horizontal, VNSpacing.screenMargin)
    }

    private func generationHeader(_ group: FamilyMemberGroup, vm: FamilyHierarchyViewModel) -> some View {
        let expanded = vm.isExpanded(group.id)
        return Button {
            withAnimation(reduceMotion ? VNAnimation.reduced : VNAnimation.expand) {
                vm.toggleGeneration(group.id)
            }
        } label: {
            HStack(spacing: VNSpacing.sm) {
                Text(group.generationRank)
                    .font(.caption2.weight(.bold))
                    .tracking(0.66)
                    .foregroundColor(.vnAccentGoldText)

                Text(group.generationTitle)
                    .font(.vnDisplay(.headline, weight: .bold))
                    .foregroundColor(.vnTextPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Spacer()

                Text(String(format: String(localized: "family.group_count"), group.members.count))
                    .font(.caption.weight(.medium))
                    .foregroundColor(.vnTextSecondary)
                    .contentTransition(.numericText())
                    .vnAnimation(VNAnimation.layout, value: group.members.count)

                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.vnTextTertiary)
                    .rotationEffect(.degrees(expanded ? 0 : -90))
                    .vnAnimation(VNAnimation.expand, value: expanded)
                    .accessibilityHidden(true)
            }
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .frame(minHeight: VNSize.minTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.vnPress)
        .vnSelectionFeedback(trigger: expanded)
        .accessibilityLabel("\(group.generationRank) \(group.generationTitle)")
        .accessibilityValue(expanded
            ? String(localized: "family.generation.expanded")
            : String(localized: "family.generation.collapsed"))
        .accessibilityHint(String(localized: "family.generation.toggle_hint"))
        .accessibilityAddTraits(.isHeader)
    }

    private func generationRail(rank: String) -> some View {
        VStack(spacing: VNSpacing.sm) {
            Text(FamilyMemberGroup.badgeText(fromRank: rank))
                .font(.vnDisplay(.footnote, weight: .bold))
                .foregroundColor(.vnAccentHeritageRed)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(width: railBadgeWidth, height: railBadgeWidth)
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
        .frame(width: railBadgeWidth)
    }

    @ViewBuilder
    private func memberBranch(_ member: ReminderEvent) -> some View {
        HStack(alignment: .top, spacing: VNSpacing.xs) {
            Rectangle()
                .fill(Color.vnAccentImperialGold.opacity(0.45))
                .frame(width: VNSpacing.xs, height: VNBorderWidth.regular)
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
            .accessibilityHint("family.a11y_edit_hint")
        }
    }

    private func isWorshipped(_ member: ReminderEvent) -> Bool {
        member.category == .deathAnniversary || member.category == .ancestral
    }

    private func anniversaryText(_ member: ReminderEvent) -> String {
        String(format: String(localized: "family.member_date"), member.day, member.month, member.dateType == .lunar ? String(localized: "family.abbrev_lunar") : String(localized: "family.abbrev_solar"))
    }

    private func statusText(_ member: ReminderEvent) -> String {
        isWorshipped(member) ? String(localized: "family.status_deceased") : String(localized: "family.status_living")
    }

    private func memberSubtitle(_ member: ReminderEvent) -> String {
        var parts = [anniversaryText(member)]
        if let rel = member.relationship, !rel.isEmpty { parts.insert(rel, at: 0) }
        if let y = member.year { parts.append(String(format: String(localized: "family.member_year"), String(y))) }
        return parts.joined(separator: " · ")
    }

    // MARK: - Member Card
    private func memberCard(member: ReminderEvent) -> some View {
        let isDeath = isWorshipped(member)
        return HStack(alignment: .top, spacing: VNSpacing.sm) {
            if member.category == .deathAnniversary {
                VNSealBadge.gio(size: .small)
            } else {
                Text("family.seal_toc")
                    .font(.vnDisplay(.footnote, weight: .bold))
                    .foregroundColor(Color.vnAccentGoldText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(width: memberBadgeSize, height: memberBadgeSize)
                    .background(Color.vnBackgroundTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
            }

            VStack(alignment: .leading, spacing: VNSpacing.xs) {
                Text(member.title)
                    .font(.vnDisplay(.subheadline, weight: .semibold))
                    .foregroundColor(.vnTextPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(memberSubtitle(member))
                    .font(.caption)
                    .foregroundColor(.vnTextSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(statusText(member))
                    .font(.vnCaption2)
                    .fontWeight(.semibold)
                    .foregroundColor(isDeath ? .vnOnAccent : .vnTextSecondary)
                    .padding(.horizontal, VNSpacing.sm)
                    .padding(.vertical, VNSpacing.space2)
                    .background(isDeath ? Color.vnAccentDeepPrimary : Color.vnBackgroundTertiary)
                    .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity, alignment: .leading)

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
                .stroke(Color.vnBorderSubtle, lineWidth: VNBorderWidth.regular)
        )
        .shadow(color: VNShadow.folio.color, radius: VNShadow.folio.radius, x: VNShadow.folio.x, y: VNShadow.folio.y)
    }
}
