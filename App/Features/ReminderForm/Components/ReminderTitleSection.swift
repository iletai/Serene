import SwiftUI
import VNCalendarDesignSystem

struct ReminderTitleSection: View {
    @Binding var title: String
    @Binding var relationship: String
    var focusedField: FocusState<ReminderFormView.Field?>.Binding
    let showsError: Bool
    let errorMessage: String

    private var isFocused: Bool { focusedField.wrappedValue == .title }

    var body: some View {
        VStack(alignment: .leading, spacing: VNSpacing.sm) {
            Text(String(localized: "reminderForm.title.header"))
                .font(.caption2.weight(.medium))
                .tracking(0.66)
                .foregroundColor(.vnAccentGoldText)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .accessibilityAddTraits(.isHeader)

            VNCard(
                allPadding: VNSpacing.cardPadding,
                cornerRadius: VNCornerRadius.card,
                backgroundColor: Color.vnBackgroundSecondary,
                borderColor: showsError ? Color.vnStatusError : Color.vnBorderStrong,
                shadow: nil
            ) {
                VStack(alignment: .leading, spacing: VNSpacing.md) {
                    VStack(alignment: .leading, spacing: 0) {
                        TextField(String(localized: "reminderForm.title.placeholder"), text: $title)
                            .font(.callout.weight(.semibold))
                            .foregroundColor(.vnTextPrimary)
                            .focused(focusedField, equals: .title)
                            .submitLabel(.next)
                            .onSubmit { focusedField.wrappedValue = .note }
                            .padding(.bottom, VNSpacing.sm)
                        Rectangle()
                            .fill(underlineColor)
                            .frame(height: isFocused || showsError ? VNBorderWidth.active : VNBorderWidth.hairline)
                    }

                    if showsError {
                        Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                            .font(.footnote)
                            .foregroundColor(.vnStatusError)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: VNSpacing.xs) {
                            Text(String(localized: "reminderForm.role.label"))
                                .font(.caption)
                                .foregroundColor(.vnTextSecondary)

                            let roles = ["Nội Tộc", "Ngoại Tộc", "Cụ", "Ông", "Bà", "Cha / Bố", "Mẹ", "Bác", "Chú", "Cô", "Dì", "Anh / Chị"]
                            ForEach(roles, id: \.self) { role in
                                roleChip(role: role)
                            }
                        }
                    }
                }
            }
        }
    }

    private var underlineColor: Color {
        if showsError { return .vnStatusError }
        return isFocused ? .vnAccentHeritageRed : .vnBorderSubtle
    }

    private func roleChip(role: String) -> some View {
        let isSelected = relationship == role
        return Button(
            action: {
                relationship = role
                if title.isEmpty {
                    title = String(format: String(localized: "reminderForm.defaultTitle"), role)
                }
            },
            label: {
                HStack(spacing: VNSpacing.xs) {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .accessibilityHidden(true)
                    }
                    Text(role)
                        .font(.footnote.weight(isSelected ? .semibold : .regular))
                        .lineLimit(1)
                }
                .foregroundColor(isSelected ? .vnAccentDeepPrimary : .vnTextSecondary)
                .padding(.horizontal, VNSpacing.md)
                .frame(minHeight: VNSize.buttonSmall)
                .background(isSelected ? Color.vnAccentRedSurface : Color.clear, in: Capsule())
                .overlay(
                    Capsule().stroke(
                        isSelected ? Color.vnAccentDeepPrimary : Color.vnBorderSubtle,
                        lineWidth: VNBorderWidth.regular
                    )
                )
                .frame(minHeight: VNSize.minTapTarget)
                .contentShape(Rectangle())
            }
        )
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
