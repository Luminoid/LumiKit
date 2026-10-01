//
//  LMKCalendarSelection.swift
//  LumiKit
//
//  The selection state of a calendar and the pure reducer that advances it
//  on a tap, shared by the month calendar view and the range picker.
//

import Foundation

/// How a calendar responds to taps.
public nonisolated enum LMKCalendarSelectionMode: Sendable, Hashable, CaseIterable {
    /// Taps report the day but select nothing.
    case none
    /// One day at a time.
    case single
    /// A start and an end: the first tap starts, a later tap closes, an earlier tap re-anchors,
    /// and any tap once a range exists starts over.
    case range
    /// Any set of days; a tap toggles membership.
    case multiple
}

/// What a calendar has selected.
///
/// The days are Gregorian civil days (`LMKCalendarDay`). A `range` built with its bounds
/// reversed is read in chronological order by every query (`selectedRange`, `contains`,
/// `earliest`, `latest`, `days`), though the case itself keeps the payload it was given, so
/// `.range(b, a) != .range(a, b)`; the initializers always store the bounds in order.
public nonisolated enum LMKCalendarSelection: Sendable, Hashable {
    case empty
    /// One day (single mode).
    case single(LMKCalendarDay)
    /// The start of a range awaiting its end (range mode).
    case start(LMKCalendarDay)
    /// A closed range (range mode).
    case range(LMKCalendarDay, LMKCalendarDay)
    /// A set of days (multiple mode); never empty.
    case multiple(Set<LMKCalendarDay>)

    // MARK: - Construction

    /// A selection from optional bounds: `nil` / `nil` is empty, a start alone is a range start,
    /// both give the range, collapsed to the start when the end comes first.
    public init(start: LMKCalendarDay?, end: LMKCalendarDay?) {
        guard let start else {
            self = .empty
            return
        }
        guard let end else {
            self = .start(start)
            return
        }
        self = end < start ? .range(start, start) : .range(start, end)
    }

    /// A range selection over `range`.
    public init(_ range: ClosedRange<LMKCalendarDay>) {
        self = .range(range.lowerBound, range.upperBound)
    }

    /// A multiple selection over `days`; empty when `days` is empty.
    public init(_ days: Set<LMKCalendarDay>) {
        self = days.isEmpty ? .empty : .multiple(days)
    }

    // MARK: - Queries

    public var isEmpty: Bool {
        if case .empty = self { return true }
        return false
    }

    /// The selected span: a single day or a range start is a one-day range; `nil` for empty and
    /// multiple selections.
    public var selectedRange: ClosedRange<LMKCalendarDay>? {
        switch self {
        case .empty, .multiple: nil
        case let .single(day), let .start(day): day ... day
        case let .range(start, end): min(start, end) ... max(start, end)
        }
    }

    /// The earliest selected day; `nil` when empty.
    public var earliest: LMKCalendarDay? {
        switch self {
        case .empty: nil
        case let .single(day), let .start(day): day
        case let .range(start, end): min(start, end)
        case let .multiple(days): days.min()
        }
    }

    /// The latest selected day; `nil` when empty.
    public var latest: LMKCalendarDay? {
        switch self {
        case .empty: nil
        case let .single(day), let .start(day): day
        case let .range(start, end): max(start, end)
        case let .multiple(days): days.max()
        }
    }

    /// Whether `day` is selected.
    public func contains(_ day: LMKCalendarDay) -> Bool {
        switch self {
        case .empty: false
        case let .single(selected), let .start(selected): selected == day
        case let .range(start, end): min(start, end) <= day && day <= max(start, end)
        case let .multiple(days): days.contains(day)
        }
    }

    /// Whether `day` is the first day of the selection (the range start, the single day, or the
    /// earliest of a set).
    public func isStart(_ day: LMKCalendarDay) -> Bool {
        earliest == day
    }

    /// Whether `day` is the last day of the selection.
    public func isEnd(_ day: LMKCalendarDay) -> Bool {
        latest == day
    }

    /// Every selected day, enumerated in order (capped at `limit` days so a typo'd year cannot
    /// enumerate thousands). Multiple selections come back sorted.
    public func days(calendar: Calendar = LMKDate.calendar, limit: Int = 366) -> [LMKCalendarDay] {
        switch self {
        case .empty:
            return []
        case let .single(day), let .start(day):
            return [day]
        case let .range(start, end):
            let last = max(start, end)
            var result: [LMKCalendarDay] = []
            var day = min(start, end)
            while day <= last, result.count < limit {
                result.append(day)
                let next = day.adding(days: 1, calendar: calendar)
                guard next > day else { break }
                day = next
            }
            return result
        case let .multiple(days):
            return Array(days.sorted().prefix(limit))
        }
    }

    // MARK: - Reduction

    /// The selection after tapping `day` in `mode`.
    ///
    /// - `none`: unchanged.
    /// - `single`: `day` becomes the selection (tapping it again keeps it).
    /// - `range`: the first tap starts the range, a later tap closes it, an earlier tap
    ///   re-anchors, and any tap once a full range exists starts over.
    /// - `multiple`: `day` toggles in and out of the set; a range expands into its days first,
    ///   enumerated in `calendar` (the calendar the days belong to).
    public static func next(after selection: Self, tapping day: LMKCalendarDay, mode: LMKCalendarSelectionMode, calendar: Calendar = LMKDate.calendar) -> Self {
        switch mode {
        case .none:
            return selection
        case .single:
            return .single(day)
        case .range:
            switch selection {
            case .empty, .multiple, .range:
                return .start(day)
            case let .single(anchor), let .start(anchor):
                return day < anchor ? .start(day) : .range(anchor, day)
            }
        case .multiple:
            var days: Set<LMKCalendarDay> = switch selection {
            case .empty: []
            case let .single(selected), let .start(selected): [selected]
            case .range: Set(selection.days(calendar: calendar))
            case let .multiple(set): set
            }
            if days.contains(day) {
                days.remove(day)
            } else {
                days.insert(day)
            }
            return Self(days)
        }
    }

    /// `next(after: self, tapping: day, mode: mode, calendar: calendar)`.
    public func tapping(_ day: LMKCalendarDay, mode: LMKCalendarSelectionMode, calendar: Calendar = LMKDate.calendar) -> Self {
        Self.next(after: self, tapping: day, mode: mode, calendar: calendar)
    }
}
