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
                                .accessibilityHint("Xem chi tiết")
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
                Text("Văn Hoá")
                    .font(.vnHeadline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.vnAccentDeepPrimary)
                Text("Văn khấn & phong tục")
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
            .accessibilityLabel("Đặt lại tìm kiếm")
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
                Text("VĂN HOÁ & LỄ TIẾT")
                    .font(.vnCaption2)
                    .fontWeight(.bold)
                    .tracking(1.0)
                    .foregroundColor(.vnAccentGoldText)
            }
            .padding(.horizontal, VNSpacing.sm)
            .padding(.vertical, VNSpacing.xs)
            .background(Color.vnAccentGoldSurface)
            .clipShape(Capsule())

            Text("Văn Khấn & Phong Tục")
                .font(.vnTitleHero)
                .foregroundColor(.vnTextPrimary)

            Text("Tri thức ngàn năm về lễ nghi, văn khấn và phong tục truyền thống Việt Nam")
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

            TextField("Tìm văn khấn, ngày lễ, phong tục tập quán...", text: $boundVM.searchQuery)
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
                        Text(cat)
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
            Text("Không Tìm Thấy Bài Viết")
                .font(.system(.title2, design: .serif).weight(.semibold))
                .foregroundColor(.vnTextPrimary)

            Text("Thử từ khoá hoặc bộ lọc khác để khám phá tri thức lễ nghi truyền thống.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.vnTextSecondary)
                .padding(.horizontal, VNSpacing.screenMargin)

            VNButton("Xem Tất Cả", variant: .primary, size: .medium) {
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

                    Text(isLunar ? "\(holiday.day)/\(holiday.month) ÂL" : "\(holiday.day)/\(holiday.month) DL")
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
                        Label("Có Bài Văn Khấn", systemImage: "book.pages.fill")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(Color.vnAccentDeepPrimary)
                    } else {
                        Text(isLunar ? "Âm lịch" : "Dương lịch")
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
                        let calendarName = holiday.calendarType == .lunar ? "Âm Lịch" : "Dương Lịch"
                        Text("Ngày \(holiday.day) Tháng \(holiday.month) \(calendarName)")
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
                        Text("Ý NGHĨA & NGUỒN GỐC")
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
                            Text("PHONG TỤC NÊN LÀM")
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
                            Text("ĐIỀU KIÊNG KỴ")
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
                                Text("BÀI VĂN KHẤN TRUYỀN THỐNG")
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
                                    Label("Sao Chép", systemImage: "doc.on.doc")
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
                    VNDismissButton(style: .text("Đóng")) { router.dismissModals() }
                }
            }
        }
    }
}
