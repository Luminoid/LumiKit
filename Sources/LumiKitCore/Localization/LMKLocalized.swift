//
//  LMKLocalized.swift
//  LumiKit
//
//  Module-internal lookup into this target's `Localizable.strings`
//  (Resources/<locale>.lproj). Every user-visible default string in the
//  module goes through here; hosts override per type via `Strings`.
//

import Foundation

/// This module's resource bundle.
@usableFromInline
nonisolated let lmkModuleBundle: Bundle = .module

/// Returns the localized string for `key` from this module's resource bundle.
///
/// Falls back to the key itself when the table has no entry, which the
/// localization parity tests treat as a failure.
@usableFromInline
nonisolated func LMKLocalized(_ key: String) -> String {
    String(localized: String.LocalizationValue(key), bundle: lmkModuleBundle)
}
