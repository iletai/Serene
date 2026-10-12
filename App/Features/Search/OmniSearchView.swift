import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem
import VNCalendarLunar

public struct OmniSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var container = AppContainer.shared
    @State private var searchText: String = ""
    @State private var searchResults: [SearchResultItem] = []
    @State private var parsedDate: ParsedDateResult?
    @State private var resolvedConvertedDateText: String?
    @FocusState private var isSearchFocused: Bool

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: VNSpacing.xl) {
                    searchField

                    if let parsed = parsedDate {
                        parsedDateCard(parsed)
                    }

                    if !searchResults.isEmpty {
                        resultsList
                    } else if !searchText.isEmpty && parsedDate == nil {
                        Text("Không tìm thấy kết quả phù hợp cho \"\(searchText)\".")
                            .font(.vnFootnote)
                            .foregroundColor(.vnTextSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, VNSpacing.xl)
                .padding(.top, VNSpacing.xl)
                .padding(.bottom, VNSpacing.xxl)
            }
            .background(Color.vnBackgroundPrimary.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.vnBackgroundPrimary.opacity(0.9), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Tra Cứu Thông Minh")
                        .font(.system(size: 18, weight: .semibold, design: .serif))
                        .foregroundColor(.vnAccentDeepPrimary)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") { dismiss() }
                        .frame(minWidth: 44, minHeight: 44)
                }
            }
        }
    }

    // MARK: - Search Field (bottom hairline turns red on focus)
    private var searchField: some View {
        VStack(spacing: 0) {
            HStack(spacing: VNSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15))
                    .foregroundColor(isSearchFocused ? .vnAccentHeritageRed : .vnTextTertiary)

                TextField("", text: $searchText, prompt: Text("Tìm giỗ ông, 15/8 âm, rằm tháng 7..."))
                    .font(.system(size: 15))
                    .foregroundColor(.vnTextPrimary)
                    .focused($isSearchFocused)
                    .submitLabel(.search)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        performSearch(query: "")
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.vnTextTertiary)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                    .accessibilityLabel("Xóa tìm kiếm")
                }
            }
            .padding(.horizontal, VNSpacing.md)
            .padding(.vertical, VNSpacing.sm)
            .frame(minHeight: 44)
            .background(Color.vnSurfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))

            Rectangle()
                .fill(isSearchFocused ? Color.vnAccentHeritageRed : Color.vnBorderSubtle)
                .frame(height: isSearchFocused ? VNBorderWidth.active : VNBorderWidth.regular)
        }
        .onChange(of: searchText) { _, newValue in
            performSearch(query: newValue)
        }
    }

    // MARK: - Deterministic Date Parser Result
    private func parsedDateCard(_ parsed: ParsedDateResult) -> some View {
        folioCard {
            HStack(alignment: .top, spacing: VNSpacing.md) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.vnAccentImperialGold)
                    .frame(width: 40, height: 40)
                    .background(Color.vnAccentImperialGold.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous)
                            .stroke(Color.vnAccentImperialGold.opacity(0.22), lineWidth: VNBorderWidth.regular)
                    )

                VStack(alignment: .leading, spacing: VNSpacing.xs) {
                    HStack(spacing: VNSpacing.sm) {
                        Text("Phân Tích Ngày Nhanh")
                            .font(.system(size: 11, weight: .medium))
                            .tracking(0.7)
                            .foregroundColor(.vnOnGoldContainer)
                            .padding(.horizontal, VNSpacing.sm)
                            .padding(.vertical, VNSpacing.xs)
                            .background(Color.vnGoldContainer.opacity(0.5))
                            .clipShape(Capsule())
                    }

                    Text(parsed.label)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.vnTextPrimary)

                    if let conv = resolvedConvertedDateText {
                        Text(conv)
                            .font(.system(size: 13))
                            .foregroundColor(.vnAccentHeritageRed)
                    }
                }
            }
            .padding(VNSpacing.lg)
        }
    }

    // MARK: - Matched Events & Holidays
    private var resultsList: some View {
        VStack(spacing: VNSpacing.sm) {
            Text("Sự Kiện & Ngày Lễ Trùng Khớp")
                .font(.system(size: 11, weight: .medium))
                .tracking(0.7)
                .foregroundColor(.vnOnGoldContainer)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, VNSpacing.xs)
                .accessibilityAddTraits(.isHeader)

            ForEach(searchResults) { item in
                switch item {
                case .reminder(let r):
                    resultCard(
                        icon: "flame.fill",
                        tint: .vnAccentHeritageRed,
                        title: r.title,
                        detail: "\(r.day)/\(r.month) \(r.dateType == .lunar ? "Âm lịch" : "Dương lịch") • \(r.category.title)"
                    )
                case .holiday(let h):
                    resultCard(
                        icon: "leaf.fill",
                        tint: .vnAccentImperialGold,
                        title: h.title,
                        detail: h.summary
                    )
                }
            }
        }
    }

    private func resultCard(icon: String, tint: Color, title: String, detail: String) -> some View {
        folioCard {
            HStack(alignment: .top, spacing: VNSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(tint)
                    .frame(width: 40, height: 40)
                    .background(tint.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous)
                            .stroke(tint.opacity(0.22), lineWidth: VNBorderWidth.regular)
                    )

                VStack(alignment: .leading, spacing: VNSpacing.xs) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.vnTextPrimary)
                    Text(detail)
                        .font(.system(size: 12))
                        .foregroundColor(.vnTextSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(VNSpacing.lg)
        }
    }

    // Rice-paper folio card: 8pt radius + gold hairline
    private func folioCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(Color.vnBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.card, style: .continuous)
                .stroke(Color.vnAccentImperialGold.opacity(0.28), lineWidth: VNBorderWidth.regular)
        )
        .shadow(color: VNShadow.folio.color, radius: VNShadow.folio.radius, x: VNShadow.folio.x, y: VNShadow.folio.y)
    }

    private func performSearch(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            searchResults = []
            parsedDate = nil
            resolvedConvertedDateText = nil
            return
        }

        // 1. Parse deterministic natural date
        let parsed = DeterministicDateParser.parse(query: trimmed)
        self.parsedDate = parsed

        if let p = parsed {
            Task {
                let engine = LunarAstronomicalEngine.shared
                if let lunar = p.lunarDate {
                    let solar = await engine.convertToSolar(from: lunar)
                    let canChi = await engine.computeCanChi(for: solar)
                    resolvedConvertedDateText = "Tương ứng Dương lịch: \(solar.day)/\(solar.month)/\(solar.year) " +
                        "(Năm \(canChi.year.description))"
                } else if let solar = p.solarDate {
                    let lunar = await engine.convertToLunar(from: solar)
                    let canChi = await engine.computeCanChi(for: solar)
                    resolvedConvertedDateText = "Tương ứng Âm lịch: \(lunar.day)/\(lunar.month)/\(lunar.year) ÂL " +
                        "(Năm \(canChi.year.description))"
                }
            }
        } else {
            resolvedConvertedDateText = nil
        }

        // 2. Perform natural search in repositories
        Task {
            if let results = try? await container.naturalSearchUseCase.execute(query: trimmed) {
                self.searchResults = results
            }
        }
    }
}
