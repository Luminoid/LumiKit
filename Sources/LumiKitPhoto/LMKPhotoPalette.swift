//
//  LMKPhotoPalette.swift
//  LumiKit
//
//  Default colors of the forced-dark photo chrome (browser, crop editor). These are
//  not theme roles: the photo screens force `overrideUserInterfaceStyle = .dark`
//  and keep a near-black stage regardless of the app theme; each screen's `Style`
//  overrides them per instance or through its theme slot.
//

import UIKit

/// Default palette of the forced-dark photo screens.
nonisolated enum LMKPhotoPalette {
    /// Stage behind photos and the crop editor.
    static let background = UIColor(white: 0.1, alpha: 1)
    /// Foreground on the dark stage (counter, buttons, crop handles).
    static let foreground = UIColor.white
    /// Backing of the LIVE badge over a photo (at an alpha), in the grid as in the browser: the
    /// badge sits on the photo, not on the screen's background, so it keeps one look in every
    /// appearance mode.
    static let badgeBacking = UIColor.black
}
