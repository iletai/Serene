import SwiftUI
import AppUpdateKit
import VNCalendarDesignSystem

/// Icon hero. Mirrors design.html art-panel motion: slow drum-turn ring + pulsing glow.
/// Both loops are skipped under Reduce Motion.
struct UpdateHero: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let kind: ForceUpdateViewModel.Kind
    @State private var glowing = false
    @State private var turning = false

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
        ZStack {
            Circle()
                .fill(Color.vnAccentImperialGold)
                .blur(radius: 22)
                .scaleEffect(glowing ? 1.15 : 0.9)
                .opacity(glowing ? 0.8 : 0.35)
            Circle()
                .strokeBorder(tint.opacity(0.35), style: StrokeStyle(lineWidth: 2, dash: [3, 7]))
                .rotationEffect(.degrees(turning ? 360 : 0))
            Image(systemName: symbol)
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(width: 120, height: 120)
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion, !turning else { return }
            withAnimation(.easeInOut(duration: 2.1).repeatForever(autoreverses: true)) { glowing = true }
            withAnimation(.linear(duration: 90).repeatForever(autoreverses: false)) { turning = true }
        }
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

extension View {
    /// Presents the update screen full-screen whenever `action` isn't `.none`.
    /// A force update cannot be dismissed (no close button, swipe disabled).
    func updateScreen(action: Binding<AppUpdateAction>, locale: Locale) -> some View {
        fullScreenCover(isPresented: Binding(
            get: { action.wrappedValue != .none },
            set: { if !$0 { action.wrappedValue = .none } }
        )) {
            ForceUpdateView(viewModel: ForceUpdateViewModel(action: action.wrappedValue) { action.wrappedValue = .none })
                .environment(\.locale, locale)
        }
    }
}
