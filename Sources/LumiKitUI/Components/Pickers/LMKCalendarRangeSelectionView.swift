//
//  LMKCalendarRangeSelectionView.swift
//  LumiKit
//
//  A live range summary over a UICalendarView whose multi-date selection
//  renders every day of the range. Selection runs through the shared
//  `LMKCalendarSelection` reducer in range mode.
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
public final class LMKCalendarRangeSelectionView: UIView {
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

    public let summaryLabel = UILabel()
    public let calendarView = UICalendarView()

    private let calendar: Calendar
    private var multiDateSelection: UICalendarSelectionMultiDate?

    /// Display cap: a selection is rebuilt day by day, so a typo'd year must not
    /// enumerate thousands of components.
    private static let maxSelectedDays = 366

    private static let intervalFormatter: DateIntervalFormatter = {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    // MARK: - Initialization

    public init(startDate: Date? = nil, endDate: Date? = nil, calendar: Calendar = LMKDate.calendar) {
        self.calendar = calendar
        selection = LMKCalendarSelection(
            start: startDate.map { LMKCalendarDay($0, calendar: calendar) },
            end: endDate.map { LMKCalendarDay($0, calendar: calendar) }
        )
        super.init(frame: .zero)
        setupUI()
        refreshSelection()
        refreshSummary()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        summaryLabel.lmk_apply(.bodyMedium, color: LMKColor.textPrimary)
        summaryLabel.textAlignment = .center

        let behavior = UICalendarSelectionMultiDate(delegate: self)
        multiDateSelection = behavior
        calendarView.selectionBehavior = behavior
        calendarView.calendar = calendar
        calendarView.locale = .current
        calendarView.tintColor = LMKColor.primary
        let anchor = selectedRange?.lowerBound ?? LMKDate.today
        calendarView.visibleDateComponents = calendar.dateComponents([.year, .month], from: anchor)

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
            summaryLabel.text = Self.intervalFormatter.string(from: range.lowerBound, to: range.upperBound)
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
