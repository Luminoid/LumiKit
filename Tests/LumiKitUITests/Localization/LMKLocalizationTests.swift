//
//  LMKLocalizationTests.swift
//  LumiKitTests
//
//  Guards the shipped string tables: every locale carries every English key,
//  no value equals its key, and the `Strings` defaults resolve to real text
//  (a key coming back means the resource bundle is not wired).
//

import Foundation
import Testing
@testable import LumiKitUI

struct LMKLocalizationTests {
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

    /// Every English value with a format specifier keeps the same specifiers, in the same
    /// order (positional or not), in the other three tables.
    @Test func `format keys keep their specifiers in every locale`() throws {
        let english = try Self.table(for: "en")
        let formatKeys = english.filter { !Self.specifiers(in: $0.value).isEmpty }.keys
        #expect(formatKeys.count >= 4, "the format keys are counted")
        for locale in Self.locales {
            let table = try Self.table(for: locale)
            for key in formatKeys {
                #expect(Self.specifiers(in: table[key] ?? "") == Self.specifiers(in: english[key] ?? ""), "\(locale) \(key) format specifiers")
            }
        }
    }

    /// Every key looked up in this target's sources is in the English table, and every key in
    /// the table is looked up somewhere (no dead keys, no missing keys).
    @Test func `the keys in Sources match the English table`() throws {
        let english = try Self.table(for: "en")
        let pattern = try NSRegularExpression(pattern: #"LMKLocalized\("([^"]+)"\)"#)
        var looked: Set<String> = []
        let root = Self.sourcesDirectory
        let enumerator = try #require(FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil))
        for case let url as URL in enumerator where url.pathExtension == "swift" {
            let text = try String(contentsOf: url, encoding: .utf8)
            for match in pattern.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
                if let range = Range(match.range(at: 1), in: text) {
                    looked.insert(String(text[range]))
                }
            }
        }
        #expect(!looked.isEmpty, "no lookups under \(root.path)")
        #expect(looked.subtracting(english.keys).isEmpty, "looked up but missing from en: \(looked.subtracting(english.keys).sorted())")
        #expect(Set(english.keys).subtracting(looked).isEmpty, "in en but never looked up: \(Set(english.keys).subtracting(looked).sorted())")
    }

    private static let sourcesDirectory: URL = {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0 ..< 4 {
            url.deleteLastPathComponent()
        }
        return url.appendingPathComponent("Sources/LumiKitUI", isDirectory: true)
    }()

    /// The `%` specifiers in `value`, in order: `%@`, `%lld`, `%1$@`, `%2$lld`, and so on.
    private static func specifiers(in value: String) -> [String] {
        guard let pattern = try? NSRegularExpression(pattern: #"%(\d+\$)?(lld|d|@|f|\.\df)"#) else { return [] }
        return pattern.matches(in: value, range: NSRange(value.startIndex..., in: value)).compactMap {
            Range($0.range, in: value).map { String(value[$0]) }
        }
    }

    @MainActor
    @Test func `Strings defaults resolve to localized text`() {
        #expect(LMKAlert.Strings().ok != "alert.ok")
        #expect(LMKErrorHandler.Strings().retry != "errorHandler.retry")
        #expect(LMKActionSheet.Strings().submenuAccessibilityHint != "actionSheet.submenu.accessibilityHint")
        #expect(LMKNavigationBar.Strings().backAccessibilityLabel != "navigationBar.back.accessibilityLabel")
        #expect(LMKChipView.Strings().dismissAccessibilityLabel != "chip.dismiss.accessibilityLabel")
        #expect(LMKSkeletonView.Strings().loadingAccessibilityLabel != "skeletonCell.loading.accessibilityLabel")
        #expect(LMKSwitch.Strings().onAccessibilityValue != "switch.on.accessibilityValue")
        #expect(LMKPageIndicator.Strings().pageFormat.contains("%lld"))
        #expect(LMKTipView.Strings().dismissButtonTitle != "tip.dismissButton")
        #expect(LMKDatePicker.Strings().selectDatesPrompt != "datePicker.selectDatesPrompt")
        #expect(LMKBadgeView.Strings().dotAccessibilityLabel != "badge.dot.accessibilityLabel")
        #expect(LMKCheckboxCell.Strings().doneAccessibilityValue != "checkboxCell.done.accessibilityValue")
        #expect(LMKButton.Strings().offAccessibilityValue != "button.off.accessibilityValue")
        #expect(LMKFormKeyCommands.Strings().save != "formKeyCommands.save")
        #expect(LMKRatingControl.Strings().accessibilityValueFormat.contains("%lld"))
        #expect(LMKCopyableLabel.Strings().copy != "copyableLabel.copy")
        #expect(LMKPhotoButton.Strings().addAccessibilityLabel != "photoButton.add.accessibilityLabel")
        #expect(LMKMonthCalendarView.Strings().today != "monthCalendar.today")
        #expect(LMKSortMenu.Strings().layoutSectionTitle != "sortMenu.layout.title")
        #expect(LMKDetailCardView.Strings().photoAccessibilityLabelFormat.contains("%lld"))
        #expect(LMKDetailPageViewController.Strings().save != "detailPage.save")
    }
}
