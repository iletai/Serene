import SwiftUI
import AppUpdateKit
import VNCalendarDesignSystem

/// Icon hero on the lantern art panel (design.html `.force-hero .art-panel`): photo drift and drum turn
/// come from `ArtPanel`; all loops are skipped under Reduce Motion.
struct UpdateHero: View {
    let kind: ForceUpdateViewModel.Kind

    private var symbol: String {
        switch kind {
        case .force: "arrow.down.app.fill"
        case .optional: "sparkles"
        case .maintenance: "wrench.and.screwdriver.fill"
        }
    }

    private var tint: Color {
        switch kind {
        case .force: .vnAccentHeritageRed
        case .optional: .vnAccentJade
        case .maintenance: .vnAccentGoldText
        }
    }

    var body: some View {
        ArtPanel(season: .lantern, height: 220) {
            Image(systemName: symbol)
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(Color.vnOnAccent)
                .frame(width: 80, height: 80)
                .background(tint, in: .rect(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.3), radius: 12, y: 8)
        }
        .accessibilityHidden(true)
    }
}

/// "What's new" list: group header, one row per release note, reassurance footer.
struct UpdateNotesSection: View {
    let notes: [String]
    let version: String?

    private static let tints: [Color] = [.vnAccentSky, .vnAccentHeritageRed, .vnAccentJade]
    private static let surfaces: [Color] = [.vnAccentSkySurface, .vnAccentRedSurface, .vnAccentJadeSurface]
    private static let symbols = ["calendar", "bell", "icloud"]

    private var header: String {
        guard let version else { return String(localized: "update.notes.header") }
        return String(format: String(localized: "update.notes.header.version"), version)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: VNSpacing.sm) {
            VNSectionLabel(header)
            VNGroupCard {
                ForEach(Array(notes.enumerated()), id: \.offset) { index, note in
                    if index > 0 { VNRowDivider(leadingInset: 58) }
                    row(note, index: index % Self.tints.count)
                }
            }
            Text("update.notes.footer")
                .font(.vnCaption1)
                .foregroundStyle(Color.vnTextSecondary)
                .padding(.horizontal, VNSpacing.xs)
        }
    }

    private func row(_ note: String, index: Int) -> some View {
        HStack(spacing: VNSpacing.md) {
            Image(systemName: Self.symbols[index])
                .font(.vnSubheadline)
                .foregroundStyle(Self.tints[index])
                .frame(width: 32, height: 32)
                .background(Self.surfaces[index], in: .rect(cornerRadius: VNCornerRadius.small))
                .accessibilityHidden(true)
            Text(verbatim: note)
                .font(.vnSubheadline)
                .foregroundStyle(Color.vnTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, VNSpacing.lg)
        .padding(.vertical, VNSpacing.md)
        .accessibilityElement(children: .combine)
    }
}
