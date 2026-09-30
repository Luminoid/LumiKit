//
//  LMKMonthCalendarViewInitTests.swift
//  LumiKit
//
//  `LMKMonthCalendarView()` and `init(frame:)` once recursed through
//  `UIView.init()` until the stack overflowed (found by the Example sweep).
//

import LumiKitCore
import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKMonthCalendarViewInitTests {
    @Test
    func `The parameterless and frame initializers reach the designated one`() {
        let plain = LMKMonthCalendarView()
        #expect(plain.calendar.identifier == LMKDate.calendar.identifier)
        #expect(plain.visibleMonth == LMKCalendarMonth.current(calendar: plain.calendar))

        let framed = LMKMonthCalendarView(frame: CGRect(x: 0, y: 0, width: 320, height: 300))
        #expect(framed.frame.width == 320)
        #expect(framed.visibleMonth == plain.visibleMonth)
    }
}
