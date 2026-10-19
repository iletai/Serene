import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem
import VNCalendarLunar

public struct ReminderFormView: View {
    @Environment(\.dismiss) private var dismiss
    public var onSave: (ReminderEvent) -> Void

    @FocusState private var isTitleFocused: Bool
    @State private var viewModel: ReminderFormViewModel

    public init(
        existingReminder: ReminderEvent? = nil,
        initialDate: Date? = nil,
        onSave: @escaping (ReminderEvent) -> Void
    ) {
        self.onSave = onSave
        _viewModel = State(initialValue: ReminderFormViewModel(
            existingReminder: existingReminder,
            initialDate: initialDate
        ))
    }

    public var body: some View {
        @Bindable var vm = viewModel
        NavigationStack {
            ScrollView {
                VStack(spacing: VNSpacing.xl) {
                    ReminderHeaderView(
                        isEditing: vm.existingReminder != nil,
                        day: vm.day,
                        month: vm.month,
                        year: vm.year,
                        dateType: vm.dateType,
                        isLeapMonth: vm.isLeapMonth
                    )
                    ReminderCategoryGrid(selectedCategory: $vm.category)
                    ReminderTitleSection(
                        title: $vm.title,
                        relationship: $vm.relationship,
                        isFocused: $isTitleFocused
                    )
                    ReminderDatePickerCard(
                        dateType: $vm.dateType,
                        day: $vm.day,
                        month: $vm.month,
                        year: $vm.year,
                        isLeapMonth: $vm.isLeapMonth
                    )
                    ReminderOffsetsCard(
                        notifyOnDay: $vm.notifyOnDay,
                        notify1DayBefore: $vm.notify1DayBefore,
                        notify3DaysBefore: $vm.notify3DaysBefore,
                        notify7DaysBefore: $vm.notify7DaysBefore,
                        notify14DaysBefore: $vm.notify14DaysBefore,
                        notify30DaysBefore: $vm.notify30DaysBefore
                    )
                    notesSection(vm: vm)
                    saveActionButton(vm: vm)
                }
                .padding(.horizontal, VNSpacing.xl)
                .padding(.vertical, VNSpacing.md)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.vnBackgroundPrimary.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.vnBackgroundPrimary.opacity(0.9), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng", action: { dismiss() })
                        .foregroundColor(.vnTextSecondary)
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Xong") {
                        isTitleFocused = false
                    }
                    .foregroundColor(.vnAccentDeepPrimary)
                }
            }
        }
    }

    @ViewBuilder
    private func notesSection(vm: ReminderFormViewModel) -> some View {
        @Bindable var boundVM = vm
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            Text("GHI CHÚ THÊM")
                .font(.system(size: 11, weight: .bold))
                .tracking(0.5)
                .foregroundColor(.vnTextTertiary)

            VStack(alignment: .leading, spacing: VNSpacing.sm) {
                TextField("Ví dụ: Cúng gà luộc, xôi gấc, mời họ hàng nội tộc...", text: $boundVM.note, axis: .vertical)
                    .font(.system(size: 14))
                    .foregroundColor(.vnTextPrimary)
                    .lineLimit(3...5)
                    .padding(VNSpacing.md)
                    .background(Color.vnBackgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
                    .overlay(
                        RoundedRectangle(cornerRadius: VNCornerRadius.card)
                            .stroke(Color.vnBorderSubtle, lineWidth: VNBorderWidth.hairline)
                    )
                    .frame(minHeight: 70)
                    .accessibilityLabel("Ghi chú / phân công cúng giỗ")
            }
        }
    }

    @ViewBuilder
    private func saveActionButton(vm: ReminderFormViewModel) -> some View {
        VNButton(
            vm.existingReminder != nil ? "Lưu Thay Đổi" : "Lưu Ngày Lễ",
            icon: "checkmark.seal.fill",
            variant: vm.isValid ? .primary : .secondary,
            size: .large,
            isFullWidth: true
        ) {
            onSave(vm.buildReminder())
            dismiss()
        }
        .disabled(!vm.isValid)
        .padding(.top, VNSpacing.md)
    }
}
