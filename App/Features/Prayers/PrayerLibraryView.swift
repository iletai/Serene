import SwiftUI
import VNCalendarDesignSystem
import VNCalendarDomain

public struct PrayerLibraryView: View {
    @State private var container = AppContainer.shared
    @State private var prayers: [Prayer] = []
    @State private var searchQuery: String = ""
    @State private var selectedCategory: PrayerCategory?
    @State private var selectedPrayer: Prayer?

    public init() {}

    private var filteredPrayers: [Prayer] {
        var list = prayers
        if let cat = selectedCategory {
            list = list.filter { $0.category == cat }
        }
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            list = list.filter { prayer in
                prayer.title.localizedCaseInsensitiveContains(query) ||
                prayer.occasion.localizedCaseInsensitiveContains(query) ||
                prayer.tags.contains(where: { $0.localizedCaseInsensitiveContains(query) })
            }
        }
        return list
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: VNSpacing.xl) {
                    // Header Section
                    headerSection

                    // Search Bar
                    searchBarSection

                    // Category Filter Pills
                    categoryPillsSection

                    // Prayer Items List
                    prayerListSection
                }
                .padding(.bottom, VNSpacing.xxl)
            }
            .background(Color.vnBackgroundPrimary.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $selectedPrayer) { prayer in
                PrayerDetailView(prayer: prayer)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .task {
                await loadPrayers()
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            HStack {
                HStack(spacing: VNSpacing.xs) {
                    Image(systemName: "book.pages.fill")
                        .font(.vnCaption2)
                        .foregroundColor(.vnAccentDeepPrimary)
                        .accessibilityHidden(true)
                    Text("NGHI LỄ TRUYỀN THỐNG")
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

                if !prayers.isEmpty {
                    Text("\(prayers.count) bài khấn")
                        .font(.vnCaption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.vnAccentDeepPrimary)
                        .padding(.horizontal, VNSpacing.sm)
                        .padding(.vertical, VNSpacing.xs)
                        .background(Color.vnAccentRedSurface)
                        .clipShape(Capsule())
                }
            }

            Text("Văn Khấn Cổ Truyền")
                .font(.vnTitleHero)
                .foregroundColor(.vnAccentDeepPrimary)
                .padding(.top, VNSpacing.space2)

            Text("Nghi thức cúng bái & phụng thờ linh thiêng chuẩn phong tục Việt")
                .font(.system(size: 13, design: .serif))
                .italic()
                .foregroundColor(.vnTextSecondary)
        }
        .padding(.horizontal, VNSpacing.xl)
        .padding(.top, VNSpacing.md)
    }

    // MARK: - Search Bar

    private var searchBarSection: some View {
        HStack(spacing: VNSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.vnTextSecondary)
                .font(.vnFootnote)
                .accessibilityHidden(true)

            TextField("Tìm văn khấn Mùng 1, Rằm, Giỗ, Táo Quân...", text: $searchQuery)
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
                .strokeBorder(Color.vnBorderSubtle, lineWidth: VNBorderWidth.hairline)
        )
        .padding(.horizontal, VNSpacing.xl)
    }

    // MARK: - Category Filter Pills

    private var categoryPillsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: VNSpacing.sm) {
                // "Tất cả" Pill
                Button {
                    triggerHaptic()
                    selectedCategory = nil
                } label: {
                    Text("Tất cả")
                        .font(.system(size: 12, weight: .semibold, design: .serif))
                        .foregroundColor(selectedCategory == nil ? .vnAccentDeepPrimary : .vnTextSecondary)
                        .frame(minHeight: 44)
                        .padding(.horizontal, VNSpacing.lg)
                        .background(selectedCategory == nil ? Color.vnAccentRedSurface : Color.clear)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().strokeBorder(
                                selectedCategory == nil ? Color.vnAccentHeritageRed.opacity(0.25) : Color.vnBorderSubtle,
                                lineWidth: selectedCategory == nil ? 1 : 0.5
                            )
                        )
                }
                .buttonStyle(.plain)
                .contentShape(Capsule())
                .accessibilityAddTraits(selectedCategory == nil ? [.isSelected, .isButton] : .isButton)

                // Each Category
                ForEach(PrayerCategory.allCases, id: \.self) { cat in
                    PrayerCategoryCard(
                        category: cat,
                        count: prayers.filter { $0.category == cat }.count,
                        isSelected: selectedCategory == cat,
                        action: {
                            selectedCategory = (selectedCategory == cat) ? nil : cat
                        }
                    )
                }
            }
            .padding(.horizontal, VNSpacing.xl)
            .padding(.vertical, VNSpacing.space2)
        }
    }

    // MARK: - Prayer List

    private var prayerListSection: some View {
        VStack(spacing: VNSpacing.sm) {
            if filteredPrayers.isEmpty {
                emptyState
            } else {
                ForEach(filteredPrayers) { prayer in
                    prayerRowCard(for: prayer)
                        .onTapGesture {
                            triggerHaptic()
                            selectedPrayer = prayer
                        }
                        .accessibilityAddTraits(.isButton)
                        .accessibilityHint("Xem chi tiết bài văn khấn")
                }
            }
        }
        .padding(.horizontal, VNSpacing.xl)
    }

    private func prayerRowCard(for prayer: Prayer) -> some View {
        HStack(spacing: VNSpacing.md) {
            // Category icon tile: 40x40, 8pt radius, red tint from canonical brief
            Image(systemName: prayer.category.iconName)
                .font(.system(size: 17))
                .foregroundColor(.vnAccentDeepPrimary)
                .frame(width: 40, height: 40)
                .background(Color.vnAccentRedSurface)
                .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: VNCornerRadius.card)
                        .strokeBorder(Color.vnAccentHeritageRed.opacity(0.28), lineWidth: VNBorderWidth.regular)
                )

            VStack(alignment: .leading, spacing: VNSpacing.space2) {
                Text(prayer.title)
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundColor(.vnTextPrimary)
                    .lineLimit(2)

                HStack(spacing: VNSpacing.xs) {
                    Text(prayer.occasion)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.vnTextSecondary)

                    if !prayer.offerings.isEmpty {
                        Text("• \(prayer.offerings.count) lễ vật")
                            .font(.system(size: 11))
                            .foregroundColor(.vnAccentImperialGold)
                    }
                }
                .lineLimit(1)
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
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
        .shadow(color: folioShadow.color, radius: folioShadow.radius, x: folioShadow.x, y: folioShadow.y)
        .contentShape(Rectangle())
    }

    // Faint folio shadow from canonical: 0 4px 20px -2px rgba(90,84,79,0.05).
    private var folioShadow: VNShadow.ShadowConfig { VNShadow.folio }

    private var emptyState: some View {
        VStack(spacing: VNSpacing.sm) {
            Image(systemName: "book.closed")
                .font(.system(size: 36))
                .foregroundColor(.vnTextTertiary)
                .padding(.top, VNSpacing.lg)

            Text("Không tìm thấy bài văn khấn phù hợp")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.vnTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, VNSpacing.xxl)
    }

    // MARK: - Helpers

    private func loadPrayers() async {
        if let items = try? await container.prayerRepository.fetchAllPrayers() {
            self.prayers = items
        }
    }

    private func triggerHaptic() {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }
}
