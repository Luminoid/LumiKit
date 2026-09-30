//
//  LMKTextMeasurement.swift
//  LumiKit
//
//  Width and line height of a text style resolved against a view's traits, for
//  components that pin widths or height floors to their labels (segment widths,
//  bar row heights) and must re-measure on Dynamic Type and theme changes.
//

import UIKit

enum LMKTextMeasurement {
    /// The font `style` resolves to under `traits` (theme and content size category).
    static func font(for style: LMKTextStyle, traits: UITraitCollection) -> UIFont {
        traits.lmkTheme.typography.font(for: style, compatibleWith: traits)
    }

    /// Rendered width of `text` in `style`, rounded up to a whole point.
    static func width(of text: String, style: LMKTextStyle, traits: UITraitCollection) -> CGFloat {
        let size = (text as NSString).size(withAttributes: [.font: font(for: style, traits: traits)])
        return size.width.rounded(.up)
    }

    /// Line height of `style`, rounded up to a whole point.
    static func lineHeight(of style: LMKTextStyle, traits: UITraitCollection) -> CGFloat {
        font(for: style, traits: traits).lineHeight.rounded(.up)
    }
}
