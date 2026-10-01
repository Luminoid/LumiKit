//
//  LMKCalendarRangeSelectionView.swift
//  LumiKit
//
//  A live range summary over a UICalendarView whose multi-date selection
//  renders every day of the range. Selection runs through the shared
//  `LMKCalendarSelection` reducer in range mode, styled from
//  `theme.calendarRangeSelection`.
//

import LumiKitCore
import SnapKit
import UIKit

/// Single-calendar date range selection: nothing is selected until the first tap,
/// the second tap closes the range, an earlier tap re-anchors, and any tap once a
/// full range exists starts over.
///
/// ```swift
/// let picker = LMKCalendarRangeSelectionView(startDate: trip.start, endDate: trip.end)
/// picker.onSelectionChange = { selection in ... }
/// if let range = picker.selectedRange { ... }
/// ```
public final class LMKCalendarRangeSelectionView: UIView, LMKThemeApplying {
    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// `nil` = `bodyMedium`.
        public var summaryTextStyle: LMKTextStyle?
        /// `nil` = `textPrimary`.
        public var summaryColor: UIColor?
        /// The calendar's selection tint; `nil` = `primary`.
        public var tintColor: UIColor?
        /// Gap between the summary and the calendar; `nil` = `xs`.
        public var spacing: CGFloat?

        public init(
            summaryTextStyle: LMKTextStyle? = nil,
            summaryColor: UIColor? = nil,
            tintColor: UIColor? = nil,
            spacing: CGFloat? = nil
        ) {
            self.summaryTextStyle = summaryTextStyle
            self.summaryColor = summaryColor
            self.tintColor = tintColor
            self.spacing = spacing
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                summaryTextStyle: other.summaryTextStyle ?? summaryTextStyle,
                summaryColor: other.summaryColor ?? summaryColor,
                tintColor: other.tintColor ?? tintColor,
                spacing: other.spacing ?? spacing
            )
        }
    }

    // MARK: - Properties

    /// The reduced selection (`empty`, `start`, or `range`).
    public private(set) var selection: LMKCalendarSelection {
        didSet { onSelectionChange?(selection) }
    }

    /// The chosen days, or `nil` while nothing is selected. A lone start is a single day.
    public var selectedDays: ClosedRange<LMKCalendarDay>? {
        selection.selectedRange
    }

    /// `selectedDays` as start-of-day dates in the view's calendar.
    public var selectedRange: ClosedRange<Date>? {
        guard let days = selectedDays, let start = days.lowerBound.startOfDay(in: calendar), let end = days.upperBound.startOfDay(in: calendar) else { return nil }
        return start ... end
    }

    /// Called after every tap that changes the selection.
    public var onSelectionChange: ((LMKCalendarSelection) -> Void)?

    /// Strings for the summary prompt (default `LMKDatePicker.strings`).
    public var strings: LMKDatePicker.Strings = LMKDatePicker.strings {
        didSet { refreshSummary() }
    }

    /// Per-instance style; `nil` fields resolve from `theme.calendarRangeSelection`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKCalendarRangeSelectionView) -> Void)?

    public let summaryLabel = UILabel()
    public let calendarView = UICalendarView()

    /// The calendar the days and the summary are expressed in.
    public let calendar: Calendar
    /// The locale of the calendar grid and the summary.
    public let locale: Locale

    private var multiDateSelection: UICalendarSelectionMultiDate?
    private var resolved = Style()
    private var spacingConstraint: Constraint?
    private let intervalFormatter: DateIntervalFormatter

    /// Display cap: a selection is rebuilt day by day, so a typo'd year must not
    /// enumerate thousands of components.
    private static let maxSelectedDays = 366

    // MARK: - Initialization

    /// - Parameters:
    ///   - startDate: The first day of the initial range; `nil` starts with nothing selected.
    ///   - endDate: The last day of the initial range; `nil` leaves the range open at `startDate`
    ///     for the next tap to close.
    ///   - calendar: The calendar (and time zone) the days are expressed in.
    ///   - locale: The locale of the grid and the summary; `nil` = the current locale.
    ///   - style: Per-instance overrides layered over `theme.calendarRangeSelection`.
    public init(startDate: Date? = nil, endDate: Date? = nil, calendar: Calendar = LMKDate.calendar, locale: Locale? = nil, style: Style = Style()) {
        self.calendar = calendar
        self.locale = locale ?? .current
        self.style = style
        // The summary must agree with the grid: both format in the view's calendar and time zone,
        // not the device's, so a Tokyo start of day never reads as the previous evening.
        let formatter = DateIntervalFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = self.locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        intervalFormatter = formatter
        selection = LMKCalendarSelection(
            start: startDate.map { LMKCalendarDay($0, calendar: calendar) },
            end: endDate.map { LMKCalendarDay($0, calendar: calendar) }
        )
        super.init(frame: .zero)
        setupUI()
        refreshSelection()
        refreshSummary()
        lmk_startApplyingTheme()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        summaryLabel.textAlignment = .center

        let behavior = UICalendarSelectionMultiDate(delegate: self)
        multiDateSelection = behavior
        calendarView.selectionBehavior = behavior
        calendarView.calendar = calendar
        calendarView.locale = locale
        let anchor = selectedRange?.lowerBound ?? LMKDate.today
        calendarView.visibleDateComponents = calendar.dateComponents([.year, .month], from: anchor)

        addSubview(summaryLabel)
        addSubview(calendarView)
        summaryLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        calendarView.snp.makeConstraints { make in
            spacingConstraint = make.top.equalTo(summaryLabel.snp.bottom).offset(0).constraint
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        resolved = theme.calendarRangeSelection.merging(style)
        summaryLabel.lmk_apply(resolved.summaryTextStyle ?? .bodyMedium, color: resolved.summaryColor ?? LMKColor.textPrimary)
        calendarView.tintColor = resolved.tintColor ?? LMKColor.primary
        spacingConstraint?.update(offset: resolved.spacing ?? theme.spacing.xs)
        didApplyStyle?(self)
    }

    // MARK: - State

    /// Applies a tap on `day` through the range reducer, as the calendar would.
    public func select(_ day: LMKCalendarDay) {
        selection = selection.tapping(day, mode: .range)
        refreshSelection()
        refreshSummary()
    }

    /// `select(_:)` for a `Date` in the view's calendar.
    public func select(_ date: Date) {
        select(LMKCalendarDay(date, calendar: calendar))
    }

    private func refreshSelection() {
        guard let multiDateSelection else { return }
        let components = selection.days(calendar: calendar, limit: Self.maxSelectedDays).map(\.components)
        multiDateSelection.setSelectedDates(components, animated: false)
    }

    private func refreshSummary() {
        if let range = selectedRange {
            summaryLabel.text = intervalFormatter.string(from: range.lowerBound, to: range.upperBound)
        } else {
            summaryLabel.text = strings.selectDatesPrompt
        }
        summaryLabel.accessibilityLabel = summaryLabel.text
    }
}

// MARK: - UICalendarSelectionMultiDateDelegate

extension LMKCalendarRangeSelectionView: UICalendarSelectionMultiDateDelegate {
    /// Selecting and deselecting are the same gesture here: a tap inside the current range
    /// arrives as a deselect, but still means "start over here".
    public func multiDateSelection(_: UICalendarSelectionMultiDate, didSelectDate dateComponents: DateComponents) {
        handleTap(dateComponents)
    }

    public func multiDateSelection(_: UICalendarSelectionMultiDate, didDeselectDate dateComponents: DateComponents) {
        handleTap(dateComponents)
    }

    public func multiDateSelection(_: UICalendarSelectionMultiDate, canSelectDate _: DateComponents) -> Bool {
        true
    }

    public func multiDateSelection(_: UICalendarSelectionMultiDate, canDeselectDate _: DateComponents) -> Bool {
        true
    }

    private func handleTap(_ dateComponents: DateComponents) {
        guard let year = dateComponents.year, let month = dateComponents.month, let day = dateComponents.day else {
            refreshSelection()
            return
        }
        select(LMKCalendarDay(year: year, month: month, day: day))
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKCalendarRangeSelectionView`.
    var calendarRangeSelection: LMKCalendarRangeSelectionView.Style {
        get { self[LMKCalendarRangeSelectionView.Style.self] }
        set { self[LMKCalendarRangeSelectionView.Style.self] = newValue }
    }
}
