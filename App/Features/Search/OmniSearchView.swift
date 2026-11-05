import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem
import VNCalendarLunar

public struct OmniSearchView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AppContainer.self) private var container
    @ScaledMetric(relativeTo: .callout) private var iconBox: CGFloat = VNSize.iconButton
    @State private var viewModel: OmniSearchViewModel?
    @FocusState private var isSearchFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    private var activeViewModel: OmniSearchViewModel {
        if let existing = viewModel { return existing }
        return OmniSearchViewModel(
            naturalSearchUseCase: container.naturalSearchUseCase,
            evaluateFeatureGateUseCase: container.evaluateFeatureGateUseCase
        )
    }

    public var body: some View {
        @Bindable var vm = activeViewModel
        NavigationStack {
            ScrollView {
                VStack(spacing: VNSpacing.xl) {
                    searchField(vm: vm)

                    ZStack {
                        if let parsed = vm.parsedDate {
                            parsedDateCard(parsed, vm: vm)
                                .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
                        }
                    }
                    .animation(reduceMotion ? nil : .smooth(duration: 0.3), value: vm.parsedDate?.label)

                    if !vm.searchResults.isEmpty {
                        resultsList(vm: vm)
                    } else if !vm.searchText.isEmpty && vm.parsedDate == nil {
                        Text(String(format: String(localized: "search.no_results"), vm.searchText))
                            .font(.vnFootnote)
                            .foregroundColor(.vnTextSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, VNSpacing.screenMargin)
                .padding(.top, VNSpacing.xl)
                .padding(.bottom, VNSpacing.xxl)
            }
            .background(Color.vnBackgroundPrimary.ignoresSafeArea())
            .vnNavBar(title: String(localized: "search.view_title")) {
                VNDismissButton { router.dismissModals() }
            }
            .task {
                if viewModel == nil {
                    viewModel = activeViewModel
                }
            }
        }
    }

    // MARK: - Search Field
    @ViewBuilder
    private func searchField(vm: OmniSearchViewModel) -> some View {
        @Bindable var boundVM = vm
        VStack(spacing: 0) {
            HStack(spacing: VNSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.subheadline)
                    .foregroundColor(isSearchFocused ? .vnAccentHeritageRed : .vnTextTertiary)
                    .accessibilityHidden(true)

                TextField("", text: $boundVM.searchText, prompt: Text("search.field_prompt"))
                    .font(.subheadline)
                    .foregroundColor(.vnTextPrimary)
                    .focused($isSearchFocused)
                    .submitLabel(.search)

                if !vm.searchText.isEmpty {
                    Button {
                        vm.searchText = ""
                        vm.performSearch(query: "")
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.vnTextTertiary)
                    }
                    .frame(minWidth: VNSize.minTapTarget, minHeight: VNSize.minTapTarget)
                    .contentShape(Rectangle())
                    .accessibilityLabel("search.clear_accessibility")
                }
            }
            .padding(.horizontal, VNSpacing.md)
            .padding(.vertical, VNSpacing.sm)
            .frame(minHeight: VNSize.minTapTarget)
            .background(Color.vnSurfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))

            Rectangle()
                .fill(isSearchFocused ? Color.vnAccentHeritageRed : Color.vnBorderSubtle)
                .frame(height: isSearchFocused ? VNBorderWidth.active : VNBorderWidth.regular)
                .animation(reduceMotion ? nil : .snappy(duration: 0.25), value: isSearchFocused)
        }
        .onChange(of: vm.searchText) { _, newValue in
            vm.performSearch(query: newValue)
        }
    }

    // MARK: - Deterministic Date Parser Result
    private func parsedDateCard(_ parsed: ParsedDateResult, vm: OmniSearchViewModel) -> some View {
        folioCard {
            HStack(alignment: .top, spacing: VNSpacing.md) {
                Image(systemName: "sparkles")
                    .font(.callout.weight(.medium))
                    .foregroundColor(.vnAccentGoldText)
                    .frame(width: iconBox, height: iconBox)
                    .accessibilityHidden(true)
                    .background(Color.vnAccentImperialGold.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous)
                            .stroke(Color.vnAccentImperialGold.opacity(0.22), lineWidth: VNBorderWidth.regular)
                    )

                VStack(alignment: .leading, spacing: VNSpacing.xs) {
                    HStack(spacing: VNSpacing.sm) {
                        Text("search.quick_parser_badge")
                            .font(.caption2.weight(.medium))
                            .tracking(0.7)
                            .foregroundColor(.vnOnGoldContainer)
                            .padding(.horizontal, VNSpacing.sm)
                            .padding(.vertical, VNSpacing.xs)
                            .background(Color.vnGoldContainer.opacity(0.5))
                            .clipShape(Capsule())
                    }

                    Text(parsed.label)
                        .font(.callout.weight(.semibold))
                        .foregroundColor(.vnTextPrimary)
                        .minimumScaleFactor(0.8)

                    if let conv = vm.resolvedConvertedDateText {
                        Text(conv)
                            .font(.footnote)
                            .foregroundColor(.vnAccentHeritageRed)
                    }

                    createReminderButton(vm: vm)
                }
            }
            .padding(VNSpacing.cardPadding)
        }
    }

    /// Dismisses Search, then gates and presents the form (or Paywall) from the same router.
    private func createReminderButton(vm: OmniSearchViewModel) -> some View {
        Button {
            guard !vm.isCheckingGate else { return }
            let initialDate = vm.resolvedSolarDate
            router.dismissModals()
            Task {
                await Task.yield()
                switch await vm.createReminderGate() {
                case .allowed: router.present(sheet: .reminderForm(editing: nil, initialDate: initialDate))
                case .requiresPro: router.present(sheet: .paywall)
                }
            }
        } label: {
            Label("search.create_reminder", systemImage: "plus.circle.fill")
                .font(.footnote.weight(.semibold))
                .foregroundColor(.vnAccentDeepPrimary)
                .frame(minHeight: VNSize.minTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.vnPress(scale: 0.98))
        .disabled(vm.isCheckingGate)
    }

    // MARK: - Matched Events & Holidays
    private func resultsList(vm: OmniSearchViewModel) -> some View {
        VStack(spacing: VNSpacing.sm) {
            Text("search.results_section_header")
                .font(.caption2.weight(.medium))
                .tracking(0.7)
                .foregroundColor(.vnOnGoldContainer)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, VNSpacing.xs)
                .accessibilityAddTraits(.isHeader)

            ForEach(vm.searchResults) { item in
                resultRow(item)
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : .smooth(duration: 0.25), value: vm.searchResults.map(\.id))
    }

    @ViewBuilder
    private func resultRow(_ item: SearchResultItem) -> some View {
        switch item {
        case .reminder(let r):
            resultCard(
                icon: "flame.fill",
                tint: .vnAccentHeritageRed,
                title: r.title,
                detail: String(format: String(localized: "search.result_detail"), r.day, r.month, r.dateType == .lunar ? String(localized: "search.date_type_lunar") : String(localized: "search.date_type_solar"), r.category.title)
            )
        case .holiday(let h):
            resultCard(icon: "leaf.fill", tint: .vnAccentGoldText, title: h.title, detail: h.summary)
        }
    }

    private func resultCard(icon: String, tint: Color, title: String, detail: String) -> some View {
        folioCard {
            HStack(alignment: .top, spacing: VNSpacing.md) {
                Image(systemName: icon)
                    .font(.callout.weight(.medium))
                    .foregroundColor(tint)
                    .frame(width: iconBox, height: iconBox)
                    .accessibilityHidden(true)
                    .background(tint.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous)
                            .stroke(tint.opacity(0.22), lineWidth: VNBorderWidth.regular)
                    )

                VStack(alignment: .leading, spacing: VNSpacing.xs) {
                    Text(title)
                        .font(.callout.weight(.semibold))
                        .foregroundColor(.vnTextPrimary)
                        .minimumScaleFactor(0.8)

                    Text(detail)
                        .font(.footnote)
                        .foregroundColor(.vnTextSecondary)
                        .lineLimit(2)
                }
            }
            .padding(VNSpacing.cardPadding)
            .accessibilityElement(children: .combine)
        }
    }

    private func folioCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.vnSurfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous)
                    .stroke(Color.vnAccentImperialGold.opacity(0.28), lineWidth: VNBorderWidth.regular)
            )
            .shadow(color: VNShadow.folio.color, radius: VNShadow.folio.radius, x: VNShadow.folio.x, y: VNShadow.folio.y)
    }
}
