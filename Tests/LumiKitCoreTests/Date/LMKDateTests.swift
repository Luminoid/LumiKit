//
//  LMKDateTests.swift
//  LumiKit
//

import Foundation
import Testing
@testable import LumiKitCore

// MARK: - LMKDate

struct LMKDateTests {
    @Test
    func `today returns start of current day`() {
        let today = LMKDate.today
        let components = LMKDate.calendar.dateComponents([.hour, .minute, .second], from: today)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    @Test
    func `today returns same value on repeated access`() {
        let first = LMKDate.today
        let second = LMKDate.today
        #expect(first == second)
    }

    @Test
    func `isToday returns true for now`() {
        #expect(LMKDate.isToday(Date()))
    }

    @Test
    func `isToday returns false for yesterday`() throws {
        let yesterday = try #require(LMKDate.calendar.date(byAdding: .day, value: -1, to: Date()))
        #expect(!LMKDate.isToday(yesterday))
    }

    @Test
    func `isSameDay for identical dates`() {
        let now = Date()
        #expect(LMKDate.isSameDay(now, now))
    }

    @Test
    func `isSameDay for different days`() throws {
        let now = Date()
        let tomorrow = try #require(LMKDate.calendar.date(byAdding: .day, value: 1, to: now))
        #expect(!LMKDate.isSameDay(now, tomorrow))
    }

    @Test
    func `startOfDay strips time components`() {
        let now = Date()
        let start = LMKDate.startOfDay(for: now)
        let components = LMKDate.calendar.dateComponents([.hour, .minute, .second], from: start)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    @Test
    func `isValidDateRange accepts current date`() {
        #expect(LMKDate.isValidDateRange(Date()))
    }

    @Test
    func `isValidDateRange rejects far future`() throws {
        let farFuture = try #require(LMKDate.calendar.date(byAdding: .year, value: 50, to: Date()))
        #expect(!LMKDate.isValidDateRange(farFuture))
    }

    @Test
    func `isValidDateRange rejects far past`() throws {
        let farPast = try #require(LMKDate.calendar.date(byAdding: .year, value: -200, to: Date()))
        #expect(!LMKDate.isValidDateRange(farPast))
    }

    @Test
    func `Date.lmk_isToday extension works`() {
        #expect(Date().lmk_isToday)
    }

    @Test
    func `Date.lmk_startOfDay extension works`() {
        let start = Date().lmk_startOfDay
        let components = LMKDate.calendar.dateComponents([.hour, .minute, .second], from: start)
        #expect(components.hour == 0)
    }

    @Test
    func `Date.lmk_isSameDay extension works`() {
        let now = Date()
        #expect(now.lmk_isSameDay(as: now))
    }

    // MARK: - Time zone

    @Test
    func `The shared calendar is in the current time zone with or without initialize()`() {
        #expect(LMKDate.calendar.timeZone.identifier == TimeZone.current.identifier)
        LMKDate.initialize()
        LMKDate.initialize()
        #expect(LMKDate.calendar.timeZone.identifier == TimeZone.current.identifier)
    }

    @Test
    func `The calendar follows a time-zone change from creation, not from initialize()`() throws {
        final class ZoneBox: @unchecked Sendable {
            var zone: TimeZone
            init(zone: TimeZone) {
                self.zone = zone
            }
        }
        let utc = try #require(TimeZone(identifier: "UTC"))
        let tokyo = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let box = ZoneBox(zone: utc)
        let center = NotificationCenter()
        let following = LMKDate.FollowingCalendar(center: center) {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = box.zone
            return calendar
        }
        #expect(following.calendar.timeZone == utc)

        box.zone = tokyo
        #expect(following.calendar.timeZone == utc, "the snapshot holds until the system says the zone changed")
        center.post(name: .NSSystemTimeZoneDidChange, object: nil)
        #expect(following.calendar.timeZone == tokyo)
        #expect(LMKDate.calendar.timeZone.identifier == TimeZone.current.identifier, "another center's notification leaves the shared calendar alone")
    }
}
