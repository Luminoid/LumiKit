//
//  UIView+LMKBorder.swift
//  LumiKit
//
//  Border and corner radius application using design tokens.
//

import UIKit

public extension UIView {
    /// Apply border with color and width, optionally setting corner radius.
    ///
    /// - Parameters:
    ///   - color: Border color.
    ///   - width: Border width. Defaults to ``LMKLayout/hairline`` — one
    ///     physical pixel at the current screen scale. Pass an explicit width
    ///     for heavier strokes.
    ///   - cornerRadius: Optional corner radius. When provided, also sets `masksToBounds`.
    ///   - clipsToBounds: Whether to clip to bounds when `cornerRadius` is provided (default `true`).
    ///     Set to `false` when you need both a border with corner radius and a shadow.
    ///
    /// ```swift
    /// view.lmk_applyBorder(color: LMKColor.divider, cornerRadius: LMKCornerRadius.small)
    /// ```
    func lmk_applyBorder(color: UIColor, width: CGFloat = LMKLayout.hairline, cornerRadius: CGFloat? = nil, clipsToBounds: Bool = true) {
        layer.borderColor = color.cgColor
        layer.borderWidth = width
        if let cornerRadius {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = clipsToBounds
        }
    }

    /// Remove border from the view.
    func lmk_removeBorder() {
        layer.borderWidth = 0
        layer.borderColor = nil
    }

    /// Apply corner radius using design tokens.
    ///
    /// - Parameters:
    ///   - radius: Corner radius in points.
    ///   - masking: Whether to clip subviews to the rounded shape (default `true`).
    ///   - asConcentricContainer: On iOS 26 also publishes the radius as the
    ///     view's `cornerConfiguration`, which is what descendants using
    ///     ``lmk_applyConcentricCorners(minimumRadius:masking:)`` resolve against.
    ///     A bare `layer.cornerRadius` is invisible to that math (UIKit then
    ///     falls back to the display's corners). No effect before iOS 26.
    ///     Opt-in, because a published configuration is re-applied by UIKit at
    ///     layout and would override a later manual `layer.cornerRadius`.
    ///
    /// ```swift
    /// card.lmk_applyCornerRadius(LMKCornerRadius.xl, asConcentricContainer: true)
    /// innerChip.lmk_applyConcentricCorners(minimumRadius: LMKCornerRadius.small)
    /// ```
    func lmk_applyCornerRadius(_ radius: CGFloat, masking: Bool = true, asConcentricContainer: Bool = false) {
        layer.cornerRadius = radius
        layer.masksToBounds = masking
        if asConcentricContainer, #available(iOS 26, *) {
            cornerConfiguration = .corners(radius: .fixed(radius))
        }
    }

    /// Apply container-concentric corners (iOS 26+): UIKit derives the radius
    /// from the nearest ancestor that publishes a `cornerConfiguration` minus
    /// this view's inset from it, floored at `minimumRadius`, so a nested card,
    /// chip, or button stays concentric with its parent as either resizes.
    /// The container must publish its corners — `lmk_applyCornerRadius(_:asConcentricContainer: true)`
    /// or a direct `cornerConfiguration` — since a plain `layer.cornerRadius`
    /// is not consulted; with no such ancestor UIKit resolves against the
    /// display's corners, which is the right answer for floating chrome near a
    /// screen edge. Before iOS 26 this is a fixed `minimumRadius` via
    /// ``lmk_applyCornerRadius(_:masking:asConcentricContainer:)``.
    ///
    /// ```swift
    /// card.lmk_applyCornerRadius(LMKCornerRadius.xl, asConcentricContainer: true)
    /// innerCard.lmk_applyConcentricCorners(minimumRadius: LMKCornerRadius.small)
    /// ```
    func lmk_applyConcentricCorners(minimumRadius: CGFloat, masking: Bool = true) {
        if #available(iOS 26, *) {
            cornerConfiguration = .corners(radius: .containerConcentric(minimum: minimumRadius))
            layer.masksToBounds = masking
        } else {
            lmk_applyCornerRadius(minimumRadius, masking: masking)
        }
    }

    /// Make the view circular (uses half of the smallest dimension).
    /// Call after the view has been laid out (e.g., in `layoutSubviews`).
    func lmk_makeCircular() {
        let minDimension = min(bounds.width, bounds.height)
        layer.cornerRadius = minDimension / 2
        layer.masksToBounds = true
    }
}
