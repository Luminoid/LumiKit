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
        }
    }

    /// The format specifiers of a value (`%lld`, `%@`, positional ones included), in order.
    private static func specifiers(in value: String) throws -> [String] {
        let pattern = try NSRegularExpression(pattern: #"%(\d+\$)?(lld|@)"#)
        return pattern.matches(in: value, range: NSRange(value.startIndex..., in: value)).compactMap { Range($0.range, in: value).map { String(value[$0]) } }
    }

    @Test func `every format key carries the same specifiers in every locale`() throws {
        let english = try Self.table(for: "en")
        let formatKeys = try english.filter { try !Self.specifiers(in: $0.value).isEmpty }.map(\.key)
        #expect(formatKeys.count == 3, "\(formatKeys.sorted())")
        for locale in Self.locales {
            let table = try Self.table(for: locale)
            for key in formatKeys {
                #expect(try Self.specifiers(in: table[key] ?? "") == Self.specifiers(in: english[key] ?? ""), "\(locale) \(key)")
            }
        }
    }

    @Test func `every key the sources look up is in the tables, and every key is looked up`() throws {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0 ..< 3 {
            url.deleteLastPathComponent()
        }
        let sources = url.appendingPathComponent("Sources/LumiKitPhoto", isDirectory: true)
        let enumerator = try #require(FileManager.default.enumerator(at: sources, includingPropertiesForKeys: nil))
        let pattern = try NSRegularExpression(pattern: #"LMKLocalized\("([^"]+)"\)"#)
        var lookedUp: Set<String> = []
        for case let file as URL in enumerator where file.pathExtension == "swift" {
            let contents = try String(contentsOf: file, encoding: .utf8)
            for match in pattern.matches(in: contents, range: NSRange(contents.startIndex..., in: contents)) {
                if let range = Range(match.range(at: 1), in: contents) {
                    lookedUp.insert(String(contents[range]))
                }
            }
        }
        let english = try Self.table(for: "en")
        #expect(!lookedUp.isEmpty)
        #expect(lookedUp == Set(english.keys), "missing from en: \(lookedUp.subtracting(english.keys).sorted()); dead in en: \(Set(english.keys).subtracting(lookedUp).sorted())")
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
        #expect(LMKPhotoCropViewController.Strings().cropFrameAccessibilityValueFormat.contains("%lld"))
        #expect(LMKSharePreviewViewController.Strings().closeAccessibilityLabel != "sharePreview.close.accessibilityLabel")
        #expect(LMKPhotoPickCropCoordinator.Strings().loadFailedMessage != "photoPickCrop.loadFailed")
    }
}
