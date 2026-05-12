//
//  LMKHighlightable.swift
//  LumiKit
//
//  Protocol-driven custom highlight for cells. `UITableViewCell` and
//  `UICollectionViewCell` both conform out of the box; subclasses route
//  their highlight/select state changes into `lmk_applyCustomHighlight` and
//  get the dark-overlay tap feedback with Reduce Motion + dark-mode
//  awareness for free.
//

import ObjectiveC
import SnapKit
import UIKit

// MARK: - Protocol

/// Anything with a `contentView` that wants the LumiKit custom highlight.
/// Conformances ship for `UITableViewCell` and `UICollectionViewCell`; add
/// more if a future container type exposes a `contentView` worth tinting.
public protocol LMKHighlightable: UIView {
    var contentView: UIView { get }
}

extension UITableViewCell: LMKHighlightable {}
extension UICollectionViewCell: LMKHighlightable {}

// MARK: - Shared highlight constants

/// Module-internal so `UITableViewCell+LMKHighlight.swift` can read the same
/// overlay color when configuring `selectedBackgroundView` — keeps the two
/// highlight APIs visually identical without a duplicated color literal.
enum LMKHighlightConstants {
    static let darkModeOverlayAlpha = LMKAlpha.overlayDark
    static let lightModeOverlayAlpha = LMKAlpha.overlayLight
    static let animationDuration = LMKAnimationHelper.Duration.uiShort
    static let containerDetectionSubviewsThreshold = 2

    /// In dark mode the card itself is already dark, so a black overlay
    /// barely registers — use a light (white) overlay instead to actually
    /// lighten the surface. Light mode keeps the black-on-light darkening.
    static var highlightOverlayColor: UIColor {
        UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                LMKColor.white.withAlphaComponent(darkModeOverlayAlpha)
            } else {
                LMKColor.black.withAlphaComponent(lightModeOverlayAlpha)
            }
        }
    }
}

// MARK: - LMKHighlightable + Custom Highlight

public extension LMKHighlightable {
    /// Apply custom highlight effect to the cell. Call from
    /// `setHighlighted(_:animated:)` / `setSelected(_:animated:)` (table
    /// cells) or from `isHighlighted` / `isSelected` `didSet` (collection
    /// cells — those properties aren't surfaced as `setX` methods).
    func lmk_applyCustomHighlight(highlighted: Bool, animated: Bool) {
        let darkOverlayColor = LMKHighlightConstants.highlightOverlayColor
        let containerViews = lmk_findContainerViews(in: contentView)
        let shouldAnimate = animated && LMKAnimationHelper.shouldAnimate

        // Install overlay views BEFORE entering the animation block. CALayer
        // cornerRadius isn't animated implicitly, so a layer added inside
        // `UIView.animate` can flash for one frame as a rectangle before
        // the radius takes effect. Creating the overlay synchronously here
        // (alpha 0) and only animating the alpha avoids that first-frame
        // square flicker on the initial highlight.
        if highlighted, !containerViews.isEmpty {
            for cv in containerViews {
                cv.lmk_installDarkOverlay(color: darkOverlayColor)
            }
        }

        let applyHighlight = {
            if highlighted {
                if !containerViews.isEmpty {
                    for cv in containerViews {
                        cv.lmk_highlightOverlay?.alpha = 1.0
                    }
                } else {
                    self.contentView.backgroundColor = darkOverlayColor
                }
            } else {
                if !containerViews.isEmpty {
                    for cv in containerViews {
                        cv.lmk_highlightOverlay?.alpha = 0.0
                    }
                } else {
                    self.contentView.backgroundColor = .clear
                }
            }
        }

        let removeOverlaysIfNeeded = {
            if !highlighted {
                for cv in containerViews {
                    cv.lmk_removeDarkOverlay()
                }
            }
        }

        if shouldAnimate {
            UIView.animate(
                withDuration: LMKHighlightConstants.animationDuration,
                delay: 0,
                options: .curveEaseInOut,
                animations: applyHighlight
            ) { _ in
                removeOverlaysIfNeeded()
            }
        } else {
            applyHighlight()
            removeOverlaysIfNeeded()
        }
    }

    private func lmk_findContainerViews(in view: UIView) -> [UIView] {
        var containers: [UIView] = []
        for subview in view.subviews {
            if subview is UILabel || subview is UIButton || subview is UIImageView { continue }
            if subview.backgroundColor != nil, subview.backgroundColor != .clear {
                if subview.layer.cornerRadius > 0 {
                    containers.append(subview)
                } else if subview.subviews.count > LMKHighlightConstants.containerDetectionSubviewsThreshold {
                    containers.append(subview)
                }
            }
            containers.append(contentsOf: lmk_findContainerViews(in: subview))
        }
        return containers
    }
}

// MARK: - Associated-object overlay storage

private extension UIView {
    private static var lmk_highlightOverlayKey: UInt8 = 0

    var lmk_highlightOverlay: UIView? {
        get { objc_getAssociatedObject(self, &Self.lmk_highlightOverlayKey) as? UIView }
        set { objc_setAssociatedObject(self, &Self.lmk_highlightOverlayKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    /// Creates the overlay with matching corner radius/curve and resolves its
    /// frame synchronously (via `layoutIfNeeded`) so the very first display
    /// pass renders rounded — preventing the rectangle-then-rounded flicker
    /// that occurs when the overlay is created inside `UIView.animate`.
    func lmk_installDarkOverlay(color: UIColor) {
        guard lmk_highlightOverlay == nil else { return }
        let newOverlay = UIView()
        newOverlay.backgroundColor = color
        newOverlay.layer.cornerRadius = layer.cornerRadius
        newOverlay.layer.cornerCurve = layer.cornerCurve
        newOverlay.alpha = 0
        addSubview(newOverlay)
        newOverlay.snp.makeConstraints { make in make.edges.equalToSuperview() }
        layoutIfNeeded()
        lmk_highlightOverlay = newOverlay
    }

    func lmk_removeDarkOverlay() {
        lmk_highlightOverlay?.removeFromSuperview()
        lmk_highlightOverlay = nil
    }
}
