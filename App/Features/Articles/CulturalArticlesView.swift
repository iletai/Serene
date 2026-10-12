import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem

public struct CulturalArticlesView: View {
    @State private var container = AppContainer.shared
    @State private var holidays: [Holiday] = []
    @State private var selectedHoliday: Holiday?
    @State private var searchQuery = ""
    @State private var selectedCategory: String = "Tất cả"

    private let categories = ["Tất cả", "Cúng Giỗ", "Lễ Tiết & Tết", "Rằm & Mùng 1"]

    public init() {}

    public var filteredHolidays: [Holiday] {
        holidays.filter { holiday in
            let matchesSearch = searchQuery.isEmpty ||
                holiday.title.localizedCaseInsensitiveContains(searchQuery) ||
                holiday.summary.localizedCaseInsensitiveContains(searchQuery)

            let matchesCategory: Bool
            switch selectedCategory {
            case "Cúng Giỗ":
                matchesCategory = holiday.title.localizedCaseInsensitiveContains("Giỗ") ||
                    holiday.summary.localizedCaseInsensitiveContains("Giỗ") ||
                    (holiday.rituals?.localizedCaseInsensitiveContains("Giỗ") == true)
            case "Lễ Tiết & Tết":
                matchesCategory = holiday.title.localizedCaseInsensitiveContains("Tết") ||
                    holiday.title.localizedCaseInsensitiveContains("Tiết")
            case "Rằm & Mùng 1":
                matchesCategory = holiday.title.localizedCaseInsensitiveContains("Rằm") ||
                    holiday.title.localizedCaseInsensitiveContains("Mùng 1") ||
                    holiday.day == 1 || holiday.day == 15
            default:
                matchesCategory = true
            }

            return matchesSearch && matchesCategory
        }
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                topBar

                ScrollView {
                    VStack(alignment: .leading, spacing: VNSpacing.xl) {
                        headerSection
                        searchBarSection
                        categoryChipsSection

                        // Articles & Rituals Editorial Cards Grid
                        if filteredHolidays.isEmpty {
                            emptyStateSection
                        } else {
                            LazyVStack(spacing: VNSpacing.md) {
                                ForEach(filteredHolidays) { holiday in
                                    Button {
                                        selectedHoliday = holiday
                                    } label: {
                                        articleCard(holiday: holiday)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityHint("Xem chi tiết")
                                }
                            }
                            .padding(.horizontal, VNSpacing.xl)
                        }
                    }
                    .padding(.bottom, VNSpacing.xl)
                }
            }
            .background(Color.vnBackgroundPrimary.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $selectedHoliday) { item in
                HolidayDetailSheet(holiday: item)
            }
            .task {
                if let items = try? await container.holidayRepository.getHolidays() {
                    self.holidays = items
                }
            }
        }
    }

    // MARK: - Top Bar (canonical translucent bar)
    @ViewBuilder
    private var topBar: some View {
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

            Spacer()

            Button {
                selectedCategory = "Tất cả"
                searchQuery = ""
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.vnTextSecondary)
                    .frame(width: 44, height: 44)
                    .background(Color.vnBackgroundTertiary, in: RoundedRectangle(cornerRadius: VNCornerRadius.card))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Đặt lại tìm kiếm")
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
            HStack(spacing: VNSpacing.xs) {
                Image(systemName: "book.pages.fill")
                    .font(.vnCaption2)
                    .foregroundColor(.vnAccentImperialGold)
                    .accessibilityHidden(true)
                Text("VĂN HOÁ & LỄ TIẾT")
                    .font(.vnCaption2)
                    .fontWeight(.bold)
                    .tracking(1.0)
                    .foregroundColor(.vnAccentImperialGold)
            }
            .padding(.horizontal, VNSpacing.sm)
            .padding(.vertical, VNSpacing.xs)
            .background(Color.vnAccentGoldSurface)
            .clipShape(Capsule())

            Text("Văn Khấn & Phong Tục")
                .font(.vnTitleHero)
                .foregroundColor(.vnTextPrimary)

            Text("Tri thức ngàn năm về lễ nghi, văn khấn và phong tục truyền thống Việt Nam")
                .font(.system(size: 13, design: .serif))
                .italic()
                .foregroundColor(.vnTextSecondary)
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
                .font(.vnFootnote)
                .accessibilityHidden(true)

            TextField("Tìm văn khấn, ngày lễ, phong tục tập quán...", text: $searchQuery)
                .font(.vnFootnote)

            if !searchQuery.isEmpty {
                Button {
                    searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.vnTextTertiary)
                        .font(.vnFootnote)
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
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.card)
                .stroke(Color.vnBorderSubtle, lineWidth: VNBorderWidth.hairline)
        )
        .padding(.horizontal, VNSpacing.xl)
    }

    // MARK: - Category Filter Chips
    @ViewBuilder
    private var categoryChipsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { cat in
                    let isSelected = selectedCategory == cat
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedCategory = cat
                        }
                    } label: {
                        Text(cat)
                            .font(.vnCaption1)
                            .fontWeight(isSelected ? .semibold : .regular)
                            .frame(minHeight: 44)
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
            .padding(.horizontal, VNSpacing.xl)
            .padding(.vertical, VNSpacing.space2)
        }
    }

    // MARK: - Empty State
    @ViewBuilder
    private var emptyStateSection: some View {
        VStack(spacing: VNSpacing.md) {
            Text("Không Tìm Thấy Bài Viết")
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundColor(.vnTextPrimary)

            Text("Thử từ khoá hoặc bộ lọc khác để khám phá tri thức lễ nghi truyền thống.")
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .foregroundColor(.vnTextSecondary)
                .padding(.horizontal, VNSpacing.xl)

            Button {
                selectedCategory = "Tất cả"
                searchQuery = ""
            } label: {
                Text("Xem Tất Cả")
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .padding(.horizontal, VNSpacing.xxl)
                    .padding(.vertical, VNSpacing.md)
                    .frame(minHeight: 44)
                    .background(Color.vnAccentHeritageRed)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.small))
            }
            .buttonStyle(.plain)
            .padding(.top, VNSpacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, VNSpacing.xxl)
        .padding(.horizontal, VNSpacing.xl)
    }

    // MARK: - Article Card
    private func articleCard(holiday: Holiday) -> some View {
        let isLunar = holiday.calendarType == .lunar

        return VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Text(holiday.title)
                        .font(.system(size: 17, weight: .semibold, design: .serif))
                        .foregroundColor(.vnTextPrimary)

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
                    .font(.system(size: 12))
                    .foregroundColor(.vnTextSecondary)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    if holiday.rituals != nil {
                        Label("Có Bài Văn Khấn", systemImage: "book.pages.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color.vnAccentDeepPrimary)
                    } else {
                        Text(isLunar ? "Âm lịch" : "Dương lịch")
                            .font(.system(size: 11))
                            .foregroundColor(.vnTextSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.vnTextTertiary)
                        .accessibilityHidden(true)
                }
                .padding(.top, 2)
            }
            .padding(VNSpacing.xl)
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
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: VNSpacing.xl) {
                    // Header
                    VStack(alignment: .leading, spacing: VNSpacing.xs) {
                        let calendarName = holiday.calendarType == .lunar ? "Âm Lịch" : "Dương Lịch"
                        Text("Ngày \(holiday.day) Tháng \(holiday.month) \(calendarName)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.vnAccentHeritageRed)

                        Text(holiday.title)
                            .font(.vnTitleHero)
                            .foregroundColor(.vnTextPrimary)
                    }

                    Divider().background(Color.vnBorderSubtle)

                    // Summary / Meaning
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ý NGHĨA & NGUỒN GỐC")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.vnTextSecondary)
                            .tracking(0.8)

                        Text(holiday.summary)
                            .font(.system(size: 15, design: .serif))
                            .foregroundColor(.vnTextPrimary)
                            .lineSpacing(5)
                    }

                    if let customs = holiday.customs {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("PHONG TỤC NÊN LÀM")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.vnStatusSuccess)
                                .tracking(0.8)

                            Text(customs)
                                .font(.system(size: 14))
                                .foregroundColor(.vnTextPrimary)
                                .lineSpacing(4)
                                .padding(VNSpacing.xl)
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
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ĐIỀU KIÊNG KỴ")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.vnStatusError)
                                .tracking(0.8)

                            Text(taboos)
                                .font(.system(size: 14))
                                .foregroundColor(.vnTextPrimary)
                                .lineSpacing(4)
                                .padding(VNSpacing.xl)
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
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.vnAccentImperialGold)
                                    .tracking(0.8)

                                Spacer()

                                Button {
                                    #if canImport(UIKit)
                                    UIPasteboard.general.string = rituals
                                    let generator = UINotificationFeedbackGenerator()
                                    generator.notificationOccurred(.success)
                                    #endif
                                } label: {
                                    Label("Sao Chép", systemImage: "doc.on.doc")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.vnAccentHeritageRed)
                                        .frame(minHeight: 44)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }

                            Text(rituals)
                                .font(.system(size: 15, design: .serif))
                                .foregroundColor(.vnTextPrimary)
                                .lineSpacing(7)
                                .padding(VNSpacing.xl)
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
                .padding(.horizontal, VNSpacing.xl)
                .padding(.bottom, VNSpacing.xxl)
            }
            .background(Color.vnBackgroundPrimary.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.vnAccentHeritageRed)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
            }
        }
    }
}
