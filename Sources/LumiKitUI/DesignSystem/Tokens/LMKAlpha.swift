//
//  LMKAlpha.swift
//  LumiKit
//
//  Opacity tokens. Proxies to `LMKTheme.current.alpha`.
//

import UIKit

/// Opacity tokens: a seven-step ramp plus `dimming` and `disabled`.
///
/// Usage: `overlay.backgroundColor = LMKColor.scrim.withAlphaComponent(LMKAlpha.dimming)`
public nonisolated enum LMKAlpha {
    private static var config: LMKAlphaTheme {
        LMKTheme.current.alpha
    }

    public static var xxs: CGFloat { config.xxs }
    public static var xs: CGFloat { config.xs }
    public static var small: CGFloat { config.small }
    public static var medium: CGFloat { config.medium }
    public static var large: CGFloat { config.large }
    public static var xl: CGFloat { config.xl }
    public static var xxl: CGFloat { config.xxl }
    /// Dimming view behind sheets and panels.
    public static var dimming: CGFloat { config.dimming }
    /// Disabled controls.
    public static var disabled: CGFloat { config.disabled }
}
