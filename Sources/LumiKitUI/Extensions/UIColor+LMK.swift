//
//  UIColor+LMK.swift
//  LumiKit
//
//  Color utility extensions for hex initialization and brightness inspection.
//

import UIKit

public nonisolated extension UIColor {
    /// Initialize from a 24-bit hex literal in `0xRRGGBB` form.
    ///
    /// Compile-time validated (no Optional, no force-unwrap) and avoids the
    /// string-parsing overhead of the `lmk_hex: String` initializer. Use for
    /// hardcoded color literals in code: design tokens, theme constants,
    /// generated themes:
    ///
    /// ```swift
    /// let violet = UIColor(lmk_hex: 0x7C5CFF)
    /// let withAlpha = UIColor(lmk_hex: 0x7C5CFF, alpha: 0.5)
    /// ```
    ///
    /// `lmk_hex` is the lowest 24 bits (`0x000000`...`0xFFFFFF`). Bits above
    /// the 24-bit window are ignored, so passing `0xFF7C5CFF` is the same as
    /// `0x7C5CFF`; pass `alpha` separately rather than packing it into the
    /// hex.
    convenience init(lmk_hex: UInt32, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat((lmk_hex & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((lmk_hex & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(lmk_hex & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }

    /// Whether two colors resolve identically in light and in dark mode.
    ///
    /// `UIColor ==` compares dynamic (provider) colors by identity, so two independently built
    /// themes never compare equal; this samples both interface styles instead.
    func lmk_isVisuallyEqual(to other: UIColor) -> Bool {
        if self == other { return true }
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            guard resolvedColor(with: traits) == other.resolvedColor(with: traits) else { return false }
        }
        return true
    }

    /// A trait-aware color that resolves to `light` or `dark` by interface style.
    static func lmk_dynamic(light: UIColor, dark: UIColor) -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        }
    }

    /// Initialize a dynamic light/dark color from two 24-bit hex literals.
    ///
    /// Trait-aware color that auto-resolves to the appropriate variant. The
    /// returned `UIColor` uses `UIColor { traitCollection in ... }` under the
    /// hood, so it tracks user interface style changes automatically.
    ///
    /// ```swift
    /// var primary: UIColor {
    ///     .lmk_dynamic(lightHex: 0x694ED9, darkHex: 0x553BBF)
    /// }
    /// ```
    ///
    /// Designed for theme files where every color has both a light and dark
    /// variant. Generated theme code uses this convenience to shrink each
    /// color declaration from ~5 lines of arithmetic to one line.
    static func lmk_dynamic(lightHex: UInt32, darkHex: UInt32, alpha: CGFloat = 1.0) -> UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(lmk_hex: darkHex, alpha: alpha)
                : UIColor(lmk_hex: lightHex, alpha: alpha)
        }
    }

    /// Initialize from hex string. Supports "#RRGGBB", "RRGGBB", "#RRGGBBAA", "RRGGBBAA";
    /// anything else (a `0x` prefix, a stray character, another length) is `nil`.
    ///
    /// ```swift
    /// let color = UIColor(lmk_hex: "#FF5733")
    /// let withAlpha = UIColor(lmk_hex: "#FF573380")
    /// ```
    convenience init?(lmk_hex: String) {
        var hex = lmk_hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") {
            hex.removeFirst()
        }

        guard hex.count == 6 || hex.count == 8, hex.utf8.allSatisfy(Self.lmk_isHexDigit) else { return nil }
        guard let rgbValue = UInt64(hex, radix: 16) else { return nil }

        if hex.count == 6 {
            self.init(
                red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                alpha: 1.0
            )
        } else {
            self.init(
                red: CGFloat((rgbValue & 0xFF00_0000) >> 24) / 255.0,
                green: CGFloat((rgbValue & 0x00FF_0000) >> 16) / 255.0,
                blue: CGFloat((rgbValue & 0x0000_FF00) >> 8) / 255.0,
                alpha: CGFloat(rgbValue & 0x0000_00FF) / 255.0
            )
        }
    }

    private static func lmk_isHexDigit(_ byte: UInt8) -> Bool {
        (UInt8(ascii: "0") ... UInt8(ascii: "9")).contains(byte)
            || (UInt8(ascii: "A") ... UInt8(ascii: "F")).contains(byte)
            || (UInt8(ascii: "a") ... UInt8(ascii: "f")).contains(byte)
    }

    /// Hex string representation (uppercase, without #).
    /// Returns `"RRGGBB"` for opaque colors and `"RRGGBBAA"` when alpha < 1.
    ///
    /// ```swift
    /// UIColor.red.lmk_hexString                         // "FF0000"
    /// UIColor.red.withAlphaComponent(0.5).lmk_hexString  // "FF000080"
    /// ```
    var lmk_hexString: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let ri = Int(round(min(max(r, 0), 1) * 255))
        let gi = Int(round(min(max(g, 0), 1) * 255))
        let bi = Int(round(min(max(b, 0), 1) * 255))
        let ai = Int(round(min(max(a, 0), 1) * 255))
        if ai == 255 {
            return String(format: "%02X%02X%02X", ri, gi, bi)
        }
        return String(format: "%02X%02X%02X%02X", ri, gi, bi, ai)
    }

    /// Whether this color is perceptually light (luminance > 0.5).
    /// Useful for choosing text color on a dynamic background.
    ///
    /// - Note: For dynamic/adaptive colors (e.g., `UIColor.systemBackground`), the result
    ///   depends on the current trait collection at call time. Call from a view context
    ///   with a resolved trait collection for accurate results.
    var lmk_isLight: Bool {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard getRed(&r, green: &g, blue: &b, alpha: &a) else { return false }
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance > 0.5
    }

    /// The color to draw glyphs and text in when this color is an accent: itself when it is
    /// dark enough, otherwise darkened by `factor` so a pale accent stays legible on light
    /// backgrounds. Use the raw accent only for translucent fills behind the glyph.
    func lmk_glyphTint(onLightAccentDarkenBy factor: CGFloat = 0.7) -> UIColor {
        lmk_isLight ? lmk_adjustedBrightness(by: factor) : self
    }

    /// Returns a new color with brightness adjusted by the given factor.
    /// Values > 1.0 lighten, < 1.0 darken.
    ///
    /// ```swift
    /// let lighter = color.lmk_adjustedBrightness(by: 1.2)
    /// let darker = color.lmk_adjustedBrightness(by: 0.8)
    /// ```
    func lmk_adjustedBrightness(by factor: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return self }
        return UIColor(
            hue: h,
            saturation: s,
            brightness: min(max(b * factor, 0), 1),
            alpha: a
        )
    }

    /// The shade a pressed or selected fill takes: darker by `factor` (a multiplier, `0.9` =
    /// 10% darker). A color that is already dark lightens by the same amount instead, where
    /// darkening would not show. Follows the color through appearance changes.
    ///
    /// ```swift
    /// let pressed = LMKColor.primary.lmk_stateShade(by: 0.9)
    /// ```
    func lmk_stateShade(by factor: CGFloat) -> UIColor {
        let amount = min(max(1 - factor, 0), 1)
        // Below this brightness darkening does not show, so the shade lightens.
        let darkFillBrightness: CGFloat = 0.35
        return UIColor { traits in
            let resolved = self.resolvedColor(with: traits)
            var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            guard resolved.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return resolved }
            let shaded = b < darkFillBrightness ? min(1, b + amount) : b * (1 - amount)
            return UIColor(hue: h, saturation: s, brightness: shaded, alpha: a)
        }
    }

    /// Returns a contrasting text color (white or black) based on this color's luminance.
    var lmk_contrastingTextColor: UIColor {
        lmk_isLight ? .black : .white
    }

    /// This color at `alpha` painted over `background`, as one opaque color that follows both
    /// colors through appearance changes. A tinted surface that floats over content uses it in
    /// place of a translucent fill, so what lies underneath never shows through.
    ///
    /// ```swift
    /// let surface = LMKColor.warning.lmk_composited(over: LMKColor.backgroundPrimary, alpha: 0.15)
    /// ```
    func lmk_composited(over background: UIColor, alpha: CGFloat) -> UIColor {
        let amount = min(max(alpha, 0), 1)
        return UIColor { traits in
            var top: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) = (0, 0, 0, 0)
            var base: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) = (0, 0, 0, 0)
            let resolvedBase = background.resolvedColor(with: traits)
            guard self.resolvedColor(with: traits).getRed(&top.r, green: &top.g, blue: &top.b, alpha: &top.a),
                  resolvedBase.getRed(&base.r, green: &base.g, blue: &base.b, alpha: &base.a)
            else { return resolvedBase }
            let weight = amount * top.a
            return UIColor(
                red: top.r * weight + base.r * (1 - weight),
                green: top.g * weight + base.g * (1 - weight),
                blue: top.b * weight + base.b * (1 - weight),
                alpha: base.a
            )
        }
    }
}
