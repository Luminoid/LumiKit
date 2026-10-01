//
//  UIView+LMKLayerColors.swift
//  LumiKit
//
//  Shadows and borders whose `CGColor`s follow the theme, dark mode, and
//  Increase Contrast. A layer stores a snapshot, so one registration per view
//  re-resolves the sources whenever a color-affecting trait changes. Border
//  widths are whole pixels of the view's display.
//

import UIKit

private nonisolated(unsafe) var lmk_layerColorRestamperKey: UInt8 = 0

/// The color sources of a view's layer shadow and border, the border's width, plus the one
/// trait registration that re-stamps them (the width follows the display scale).
@MainActor
private final class LMKLayerColorRestamper {
    enum ShadowSource {
        case level(LMKShadow.Level)
        case style(LMKShadowStyle)
    }

    var shadow: ShadowSource?
    var borderColor: UIColor?
    /// The width asked for; `nil` = one hairline. Snapped to whole pixels when stamped.
    var borderWidth: CGFloat?
    var registration: (any UITraitChangeRegistration)?

    var isEmpty: Bool { shadow == nil && borderColor == nil }
}

public extension UIView {
    // MARK: - Shadow

    /// Applies the theme's shadow for `level` (`.none` clears it), resolved against this
    /// view's traits and re-stamped on theme, dark mode, and contrast changes. A visible
    /// shadow turns `masksToBounds` off, since a clipping layer cannot draw one.
    ///
    /// ```swift
    /// cardView.lmk_applyShadow(.level3)
    /// ```
    func lmk_applyShadow(_ level: LMKShadow.Level) {
        guard level != .none else {
            lmk_removeShadow()
            return
        }
        lmk_restamper(creating: true)?.shadow = .level(level)
        layer.masksToBounds = false
        lmk_restampLayerColors()
    }

    /// Applies `shadow`, resolving its color against this view's traits and re-stamping
    /// it on trait changes (a dynamic `color` therefore follows dark mode). A zero opacity
    /// clears the shadow; a visible one turns `masksToBounds` off.
    func lmk_applyShadow(_ shadow: LMKShadowStyle) {
        guard shadow.opacity > 0 else {
            lmk_removeShadow()
            return
        }
        lmk_restamper(creating: true)?.shadow = .style(shadow)
        layer.masksToBounds = false
        lmk_restampLayerColors()
    }

    /// Removes the shadow and stops re-stamping it.
    func lmk_removeShadow() {
        layer.shadowOpacity = 0
        layer.shadowColor = nil
        lmk_restamper(creating: false)?.shadow = nil
        lmk_releaseRestamperIfEmpty()
    }

    // MARK: - Border

    /// Applies a border, resolving `color` against this view's traits and re-stamping
    /// it on trait changes. `width` defaults to one physical pixel on this view's display
    /// and is rounded to whole pixels, so every edge renders the same thickness.
    ///
    /// ```swift
    /// view.lmk_applyBorder(color: LMKColor.outline)
    /// ```
    func lmk_applyBorder(color: UIColor, width: CGFloat? = nil) {
        let restamper = lmk_restamper(creating: true)
        restamper?.borderColor = color
        restamper?.borderWidth = width
        lmk_restampLayerColors()
        lmk_updateCornerPublication()
    }

    /// Removes the border and stops re-stamping it.
    func lmk_removeBorder() {
        layer.borderWidth = 0
        layer.borderColor = nil
        let restamper = lmk_restamper(creating: false)
        restamper?.borderColor = nil
        restamper?.borderWidth = nil
        lmk_releaseRestamperIfEmpty()
        lmk_updateCornerPublication()
    }

    // MARK: - Internals

    /// Whether a shadow or border source is registered for re-stamping. Test hook.
    internal var lmk_isRestampingLayerColors: Bool {
        lmk_restamper(creating: false) != nil
    }

    private func lmk_restamper(creating: Bool) -> LMKLayerColorRestamper? {
        if let existing = objc_getAssociatedObject(self, &lmk_layerColorRestamperKey) as? LMKLayerColorRestamper {
            return existing
        }
        guard creating else { return nil }
        let restamper = LMKLayerColorRestamper()
        restamper.registration = registerForTraitChanges([
            UITraitUserInterfaceStyle.self,
            UITraitAccessibilityContrast.self,
            UITraitUserInterfaceLevel.self,
            UITraitDisplayScale.self,
            LMKThemeTrait.self,
        ]) { (view: Self, _) in
            view.lmk_restampLayerColors()
        }
        objc_setAssociatedObject(self, &lmk_layerColorRestamperKey, restamper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return restamper
    }

    private func lmk_releaseRestamperIfEmpty() {
        guard let restamper = lmk_restamper(creating: false), restamper.isEmpty else { return }
        if let registration = restamper.registration {
            unregisterForTraitChanges(registration)
        }
        objc_setAssociatedObject(self, &lmk_layerColorRestamperKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    /// Re-resolves the stored shadow and border colors against the current traits.
    private func lmk_restampLayerColors() {
        guard let restamper = lmk_restamper(creating: false) else { return }
        if let shadow = restamper.shadow {
            let style: LMKShadowStyle = switch shadow {
            case let .level(level): traitCollection.lmkTheme.shadow.shadow(for: level).style
            case let .style(style): style
            }
            layer.shadowColor = style.color.resolvedColor(with: traitCollection).cgColor
            layer.shadowOffset = style.offset
            layer.shadowRadius = style.radius
            layer.shadowOpacity = style.opacity
        }
        if let borderColor = restamper.borderColor {
            layer.borderColor = borderColor.resolvedColor(with: traitCollection).cgColor
            layer.borderWidth = LMKLayout.pixelAligned(restamper.borderWidth ?? LMKLayout.hairline(for: self), for: self)
        }
    }
}
