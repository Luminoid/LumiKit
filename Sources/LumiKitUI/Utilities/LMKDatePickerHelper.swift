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

        public init(
            confirm: String = "OK",
            fromLabel: String = "From",
            toLabel: String = "To",
            textFieldPlaceholder: String = "Add notes..."
        ) {
            self.confirm = confirm
            self.fromLabel = fromLabel
            self.toLabel = toLabel
            self.textFieldPlaceholder = textFieldPlaceholder
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
        let minimumDate: Date?

        if excludeToday {
            minimumDate = LMKDateHelper.calendar.date(byAdding: .day, value: 1, to: today)
        } else {
            minimumDate = today
        }

        // Clamp: if defaultDate is in the past, snap to minimumDate
        let defaultDateValue: Date
        if let requested = defaultDate {
            defaultDateValue = clampedDate(requested, min: minimumDate, max: nil)
        } else {
            defaultDateValue = minimumDate ?? today
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
        textField.borderStyle = .roundedRect
        textField.font = LMKTypography.body
        textField.textColor = LMKColor.textPrimary
        textField.backgroundColor = LMKColor.backgroundSecondary

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
