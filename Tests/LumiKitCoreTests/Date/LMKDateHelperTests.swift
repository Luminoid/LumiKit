//
//  LMKDateHelperTests.swift
//  LumiKit
//

import Foundation
import Testing
@testable import LumiKitCore

// MARK: - LMKDateHelper

struct LMKDateHelperTests {
    @Test
    func `today returns start of current day`() {
        let today = LMKDateHelper.today
        let components = LMKDateHelper.calendar.dateComponents([.hour, .minute, .second], from: today)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    @Test
    func `today returns same value on repeated access`() {
        let first = LMKDateHelper.today
        let second = LMKDateHelper.today
        #expect(first == second)
    }

    @Test
    func `isToday returns true for now`() {
        #expect(LMKDateHelper.isToday(Date()))
    }

    @Test
    func `isToday returns false for yesterday`() throws {
        let yesterday = try #require(LMKDateHelper.calendar.date(byAdding: .day, value: -1, to: Date()))
        #expect(!LMKDateHelper.isToday(yesterday))
    }

    @Test
    func `isSameDay for identical dates`() {
        let now = Date()
        #expect(LMKDateHelper.isSameDay(now, now))
    }

    @Test
    func `isSameDay for different days`() throws {
        let now = Date()
        let tomorrow = try #require(LMKDateHelper.calendar.date(byAdding: .day, value: 1, to: now))
        #expect(!LMKDateHelper.isSameDay(now, tomorrow))
    }

    @Test
    func `startOfDay strips time components`() {
        let now = Date()
        let start = LMKDateHelper.startOfDay(for: now)
        let components = LMKDateHelper.calendar.dateComponents([.hour, .minute, .second], from: start)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    @Test
    func `isValidDateRange accepts current date`() {
        #expect(LMKDateHelper.isValidDateRange(Date()))
    }

    @Test
    func `isValidDateRange rejects far future`() throws {
        let farFuture = try #require(LMKDateHelper.calendar.date(byAdding: .year, value: 50, to: Date()))
        #expect(!LMKDateHelper.isValidDateRange(farFuture))
    }

    @Test
    func `isValidDateRange rejects far past`() throws {
        let farPast = try #require(LMKDateHelper.calendar.date(byAdding: .year, value: -200, to: Date()))
        #expect(!LMKDateHelper.isValidDateRange(farPast))
    }

    @Test
    func `Date.lmk_isToday extension works`() {
        #expect(Date().lmk_isToday)
    }

    @Test
    func `Date.lmk_startOfDay extension works`() {
        let start = Date().lmk_startOfDay
        let components = LMKDateHelper.calendar.dateComponents([.hour, .minute, .second], from: start)
        #expect(components.hour == 0)
    }

    @Test
    func `Date.lmk_isSameDay extension works`() {
        let now = Date()
        #expect(now.lmk_isSameDay(as: now))
    }
}
