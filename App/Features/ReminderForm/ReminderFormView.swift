import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem
import VNCalendarLunar

public struct ReminderFormView: View {
    enum Field: Hashable { case title, note }

    @Environment(AppRouter.self) private var router
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    public var onSave: (ReminderEvent) -> Void

    @FocusState private var focusedField: Field?
    @State private var viewModel: ReminderFormViewModel
    @State private var isConfirmingDiscard = false
    /// Set once the form has saved, so a double tap on Save persists only once.
    @State private var didFinish = false
    @ScaledMetric(relativeTo: .caption2) private var bottomInset: CGFloat = VNSpacing.hero + VNSpacing.sectionGap

    static var titleRequiredMessage: String { String(localized: "reminder.title_required") }

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
                VStack(spacing: VNSpacing.sectionGap) {
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
                        focusedField: $focusedField,
                        showsError: vm.showsTitleError,
                        errorMessage: Self.titleRequiredMessage
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
                .padding(.horizontal, VNSpacing.screenMargin)
                .padding(.top, VNSpacing.md)
                .padding(.bottom, bottomInset)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.vnBackgroundPrimary.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.vnBackgroundPrimary.opacity(0.9), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    VNDismissButton { close() }
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Xong") {
                        focusedField = nil
                    }
                    .foregroundColor(.vnAccentDeepPrimary)
                }
            }
        }
        .interactiveDismissDisabled(vm.isDirty)
        .confirmationDialog("reminder.discard_title", isPresented: $isConfirmingDiscard, titleVisibility: .visible) {
            Button("reminder.discard_confirm", role: .destructive) { router.dismissModals() }
            Button("reminder.discard_keep", role: .cancel) {}
        }
    }

    private func close() {
        if viewModel.isDirty {
            isConfirmingDiscard = true
        } else {
            router.dismissModals()
        }
    }

    @ViewBuilder
    private func notesSection(vm: ReminderFormViewModel) -> some View {
        @Bindable var boundVM = vm
        VStack(alignment: .leading, spacing: VNSpacing.xs) {
            Text("reminder.notes_extra_header")
                .font(.caption2.weight(.bold))
                .tracking(0.5)
                .foregroundColor(.vnTextTertiary)
                .accessibilityAddTraits(.isHeader)

            TextField("reminder.notes_placeholder", text: $boundVM.note, axis: .vertical)
                .font(.subheadline)
                .foregroundColor(.vnTextPrimary)
                .lineLimit(3...5)
                .focused($focusedField, equals: .note)
                .padding(VNSpacing.md)
                .background(Color.vnBackgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: VNCornerRadius.card)
                        .stroke(Color.vnBorderSubtle, lineWidth: VNBorderWidth.hairline)
                )
                .accessibilityLabel("reminder.a11y_notes")
        }
    }

    @ViewBuilder
    private func saveActionButton(vm: ReminderFormViewModel) -> some View {
        VNButton(
            vm.existingReminder != nil ? String(localized: "reminder.action.save_edit") : String(localized: "reminder.action.save_new"),
            icon: "checkmark.seal.fill",
            variant: vm.isValid ? .primary : .secondary,
            size: .large,
            isFullWidth: true
        ) {
            guard !didFinish else { return }
            guard let reminder = vm.save() else {
                focusedField = .title
                return
            }
            didFinish = true
            VNHaptics.impact(.success, enabled: hapticFeedbackEnabled)
            onSave(reminder)
            router.dismissModals()
        }
        .accessibilityHint(vm.isValid ? "" : Self.titleRequiredMessage)
        .padding(.top, VNSpacing.md)
    }
}
