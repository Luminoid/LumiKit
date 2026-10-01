//
//  LMKLocalizationTests.swift
//  LumiKitTests
//
//  Guards LumiKitDebug's string tables: every locale carries every English
//  key, no value equals its key, and the `Strings` defaults resolve to text.
//

import Foundation
import Testing
@testable import LumiKitDebug

struct LMKDebugLocalizationTests {
    private static let locales = ["en", "es", "zh-Hans", "zh-Hant"]

    private static func table(for locale: String) throws -> [String: String] {
        let url = try #require(
            lmkModuleBundle.url(forResource: "Localizable", withExtension: "strings", subdirectory: nil, localization: locale),
            "missing Localizable.strings for \(locale)"
        )
        return try #require(NSDictionary(contentsOf: url) as? [String: String])
    }

    @Test func `every locale carries every English key with a real value`() throws {
        let english = try Self.table(for: "en")
        #expect(!english.isEmpty)
        for locale in Self.locales {
            let table = try Self.table(for: locale)
            #expect(Set(table.keys) == Set(english.keys), "\(locale) key set differs from en")
            for (key, value) in table {
                #expect(!value.isEmpty, "\(locale) \(key) is empty")
                #expect(value != key, "\(locale) \(key) equals its key")
            }
        }
    }

    @Test func `format keys keep their specifiers in every locale`() throws {
        let english = try Self.table(for: "en")
        let specifiers = try NSRegularExpression(pattern: #"%(\d+\$)?(lld|@)"#)
        func sequence(_ value: String) -> [String] {
            specifiers.matches(in: value, range: NSRange(value.startIndex..., in: value)).compactMap { match in
                Range(match.range, in: value).map { String(value[$0]) }
            }
        }
        let formatKeys = english.filter { !sequence($0.value).isEmpty }.keys
        #expect(formatKeys.count >= 6, "the summary lines, the two notes, and the binary placeholder are formats")
        for locale in Self.locales {
            let table = try Self.table(for: locale)
            for key in formatKeys {
                #expect(sequence(table[key] ?? "") == sequence(english[key] ?? ""), "\(locale) \(key)")
            }
        }
    }

    @Test func `defaults resolve to localized text`() {
        #expect(LMKLocalized("networkRecord.errorStatus") != "networkRecord.errorStatus")
        #expect(LMKLocalized("networkHistory.title") != "networkHistory.title")
        #expect(LMKLocalized("networkHistory.clear.accessibilityLabel") != "networkHistory.clear.accessibilityLabel")
        #expect(LMKLocalized("networkDetail.copy.accessibilityLabel") != "networkDetail.copy.accessibilityLabel")
        #expect(LMKLocalized("networkDetail.section.summary") != "networkDetail.section.summary")
        #expect(LMKLocalized("networkRecord.binaryBody").contains("%lld"))
    }
}
