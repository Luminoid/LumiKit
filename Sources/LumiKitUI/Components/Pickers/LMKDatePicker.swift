//
//  LMKDatePicker.swift
//  LumiKit
//
//  Date picking in an action sheet: one date from a configuration, a From / To
//  range, a single-calendar range, and a date with a notes field.
//

import LumiKitCore
import UIKit

/// Presents `UIDatePicker` flows inside `LMKActionSheet`.
///
/// ```swift
/// LMKDatePicker.present(.past(title: "Log Event"), from: self) { date in log(date) }
/// LMKDatePicker.present(.future(title: "Schedule", excludingToday: true), from: self) { date in schedule(date) }
/// LMKDatePicker.presentRange(from: self, title: "Trip") { start, end in ... }
/// ```
///
/// Bounds are normalized (a minimum past the maximum swaps them) and the initial
/// date is clamped into them, so a stale default never leaves the picker unusable.
/// Every presenter takes an `onCancel` that runs when the sheet goes away without
/// confirming (Cancel, dimming tap, drag, key command).
///
/// `Configuration.pickerStyle` is the request; the picker on screen uses
/// `Configuration.resolvedPickerStyle(for:)`, which swaps `.wheels` for the style Apple
/// uses under the Mac idiom (`.inline` for dates, `.compact` for a time), where a wheel
/// picker is not supported and would throw on its way into a window.
public enum LMKDatePicker {
    // MARK: - Configuration

    public nonisolated struct Configuration: Sendable, Equatable {
        public nonisolated enum Mode: Sendable, Hashable, CaseIterable {
            case date
            case time
            case dateAndTime
        }

        public nonisolated enum PickerStyle: Sendable, Hashable, CaseIterable {
            case wheels
            case inline
            case compact
        }

        public var title: String
        public var message: String?
        public var mode: Mode
        /// The requested style; see `resolvedPickerStyle(for:)` for the one that shows.
        public var pickerStyle: PickerStyle
        /// The initial date; `nil` = today (clamped into the bounds).
        public var initial: Date?
        public var minimum: Date?
        public var maximum: Date?
        /// `nil` = `LMKDate.calendar`.
        public var calendar: Calendar?
        /// `nil` = the current locale.
        public var locale: Locale?

        public init(
            title: String,
            message: String? = nil,
            mode: Mode = .date,
            pickerStyle: PickerStyle = .wheels,
            initial: Date? = nil,
            minimum: Date? = nil,
            maximum: Date? = nil,
            calendar: Calendar? = nil,
            locale: Locale? = nil
        ) {
            self.title = title
            self.message = message
            self.mode = mode
            self.pickerStyle = pickerStyle
            self.initial = initial
            self.minimum = minimum
            self.maximum = maximum
            self.calendar = calendar
            self.locale = locale
        }

        /// Past dates only (through today).
        public static func past(title: String, message: String? = nil, initial: Date? = nil) -> Self {
            Self(title: title, message: message, initial: initial, maximum: LMKDate.today)
        }

        /// Future dates only (from today, or tomorrow with `excludingToday`).
        public static func future(title: String, message: String? = nil, initial: Date? = nil, excludingToday: Bool = false) -> Self {
            let today = LMKDate.today
            let minimum = excludingToday ? (LMKDate.calendar.date(byAdding: .day, value: 1, to: today) ?? today) : today
            return Self(title: title, message: message, initial: initial, minimum: minimum)
        }

        /// The bounds with an inverted pair swapped.
        public var resolvedBounds: (minimum: Date?, maximum: Date?) {
            if let minimum, let maximum, minimum > maximum {
                return (maximum, minimum)
            }
            return (minimum, maximum)
        }

        /// The initial date clamped into the resolved bounds.
        public var resolvedInitial: Date {
            var date = initial ?? LMKDate.today
            let bounds = resolvedBounds
            if let minimum = bounds.minimum { date = max(date, minimum) }
            if let maximum = bounds.maximum { date = min(date, maximum) }
            return date
        }

        /// The style the picker shows under `idiom`: `pickerStyle`, except that `.wheels` under
        /// the Mac idiom becomes `.inline` (date modes) or `.compact` (time), the styles Apple
        /// uses there. A wheel picker throws when it enters a window in a Mac-idiom Catalyst app.
        public func resolvedPickerStyle(for idiom: UIUserInterfaceIdiom) -> PickerStyle {
            guard idiom == .mac, pickerStyle == .wheels else { return pickerStyle }
            return mode == .time ? .compact : .inline
        }
    }

    // MARK: - Strings

    public nonisolated struct Strings: Sendable, Equatable {
        public var confirm: String
        public var fromLabel: String
        public var toLabel: String
        public var textFieldPlaceholder: String
        /// Summary shown by the calendar range picker before anything is tapped.
        public var selectDatesPrompt: String

        public init(
            confirm: String = LMKLocalized("datePicker.confirm"),
            fromLabel: String = LMKLocalized("datePicker.from"),
            toLabel: String = LMKLocalized("datePicker.to"),
            textFieldPlaceholder: String = LMKLocalized("datePicker.textFieldPlaceholder"),
            selectDatesPrompt: String = LMKLocalized("datePicker.selectDatesPrompt")
        ) {
            self.confirm = confirm
            self.fromLabel = fromLabel
            self.toLabel = toLabel
            self.textFieldPlaceholder = textFieldPlaceholder
            self.selectDatesPrompt = selectDatesPrompt
        }
    }

    /// Process-wide defaults; set at app launch to override.
    public nonisolated(unsafe) static var strings = Strings()

    private static var defaultRangeEndDate: Date {
        LMKDate.calendar.date(byAdding: .weekOfYear, value: 4, to: LMKDate.today) ?? LMKDate.today
    }

    // MARK: - Single date

    /// Presents one date picker; `onConfirm` receives the picked date after the sheet closes.
    @discardableResult
    public static func present(
        _ configuration: Configuration,
        from host: UIViewController,
        strings: Strings = Self.strings,
        onConfirm: @escaping (Date) -> Void,
        onCancel: (() -> Void)? = nil
    ) -> LMKActionSheetViewController {
        let picker = makePicker(configuration)
        return LMKActionSheet.present(LMKActionSheet.Configuration(
            title: configuration.title,
            message: configuration.message,
            contentView: picker,
            confirmTitle: strings.confirm,
            onConfirm: { onConfirm(picker.date) },
            onCancel: onCancel
        ), from: host)
    }

    /// Presents a date picker built from the arguments (bounds are optional and normalized).
    @discardableResult
    public static func present(
        from host: UIViewController,
        title: String,
        message: String? = nil,
        initial: Date? = nil,
        minimum: Date? = nil,
        maximum: Date? = nil,
        strings: Strings = Self.strings,
        onConfirm: @escaping (Date) -> Void,
        onCancel: (() -> Void)? = nil
    ) -> LMKActionSheetViewController {
        present(
            Configuration(title: title, message: message, initial: initial, minimum: minimum, maximum: maximum),
            from: host,
            strings: strings,
            onConfirm: onConfirm,
            onCancel: onCancel
        )
    }

    // MARK: - Range

    /// Presents two compact pickers (From / To). Moving one past the other drags the other along.
    @discardableResult
    public static func presentRange(
        from host: UIViewController,
        title: String,
        message: String? = nil,
        start: Date? = nil,
        end: Date? = nil,
        strings: Strings = Self.strings,
        onConfirm: @escaping (Date, Date) -> Void,
        onCancel: (() -> Void)? = nil
    ) -> LMKActionSheetViewController {
        let startDate = start ?? LMKDate.today
        let endDate = end ?? defaultRangeEndDate
        let fromPicker = makePicker(Configuration(title: title, pickerStyle: .compact, initial: min(startDate, endDate)))
        let toPicker = makePicker(Configuration(title: title, pickerStyle: .compact, initial: max(startDate, endDate)))
        // Weak: each picker retains its action, and a strong capture of the pair would keep
        // both alive after the sheet is gone.
        fromPicker.addAction(UIAction { [weak fromPicker, weak toPicker] _ in
            guard let fromPicker, let toPicker else { return }
            if fromPicker.date > toPicker.date { toPicker.date = fromPicker.date }
        }, for: .valueChanged)
        toPicker.addAction(UIAction { [weak fromPicker, weak toPicker] _ in
            guard let fromPicker, let toPicker else { return }
            if toPicker.date < fromPicker.date { fromPicker.date = toPicker.date }
        }, for: .valueChanged)

        // A static presenter builds a one-shot stack for the sheet; there is no theme argument or component to re-apply it.
        // swiftlint:disable:next no_global_token_proxies_in_components
        let rows = UIStackView(lmk_axis: .vertical, spacing: LMKSpacing.large)
        rows.addArrangedSubview(makeRow(label: strings.fromLabel, picker: fromPicker))
        rows.addArrangedSubview(makeRow(label: strings.toLabel, picker: toPicker))

        return LMKActionSheet.present(LMKActionSheet.Configuration(
            title: title,
            message: message,
            contentView: rows,
            confirmTitle: strings.confirm,
            onConfirm: { onConfirm(fromPicker.date.lmk_startOfDay, toPicker.date.lmk_startOfDay) },
            onCancel: onCancel
        ), from: host)
    }

    /// Presents one calendar for the whole range. The first tap sets the start, a later tap the
    /// end, an earlier tap re-anchors, and any tap once a range exists starts over. `onConfirm`
    /// fires only when something is selected.
    @discardableResult
    public static func presentCalendarRange(
        from host: UIViewController,
        title: String,
        message: String? = nil,
        start: Date? = nil,
        end: Date? = nil,
        strings: Strings = Self.strings,
        onConfirm: @escaping (Date, Date) -> Void,
        onCancel: (() -> Void)? = nil
    ) -> LMKActionSheetViewController {
        let rangeView = LMKCalendarRangeSelectionView(startDate: start, endDate: end)
        rangeView.strings = strings
        return LMKActionSheet.present(LMKActionSheet.Configuration(
            title: title,
            message: message,
            contentView: rangeView,
            confirmTitle: strings.confirm,
            onConfirm: {
                if let range = rangeView.selectedRange {
                    onConfirm(range.lowerBound, range.upperBound)
                }
            },
            onCancel: onCancel
        ), from: host)
    }

    // MARK: - Date with notes

    /// Presents a date picker with a notes field above it; `onConfirm` receives the date and the
    /// trimmed notes (`nil` when empty).
    @discardableResult
    public static func presentWithTextField(
        _ configuration: Configuration,
        from host: UIViewController,
        placeholder: String? = nil,
        strings: Strings = Self.strings,
        onConfirm: @escaping (Date, String?) -> Void,
        onCancel: (() -> Void)? = nil
    ) -> LMKActionSheetViewController {
        let field = LMKTextField()
        field.placeholder = placeholder ?? strings.textFieldPlaceholder
        field.textField.autocapitalizationType = .sentences
        field.textField.lmk_dismissKeyboardOnReturn()
        let picker = makePicker(configuration)
        // A static presenter builds a one-shot stack for the sheet; there is no theme argument or component to re-apply it.
        // swiftlint:disable:next no_global_token_proxies_in_components
        let stack = UIStackView(lmk_axis: .vertical, spacing: LMKSpacing.medium)
        stack.addArrangedSubview(field)
        stack.addArrangedSubview(picker)
        return LMKActionSheet.present(LMKActionSheet.Configuration(
            title: configuration.title,
            message: configuration.message,
            contentView: stack,
            confirmTitle: strings.confirm,
            onConfirm: {
                let notes = field.text?.trimmingCharacters(in: .whitespacesAndNewlines)
                onConfirm(picker.date, notes.lmk_nonEmpty)
            },
            onCancel: onCancel
        ), from: host)
    }

    // MARK: - Helpers

    /// A `UIDatePicker` configured from `configuration`: bounds normalized, the date clamped, and
    /// the style resolved for the running idiom (`Configuration.resolvedPickerStyle(for:)`).
    public static func makePicker(_ configuration: Configuration) -> UIDatePicker {
        let picker = UIDatePicker()
        picker.datePickerMode = switch configuration.mode {
        case .date: .date
        case .time: .time
        case .dateAndTime: .dateAndTime
        }
        picker.preferredDatePickerStyle = switch configuration.resolvedPickerStyle(for: UIDevice.current.userInterfaceIdiom) {
        case .wheels: .wheels
        case .inline: .inline
        case .compact: .compact
        }
        picker.calendar = configuration.calendar ?? LMKDate.calendar
        picker.locale = configuration.locale
        let bounds = configuration.resolvedBounds
        picker.minimumDate = bounds.minimum
        picker.maximumDate = bounds.maximum
        picker.date = configuration.resolvedInitial
        return picker
    }

    private static func makeRow(label text: String, picker: UIDatePicker) -> UIStackView {
        let label = UILabel.lmk_make(.bodyMedium, text: text, color: LMKColor.textPrimary, numberOfLines: 1)
        // A static presenter builds a one-shot row for the sheet; there is no theme argument or component to re-apply it.
        // swiftlint:disable:next no_global_token_proxies_in_components
        let row = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.medium)
        row.alignment = .center
        row.addArrangedSubview(label)
        row.addArrangedSubview(picker)
        return row
    }
}
