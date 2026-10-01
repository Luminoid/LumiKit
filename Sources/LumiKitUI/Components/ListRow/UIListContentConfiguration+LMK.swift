//
//  UIListContentConfiguration+LMK.swift
//  LumiKit
//
//  Token treatments for the system list content configuration, for rows
//  that stay on `defaultContentConfiguration()`.
//

import UIKit

// A value-type helper without a theme argument: every read happens when the host configures the
// row, and a theme change reconfigures every `UIListContentConfiguration` anyway.
// swiftlint:disable no_global_token_proxies_in_components

public extension UIListContentConfiguration {
    /// The LumiKit text treatment: `primary` in `textPrimary`, `secondary` in `textSecondary`,
    /// both following Dynamic Type. Secondary lines are load-bearing (ids, reasons), so the
    /// default is `textSecondary`; `textTertiary` fails WCAG AA on cell backgrounds.
    mutating func lmk_applyTextStyle(primary: LMKTextStyle = .bodyMedium, secondary: LMKTextStyle = .caption, primaryColor: UIColor? = nil, secondaryColor: UIColor? = nil) {
        textProperties.font = LMKTypography.font(for: primary)
        textProperties.color = primaryColor ?? LMKColor.textPrimary
        textProperties.adjustsFontForContentSizeCategory = true
        secondaryTextProperties.font = LMKTypography.font(for: secondary)
        secondaryTextProperties.color = secondaryColor ?? LMKColor.textSecondary
        secondaryTextProperties.adjustsFontForContentSizeCategory = true
    }

    /// An SF Symbol in the leading image slot: inside a circle filled with translucent `tint`
    /// when `circle` (the `LMKListRowConfiguration.Leading.symbol` look), else the bare symbol
    /// sized into the same `LMKLayout.iconCircle` slot so icon rows align with thumbnail rows.
    ///
    /// The circle is a bitmap rendered for light and dark appearance (both registered on the
    /// image), so a visible row follows an appearance switch; a theme change still needs the row
    /// reconfigured, as every `UIListContentConfiguration` does.
    mutating func lmk_applyLeadingSymbol(_ systemName: String, tint: UIColor? = nil, circle: Bool = true) {
        let tint = tint ?? LMKColor.primary
        let side = LMKLayout.iconCircle
        if circle {
            let asset = UIImageAsset()
            var registered = false
            for style in [UIUserInterfaceStyle.light, .dark] {
                let traits = UITraitCollection(userInterfaceStyle: style)
                let resolvedTint = tint.resolvedColor(with: traits)
                guard let variant = LMKImage.makeSymbolImage(
                    systemName,
                    size: CGSize(width: side, height: side),
                    symbolPointSize: LMKLayout.iconExtraSmall,
                    tintColor: resolvedTint,
                    backgroundColor: resolvedTint.withAlphaComponent(LMKAlpha.xxs)
                ) else { continue }
                asset.register(variant, with: traits)
                registered = true
            }
            image = registered ? asset.image(with: UITraitCollection(userInterfaceStyle: .light)) : nil
            imageProperties.cornerRadius = side / 2
        } else {
            image = UIImage(systemName: systemName, withConfiguration: UIImage.SymbolConfiguration(pointSize: LMKLayout.symbolProminent))
            imageProperties.tintColor = tint
            imageProperties.cornerRadius = 0
        }
        imageProperties.maximumSize = CGSize(width: side, height: side)
        imageProperties.reservedLayoutSize = CGSize(width: side, height: side)
        lmk_applyMacIdiomMargins()
    }

    /// A square thumbnail in the leading image slot, or `fallbackSymbol` in the same slot when
    /// `image` is `nil`, so photo rows and icon rows align.
    ///
    /// - Parameters:
    ///   - image: The thumbnail (already downsampled for cell display).
    ///   - side: The slot side; `nil` = `LMKLayout.iconCircle`.
    ///   - cornerRadius: `nil` = `LMKCornerRadius.small`.
    ///   - fallbackSymbol: Shown without an image.
    ///   - fallbackTint: `nil` = `textTertiary`.
    mutating func lmk_applyThumbnail(_ image: UIImage?, side: CGFloat? = nil, cornerRadius: CGFloat? = nil, fallbackSymbol: String = "photo", fallbackTint: UIColor? = nil) {
        let side = side ?? LMKLayout.iconCircle
        if let image {
            self.image = image
            imageProperties.tintColor = nil
            imageProperties.cornerRadius = cornerRadius ?? LMKCornerRadius.small
        } else {
            self.image = UIImage(systemName: fallbackSymbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: LMKLayout.symbolProminent))
            imageProperties.tintColor = fallbackTint ?? LMKColor.textTertiary
            imageProperties.cornerRadius = 0
        }
        imageProperties.maximumSize = CGSize(width: side, height: side)
        imageProperties.reservedLayoutSize = CGSize(width: side, height: side)
        lmk_applyMacIdiomMargins()
    }

    /// The Mac idiom's default list-content margins are sized for compact text rows; against an
    /// image slot they collapse to a couple of points. Restores insets matching iPhone and iPad.
    private mutating func lmk_applyMacIdiomMargins() {
        guard UIDevice.current.userInterfaceIdiom == .mac else { return }
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: LMKSpacing.medium, leading: LMKSpacing.xl, bottom: LMKSpacing.medium, trailing: LMKSpacing.xl)
    }
}

// swiftlint:enable no_global_token_proxies_in_components
