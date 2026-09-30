//
//  LMKLocalized.swift
//  LumiKit
//
//  Module-internal lookup into this target's `Localizable.strings`
//  (Resources/<locale>.lproj). Every user-visible default string in the
//  module goes through here; hosts override per type via `Strings`.
//

import Foundation

private final class LMKBundleFinder {}

/// This module's resource bundle.
///
/// SwiftPM generates `Bundle.module` under the target's default isolation, which makes it
/// MainActor-only in the UI modules; strings are read from nonisolated `Strings` initializers,
/// so the bundle is located here with the same candidates the generated accessor uses.
nonisolated let lmkModuleBundle: Bundle = {
    let bundleName = "LumiKit_LumiKitDebug"
    let finder = Bundle(for: LMKBundleFinder.self)
    let candidates: [URL?] = [
        Bundle.main.resourceURL,
        finder.resourceURL,
        Bundle.main.bundleURL,
        finder.bundleURL.deletingLastPathComponent(),
    ]
    for candidate in candidates {
        guard let url = candidate?.appendingPathComponent("\(bundleName).bundle"), let bundle = Bundle(url: url) else { continue }
        return bundle
    }
    fatalError("LumiKit: unable to locate the resource bundle \(bundleName)")
}()

/// Returns the localized string for `key` from this module's resource bundle.
///
/// Falls back to the key itself when the table has no entry, which the
/// localization parity tests treat as a failure.
@usableFromInline
nonisolated func LMKLocalized(_ key: String) -> String {
    String(localized: String.LocalizationValue(key), bundle: lmkModuleBundle)
}

/// Localized format string filled with `arguments` (`%lld`, `%@`, …).
@usableFromInline
nonisolated func LMKLocalized(_ key: String, _ arguments: CVarArg...) -> String {
    String(format: LMKLocalized(key), arguments: arguments)
}
