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

    @Test func `format keys keep their specifiers in every locale`() throws {
        for locale in Self.locales {
            let table = try Self.table(for: locale)
            #expect(table["pageIndicator.accessibilityValue"]?.components(separatedBy: "%lld").count == 3, "\(locale) format specifiers")
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

    @Test func `LMKLocalized formats arguments`() {
        let text = LMKLocalized("pageIndicator.accessibilityValue", 2, 5)
        #expect(text.contains("2"))
        #expect(text.contains("5"))
        #expect(!text.contains("%"))
    }
}
