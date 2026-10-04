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
    /// dark enough, otherwise darkened by `factor` so a pale accent stays legible on a light
    /// page. Resolved per appearance: in Dark Mode the page is dark, so a light accent (the
    /// dark-mode tone of a tonal theme) is drawn as is. Use the raw accent only for translucent
    /// fills behind the glyph.
    func lmk_glyphTint(onLightAccentDarkenBy factor: CGFloat = 0.7) -> UIColor {
        UIColor { traits in
            let resolved = self.resolvedColor(with: traits)
            guard traits.userInterfaceStyle != .dark, resolved.lmk_isLight else { return resolved }
            return resolved.lmk_adjustedBrightness(by: factor)
        }
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

    // MARK: - WCAG contrast

    /// The WCAG 2 relative luminance of this color resolved with `traits`: `0` for black, `1`
    /// for white. Alpha is ignored; channels outside the sRGB range (extended or Display P3
    /// colors) are clamped first, as the WCAG formula is defined for sRGB.
    ///
    /// ```swift
    /// UIColor(lmk_hex: 0x777777).lmk_relativeLuminance(resolvedWith: view.traitCollection)   // ≈ 0.184
    /// ```
    func lmk_relativeLuminance(resolvedWith traits: UITraitCollection) -> CGFloat {
        Self.lmk_luminance(of: Self.lmk_components(of: self, resolvedWith: traits))
    }

    /// The WCAG 2 contrast ratio between this color and `other`, both resolved with `traits`:
    /// from `1` (identical) to `21` (black on white). A translucent color is composited over
    /// `other` first, as it would be drawn; `other` is read as opaque. WCAG asks for 4.5 for body
    /// text, 3 for large text and for graphics such as icons.
    ///
    /// ```swift
    /// let ratio = glyphColor.lmk_contrastRatio(to: tileBackground, resolvedWith: traitCollection)
    /// ```
    func lmk_contrastRatio(to other: UIColor, resolvedWith traits: UITraitCollection) -> CGFloat {
        let background = Self.lmk_components(of: other, resolvedWith: traits)
        let foreground = Self.lmk_flattened(Self.lmk_components(of: self, resolvedWith: traits), over: background)
        return Self.lmk_ratio(Self.lmk_luminance(of: foreground), Self.lmk_luminance(of: background))
    }

    /// The softest tone of this color that still stands out against a wash of it: the color for
    /// a glyph drawn on a tile tinted with the same color at `washAlpha` over `background`.
    ///
    /// While the color has contrast to spare against the wash, the tone mixes toward
    /// `background` as far as the WCAG ratio stays at or above `minimumContrast`, so the glyph
    /// reads soft rather than heavy. When even the color itself falls short, the tone moves away
    /// from the wash just far enough instead: darker on a light wash (keeping the hue), lighter on
    /// a dark one. A ratio no tone can reach returns black or white, whichever comes closer.
    /// The result is opaque and resolved for `traits`; a translucent color is composited over
    /// `background` first. Wrap the call in `UIColor { traits in … }` for a color that follows
    /// appearance changes.
    ///
    /// ```swift
    /// let glyph = accent.lmk_softestTone(over: LMKColor.backgroundPrimary, washAlpha: 0.1, minimumContrast: 3, resolvedWith: traitCollection)
    /// ```
    ///
    /// - Parameters:
    ///   - background: The color under the wash (the page or card the tile sits on).
    ///   - washAlpha: The opacity of the color's wash over `background`, `0 ... 1`; `0` measures
    ///     the glyph against `background` itself.
    ///   - minimumContrast: The WCAG ratio the glyph keeps against the wash (3 for graphics).
    ///   - traits: The trait collection both colors resolve with.
    func lmk_softestTone(over background: UIColor, washAlpha: CGFloat, minimumContrast: CGFloat, resolvedWith traits: UITraitCollection) -> UIColor {
        var page = Self.lmk_components(of: background, resolvedWith: traits)
        page.alpha = 1
        let base = Self.lmk_flattened(Self.lmk_components(of: self, resolvedWith: traits), over: page)
        let wash = Self.lmk_mix(page, base, amount: min(max(washAlpha, 0), 1))
        let washLuminance = Self.lmk_luminance(of: wash)
        let target = max(1, minimumContrast)
        func contrast(_ tone: LMKRGBA) -> CGFloat {
            Self.lmk_ratio(Self.lmk_luminance(of: tone), washLuminance)
        }

        let baseLuminance = Self.lmk_luminance(of: base)
        if contrast(base) >= target {
            // Mix toward the page while the tone stays on the base's side of the wash: past the
            // wash the ratio climbs again toward the page's, which is no glyph at all.
            let baseIsLighter = baseLuminance >= washLuminance
            let amount = Self.lmk_largestPassing { amount in
                let tone = Self.lmk_mix(base, page, amount: amount)
                let luminance = Self.lmk_luminance(of: tone)
                return (luminance >= washLuminance) == baseIsLighter && Self.lmk_ratio(luminance, washLuminance) >= target
            }
            return Self.lmk_color(Self.lmk_mix(base, page, amount: amount))
        }

        // Even the base falls short: away from the wash, toward whichever of black and white
        // stands out against it more.
        if Self.lmk_ratio(1, washLuminance) > Self.lmk_ratio(0, washLuminance) {
            let white = LMKRGBA(red: 1, green: 1, blue: 1, alpha: 1)
            let kept = Self.lmk_largestPassing { kept in contrast(Self.lmk_mix(base, white, amount: 1 - kept)) >= target }
            return Self.lmk_color(Self.lmk_mix(base, white, amount: 1 - kept))
        }
        let factor = Self.lmk_largestPassing { factor in contrast(Self.lmk_scaled(base, by: factor)) >= target }
        return Self.lmk_color(Self.lmk_scaled(base, by: factor))
    }

    /// sRGB components, clamped to `0 ... 1`.
    private nonisolated struct LMKRGBA: Sendable {
        var red: CGFloat
        var green: CGFloat
        var blue: CGFloat
        var alpha: CGFloat
    }

    private static func lmk_components(of color: UIColor, resolvedWith traits: UITraitCollection) -> LMKRGBA {
        let resolved = color.resolvedColor(with: traits)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 1
        if !resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            var white: CGFloat = 0
            guard resolved.getWhite(&white, alpha: &alpha) else { return LMKRGBA(red: 0, green: 0, blue: 0, alpha: 1) }
            (red, green, blue) = (white, white, white)
        }
        func clamped(_ value: CGFloat) -> CGFloat {
            min(max(value, 0), 1)
        }
        return LMKRGBA(red: clamped(red), green: clamped(green), blue: clamped(blue), alpha: clamped(alpha))
    }

    private static func lmk_luminance(of color: LMKRGBA) -> CGFloat {
        func linear(_ channel: CGFloat) -> CGFloat {
            channel <= 0.040_45 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(color.red) + 0.7152 * linear(color.green) + 0.0722 * linear(color.blue)
    }

    private static func lmk_ratio(_ first: CGFloat, _ second: CGFloat) -> CGFloat {
        (max(first, second) + 0.05) / (min(first, second) + 0.05)
    }

    /// `from` moved toward `to` by `amount` (`0` = `from`, `1` = `to`), opaque.
    private static func lmk_mix(_ from: LMKRGBA, _ to: LMKRGBA, amount: CGFloat) -> LMKRGBA {
        LMKRGBA(
            red: from.red + (to.red - from.red) * amount,
            green: from.green + (to.green - from.green) * amount,
            blue: from.blue + (to.blue - from.blue) * amount,
            alpha: 1
        )
    }

    /// `color` painted at its own alpha over an opaque `background`.
    private static func lmk_flattened(_ color: LMKRGBA, over background: LMKRGBA) -> LMKRGBA {
        lmk_mix(background, color, amount: color.alpha)
    }

    /// Every channel times `factor`: the HSB brightness scaled with hue and saturation kept.
    private static func lmk_scaled(_ color: LMKRGBA, by factor: CGFloat) -> LMKRGBA {
        LMKRGBA(red: color.red * factor, green: color.green * factor, blue: color.blue * factor, alpha: 1)
    }

    private static func lmk_color(_ color: LMKRGBA) -> UIColor {
        UIColor(red: color.red, green: color.green, blue: color.blue, alpha: color.alpha)
    }

    /// The largest `x` in `0 ... 1` for which `passes(x)`, given that it holds at `0` and stops
    /// holding at a single point (bisection); `0` when nothing passes.
    private static func lmk_largestPassing(_ passes: (CGFloat) -> Bool) -> CGFloat {
        guard !passes(1) else { return 1 }
        var low: CGFloat = 0, high: CGFloat = 1
        for _ in 0 ..< 20 {
            let middle = (low + high) / 2
            if passes(middle) { low = middle } else { high = middle }
        }
        return low
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
