//
//  LMKCalendarSelectionTests.swift
//  LumiKit
//

import Foundation
import Testing
@testable import LumiKitCore

private nonisolated func day(_ day: Int, month: Int = 9) -> LMKCalendarDay {
    LMKCalendarDay(year: 2026, month: month, day: day)
}

struct LMKCalendarSelectionTests {
    @Test
    func `Construction from bounds normalizes the range`() {
        #expect(LMKCalendarSelection(start: nil, end: nil) == .empty)
        #expect(LMKCalendarSelection(start: day(10), end: nil) == .start(day(10)))
        #expect(LMKCalendarSelection(start: day(10), end: day(12)) == .range(day(10), day(12)))
        #expect(LMKCalendarSelection(start: day(10), end: day(5)) == .range(day(10), day(10)), "an end before the start collapses to the start")
        #expect(LMKCalendarSelection(day(3) ... day(4)) == .range(day(3), day(4)))
        #expect(LMKCalendarSelection(Set<LMKCalendarDay>()) == .empty)
        #expect(LMKCalendarSelection([day(1), day(3)]) == .multiple([day(1), day(3)]))
    }

    @Test
    func `Queries: emptiness, range, bounds, containment`() {
        #expect(LMKCalendarSelection.empty.isEmpty)
        #expect(LMKCalendarSelection.empty.selectedRange == nil)
        #expect(LMKCalendarSelection.empty.earliest == nil)
        #expect(!LMKCalendarSelection.empty.contains(day(1)))

        let single = LMKCalendarSelection.single(day(7))
        #expect(single.selectedRange == day(7) ... day(7))
        #expect(single.contains(day(7)))
        #expect(!single.contains(day(8)))
        #expect(single.isStart(day(7)) && single.isEnd(day(7)))

        let start = LMKCalendarSelection.start(day(7))
        #expect(start.selectedRange == day(7) ... day(7))

        let range = LMKCalendarSelection.range(day(5), day(9))
        #expect(range.selectedRange == day(5) ... day(9))
        #expect(range.contains(day(5)) && range.contains(day(7)) && range.contains(day(9)))
        #expect(!range.contains(day(4)) && !range.contains(day(10)))
        #expect(range.isStart(day(5)) && !range.isStart(day(9)))
        #expect(range.isEnd(day(9)) && !range.isEnd(day(5)))
        #expect(range.earliest == day(5) && range.latest == day(9))

        let multiple = LMKCalendarSelection.multiple([day(3), day(1), day(9)])
        #expect(multiple.selectedRange == nil)
        #expect(multiple.earliest == day(1) && multiple.latest == day(9))
        #expect(multiple.contains(day(3)) && !multiple.contains(day(2)))
    }

    @Test
    func `days() enumerates in order and caps long ranges`() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "UTC"))
        #expect(LMKCalendarSelection.empty.days(calendar: calendar).isEmpty)
        #expect(LMKCalendarSelection.single(day(4)).days(calendar: calendar) == [day(4)])
        #expect(LMKCalendarSelection.range(day(29), day(2, month: 10)).days(calendar: calendar) == [day(29), day(30), day(1, month: 10), day(2, month: 10)])
        #expect(LMKCalendarSelection.multiple([day(9), day(2)]).days(calendar: calendar) == [day(2), day(9)])
        let long = LMKCalendarSelection.range(day(1), LMKCalendarDay(year: 2030, month: 1, day: 1))
        #expect(long.days(calendar: calendar, limit: 10).count == 10)
    }

    @Test
    func `Single mode replaces the selection; none mode leaves it alone`() {
        let single = LMKCalendarSelection.empty.tapping(day(3), mode: .single)
        #expect(single == .single(day(3)))
        #expect(single.tapping(day(3), mode: .single) == .single(day(3)), "re-tapping keeps the day")
        #expect(single.tapping(day(8), mode: .single) == .single(day(8)))
        #expect(LMKCalendarSelection.empty.tapping(day(3), mode: .none) == .empty)
        #expect(single.tapping(day(9), mode: .none) == single)
    }

    @Test
    func `Range mode: first tap starts, a later tap closes, an earlier tap re-anchors, a full range restarts`() {
        let start = LMKCalendarSelection.empty.tapping(day(10), mode: .range)
        #expect(start == .start(day(10)))
        #expect(start.tapping(day(14), mode: .range) == .range(day(10), day(14)))
        #expect(start.tapping(day(10), mode: .range) == .range(day(10), day(10)), "the same day closes a one-day range")
        #expect(start.tapping(day(6), mode: .range) == .start(day(6)), "an earlier day re-anchors")
        let full = LMKCalendarSelection.range(day(10), day(14))
        #expect(full.tapping(day(12), mode: .range) == .start(day(12)), "any tap on a full range starts over")
        #expect(full.tapping(day(20), mode: .range) == .start(day(20)))
        #expect(LMKCalendarSelection.single(day(4)).tapping(day(6), mode: .range) == .range(day(4), day(6)), "a single day acts as an anchor")
        #expect(LMKCalendarSelection.multiple([day(1)]).tapping(day(6), mode: .range) == .start(day(6)))
    }

    @Test
    func `Multiple mode toggles membership and empties out`() {
        let one = LMKCalendarSelection.empty.tapping(day(2), mode: .multiple)
        #expect(one == .multiple([day(2)]))
        let two = one.tapping(day(5), mode: .multiple)
        #expect(two == .multiple([day(2), day(5)]))
        #expect(two.tapping(day(2), mode: .multiple) == .multiple([day(5)]))
        #expect(one.tapping(day(2), mode: .multiple) == .empty, "removing the last day empties the selection")
        #expect(LMKCalendarSelection.single(day(3)).tapping(day(4), mode: .multiple) == .multiple([day(3), day(4)]), "a single day joins the set")
        #expect(LMKCalendarSelection.range(day(3), day(4)).tapping(day(4), mode: .multiple) == .multiple([day(3)]), "a range expands into days first")
    }

    @Test
    func `The static reducer and the instance method agree`() {
        let selection = LMKCalendarSelection.start(day(1))
        #expect(LMKCalendarSelection.next(after: selection, tapping: day(4), mode: .range) == selection.tapping(day(4), mode: .range))
    }
}
