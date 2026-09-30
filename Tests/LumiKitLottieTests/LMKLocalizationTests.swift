//
//  LMKLocalizationTests.swift
//  LumiKitTests
//
//  Guards LumiKitLottie's string tables: every locale carries every English
//  key, no value equals its key, and the bundled animation is present.
//

import Foundation
import Testing
@testable import LumiKitLottie

struct LMKLottieLocalizationTests {
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

    @Test func `defaults resolve to localized text and the animation ships`() {
        #expect(LMKLocalized("refreshControl.refresh") != "refreshControl.refresh")
        #expect(lmkModuleBundle.url(forResource: "refresh_spinner", withExtension: "json") != nil)
    }
}
