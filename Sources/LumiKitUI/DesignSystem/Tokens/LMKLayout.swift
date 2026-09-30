//
//  LMKLayout.swift
//  LumiKit
//
//  Layout dimension tokens. Proxies to `LMKTheme.current.layout`, except
//  `hairline`, which is display physics rather than branding.
//

import UIKit

/// Layout dimension tokens.
///
/// Usage: `button.snp.makeConstraints { $0.size.equalTo(LMKLayout.minimumTouchTarget) }`
public nonisolated enum LMKLayout {
    private static var config: LMKLayoutTheme {
        LMKTheme.current.layout
    }

    // MARK: Touch targets and icon frames

    /// HIG minimum hit target (44pt).
    public static var minimumTouchTarget: CGFloat { config.minimumTouchTarget }
    public static var iconMedium: CGFloat { config.iconMedium }
    public static var iconLarge: CGFloat { config.iconLarge }
    public static var iconSmall: CGFloat { config.iconSmall }
    public static var iconExtraSmall: CGFloat { config.iconExtraSmall }
    /// Tinted circle behind a list-row symbol.
    public static var iconCircle: CGFloat { config.iconCircle }

    // MARK: SF Symbol point sizes

    public static var symbolMicro: CGFloat { config.symbolMicro }
    public static var symbolBadge: CGFloat { config.symbolBadge }
    public static var symbolAccessory: CGFloat { config.symbolAccessory }
    public static var symbolInline: CGFloat { config.symbolInline }
    public static var symbolRow: CGFloat { config.symbolRow }
    public static var symbolProminent: CGFloat { config.symbolProminent }
    public static var symbolAction: CGFloat { config.symbolAction }
    public static var symbolLarge: CGFloat { config.symbolLarge }
    public static var symbolPlaceholder: CGFloat { config.symbolPlaceholder }
    public static var symbolIllustration: CGFloat { config.symbolIllustration }
    public static var symbolHero: CGFloat { config.symbolHero }

    // MARK: Row heights

    public static var rowHeightCompact: CGFloat { config.rowHeightCompact }
    public static var rowHeight: CGFloat { config.rowHeight }
    public static var rowHeightComfortable: CGFloat { config.rowHeightComfortable }
    public static var rowHeightEstimated: CGFloat { config.rowHeightEstimated }
    public static var cellHeightMin: CGFloat { config.cellHeightMin }

    // MARK: Readable width

    /// Maximum content width on wide canvases.
    public static var readableContentMaxWidth: CGFloat { config.readableContentMaxWidth }

    // MARK: Component metrics

    public static var pullThreshold: CGFloat { config.pullThreshold }

    // MARK: Hairline

    /// One physical pixel at `scale` (1pt at 1x, 0.5pt at 2x, 1/3pt at 3x). Not themeable.
    public static func hairline(forScale scale: CGFloat) -> CGFloat {
        1 / max(1, scale)
    }

    /// One physical pixel on the key window's display (falls back to 2x when there is no window).
    @MainActor public static var hairline: CGFloat {
        hairline(forScale: LMKScene.displayScale(of: LMKScene.keyWindow) ?? 2)
    }

    /// One physical pixel on the display `view` is rendered on.
    @MainActor public static func hairline(for view: UIView) -> CGFloat {
        guard let scale = LMKScene.displayScale(of: view) else { return hairline }
        return hairline(forScale: scale)
    }

    // MARK: Pixel alignment

    /// `length` rounded to whole physical pixels at `scale`, at least one pixel for a positive
    /// length. A line whose width is a fraction of a pixel (1.5pt at 3x is 4.5 pixels) renders
    /// one pixel thicker on some edges than on others.
    public static func pixelAligned(_ length: CGFloat, scale: CGFloat) -> CGFloat {
        guard length > 0 else { return 0 }
        let scale = max(1, scale)
        return max(1, (length * scale).rounded()) / scale
    }

    /// `length` rounded to whole physical pixels on the display `view` is rendered on.
    @MainActor public static func pixelAligned(_ length: CGFloat, for view: UIView) -> CGFloat {
        pixelAligned(length, scale: LMKScene.displayScale(of: view) ?? LMKScene.screenScale)
    }
}
