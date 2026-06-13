//
//  LMKDatePickerHelper.swift
//  LumiKit
//
//  Reusable date picker presentation using LMKActionSheet.
//

import LumiKitCore
import SnapKit
import UIKit

/// Helper for presenting date pickers using LMKActionSheet.
///
/// Provides convenience methods for common date-picking patterns:
/// single date (past/future), date range, and date with text field.
///
/// Configure localized strings at app launch:
/// ```swift
/// LMKDatePickerHelper.strings = .init(
///     confirm: "OK",
///     fromLabel: "From",
///     toLabel: "To",
///     textFieldPlaceholder: "Add notes..."
/// )
/// ```
public enum LMKDatePickerHelper {
    // MARK: - Configurable Strings

    public nonisolated struct Strings: Sendable {
        public var confirm: String
        public var fromLabel: String
        public var toLabel: String
        public var textFieldPlaceholder: String
        /// Summary shown by the calendar range picker before anything is tapped.
        public var selectDatesPrompt: String

        public init(
            confirm: String = "OK",
            fromLabel: String = "From",
            toLabel: String = "To",
            textFieldPlaceholder: String = "Add notes...",
            selectDatesPrompt: String = "Select dates"
        ) {
            self.confirm = confirm
            self.fromLabel = fromLabel
            self.toLabel = toLabel
            self.textFieldPlaceholder = textFieldPlaceholder
            self.selectDatesPrompt = selectDatesPrompt
        }
    }

    public nonisolated(unsafe) static var strings = Strings()

    // MARK: - Constants

    private static var defaultRangeEndDate: Date {
        LMKDateHelper.calendar.date(byAdding: .weekOfYear, value: 4, to: LMKDateHelper.today) ?? LMKDateHelper.today
    }

    private static let pickerHeight: CGFloat = 200

    // MARK: - Helpers

    /// Clamp a date to the given bounds. If min > max, swaps them.
    private static func clampedDate(_ date: Date, min: Date?, max: Date?) -> Date {
        var result = date
        if let min { result = Swift.max(result, min) }
        if let max { result = Swift.min(result, max) }
        return result
    }

    // MARK: - Date Picker (Photo Flows)

    /// Present a date picker action sheet for photo edit / select date flows.
    public static func presentDatePickerAlert(
        on viewController: UIViewController,
        title: String,
        defaultDate: Date,
        maximumDate: Date = LMKDateHelper.today,
        onConfirm: @escaping (Date) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        let clamped = clampedDate(defaultDate, min: nil, max: maximumDate)

        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.maximumDate = maximumDate
        datePicker.date = clamped

        LMKActionSheet.present(
            in: viewController,
            title: title,
            contentView: datePicker,
            contentHeight: pickerHeight,
            confirmTitle: strings.confirm,
            onConfirm: { onConfirm(datePicker.date) },
            onDismiss: onCancel
        )
    }

    // MARK: - Date Picker (General)

    /// Present a date picker for selecting a date (past dates allowed).
    public static func presentDatePicker(
        on viewController: UIViewController,
        title: String,
        message: String? = nil,
        defaultDate: Date = LMKDateHelper.today,
        maximumDate: Date? = LMKDateHelper.today,
        minimumDate: Date? = nil,
        onConfirm: @escaping (Date) -> Void
    ) {
        // Swap if caller passed min > max
        let resolvedMin: Date?
        let resolvedMax: Date?
        if let lo = minimumDate, let hi = maximumDate, lo > hi {
            resolvedMin = hi
            resolvedMax = lo
        } else {
            resolvedMin = minimumDate
            resolvedMax = maximumDate
        }

        let clamped = clampedDate(defaultDate, min: resolvedMin, max: resolvedMax)

        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.minimumDate = resolvedMin
        datePicker.maximumDate = resolvedMax
        datePicker.date = clamped

        LMKActionSheet.present(
            in: viewController,
            title: title,
            message: message,
            contentView: datePicker,
            contentHeight: pickerHeight,
            confirmTitle: strings.confirm,
            onConfirm: { onConfirm(datePicker.date) }
        )
    }

    /// Present a date picker for selecting a future date (rescheduling).
    public static func presentFutureDatePicker(
        on viewController: UIViewController,
        title: String,
        message: String? = nil,
        defaultDate: Date? = nil,
        excludeToday: Bool = false,
        onConfirm: @escaping (Date) -> Void
    ) {
        let today = LMKDateHelper.today
        let minimumDate: Date? = if excludeToday {
            LMKDateHelper.calendar.date(byAdding: .day, value: 1, to: today)
        } else {
            today
        }

        // Clamp: if defaultDate is in the past, snap to minimumDate
        let defaultDateValue: Date = if let requested = defaultDate {
            clampedDate(requested, min: minimumDate, max: nil)
        } else {
            minimumDate ?? today
        }

        presentDatePicker(
            on: viewController,
            title: title,
            message: message,
            defaultDate: defaultDateValue,
            maximumDate: nil,
            minimumDate: minimumDate,
            onConfirm: onConfirm
        )
    }

    /// Present a date picker for selecting a past date (logging past events).
    public static func presentPastDatePicker(
        on viewController: UIViewController,
        title: String,
        message: String? = nil,
        defaultDate: Date = LMKDateHelper.today,
        onConfirm: @escaping (Date) -> Void
    ) {
        presentDatePicker(
            on: viewController,
            title: title,
            message: message,
            defaultDate: defaultDate,
            maximumDate: LMKDateHelper.today,
            minimumDate: nil,
            onConfirm: onConfirm
        )
    }

    // MARK: - Date Range Picker

    /// Present two compact date pickers (From / To) for selecting a date range.
    public static func presentDateRangePicker(
        on viewController: UIViewController,
        title: String,
        message: String? = nil,
        defaultStartDate: Date = LMKDateHelper.today,
        defaultEndDate: Date? = nil,
        onConfirm: @escaping (Date, Date) -> Void
    ) {
        let endDate = defaultEndDate ?? defaultRangeEndDate
        // Normalize so start <= end for initial display
        let resolvedStart = min(defaultStartDate, endDate)
        let resolvedEnd = max(defaultStartDate, endDate)

        let fromLabel = UILabel()
        fromLabel.text = strings.fromLabel
        fromLabel.font = LMKTypography.bodyMedium
        fromLabel.textColor = LMKColor.textPrimary

        let fromPicker = UIDatePicker()
        fromPicker.datePickerMode = .date
        fromPicker.preferredDatePickerStyle = .compact
        fromPicker.date = resolvedStart

        let toPicker = UIDatePicker()
        toPicker.datePickerMode = .date
        toPicker.preferredDatePickerStyle = .compact
        toPicker.date = resolvedEnd

        // Live enforcement: if From moves past To, snap To forward (and vice versa)
        fromPicker.addAction(UIAction { _ in
            if fromPicker.date > toPicker.date {
                toPicker.date = fromPicker.date
            }
        }, for: .valueChanged)

        toPicker.addAction(UIAction { _ in
            if toPicker.date < fromPicker.date {
                fromPicker.date = toPicker.date
            }
        }, for: .valueChanged)

        let fromStack = UIStackView(arrangedSubviews: [fromLabel, fromPicker])
        fromStack.axis = .horizontal
        fromStack.alignment = .center
        fromStack.spacing = LMKSpacing.medium

        let toLabel = UILabel()
        toLabel.text = strings.toLabel
        toLabel.font = LMKTypography.bodyMedium
        toLabel.textColor = LMKColor.textPrimary

        let toStack = UIStackView(arrangedSubviews: [toLabel, toPicker])
        toStack.axis = .horizontal
        toStack.alignment = .center
        toStack.spacing = LMKSpacing.medium

        let containerStack = UIStackView(arrangedSubviews: [fromStack, toStack])
        containerStack.axis = .vertical
        containerStack.spacing = LMKSpacing.large

        let contentHeight: CGFloat = 90

        LMKActionSheet.present(
            in: viewController,
            title: title,
            message: message,
            contentView: containerStack,
            contentHeight: contentHeight,
            confirmTitle: strings.confirm,
            onConfirm: {
                onConfirm(fromPicker.date.lmk_startOfDay, toPicker.date.lmk_startOfDay)
            }
        )
    }

    // MARK: - Calendar Range Picker

    private static let calendarRangeContentHeight: CGFloat = 440

    /// Present a single calendar (UICalendarView) for selecting a date range.
    ///
    /// Nothing is selected until the user taps, unless `defaultStartDate` /
    /// `defaultEndDate` seed an existing range. The first tap sets the start, a
    /// later tap sets the end, an earlier tap re-anchors the start, and any tap
    /// once a full range exists resets and begins a new selection. `onConfirm`
    /// fires only when a selection exists — confirming an empty calendar is a
    /// no-op, leaving the caller's dates unchanged.
    public static func presentCalendarRangePicker(
        on viewController: UIViewController,
        title: String,
        message: String? = nil,
        defaultStartDate: Date? = nil,
        defaultEndDate: Date? = nil,
        onConfirm: @escaping (Date, Date) -> Void
    ) {
        let rangeView = LMKCalendarRangeSelectionView(
            startDate: defaultStartDate,
            endDate: defaultEndDate
        )
        LMKActionSheet.present(
            in: viewController,
            title: title,
            message: message,
            contentView: rangeView,
            contentHeight: calendarRangeContentHeight,
            confirmTitle: strings.confirm,
            onConfirm: {
                if let range = rangeView.selectedRange {
                    onConfirm(range.start, range.end)
                }
            }
        )
    }

    // MARK: - Date Picker with Text Field

    private static let textFieldHeight: CGFloat = LMKLayout.minimumTouchTarget
    private static let contentWithTextFieldHeight: CGFloat = textFieldHeight + LMKSpacing.medium + pickerHeight

    /// Present a date picker with an optional text field for notes.
    ///
    /// - Parameter textFieldPlaceholder: Override the default placeholder from `strings.textFieldPlaceholder`.
    public static func presentDatePickerWithTextField(
        on viewController: UIViewController,
        title: String,
        message: String? = nil,
        defaultDate: Date = LMKDateHelper.today,
        textFieldPlaceholder: String? = nil,
        onConfirm: @escaping (Date, String?) -> Void
    ) {
        let textField = UITextField()
        textField.placeholder = textFieldPlaceholder ?? strings.textFieldPlaceholder
        textField.autocapitalizationType = .sentences
        textField.returnKeyType = .done
        textField.borderStyle = .roundedRect
        textField.font = LMKTypography.body
        textField.textColor = LMKColor.textPrimary
        textField.backgroundColor = LMKColor.backgroundSecondary
        textField.addTarget(textField, action: #selector(UIResponder.resignFirstResponder), for: .editingDidEndOnExit)

        let maxDate = LMKDateHelper.today
        let clamped = clampedDate(defaultDate, min: nil, max: maxDate)

        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.maximumDate = maxDate
        datePicker.date = clamped

        let container = UIStackView(arrangedSubviews: [textField, datePicker])
        container.axis = .vertical
        container.spacing = LMKSpacing.medium

        textField.snp.makeConstraints { make in
            make.height.equalTo(Self.textFieldHeight)
        }
        datePicker.snp.makeConstraints { make in
            make.height.equalTo(Self.pickerHeight)
        }

        LMKActionSheet.present(
            in: viewController,
            title: title,
            message: message,
            contentView: container,
            contentHeight: contentWithTextFieldHeight,
            confirmTitle: strings.confirm,
            onConfirm: {
                let notes = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
                let finalNotes = notes.nonEmpty
                onConfirm(datePicker.date, finalNotes)
            }
        )
    }
}

// MARK: - Calendar range selection view

/// Single-calendar range selection backing `presentCalendarRangePicker`: a live
/// range summary over a `UICalendarView` whose multi-date selection renders every
/// day of the range. Selection is a pure state machine (`next(after:tapping:)`):
/// nothing is selected until the first tap, the second tap closes the range, and
/// any tap once a full range exists resets and starts over.
final class LMKCalendarRangeSelectionView: UIView {
    /// Reduced selection state. A `.range` is always normalized so `start <= end`
    /// (a single-day range has `start == end`).
    enum Selection: Equatable {
        case empty
        case start(Date)
        case range(Date, Date)
    }

    private(set) var selection: Selection

    /// The chosen range, or nil when nothing is selected. A lone start resolves
    /// to a single day; callers confirm against this.
    var selectedRange: (start: Date, end: Date)? {
        switch selection {
        case .empty: nil
        case let .start(day): (day, day)
        case let .range(start, end): (start, end)
        }
    }

    private let calendar = LMKDateHelper.calendar
    private var multiDateSelection: UICalendarSelectionMultiDate?

    /// Display cap: a selection is rebuilt date-by-date, so an absurd range
    /// (a typo'd year) must not enumerate thousands of components.
    private static let maxSelectedDays = 366

    private static let intervalFormatter: DateIntervalFormatter = {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private let summaryLabel = UILabel()
    private let calendarView = UICalendarView()

    init(startDate: Date?, endDate: Date?) {
        let calendar = LMKDateHelper.calendar
        selection = Self.initialSelection(startDate: startDate, endDate: endDate, calendar: calendar)
        super.init(frame: .zero)
        setupUI()
        refreshSelection()
        refreshSummary()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Tap reduction

    /// Seeds the initial state from caller-provided defaults: nil/nil stays
    /// empty (nothing pre-selected), a start alone shows one day, both show the
    /// normalized range.
    nonisolated static func initialSelection(startDate: Date?, endDate: Date?, calendar: Calendar) -> Selection {
        guard let startDate else { return .empty }
        let start = calendar.startOfDay(for: startDate)
        guard let endDate else { return .start(start) }
        let end = calendar.startOfDay(for: endDate)
        return end <= start ? .range(start, start) : .range(start, end)
    }

    /// The next state after tapping `day`: the first tap starts the range, a
    /// later tap closes it (an earlier tap re-anchors), and any tap once a full
    /// range exists resets and begins a new selection.
    nonisolated static func next(after selection: Selection, tapping day: Date, calendar: Calendar) -> Selection {
        let day = calendar.startOfDay(for: day)
        switch selection {
        case .empty:
            return .start(day)
        case let .start(anchor):
            let anchor = calendar.startOfDay(for: anchor)
            return day < anchor ? .start(day) : .range(anchor, day)
        case .range:
            return .start(day)
        }
    }

    // MARK: - Setup

    private func setupUI() {
        summaryLabel.font = LMKTypography.bodyMedium
        summaryLabel.textColor = LMKColor.textPrimary
        summaryLabel.textAlignment = .center
        summaryLabel.adjustsFontForContentSizeCategory = true

        let selectionBehavior = UICalendarSelectionMultiDate(delegate: self)
        multiDateSelection = selectionBehavior
        calendarView.selectionBehavior = selectionBehavior
        calendarView.calendar = calendar
        calendarView.locale = .current
        calendarView.tintColor = LMKColor.primary
        let visibleAnchor = selectedRange?.start ?? LMKDateHelper.today
        calendarView.visibleDateComponents = calendar.dateComponents([.year, .month], from: visibleAnchor)

        addSubview(summaryLabel)
        addSubview(calendarView)
        summaryLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        calendarView.snp.makeConstraints { make in
            make.top.equalTo(summaryLabel.snp.bottom).offset(LMKSpacing.xs)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    // MARK: - State

    private func apply(_ next: Selection) {
        selection = next
        refreshSelection()
        refreshSummary()
    }

    private func refreshSelection() {
        guard let multiDateSelection else { return }
        var components: [DateComponents] = []
        if let range = selectedRange {
            var day = range.start
            while day <= range.end, components.count < Self.maxSelectedDays {
                components.append(calendar.dateComponents([.year, .month, .day], from: day))
                guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
                day = next
            }
        }
        multiDateSelection.setSelectedDates(components, animated: false)
    }

    private func refreshSummary() {
        if let range = selectedRange {
            summaryLabel.text = Self.intervalFormatter.string(from: range.start, to: range.end)
        } else {
            summaryLabel.text = LMKDatePickerHelper.strings.selectDatesPrompt
        }
        summaryLabel.accessibilityLabel = summaryLabel.text
    }
}

// MARK: - UICalendarSelectionMultiDateDelegate

extension LMKCalendarRangeSelectionView: UICalendarSelectionMultiDateDelegate {
    /// Selecting and deselecting are the same gesture here: any tapped day runs
    /// through the reducer (a tap inside the current range arrives as a deselect,
    /// but still means "reset and start a new selection here").
    func multiDateSelection(_: UICalendarSelectionMultiDate, didSelectDate dateComponents: DateComponents) {
        handleTap(dateComponents)
    }

    func multiDateSelection(_: UICalendarSelectionMultiDate, didDeselectDate dateComponents: DateComponents) {
        handleTap(dateComponents)
    }

    func multiDateSelection(_: UICalendarSelectionMultiDate, canSelectDate _: DateComponents) -> Bool {
        true
    }

    func multiDateSelection(_: UICalendarSelectionMultiDate, canDeselectDate _: DateComponents) -> Bool {
        true
    }

    private func handleTap(_ dateComponents: DateComponents) {
        guard let day = calendar.date(from: dateComponents) else {
            refreshSelection()
            return
        }
        apply(Self.next(after: selection, tapping: day, calendar: calendar))
    }
}
