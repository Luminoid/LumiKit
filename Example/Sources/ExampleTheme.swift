//
//  ExampleTheme.swift
//  LumiKitExample
//
//  Demonstrates how to create a custom theme for LumiKit.
//

import LumiKitUI
import UIKit

/// Example theme — customize colors for your app.
struct ExampleTheme: LMKTheme {
    // Brand
    var primary: UIColor { UIColor(red: 0.29, green: 0.69, blue: 0.49, alpha: 1.0) }      // #4CAF7D
    var primaryDark: UIColor { UIColor(red: 0.24, green: 0.59, blue: 0.42, alpha: 1.0) }
    var secondary: UIColor { UIColor(red: 0.35, green: 0.55, blue: 0.75, alpha: 1.0) }    // #598CBF
    var tertiary: UIColor { .systemBrown }

    // Semantic
    var success: UIColor { .systemGreen }
    var warning: UIColor { .systemOrange }
    var error: UIColor { .systemRed }
    var info: UIColor { .systemBlue }

    // Text
    var textPrimary: UIColor { .label }
    var textSecondary: UIColor { .secondaryLabel }
    var textTertiary: UIColor { .tertiaryLabel }

    // Backgrounds
    var backgroundPrimary: UIColor { .systemBackground }
    var backgroundSecondary: UIColor { .secondarySystemBackground }
    var backgroundTertiary: UIColor { .tertiarySystemBackground }

    // Neutral / Dividers
    var divider: UIColor { .separator }
    var imageBorder: UIColor { .separator }
    var graySoft: UIColor { UIColor(white: 0.75, alpha: 1) }
    var grayMuted: UIColor { UIColor(white: 0.85, alpha: 1) }
    var white: UIColor { UIColor(white: 0.98, alpha: 1) }
    var black: UIColor { UIColor(white: 0.1, alpha: 1) }
}
