import SwiftUI
import VNCalendarDesignSystem
import VNCalendarDomain
import VNCalendarLunar

public struct PrayerDetailView: View {
    public let prayer: Prayer
    @Environment(\.dismiss) private var dismiss
    @State private var fontSize: CGFloat = 16
    @State private var isZenMode = false
    @State private var showCopiedAlert = false
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true

    public init(prayer: Prayer) {
        self.prayer = prayer
    }

    private var interpolatedPrayerText: String {
        let now = SolarDate(from: Date())
        let lunar = LunarAstronomicalEngine.shared.convertToLunar(from: now)
        let canChi = LunarAstronomicalEngine.shared.computeCanChi(for: now)

        let canChiDesc = String(
            format: String(localized: "prayers.detail.can_chi_desc"),
            canChi.year.description,
            canChi.month.description,
            canChi.day.description
        )
        var text = prayer.prayerText
        text = text.replacingOccurrences(of: "[Ngày]", with: "\(lunar.day)")
        text = text.replacingOccurrences(of: "[Tháng]", with: "\(lunar.month)")
        text = text.replacingOccurrences(of: "[Năm]", with: "\(lunar.year)")
        text = text.replacingOccurrences(of: "[Can Chi]", with: canChiDesc)
        text = text.replacingOccurrences(of: "[Năm Cũ]", with: "\(lunar.year)")
        text = text.replacingOccurrences(of: "[Năm Mới]", with: "\(lunar.year + 1)")
        text = text.replacingOccurrences(of: "[Tiết khí]", with: String(localized: "prayers.detail.solar_term"))
        return text
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: VNSpacing.xl) {
                    // Header Cluster
                    headerCluster

                    // Offerings Checklist Card (Mâm Lễ Vật Cần Chuẩn Bị)
                    if !prayer.offerings.isEmpty {
                        offeringsCard
                    }

                    // Reading Toolbar (Font Size & Bell)
                    readingToolbar

                    // Main Ceremonial Prayer Text Card (Giấy Dó & Mực Nho)
                    prayerTextCard

                    // Cultural Notes & Guidance
                    if let notes = prayer.notes {
                        notesCard(notes)
                    }
                }
                .padding(.horizontal, VNSpacing.xl)
                .padding(.top, VNSpacing.md)
                .padding(.bottom, VNSpacing.xxl)
            }
            .background(Color.vnBackgroundPrimary.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.vnBackgroundPrimary.opacity(0.9), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("action.close") {
                        dismiss()
                    }
                    .foregroundColor(.vnTextSecondary)
                    .frame(minHeight: VNSize.minTapTarget)
                    .contentShape(Rectangle())
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        copyToClipboard()
                    } label: {
                        HStack(spacing: VNSpacing.xs) {
                            Image(systemName: "doc.on.doc")
                                .font(.vnFootnote)
                                .accessibilityHidden(true)
                            Text("prayers.action.copy")
                                .font(.vnFootnote)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.vnAccentDeepPrimary)
                        .padding(.horizontal, VNSpacing.sm)
                        .padding(.vertical, VNSpacing.xs)
                        .frame(minHeight: VNSize.minTapTarget)
                        .background(Color.vnBackgroundPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.small))
                        .overlay(
                            RoundedRectangle(cornerRadius: VNCornerRadius.small)
                                .stroke(Color.vnAccentHeritageRed.opacity(0.28), lineWidth: VNBorderWidth.regular)
                        )
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if showCopiedAlert {
                    Text("prayers.copied_toast")
                        .font(.vnDisplay(.footnote, weight: .semibold))
                        .foregroundColor(.vnOnAccent)
                        .padding(.horizontal, VNSpacing.lg)
                        .padding(.vertical, VNSpacing.sm)
                        .background(Color.vnAccentDeepPrimary.opacity(0.95))
                        .clipShape(Capsule())
                        .shadow(color: VNShadow.card.color, radius: VNShadow.card.radius,
                                x: VNShadow.card.x, y: VNShadow.card.y)
                        .padding(.bottom, VNSpacing.xxl)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - Header Cluster

    private var headerCluster: some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            HStack(spacing: VNSpacing.xs) {
                Image(systemName: prayer.category.iconName)
                    .font(.vnCaption2)
                    .fontWeight(.bold)
                    .foregroundColor(.vnAccentHeritageRed)
                    .accessibilityHidden(true)

                Text(prayer.category.rawValue.uppercased())
                    .font(.vnCaption2)
                    .fontWeight(.bold)
                    .tracking(1.0)
                    .foregroundColor(.vnAccentHeritageRed)

                Spacer()

                VNSealBadge(text: String(localized: "prayers.seal_standard"), shape: .rounded(), color: .cinnabarGold, size: .small)
            }
            .padding(.horizontal, VNSpacing.sm)
            .padding(.vertical, VNSpacing.xs)
            .background(Color.vnAccentRedSurface)
            .clipShape(Capsule())

            Text(prayer.title)
                .font(.vnTitleFestival)
                .foregroundColor(.vnTextPrimary)
                .padding(.top, VNSpacing.space2)

            HStack(spacing: VNSpacing.xs) {
                Image(systemName: "calendar")
                    .font(.vnCaption1)
                    .foregroundColor(.vnAccentGoldText)
                    .accessibilityHidden(true)
                Text(prayer.occasion)
                    .font(.vnDisplay(.footnote, weight: .medium))
                    .foregroundColor(.vnTextSecondary)
            }
        }
    }

    // MARK: - Offerings Checklist Card

    private var offeringsCard: some View {
        VStack(alignment: .leading, spacing: VNSpacing.sm) {
            Text("prayers.offerings_title")
                .font(.vnDisplay(.headline, weight: .semibold))
                .foregroundColor(.vnTextPrimary)
            Text("prayers.offerings_subtitle")
                .font(.vnDisplay(.caption2))
                .foregroundColor(.vnTextSecondary)

            VNRowDivider()

            VStack(alignment: .leading, spacing: VNSpacing.xs) {
                ForEach(prayer.offerings, id: \.self) { item in
                    HStack(alignment: .top, spacing: VNSpacing.sm) {
                        Circle()
                            .fill(Color.vnAccentImperialGold)
                            .frame(width: 5, height: 5)
                            .padding(.top, VNSpacing.xs)
                            .accessibilityHidden(true)

                        Text(item)
                            .font(.vnFootnote)
                            .foregroundColor(.vnTextPrimary)
                    }
                }
            }
        }
        .padding(VNSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.vnBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.card)
                .stroke(Color.vnBorderSubtle, lineWidth: VNBorderWidth.regular)
        )
        .shadow(color: folioShadow.color, radius: folioShadow.radius, x: folioShadow.x, y: folioShadow.y)
    }

    // MARK: - Reading Toolbar

    private var readingToolbar: some View {
        HStack(spacing: VNSpacing.md) {
            // Bell chime haptic button (Chuông khánh tịnh tâm)
            Button {
                triggerBellChime()
            } label: {
                HStack(spacing: VNSpacing.xs) {
                    Image(systemName: "bell.fill")
                        .font(.vnCaption1)
                        .fontWeight(.bold)
                        .foregroundColor(.vnAccentGoldText)
                        .accessibilityHidden(true)
                    Text("prayers.bell")
                        .font(.vnCaption1)
                        .fontWeight(.semibold)
                        .foregroundColor(.vnTextPrimary)
                }
                .frame(minHeight: VNSize.minTapTarget)
                .padding(.horizontal, VNSpacing.md)
                .background(Color.vnAccentGoldSurface)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Spacer()

            // Font size controls
            HStack(spacing: VNSpacing.space2) {
                Button {
                    if fontSize > 13 { fontSize -= 1 }
                } label: {
                    Text("A-")
                        .font(.vnCaption1)
                        .fontWeight(.bold)
                        .foregroundColor(.vnTextPrimary)
                        .frame(width: VNSize.buttonSmall, height: VNSize.buttonSmall)
                        .background(Color.vnBackgroundSecondary)
                        .clipShape(Circle())
                        .frame(minWidth: VNSize.minTapTarget, minHeight: VNSize.minTapTarget)
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
                .accessibilityLabel("prayers.a11y_font_smaller")

                Text("\(Int(fontSize))pt")
                    .font(.vnCaption2)
                    .fontWeight(.medium)
                    .foregroundColor(.vnTextSecondary)
                    .frame(width: 32)

                Button {
                    if fontSize < 24 { fontSize += 1 }
                } label: {
                    Text("A+")
                        .font(.vnCaption1)
                        .fontWeight(.bold)
                        .foregroundColor(.vnTextPrimary)
                        .frame(width: VNSize.buttonSmall, height: VNSize.buttonSmall)
                        .background(Color.vnBackgroundSecondary)
                        .clipShape(Circle())
                        .frame(minWidth: VNSize.minTapTarget, minHeight: VNSize.minTapTarget)
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
                .accessibilityLabel("prayers.a11y_font_larger")
            }
        }
    }

    // MARK: - Prayer Text Card

    private var prayerTextCard: some View {
        VStack(alignment: .leading, spacing: VNSpacing.md) {
            Text("prayers.prayer_text_title")
                .font(.vnDisplay(.headline, weight: .semibold))
                .foregroundColor(.vnTextPrimary)

            VNRowDivider()

            Text(interpolatedPrayerText)
                .font(.vnDisplay(size: fontSize, weight: .medium))
                .foregroundColor(.vnTextPrimary)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .padding(VNSpacing.xl)
        .background(Color.vnBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.card)
                .stroke(Color.vnBorderSubtle, lineWidth: VNBorderWidth.regular)
        )
        .shadow(color: folioShadow.color, radius: folioShadow.radius, x: folioShadow.x, y: folioShadow.y)
    }

    // Faint folio shadow from canonical: 0 4px 20px -2px rgba(90,84,79,0.05).
    private var folioShadow: VNShadow.ShadowConfig { VNShadow.folio }

    // MARK: - Notes Card

    private func notesCard(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            Text("prayers.notes_title")
                .font(.vnDisplay(.headline, weight: .semibold))
                .foregroundColor(.vnTextPrimary)

            Text(notes)
                .font(.vnDisplay(.caption))
                .foregroundColor(.vnTextSecondary)
                .lineSpacing(3)
        }
        .padding(VNSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.vnBackgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
    }

    // MARK: - Helpers

    private func copyToClipboard() {
        #if canImport(UIKit)
        UIPasteboard.general.string = interpolatedPrayerText
        #endif
        VNHaptics.impact(.success, enabled: hapticFeedbackEnabled)

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showCopiedAlert = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedAlert = false
            }
        }
    }

    private func triggerBellChime() {
        VNHaptics.impact(.medium, enabled: hapticFeedbackEnabled)
    }
}
