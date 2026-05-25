//
//  UIColor+LMK.swift
//  LumiKit
//
//  Color utility extensions for hex initialization and brightness inspection.
//

import UIKit

public extension UIColor {
    /// Initialize from a 24-bit hex literal in `0xRRGGBB` form.
    ///
    /// Compile-time validated (no Optional, no force-unwrap) and avoids the
    /// string-parsing overhead of the `lmk_hex: String` initializer. Use for
    /// hardcoded color literals in code — design tokens, theme constants,
    /// generated themes:
    ///
    /// ```swift
    /// let violet = UIColor(lmk_hex: 0x7C5CFF)
    /// let withAlpha = UIColor(lmk_hex: 0x7C5CFF, alpha: 0.5)
    /// ```
    ///
    /// `lmk_hex` is the lowest 24 bits (`0x000000`...`0xFFFFFF`). Bits above
    /// the 24-bit window are ignored, so passing `0xFF7C5CFF` is the same as
    /// `0x7C5CFF` — pass `alpha` separately rather than packing it into the
    /// hex.
    convenience init(lmk_hex: UInt32, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat((lmk_hex & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((lmk_hex & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(lmk_hex & 0x0000FF) / 255.0,
            alpha: alpha
        )
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

    /// Initialize from hex string. Supports "#RRGGBB", "RRGGBB", "#RRGGBBAA", "RRGGBBAA".
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

        guard hex.count == 6 || hex.count == 8 else { return nil }

        var rgbValue: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&rgbValue) else { return nil }

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

    /// Returns a contrasting text color (white or black) based on this color's luminance.
    var lmk_contrastingTextColor: UIColor {
        lmk_isLight ? .black : .white
    }
}
