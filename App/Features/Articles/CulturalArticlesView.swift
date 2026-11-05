import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem

public struct CulturalArticlesView: View {
    @Environment(AppContainer.self) private var container
    @Environment(AppRouter.self) private var router
    @State private var viewModel: CulturalArticlesViewModel?
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    // Clears the floating tab pill, which grows with Dynamic Type.
    @ScaledMetric(relativeTo: .caption2) private var tabBarClearance: CGFloat = VNSpacing.hero + VNSpacing.sectionGap

    private let categories = ["Tất cả", "Cúng Giỗ", "Lễ Tiết & Tết", "Rằm & Mùng 1"]

    /// Category ids stay Vietnamese (the view model filters on them); only the chip label is localized.
    private func categoryTitle(_ id: String) -> String {
        switch id {
        case "Cúng Giỗ": return String(localized: "articles.category_gio")
        case "Lễ Tiết & Tết": return String(localized: "articles.category_les_tet")
        case "Rằm & Mùng 1": return String(localized: "articles.category_ram_new_moon")
        default: return String(localized: "articles.category_all")
        }
    }

    public init() {}

    private var activeViewModel: CulturalArticlesViewModel {
        if let existing = viewModel { return existing }
        return CulturalArticlesViewModel(holidayRepository: container.holidayRepository)
    }

    public var body: some View {
        let vm = activeViewModel
        VStack(spacing: 0) {
            topBar(vm: vm)

            ScrollView {
                VStack(alignment: .leading, spacing: VNSpacing.sectionGap) {
                    headerSection
                    searchBarSection(vm: vm)
                    categoryChipsSection(vm: vm)

                    if vm.filteredHolidays.isEmpty {
                        emptyStateSection(vm: vm)
                    } else {
                        LazyVStack(spacing: VNSpacing.md) {
                            ForEach(vm.filteredHolidays) { holiday in
                                Button {
                                    VNHaptics.impact(.light, enabled: hapticFeedbackEnabled)
                                    router.present(sheet: .holiday(holiday))
                                } label: {
                                    articleCard(holiday: holiday)
                                }
                                .buttonStyle(VNCellPressButtonStyle(pressedScale: 0.98))
                                .accessibilityElement(children: .combine)
                                .accessibilityHint("articles.a11y_view_detail")
                            }
                        }
                        .padding(.horizontal, VNSpacing.screenMargin)
                    }
                }
                .padding(.bottom, tabBarClearance)
            }
        }
        .background(Color.vnBackgroundPrimary.ignoresSafeArea())
        .task {
            if viewModel == nil {
                viewModel = activeViewModel
            }
            await viewModel?.load()
        }
    }

    // MARK: - Top Bar
    @ViewBuilder
    private func topBar(vm: CulturalArticlesViewModel) -> some View {
        HStack(spacing: VNSpacing.sm) {
            VStack(alignment: .leading, spacing: VNSpacing.space2) {
                Text("articles.title")
                    .font(.vnHeadline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.vnAccentDeepPrimary)
                Text("articles.subtitle")
                    .font(.vnCaption2)
                    .foregroundColor(.vnTextSecondary)
            }
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)

            Spacer()

            Button {
                VNHaptics.impact(.light, enabled: hapticFeedbackEnabled)
                vm.resetFilters()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.vnTextSecondary)
                    .frame(width: VNSize.minTapTarget, height: VNSize.minTapTarget)
                    .background(Color.vnBackgroundTertiary, in: RoundedRectangle(cornerRadius: VNCornerRadius.card))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("articles.a11y_reset_search")
        }
        .padding(.horizontal, VNSpacing.screenMargin)
        .padding(.vertical, VNSpacing.sm)
        .vnTopBarBackground()
        .overlay(alignment: .bottom) {
            Color.vnBorderSubtle.frame(height: VNBorderWidth.hairline)
        }
    }

    // MARK: - Header Section
    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            HStack(spacing: VNSpacing.xs) {
                Image(systemName: "book.pages.fill")
                    .font(.vnCaption2)
                    .foregroundColor(.vnAccentGoldText)
                    .accessibilityHidden(true)
                Text("articles.eyebrow")
                    .font(.vnCaption2)
                    .fontWeight(.bold)
                    .tracking(1.0)
                    .foregroundColor(.vnAccentGoldText)
            }
            .padding(.horizontal, VNSpacing.sm)
            .padding(.vertical, VNSpacing.xs)
            .background(Color.vnAccentGoldSurface)
            .clipShape(Capsule())

            Text("articles.header_title")
                .font(.vnTitleHero)
                .foregroundColor(.vnTextPrimary)

            Text("articles.header_desc")
                .font(.system(.footnote, design: .serif))
                .italic()
                .foregroundColor(.vnTextSecondary)
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .padding(.horizontal, VNSpacing.screenMargin)
        .padding(.top, VNSpacing.md)
    }

    // MARK: - Search Bar
    @ViewBuilder
    private func searchBarSection(vm: CulturalArticlesViewModel) -> some View {
        @Bindable var boundVM = vm
        HStack(spacing: VNSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.vnTextSecondary)
                .font(.vnFootnote)
                .accessibilityHidden(true)

            TextField("articles.search_placeholder", text: $boundVM.searchQuery)
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
                .accessibilityLabel("articles.a11y_clear_search")
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
    }

    // MARK: - Category Filter Chips
    @ViewBuilder
    private func categoryChipsSection(vm: CulturalArticlesViewModel) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: VNSpacing.sm) {
                ForEach(categories, id: \.self) { cat in
                    let isSelected = vm.selectedCategory == cat
                    Button {
                        VNHaptics.impact(.light, enabled: hapticFeedbackEnabled)
                        withAnimation(.easeInOut(duration: 0.15)) {
                            vm.selectedCategory = cat
                        }
                    } label: {
                        Text(categoryTitle(cat))
                            .font(.vnCaption1)
                            .fontWeight(isSelected ? .semibold : .regular)
                            .frame(minHeight: VNSize.minTapTarget)
                            .padding(.horizontal, VNSpacing.lg)
                            .background(isSelected ? Color.vnAccentRedSurface : Color.clear)
                            .foregroundColor(isSelected ? Color.vnAccentDeepPrimary : .vnTextSecondary)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(
                                        isSelected ? Color.vnAccentHeritageRed.opacity(0.25) : Color.vnBorderSubtle,
                                        lineWidth: isSelected ? VNBorderWidth.regular : VNBorderWidth.hairline
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .contentShape(Capsule())
                    .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
                }
            }
            .padding(.horizontal, VNSpacing.screenMargin)
            .padding(.vertical, VNSpacing.space2)
        }
    }

    // MARK: - Empty State
    @ViewBuilder
    private func emptyStateSection(vm: CulturalArticlesViewModel) -> some View {
        VStack(spacing: VNSpacing.md) {
            Text("articles.empty_title")
                .font(.system(.title2, design: .serif).weight(.semibold))
                .foregroundColor(.vnTextPrimary)

            Text("articles.empty_body")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.vnTextSecondary)
                .padding(.horizontal, VNSpacing.screenMargin)

            VNButton(String(localized: "articles.empty_cta"), variant: .primary, size: .medium) {
                vm.resetFilters()
            }
            .padding(.top, VNSpacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, VNSpacing.sectionGap)
        .padding(.horizontal, VNSpacing.screenMargin)
    }

    // MARK: - Article Card
    private func articleCard(holiday: Holiday) -> some View {
        let isLunar = holiday.calendarType == .lunar

        return VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: VNSpacing.sm) {
                HStack(alignment: .top) {
                    Text(holiday.title)
                        .font(.system(.headline, design: .serif))
                        .foregroundColor(.vnTextPrimary)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Text(String(
                        format: isLunar ? String(localized: "articles.date_lunar") : String(localized: "articles.date_solar"),
                        holiday.day,
                        holiday.month
                    ))
                        .font(.vnCaption2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.vnAccentDeepPrimary)
                        .padding(.horizontal, VNSpacing.sm)
                        .padding(.vertical, VNSpacing.xs)
                        .background(Color.vnAccentRedSurface)
                        .clipShape(Capsule())
                }

                Text(holiday.summary)
                    .font(.caption)
                    .foregroundColor(.vnTextSecondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                HStack(spacing: VNSpacing.xs) {
                    if holiday.rituals != nil {
                        Label("articles.has_prayer", systemImage: "book.pages.fill")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(Color.vnAccentDeepPrimary)
                    } else {
                        Text(isLunar ? String(localized: "articles.calendar_lunar") : String(localized: "articles.calendar_solar"))
                            .font(.caption2)
                            .foregroundColor(.vnTextSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.vnTextTertiary)
                        .accessibilityHidden(true)
                }
                .padding(.top, VNSpacing.space2)
            }
            .padding(VNSpacing.cardPadding)
        }
        .background(Color.vnBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.card)
                .stroke(Color.vnAccentImperialGold.opacity(0.28), lineWidth: VNBorderWidth.regular)
        )
        .shadow(color: VNShadow.folio.color, radius: VNShadow.folio.radius, x: VNShadow.folio.x, y: VNShadow.folio.y)
    }
}

public struct HolidayDetailSheet: View {
    public let holiday: Holiday
    @Environment(AppRouter.self) private var router
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: VNSpacing.sectionGap) {
                    // Header
                    VStack(alignment: .leading, spacing: VNSpacing.xs) {
                        let calendarName = holiday.calendarType == .lunar ? String(localized: "articles.calendar_lunar_title") : String(localized: "articles.calendar_solar_title")
                        Text(String(format: String(localized: "articles.detail_date"), holiday.day, holiday.month, calendarName))
                            .font(.subheadline.bold())
                            .foregroundColor(.vnAccentHeritageRed)

                        Text(holiday.title)
                            .font(.vnTitleHero)
                            .foregroundColor(.vnTextPrimary)
                            .minimumScaleFactor(0.8)
                            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                    }

                    VNRowDivider()

                    // Summary / Meaning
                    VStack(alignment: .leading, spacing: VNSpacing.xs) {
                        Text("articles.section_meaning")
                            .font(.caption2.bold())
                            .foregroundColor(.vnTextSecondary)
                            .tracking(0.8)

                        Text(holiday.summary)
                            .font(.system(.subheadline, design: .serif))
                            .foregroundColor(.vnTextPrimary)
                            .lineSpacing(VNSpacing.xs)
                    }

                    if let customs = holiday.customs {
                        VStack(alignment: .leading, spacing: VNSpacing.xs) {
                            Text("articles.section_customs")
                                .font(.caption2.bold())
                                .foregroundColor(.vnStatusSuccess)
                                .tracking(0.8)

                            Text(customs)
                                .font(.subheadline)
                                .foregroundColor(.vnTextPrimary)
                                .lineSpacing(VNSpacing.xs)
                                .padding(VNSpacing.cardPadding)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.vnBackgroundSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.small))
                                .overlay(
                                    RoundedRectangle(cornerRadius: VNCornerRadius.small)
                                        .stroke(Color.vnStatusSuccess.opacity(0.3), lineWidth: VNBorderWidth.hairlineThin)
                                )
                        }
                    }

                    if let taboos = holiday.taboos {
                        VStack(alignment: .leading, spacing: VNSpacing.xs) {
                            Text("articles.section_taboos")
                                .font(.caption2.bold())
                                .foregroundColor(.vnStatusError)
                                .tracking(0.8)

                            Text(taboos)
                                .font(.subheadline)
                                .foregroundColor(.vnTextPrimary)
                                .lineSpacing(VNSpacing.xs)
                                .padding(VNSpacing.cardPadding)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.vnBackgroundSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.small))
                                .overlay(
                                    RoundedRectangle(cornerRadius: VNCornerRadius.small)
                                        .stroke(Color.vnStatusError.opacity(0.3), lineWidth: VNBorderWidth.hairlineThin)
                                )
                        }
                    }

                    if let rituals = holiday.rituals {
                        VStack(alignment: .leading, spacing: VNSpacing.xs) {
                            HStack {
                                Text("articles.section_ritual")
                                    .font(.caption2.bold())
                                    .foregroundColor(.vnAccentGoldText)
                                    .tracking(0.8)

                                Spacer()

                                Button {
                                    #if canImport(UIKit)
                                    UIPasteboard.general.string = rituals
                                    #endif
                                    VNHaptics.impact(.success, enabled: hapticFeedbackEnabled)
                                } label: {
                                    Label("articles.action.copy", systemImage: "doc.on.doc")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundColor(.vnAccentHeritageRed)
                                        .frame(minHeight: VNSize.minTapTarget)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }

                            Text(rituals)
                                .font(.system(.subheadline, design: .serif))
                                .foregroundColor(.vnTextPrimary)
                                .lineSpacing(VNSpacing.sm)
                                .padding(VNSpacing.cardPadding)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.vnBackgroundSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
                                .overlay(
                                    RoundedRectangle(cornerRadius: VNCornerRadius.card)
                                        .stroke(Color.vnBorderSubtle, lineWidth: VNBorderWidth.hairline)
                                )
                        }
                    }
                }
                .padding(.horizontal, VNSpacing.screenMargin)
                .padding(.bottom, VNSpacing.sectionGap)
            }
            .background(Color.vnBackgroundPrimary.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    VNDismissButton(style: .text(String(localized: "action.close"))) { router.dismissModals() }
                }
            }
        }
    }
}
