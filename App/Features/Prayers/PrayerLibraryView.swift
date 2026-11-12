import SwiftUI
import VNCalendarDesignSystem
import VNCalendarDomain

public struct PrayerLibraryView: View {
    @Environment(AppContainer.self) private var container
    @State private var viewModel: PrayerLibraryViewModel?
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true

    public init() {}

    private var activeViewModel: PrayerLibraryViewModel {
        if let existing = viewModel { return existing }
        return PrayerLibraryViewModel(prayerRepository: container.prayerRepository)
    }

    public var body: some View {
        @Bindable var vm = activeViewModel
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: VNSpacing.xl) {
                    headerSection(vm: vm)
                    searchBarSection(vm: vm)
                    categoryPillsSection(vm: vm)
                    prayerListSection(vm: vm)
                }
                .padding(.bottom, VNSpacing.xxl)
            }
            .background(Color.vnBackgroundPrimary.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $vm.selectedPrayer) { prayer in
                PrayerDetailView(prayer: prayer)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
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
    private func headerSection(vm: PrayerLibraryViewModel) -> some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            HStack {
                HStack(spacing: VNSpacing.xs) {
                    Image(systemName: "book.pages.fill")
                        .font(.vnCaption2)
                        .foregroundColor(.vnAccentDeepPrimary)
                        .accessibilityHidden(true)
                    Text("prayers.eyebrow")
                        .font(.vnCaption2)
                        .fontWeight(.bold)
                        .tracking(1.0)
                        .foregroundColor(.vnAccentDeepPrimary)
                }
                .padding(.horizontal, VNSpacing.sm)
                .padding(.vertical, VNSpacing.xs)
                .background(Color.vnAccentRedSurface)
                .clipShape(Capsule())

                Spacer()

                if !vm.prayers.isEmpty {
                    Text(String(format: String(localized: "prayers.count_badge"), vm.prayers.count))
                        .font(.vnCaption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.vnAccentDeepPrimary)
                        .padding(.horizontal, VNSpacing.sm)
                        .padding(.vertical, VNSpacing.xs)
                        .background(Color.vnAccentRedSurface)
                        .clipShape(Capsule())
                }
            }

            Text("prayers.header_title")
                .font(.vnTitleHero)
                .foregroundColor(.vnAccentDeepPrimary)
                .padding(.top, VNSpacing.space2)

            Text("prayers.header_desc")
                .font(.vnDisplay(.footnote))
                .italic()
                .foregroundColor(.vnTextSecondary)
        }
        .padding(.horizontal, VNSpacing.xl)
        .padding(.top, VNSpacing.md)
    }

    // MARK: - Search Bar
    @ViewBuilder
    private func searchBarSection(vm: PrayerLibraryViewModel) -> some View {
        @Bindable var boundVM = vm
        HStack(spacing: VNSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.vnTextSecondary)
                .font(.vnFootnote)
                .accessibilityHidden(true)

            TextField("prayers.search_placeholder", text: $boundVM.searchQuery)
                .font(.vnFootnote)

            if !vm.searchQuery.isEmpty {
                Button {
                    vm.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.vnTextTertiary)
                        .font(.vnFootnote)
                }
                .buttonStyle(.plain)
                .frame(minWidth: VNSize.minTapTarget, minHeight: VNSize.minTapTarget)
                .contentShape(Rectangle())
                .accessibilityLabel("prayers.a11y_clear_search")
            }
        }
        .padding(.horizontal, VNSpacing.md)
        .padding(.vertical, VNSpacing.md)
        .frame(minHeight: VNSize.minTapTarget)
        .background(Color.vnBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.card)
                .strokeBorder(Color.vnBorderSubtle, lineWidth: VNBorderWidth.hairline)
        )
        .padding(.horizontal, VNSpacing.xl)
    }

    // MARK: - Category Filter Pills
    @ViewBuilder
    private func categoryPillsSection(vm: PrayerLibraryViewModel) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: VNSpacing.sm) {
                Button {
                    triggerHaptic()
                    vm.selectedCategory = nil
                } label: {
                    Text("prayers.category_all")
                        .font(.vnDisplay(.caption, weight: .semibold))
                        .foregroundColor(vm.selectedCategory == nil ? .vnAccentDeepPrimary : .vnTextSecondary)
                        .frame(minHeight: VNSize.minTapTarget)
                        .padding(.horizontal, VNSpacing.lg)
                        .background(vm.selectedCategory == nil ? Color.vnAccentRedSurface : Color.clear)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().strokeBorder(
                                vm.selectedCategory == nil ? Color.vnAccentHeritageRed.opacity(0.25) : Color.vnBorderSubtle,
                                lineWidth: vm.selectedCategory == nil ? 1 : 0.5
                            )
                        )
                }
                .buttonStyle(.plain)
                .contentShape(Capsule())
                .accessibilityAddTraits(vm.selectedCategory == nil ? [.isSelected, .isButton] : .isButton)

                ForEach(PrayerCategory.allCases, id: \.self) { cat in
                    PrayerCategoryCard(
                        category: cat,
                        count: vm.prayers.filter { $0.category == cat }.count,
                        isSelected: vm.selectedCategory == cat,
                        action: {
                            vm.selectedCategory = (vm.selectedCategory == cat) ? nil : cat
                        }
                    )
                }
            }
            .padding(.horizontal, VNSpacing.xl)
            .padding(.vertical, VNSpacing.space2)
        }
    }

    // MARK: - Prayer List
    @ViewBuilder
    private func prayerListSection(vm: PrayerLibraryViewModel) -> some View {
        VStack(spacing: VNSpacing.sm) {
            if vm.filteredPrayers.isEmpty {
                emptyState
            } else {
                ForEach(vm.filteredPrayers) { prayer in
                    prayerRowCard(for: prayer)
                        .onTapGesture {
                            triggerHaptic()
                            vm.selectedPrayer = prayer
                        }
                        .accessibilityAddTraits(.isButton)
                        .accessibilityHint("prayers.a11y_view_hint")
                }
            }
        }
        .padding(.horizontal, VNSpacing.xl)
    }

    @ViewBuilder
    private func prayerRowCard(for prayer: Prayer) -> some View {
        HStack(spacing: VNSpacing.md) {
            Image(systemName: "flame.fill")
                .font(.callout)
                .foregroundColor(.vnAccentHeritageRed)
                .frame(width: VNSize.minTapTarget, height: VNSize.minTapTarget)
                .accessibilityHidden(true)
                .background(Color.vnAccentRedSurface)
                .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.small))

            VStack(alignment: .leading, spacing: VNSpacing.space2) {
                Text(prayer.title)
                    .font(.vnDisplay(.subheadline, weight: .semibold))
                    .foregroundColor(.vnTextPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Text(prayer.occasion)
                    .font(.caption)
                    .foregroundColor(.vnTextSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(.vnTextTertiary)
                .accessibilityHidden(true)
        }
        .padding(VNSpacing.lg)
        .background(Color.vnBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.card)
                .stroke(Color.vnAccentImperialGold.opacity(0.28), lineWidth: VNBorderWidth.regular)
        )
        .shadow(color: folioShadow.color, radius: folioShadow.radius, x: folioShadow.x, y: folioShadow.y)
        .contentShape(Rectangle())
    }

    private var folioShadow: VNShadow.ShadowConfig { VNShadow.folio }

    private var emptyState: some View {
        VStack(spacing: VNSpacing.sm) {
            Image(systemName: "book.closed")
                .font(.largeTitle)
                .foregroundColor(.vnTextTertiary)
                .accessibilityHidden(true)
                .padding(.top, VNSpacing.lg)

            Text("prayers.empty_title")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.vnTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, VNSpacing.xxl)
    }

    private func triggerHaptic() {
        VNHaptics.impact(.light, enabled: hapticFeedbackEnabled)
    }
}
