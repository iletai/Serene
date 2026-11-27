import SwiftUI
import VNCalendarDesignSystem
import VNCalendarKit

/// Page 4 "Theo ý bạn". Writes to the same keys Settings reads, so nothing new is stored.
struct OnboardingPreferencesPage: View {
    @AppStorage("appThemeAppearance") private var appThemeAppearance: Int = 0
    @AppStorage(VNCalendarPreferenceKey.startOfWeek) private var startOfWeek = 2 // 2 = Monday, 1 = Sunday

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ArtPanel(season: .winter, height: 120) {
                    Text(String(localized: "onboarding.page4.caption"))
                        .font(.vnDisplay(.footnote, weight: .semibold))
                        .foregroundStyle(Color.vnOnNight.opacity(0.92))
                        .shadow(color: .black.opacity(0.3), radius: 8, y: 1)
                }
                .padding(.horizontal, VNSpacing.screenMargin)
                OnboardingHeading(title: String(localized: "onboarding.page4.title"), message: String(localized: "onboarding.page4.body"))
                    .padding(.top, VNSpacing.lg)
                sections.padding(.top, VNSpacing.xxl)
            }
            .padding(.vertical, VNSpacing.sm)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private var sections: some View {
        VStack(alignment: .leading, spacing: VNSpacing.sectionGap) {
            VStack(alignment: .leading, spacing: VNSpacing.sm) {
                VNGroupHeader(String(localized: "onboarding.page4.theme_header"))
                VNGroupCard {
                    HStack(spacing: VNSpacing.md) {
                        ThemeTile(title: String(localized: "onboarding.theme.auto"), value: 0, selection: $appThemeAppearance)
                        ThemeTile(title: String(localized: "onboarding.theme.light"), value: 1, selection: $appThemeAppearance)
                        ThemeTile(title: String(localized: "onboarding.theme.dark"), value: 2, selection: $appThemeAppearance)
                    }
                    .padding(VNSpacing.lg)
                }
            }
            VStack(alignment: .leading, spacing: VNSpacing.sm) {
                VNGroupHeader(String(localized: "onboarding.page4.week_header"))
                Picker(String(localized: "onboarding.page4.week_header"), selection: $startOfWeek) {
                    Text(String(localized: "settings.calendar.week_start_monday")).tag(2)
                    Text(String(localized: "settings.calendar.week_start_sunday")).tag(1)
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(.horizontal, VNSpacing.screenMargin)
    }
}

/// Title + supporting line shared by every onboarding page.
struct OnboardingHeading: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: VNSpacing.sm) {
            Text(title)
                .font(.vnDisplay(.title, weight: .bold))
                .foregroundStyle(Color.vnTextPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(message)
                .font(.vnBody)
                .foregroundStyle(Color.vnTextSecondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: 340)
        .padding(.horizontal, VNSpacing.screenMargin)
    }
}

// MARK: - Theme tile

private struct ThemeTile: View {
    let title: String
    let value: Int
    @Binding var selection: Int

    private var isSelected: Bool { selection == value }

    var body: some View {
        Button { selection = value } label: {
            VStack(spacing: VNSpacing.sm) {
                preview
                    .aspectRatio(3 / 4, contentMode: .fit)
                    .clipShape(.rect(cornerRadius: 10, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(isSelected ? Color.vnAccentHeritageRed : Color.vnBorderSubtle, lineWidth: isSelected ? 2 : 1)
                    }
                Text(title)
                    .font(.vnFootnote)
                    .foregroundStyle(Color.vnTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? Color.vnAccentHeritageRed : Color.vnBorderStrong)
            }
        }
        .buttonStyle(VNCellPressButtonStyle(pressedScale: 0.97))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    /// Auto shows the light mock-up on the left half and the dark one on the right half.
    @ViewBuilder
    private var preview: some View {
        switch value {
        case 1: mock(background: .vnNewRiceIvory, header: .vnCinnabarLacquerRed, line: .vnAncientSand)
        case 2: mock(background: .vnLacquerCharcoal, header: .vnCinnabarEmbers, line: .vnDarkSand)
        default:
            ZStack {
                mock(background: .vnNewRiceIvory, header: .vnCinnabarLacquerRed, line: .vnAncientSand)
                mock(background: .vnLacquerCharcoal, header: .vnCinnabarEmbers, line: .vnDarkSand)
                    .mask(HStack(spacing: 0) { Color.clear; Color.black })
            }
        }
    }

    private func mock(background: Color, header: Color, line: Color) -> some View {
        VStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 4).fill(header).frame(height: 18)
            RoundedRectangle(cornerRadius: 3).fill(line).frame(height: 6)
            RoundedRectangle(cornerRadius: 3).fill(line).frame(height: 6)
            RoundedRectangle(cornerRadius: 3).fill(line).frame(height: 6)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(background)
    }
}
