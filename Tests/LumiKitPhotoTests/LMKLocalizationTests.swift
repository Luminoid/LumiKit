//
//  LMKLocalizationTests.swift
//  LumiKitTests
//
//  Guards LumiKitPhoto's string tables: every locale carries every English
//  key, no value equals its key, and the `Strings` defaults resolve to text.
//

import Foundation
import Testing
@testable import LumiKitPhoto

struct LMKPhotoLocalizationTests {
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
            #expect(table["photoBrowser.counter"]?.components(separatedBy: "%lld").count == 3, "\(locale) format specifiers")
            #expect(table["photoGrid.photo.accessibilityLabel"]?.components(separatedBy: "%lld").count == 3, "\(locale) grid cell format specifiers")
        }
    }

    @MainActor
    @Test func `Strings defaults resolve to localized text`() {
        #expect(LMKPhotoBrowserViewController.Strings().emptyText != "photoBrowser.empty")
        #expect(LMKPhotoBrowserViewController.Strings().counterFormat.contains("%lld"))
        #expect(LMKPhotoGridViewController.Strings().sortAscendingLabel != "photoGrid.sortAscending")
        #expect(LMKPhotoCropViewController.Strings().done != "photoCrop.done")
        #expect(LMKSharePreviewViewController.Strings().saveImage != "sharePreview.saveImage")
        #expect(LMKLocalized("photoBrowser.liveBadge") != "photoBrowser.liveBadge")
        #expect(LMKPhotoBrowserViewController.Strings().dismissAccessibilityLabel != "photoBrowser.dismiss.accessibilityLabel")
        #expect(LMKPhotoBrowserViewController.Strings().nextPhoto != "photoBrowser.nextPhoto")
        #expect(LMKPhotoGridViewController.Strings().photoAccessibilityLabelFormat.contains("%lld"))
        #expect(LMKPhotoCropViewController.Strings().aspectRatioAccessibilityLabel != "photoCrop.aspectRatio.accessibilityLabel")
        #expect(LMKSharePreviewViewController.Strings().closeAccessibilityLabel != "sharePreview.close.accessibilityLabel")
    }
}
