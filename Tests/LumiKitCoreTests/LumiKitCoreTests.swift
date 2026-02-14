//
//  LumiKitCoreTests.swift
//  LumiKit
//
//  Tests for LumiKitCore: Logger, DateHelper, URLValidator,
//  String+LMK, ConcurrencyHelpers, DateFormatterHelper, FormatHelper,
//  Collection+LMK, NSAttributedString+LMK.
//

import Foundation
import Testing

@testable import LumiKitCore

// MARK: - LMKLogger

@Suite("LMKLogger")
struct LMKLoggerTests {
    @Test("Configure subsystem updates category logs")
    func configureSubsystem() {
        LMKLogger.configure(subsystem: "com.test.lumikit")
        // If it doesn't crash, the subsystem was applied correctly.
        LMKLogger.info("Test message after configure", category: .general)
    }

    @Test("Built-in categories exist")
    func builtInCategories() {
        _ = LMKLogger.LogCategory.general
        _ = LMKLogger.LogCategory.data
        _ = LMKLogger.LogCategory.ui
        _ = LMKLogger.LogCategory.network
        _ = LMKLogger.LogCategory.error
        _ = LMKLogger.LogCategory.localization
    }

    @Test("Custom category creation")
    func customCategory() {
        let category = LMKLogger.LogCategory(name: "CustomTest")
        LMKLogger.debug("Custom category test", category: category)
    }
}

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

// MARK: - LMKURLValidator

@Suite("LMKURLValidator")
struct LMKURLValidatorTests {
    @Test("Valid HTTPS URL passes")
    func validHTTPS() {
        let result = LMKURLValidator.validateHTTPSURL("https://example.com/api")
        #expect(result == "https://example.com/api")
    }

    @Test("HTTP URL is rejected")
    func httpRejected() {
        let result = LMKURLValidator.validateHTTPSURL("http://example.com")
        #expect(result == nil)
    }

    @Test("Empty input is rejected")
    func emptyRejected() {
        #expect(LMKURLValidator.validateHTTPSURL("") == nil)
        #expect(LMKURLValidator.validateHTTPSURL(nil) == nil)
    }

    @Test("URL exceeding max length is rejected")
    func maxLengthRejected() {
        let longURL = "https://example.com/" + String(repeating: "a", count: 500)
        #expect(LMKURLValidator.validateHTTPSURL(longURL) == nil)
    }

    @Test("Localhost is blocked (SSRF)")
    func localhostBlocked() {
        #expect(LMKURLValidator.validateHTTPSURL("https://localhost/api") == nil)
        #expect(LMKURLValidator.validateHTTPSURL("https://localhost.localdomain/api") == nil)
    }

    @Test("Private IP ranges are blocked (SSRF)")
    func privateIPBlocked() {
        #expect(LMKURLValidator.validateHTTPSURL("https://10.0.0.1/api") == nil)
        #expect(LMKURLValidator.validateHTTPSURL("https://192.168.1.1/api") == nil)
        #expect(LMKURLValidator.validateHTTPSURL("https://172.16.0.1/api") == nil)
        #expect(LMKURLValidator.validateHTTPSURL("https://127.0.0.1/api") == nil)
    }

    @Test("Link-local is blocked (SSRF)")
    func linkLocalBlocked() {
        #expect(LMKURLValidator.validateHTTPSURL("https://169.254.1.1/api") == nil)
    }

    @Test("IPv6 loopback is blocked")
    func ipv6LoopbackBlocked() {
        #expect(LMKURLValidator.isBlockedHost("::1"))
    }

    @Test("normalizeBaseURL adds trailing slash")
    func normalizeBaseURLSlash() {
        #expect(LMKURLValidator.normalizeBaseURL("https://example.com/path") == "https://example.com/path/")
    }

    @Test("normalizeBaseURL preserves existing slash")
    func normalizeBaseURLExistingSlash() {
        #expect(LMKURLValidator.normalizeBaseURL("https://example.com/path/") == "https://example.com/path/")
    }

    @Test("normalizeBaseURL preserves .json suffix")
    func normalizeBaseURLJson() {
        #expect(LMKURLValidator.normalizeBaseURL("https://example.com/data.json") == "https://example.com/data.json")
    }

    @Test("Whitespace is trimmed")
    func whitespaceTrimmed() {
        let result = LMKURLValidator.validateHTTPSURL("  https://example.com  ")
        #expect(result == "https://example.com")
    }
}

// MARK: - String+LMK

@Suite("String+LMK")
struct StringLMKTests {
    @Test("nonEmpty returns value for non-empty string")
    func nonEmptyReturnsValue() {
        let value: String? = "hello"
        #expect(value.nonEmpty == "hello")
    }

    @Test("nonEmpty returns nil for empty string")
    func nonEmptyReturnsNilForEmpty() {
        let value: String? = ""
        #expect(value.nonEmpty == nil)
    }

    @Test("nonEmpty returns nil for nil")
    func nonEmptyReturnsNilForNil() {
        let value: String? = nil
        #expect(value.nonEmpty == nil)
    }
}

// MARK: - LMKConcurrencyHelpers

@Suite("LMKConcurrencyHelpers")
struct ConcurrencyHelpersTests {
    struct TestModel: Codable, Equatable {
        let name: String
        let count: Int
    }

    @Test("Encode produces valid data")
    func encodeProducesData() {
        let model = TestModel(name: "test", count: 42)
        let data = LMKConcurrencyHelpers.encode(model)
        #expect(data != nil)
    }

    @Test("Decode recovers original model")
    func decodeRecoversModel() {
        let model = TestModel(name: "lumikit", count: 7)
        let data = LMKConcurrencyHelpers.encode(model)!
        let decoded = LMKConcurrencyHelpers.decode(TestModel.self, from: data)
        #expect(decoded == model)
    }

    @Test("Decode returns nil for invalid data")
    func decodeInvalidData() {
        let badData = Data("not json".utf8)
        let result = LMKConcurrencyHelpers.decode(TestModel.self, from: badData)
        #expect(result == nil)
    }

    @Test("Encode/decode round-trip for arrays")
    func encodeDecodeArray() {
        let models = [TestModel(name: "a", count: 1), TestModel(name: "b", count: 2)]
        let data = LMKConcurrencyHelpers.encode(models)!
        let decoded = LMKConcurrencyHelpers.decode([TestModel].self, from: data)
        #expect(decoded == models)
    }
}

// MARK: - LMKDateFormatterHelper

@Suite("LMKDateFormatterHelper")
struct DateFormatterHelperTests {
    @Test("Default format is MM/dd/yyyy")
    func defaultFormat() {
        LMKDateFormatterHelper.configure(dateFormat: { "MM/dd/yyyy" })
        let formatter = LMKDateFormatterHelper.dateFormatter()
        #expect(formatter.dateFormat == "MM/dd/yyyy")
    }

    @Test("Configure changes format")
    func configureChangesFormat() {
        LMKDateFormatterHelper.configure(dateFormat: { "yyyy-MM-dd" })
        let formatter = LMKDateFormatterHelper.dateFormatter()
        #expect(formatter.dateFormat == "yyyy-MM-dd")
        // Restore default
        LMKDateFormatterHelper.configure(dateFormat: { "MM/dd/yyyy" })
    }

    @Test("Include time appends HH:mm")
    func includeTimeFormat() {
        LMKDateFormatterHelper.configure(dateFormat: { "MM/dd/yyyy" })
        let formatter = LMKDateFormatterHelper.dateFormatter(includeTime: true)
        #expect(formatter.dateFormat == "MM/dd/yyyy HH:mm")
    }

    @Test("formatDate produces non-empty string")
    func formatDateProducesString() {
        LMKDateFormatterHelper.configure(dateFormat: { "MM/dd/yyyy" })
        let result = LMKDateFormatterHelper.formatDate(Date())
        #expect(!result.isEmpty)
    }

    @Test("formatNumber produces string")
    func formatNumber() {
        let result = LMKDateFormatterHelper.formatNumber(NSNumber(value: 42))
        #expect(!result.isEmpty)
    }
}

// MARK: - LMKFormatHelper

@Suite("LMKFormatHelper")
struct FormatHelperTests {
    @Test("progressPercent formats 0.75 as 75%")
    func progressPercent75() {
        #expect(LMKFormatHelper.progressPercent(0.75) == "75%")
    }

    @Test("progressPercent formats 0.0 as 0%")
    func progressPercentZero() {
        #expect(LMKFormatHelper.progressPercent(0.0) == "0%")
    }

    @Test("progressPercent formats 1.0 as 100%")
    func progressPercentFull() {
        #expect(LMKFormatHelper.progressPercent(1.0) == "100%")
    }
}

// MARK: - Collection+LMK

@Suite("Collection+LMK")
struct CollectionLMKTests {
    @Test("Safe subscript returns element for valid index")
    func safeSubscriptValid() {
        let items = ["a", "b", "c"]
        #expect(items[safe: 1] == "b")
    }

    @Test("Safe subscript returns nil for out-of-bounds index")
    func safeSubscriptOutOfBounds() {
        let items = ["a", "b", "c"]
        #expect(items[safe: 5] == nil)
        #expect(items[safe: -1] == nil)
    }

    @Test("Safe subscript returns nil for empty collection")
    func safeSubscriptEmpty() {
        let items: [String] = []
        #expect(items[safe: 0] == nil)
    }

    @Test("lmk_uniqued preserves order and removes duplicates")
    func uniquedPreservesOrder() {
        let items = [1, 2, 2, 3, 1, 4]
        #expect(items.lmk_uniqued() == [1, 2, 3, 4])
    }

    @Test("lmk_uniqued on empty returns empty")
    func uniquedEmpty() {
        let items: [Int] = []
        #expect(items.lmk_uniqued().isEmpty)
    }

    @Test("lmk_chunked splits correctly")
    func chunkedSplits() {
        let items = [1, 2, 3, 4, 5]
        let chunks = items.lmk_chunked(size: 2)
        #expect(chunks.count == 3)
        #expect(chunks[0] == [1, 2])
        #expect(chunks[1] == [3, 4])
        #expect(chunks[2] == [5])
    }

    @Test("lmk_chunked with size larger than count returns single chunk")
    func chunkedLargerSize() {
        let items = [1, 2]
        let chunks = items.lmk_chunked(size: 10)
        #expect(chunks.count == 1)
        #expect(chunks[0] == [1, 2])
    }

    @Test("lmk_chunked with size 0 returns empty")
    func chunkedZeroSize() {
        let items = [1, 2, 3]
        #expect(items.lmk_chunked(size: 0).isEmpty)
    }
}

// MARK: - NSAttributedString+LMK

@Suite("NSAttributedString+LMK")
struct NSAttributedStringLMKTests {
    @Test("Concatenation operator combines strings")
    func concatenation() {
        let a = NSAttributedString(string: "Hello ")
        let b = NSAttributedString(string: "World")
        let result = a + b
        #expect(result.string == "Hello World")
    }

    @Test("lmk_append adds text")
    func appendText() {
        let result = NSMutableAttributedString()
            .lmk_append("Hello ")
            .lmk_append("World")
        #expect(result.string == "Hello World")
    }

    @Test("lmk_applyToAll applies across full range")
    func applyToAll() {
        let key = NSAttributedString.Key("lmk.test")
        let result = NSMutableAttributedString(string: "Test")
            .lmk_applyToAll([key: 2.0])
        var range = NSRange()
        let attrs = result.attributes(at: 0, longestEffectiveRange: &range, in: NSRange(location: 0, length: result.length))
        #expect(attrs[key] as? Double == 2.0)
        #expect(range.length == 4)
    }

    @Test("lmk_applyToAll on empty string does not crash")
    func applyToAllEmpty() {
        let key = NSAttributedString.Key("lmk.test")
        let result = NSMutableAttributedString()
            .lmk_applyToAll([key: 2.0])
        #expect(result.length == 0)
    }
}
