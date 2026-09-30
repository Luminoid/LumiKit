//
//  LMKLocalized.swift
//  LumiKit
//
//  Module-internal lookup into this target's `Localizable.strings`
//  (Resources/<locale>.lproj) and the bundle that carries the Lottie asset.
//

import Foundation

private final class LMKBundleFinder {}

/// This module's resource bundle.
///
/// SwiftPM generates `Bundle.module` under the target's default isolation, which makes it
/// MainActor-only; strings are read from nonisolated `Strings` initializers, so the bundle is
/// located here with the same candidates the generated accessor uses.
nonisolated let lmkModuleBundle: Bundle = {
    let bundleName = "LumiKit_LumiKitLottie"
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
