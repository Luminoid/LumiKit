//
//  LMKFormatTests.swift
//  LumiKit
//

import Foundation
import Testing
@testable import LumiKitCore

struct LMKFormatTests {
    private let en = Locale(identifier: "en_US")
    private let de = Locale(identifier: "de_DE")

    @Test
    func `progressPercent renders whole percentages and clamps`() {
        #expect(LMKFormat.progressPercent(0.75, locale: en) == "75%")
        #expect(LMKFormat.progressPercent(0.0, locale: en) == "0%")
        #expect(LMKFormat.progressPercent(1.0, locale: en) == "100%")
        #expect(LMKFormat.progressPercent(1.5, locale: en) == "100%")
        #expect(LMKFormat.progressPercent(-0.2, locale: en) == "0%")
    }

    @Test
    func `percent takes fraction digits and the locale`() {
        #expect(LMKFormat.percent(0.756, locale: en) == "76%")
        #expect(LMKFormat.percent(0.756, fractionDigits: 1 ... 1, locale: en) == "75.6%")
        #expect(LMKFormat.percent(0.5, locale: de).replacingOccurrences(of: "\u{00A0}", with: " ") == "50 %")
    }

    @Test
    func `number renders decimals, integers, and NSNumbers through the locale`() {
        #expect(LMKFormat.number(1234.5, locale: en) == "1,234.5")
        #expect(LMKFormat.number(1234.5678, locale: en) == "1,234.57")
        #expect(LMKFormat.number(2.0, fractionDigits: 1 ... 1, locale: en) == "2.0")
        #expect(LMKFormat.number(1_234_567, locale: en) == "1,234,567")
        #expect(LMKFormat.number(1234.5, locale: de) == "1.234,5")
        #expect(LMKFormat.number(NSNumber(value: 1234), locale: en) == "1,234")
        #expect(LMKFormat.number(NSNumber(value: 42.25), locale: en) == "42.25")
    }

    @Test
    func `numberFormatter is a decimal formatter in the locale`() {
        let formatter = LMKFormat.numberFormatter(locale: de)
        #expect(formatter.numberStyle == .decimal)
        #expect(formatter.locale == de)
        #expect(formatter.string(from: 1234) == "1.234")
    }
}
