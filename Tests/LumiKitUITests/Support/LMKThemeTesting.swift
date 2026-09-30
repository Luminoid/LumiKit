//
//  LMKThemeTesting.swift
//  LumiKit
//
//  Theme scoping for tests without touching the process-wide store. UIKit only
//  propagates trait overrides inside a window, so views are hosted in one.
//

import UIKit
@testable import LumiKitUI

@MainActor
enum LMKThemeTesting {
    /// A theme whose every value differs from the default: solid distinct colors, odd
    /// dimensions, a serif family, and unique durations, so an assertion that a component
    /// follows the theme cannot pass by coincidence.
    static let distinct = LMKTheme(
        colors: LMKColorTheme(
            primary: .systemPurple,
            primaryVariant: .systemIndigo,
            secondary: .systemTeal,
            tertiary: .systemBrown,
            success: .systemMint,
            warning: .systemYellow,
            error: .systemPink,
            info: .systemCyan,
            onAccent: .black,
            textPrimary: .darkGray,
            textSecondary: .gray,
            textTertiary: .lightGray,
            link: .systemOrange,
            backgroundPrimary: UIColor(white: 0.95, alpha: 1),
            backgroundSecondary: UIColor(white: 0.9, alpha: 1),
            backgroundTertiary: UIColor(white: 0.85, alpha: 1),
            divider: .magenta,
            outline: .cyan,
            fill: .brown,
            fillStrong: .orange,
            scrim: .blue,
            pressedOverlay: .green,
            selection: .yellow,
            highContrastBoost: 0.2
        ),
        typography: LMKTypographyTheme(
            fontFamily: "Georgia",
            h1Size: 31, h2Size: 25, h3Size: 21, h4Size: 19,
            bodySize: 17, subbodySize: 15, captionSize: 13.5, smallSize: 11.5,
            extraSmallSize: 10.5, extraExtraSmallSize: 9.5,
            headingLineHeightMultiplier: 1.3, bodyLineHeightMultiplier: 1.6,
            captionLineHeightMultiplier: 1.45, smallLineHeightMultiplier: 1.35,
            headingLetterSpacing: -0.7, bodyLetterSpacing: 0.1, smallLetterSpacing: 0.7,
            maximumScale: 1.5
        ),
        spacing: LMKSpacingTheme(xxs: 3, xs: 5, small: 9, medium: 13, large: 17, xl: 21, xxl: 25),
        cornerRadius: LMKCornerRadiusTheme(xs: 3, small: 7, medium: 11, large: 15, xl: 19, xxl: 23),
        shadow: LMKShadowTheme(
            iconOverlayOpacity: 0.7,
            level1: .init(offset: CGSize(width: 1, height: 1), radius: 3, opacity: 0.9, lightAlpha: 0.2, darkAlpha: 0.5),
            level2: .init(offset: CGSize(width: 1, height: 3), radius: 5, opacity: 0.9, lightAlpha: 0.25, darkAlpha: 0.55),
            level3: .init(offset: CGSize(width: 1, height: 3), radius: 9, opacity: 0.9, lightAlpha: 0.2, darkAlpha: 0.5),
            level4: .init(offset: CGSize(width: 1, height: 5), radius: 13, opacity: 0.9, lightAlpha: 0.2, darkAlpha: 0.5),
            level5: .init(offset: CGSize(width: 1, height: 9), radius: 25, opacity: 0.9, lightAlpha: 0.22, darkAlpha: 0.6)
        ),
        alpha: LMKAlphaTheme(xxs: 0.11, xs: 0.16, small: 0.21, medium: 0.31, large: 0.51, xl: 0.71, xxl: 0.81, dimming: 0.41, disabled: 0.39),
        animation: LMKAnimationTheme(instant: 0.11, fast: 0.16, normal: 0.26, moderate: 0.31, slow: 0.36, emphasis: 0.51, shimmer: 1.9)
    )

    /// A trait collection carrying `theme`, for resolving `LMKColor.*` without a view.
    static func traits(
        for theme: LMKTheme,
        style: UIUserInterfaceStyle = .light,
        contrast: UIAccessibilityContrast = .normal
    ) -> UITraitCollection {
        UITraitCollection { traits in
            traits.lmkTheme = LMKThemeReference(theme)
            traits.userInterfaceStyle = style
            traits.accessibilityContrast = contrast
        }
    }

    /// Sizes `view` to its compressed fitting height at `width` and lays it out.
    static func fit(_ view: UIView, width: CGFloat = 320) {
        let size = view.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        view.frame = CGRect(origin: .zero, size: CGSize(width: width, height: size.height))
        view.layoutIfNeeded()
    }

    /// Hosts `view` in a visible window scoped to `theme` and updates its traits.
    /// Keep the returned window alive for the duration of the test.
    static func host(
        _ view: UIView,
        theme: LMKTheme? = nil,
        style: UIUserInterfaceStyle? = nil,
        contrast: UIAccessibilityContrast? = nil,
        size: CGSize = CGSize(width: 390, height: 844)
    ) -> UIWindow {
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        if let theme {
            window.traitOverrides.lmkTheme = LMKThemeReference(theme)
        }
        if let style {
            window.traitOverrides.userInterfaceStyle = style
        }
        if let contrast {
            window.traitOverrides.accessibilityContrast = contrast
        }
        window.addSubview(view)
        window.isHidden = false
        view.updateTraitsIfNeeded()
        window.layoutIfNeeded()
        return window
    }
}
