import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem
import VNCalendarLunar

public struct ReminderFormView: View {
    @Environment(\.dismiss) private var dismiss
    public var onSave: (ReminderEvent) -> Void

    @FocusState private var isTitleFocused: Bool

    @State private var title: String = ""
    @State private var category: ReminderCategory = .deathAnniversary
    @State private var dateType: CalendarDateType = .lunar
    @State private var day: Int = 1
    @State private var month: Int = 1
    @State private var year: String = ""
    @State private var isLeapMonth = false
    @State private var recurrence: RecurrenceRule = .yearly
    @State private var relationship: String = "Ông"
    @State private var note: String = ""

    // Advance Offsets
    @State private var notifyOnDay = true
    @State private var notify1DayBefore = true
    @State private var notify3DaysBefore = true
    @State private var notify7DaysBefore = true
    @State private var notify14DaysBefore = false
    @State private var notify30DaysBefore = false

    private let existingReminder: ReminderEvent?

    public init(
        existingReminder: ReminderEvent? = nil,
        initialDate: Date? = nil,
        onSave: @escaping (ReminderEvent) -> Void
    ) {
        self.existingReminder = existingReminder
        self.onSave = onSave

        if let existing = existingReminder {
            _title = State(initialValue: existing.title)
            _category = State(initialValue: existing.category)
            _dateType = State(initialValue: existing.dateType)
            _day = State(initialValue: existing.day)
            _month = State(initialValue: existing.month)
            _year = State(initialValue: existing.year.map(String.init) ?? "")
            _isLeapMonth = State(initialValue: existing.isLeapMonth)
            _recurrence = State(initialValue: existing.recurrence)
            _relationship = State(initialValue: existing.relationship ?? "Ông")
            _note = State(initialValue: existing.note ?? "")

            let offsets = Set(existing.alertOffsets)
            _notifyOnDay = State(initialValue: offsets.contains(0))
            _notify1DayBefore = State(initialValue: offsets.contains(-1))
            _notify3DaysBefore = State(initialValue: offsets.contains(-3))
            _notify7DaysBefore = State(initialValue: offsets.contains(-7))
            _notify14DaysBefore = State(initialValue: offsets.contains(-14))
            _notify30DaysBefore = State(initialValue: offsets.contains(-30))
        } else if let date = initialDate {
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = VNTime.vietnam
            _day = State(initialValue: cal.component(.day, from: date))
            _month = State(initialValue: cal.component(.month, from: date))
        }
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: VNSpacing.xl) {
                    ReminderHeaderView(
                        isEditing: existingReminder != nil,
                        day: day,
                        month: month,
                        year: year,
                        dateType: dateType,
                        isLeapMonth: isLeapMonth
                    )
                    ReminderCategoryGrid(selectedCategory: $category)
                    ReminderTitleSection(
                        title: $title,
                        relationship: $relationship,
                        isFocused: $isTitleFocused
                    )
                    ReminderDatePickerCard(
                        dateType: $dateType,
                        day: $day,
                        month: $month,
                        year: $year,
                        isLeapMonth: $isLeapMonth
                    )
                    ReminderOffsetsCard(
                        notifyOnDay: $notifyOnDay,
                        notify1DayBefore: $notify1DayBefore,
                        notify3DaysBefore: $notify3DaysBefore,
                        notify7DaysBefore: $notify7DaysBefore,
                        notify14DaysBefore: $notify14DaysBefore,
                        notify30DaysBefore: $notify30DaysBefore
                    )
                    notesSection
                    saveActionButton
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
                    .foregroundColor(.vnAccentHeritageRed)
                    .font(.system(size: 14, weight: .bold))
                }
            }
        }
    }

    @ViewBuilder
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: VNSpacing.sm) {
            Text("GHI CHÚ / PHÂN CÔNG CÚNG GIỖ")
                .font(.vnCaption2)
                .fontWeight(.medium)
                .tracking(0.66)
                .foregroundColor(.vnAccentImperialGold)

            VNCard(
                allPadding: VNSpacing.xl,
                cornerRadius: VNCornerRadius.card,
                backgroundColor: Color.vnBackgroundSecondary,
                borderColor: Color.vnAccentImperialGold.opacity(0.28),
                shadow: nil
            ) {
                TextEditor(text: $note)
                    .font(.vnCallout)
                    .foregroundColor(.vnTextPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 70)
                    .accessibilityLabel("Ghi chú / phân công cúng giỗ")
            }
        }
    }

    @ViewBuilder
    private var saveActionButton: some View {
        VNButton(
            existingReminder != nil ? "Lưu Thay Đổi" : "Lưu Ngày Lễ",
            icon: "checkmark.seal.fill",
            variant: title.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary : .primary,
            size: .large,
            isFullWidth: true
        ) {
            saveAndDismiss()
        }
        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
        .padding(.top, VNSpacing.md)
    }

    private func saveAndDismiss() {
        var offsets: [Int] = []
        if notifyOnDay { offsets.append(0) }
        if notify1DayBefore { offsets.append(-1) }
        if notify3DaysBefore { offsets.append(-3) }
        if notify7DaysBefore { offsets.append(-7) }
        if notify14DaysBefore { offsets.append(-14) }
        if notify30DaysBefore { offsets.append(-30) }
        if offsets.isEmpty { offsets.append(0) }

        let parsedYear = Int(year.trimmingCharacters(in: .whitespaces))
        let newOrUpdated = ReminderEvent(
            id: existingReminder?.id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespaces),
            category: category,
            dateType: dateType,
            day: day,
            month: month,
            year: parsedYear,
            isLeapMonth: isLeapMonth,
            recurrence: recurrence,
            alertOffsets: offsets,
            note: note.isEmpty ? nil : note,
            relationship: relationship,
            createdAt: existingReminder?.createdAt ?? Date(),
            updatedAt: Date()
        )

        onSave(newOrUpdated)
        dismiss()
    }
}
