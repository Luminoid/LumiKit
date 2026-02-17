//
//  LMKDateHelperTests.swift
//  LumiKit
//

import Foundation
import Testing

@testable import LumiKitCore

// MARK: - LMKDateHelper

@Suite("LMKDateHelper")
struct LMKDateHelperTests {
    @Test("today returns start of current day")
    func todayIsStartOfDay() {
        let today = LMKDateHelper.today
        let components = LMKDateHelper.calendar.dateComponents([.hour, .minute, .second], from: today)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    @Test("today is cached and returns same value on repeated access")
    func todayCaching() {
        let first = LMKDateHelper.today
        let second = LMKDateHelper.today
        #expect(first == second)
    }

    @Test("invalidateTodayCache forces recalculation")
    func invalidateCache() {
        let before = LMKDateHelper.today
        LMKDateHelper.invalidateTodayCache()
        let after = LMKDateHelper.today
        // Both should still be the same day
        #expect(LMKDateHelper.calendar.isDate(before, inSameDayAs: after))
    }

    @Test("isToday returns true for now")
    func isTodayNow() {
        #expect(LMKDateHelper.isToday(Date()))
    }

    @Test("isToday returns false for yesterday")
    func isTodayYesterday() {
        let yesterday = LMKDateHelper.calendar.date(byAdding: .day, value: -1, to: Date())!
        #expect(!LMKDateHelper.isToday(yesterday))
    }

    @Test("isSameDay for identical dates")
    func isSameDayIdentical() {
        let now = Date()
        #expect(LMKDateHelper.isSameDay(now, now))
    }

    @Test("isSameDay for different days")
    func isSameDayDifferent() {
        let now = Date()
        let tomorrow = LMKDateHelper.calendar.date(byAdding: .day, value: 1, to: now)!
        #expect(!LMKDateHelper.isSameDay(now, tomorrow))
    }

    @Test("startOfDay strips time components")
    func startOfDay() {
        let now = Date()
        let start = LMKDateHelper.startOfDay(for: now)
        let components = LMKDateHelper.calendar.dateComponents([.hour, .minute, .second], from: start)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    @Test("isValidDateRange accepts current date")
    func validDateRangeCurrent() {
        #expect(LMKDateHelper.isValidDateRange(Date()))
    }

    @Test("isValidDateRange rejects far future")
    func validDateRangeFarFuture() {
        let farFuture = LMKDateHelper.calendar.date(byAdding: .year, value: 50, to: Date())!
        #expect(!LMKDateHelper.isValidDateRange(farFuture))
    }

    @Test("isValidDateRange rejects far past")
    func validDateRangeFarPast() {
        let farPast = LMKDateHelper.calendar.date(byAdding: .year, value: -200, to: Date())!
        #expect(!LMKDateHelper.isValidDateRange(farPast))
    }

    @Test("Date.lmk_isToday extension works")
    func dateExtensionIsToday() {
        #expect(Date().lmk_isToday)
    }

    @Test("Date.lmk_startOfDay extension works")
    func dateExtensionStartOfDay() {
        let start = Date().lmk_startOfDay
        let components = LMKDateHelper.calendar.dateComponents([.hour, .minute, .second], from: start)
        #expect(components.hour == 0)
    }

    @Test("Date.lmk_isSameDay extension works")
    func dateExtensionIsSameDay() {
        let now = Date()
        #expect(now.lmk_isSameDay(as: now))
    }
}
