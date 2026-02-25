//
//  UITableViewCell+LMKHighlight.swift
//  LumiKit
//
//  Custom highlight behavior for table view cells.
//

import SnapKit
import UIKit

extension UITableViewCell {
    private static let lmk_darkModeOverlayAlpha = LMKAlpha.overlayDark
    private static let lmk_lightModeOverlayAlpha = LMKAlpha.overlayLight
    private static let lmk_animationDuration = LMKAnimationHelper.Duration.uiShort
    /// Unique tag for the highlight overlay view, used instead of a stored property
    /// since extensions on UITableViewCell cannot add stored properties.
    private static let lmk_overlayTag = 9999
    private static let lmk_containerDetectionSubviewsThreshold = 2

    private static var lmk_highlightOverlayColor: UIColor {
        UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                LMKColor.black.withAlphaComponent(lmk_darkModeOverlayAlpha)
            } else {
                LMKColor.black.withAlphaComponent(lmk_lightModeOverlayAlpha)
            }
        }
    }

    /// Apply custom highlight effect to the cell.
    /// Call from `setHighlighted(_:animated:)` in your cell subclass.
    public func lmk_applyCustomHighlight(highlighted: Bool, animated: Bool) {
        let darkOverlayColor = Self.lmk_highlightOverlayColor

        let containerViews = lmk_findContainerViews(in: contentView)
        let shouldAnimate = animated && LMKAnimationHelper.shouldAnimate

        let applyHighlight = {
            if highlighted {
                if !containerViews.isEmpty {
                    for cv in containerViews {
                        self.lmk_addDarkOverlay(to: cv, color: darkOverlayColor)
                    }
                } else {
                    self.contentView.backgroundColor = darkOverlayColor
                }
            } else {
                if !containerViews.isEmpty {
                    for cv in containerViews {
                        self.lmk_removeDarkOverlay(from: cv)
                    }
                } else {
                    self.contentView.backgroundColor = .clear
                }
            }
        }

        if shouldAnimate {
            UIView.animate(withDuration: Self.lmk_animationDuration, delay: 0, options: .curveEaseInOut, animations: applyHighlight)
        } else {
            applyHighlight()
        }
    }

    private func lmk_addDarkOverlay(to view: UIView, color: UIColor) {
        var overlay = view.viewWithTag(Self.lmk_overlayTag)
        if overlay == nil {
            let newOverlay = UIView()
            newOverlay.tag = Self.lmk_overlayTag
            newOverlay.backgroundColor = color
            newOverlay.layer.cornerRadius = view.layer.cornerRadius
            view.addSubview(newOverlay)
            newOverlay.snp.makeConstraints { make in make.edges.equalToSuperview() }
            overlay = newOverlay
        }
        overlay?.alpha = 1.0
    }

    private func lmk_removeDarkOverlay(from view: UIView) {
        view.viewWithTag(Self.lmk_overlayTag)?.removeFromSuperview()
    }

    private func lmk_findContainerViews(in view: UIView) -> [UIView] {
        var containers: [UIView] = []
        for subview in view.subviews {
            if subview is UILabel || subview is UIButton || subview is UIImageView { continue }
            if subview.backgroundColor != nil, subview.backgroundColor != .clear {
                if subview.layer.cornerRadius > 0 {
                    containers.append(subview)
                } else if subview.subviews.count > Self.lmk_containerDetectionSubviewsThreshold {
                    containers.append(subview)
                }
            }
            containers.append(contentsOf: lmk_findContainerViews(in: subview))
        }
        return containers
    }

    /// Configure custom highlight for standard `UITableViewCell` instances.
    public func lmk_configureCustomHighlight() {
        let selectedBgView = UIView()
        selectedBgView.backgroundColor = Self.lmk_highlightOverlayColor
        selectedBackgroundView = selectedBgView
    }
}

public extension UITableView {
    /// Configure a standard `UITableViewCell` with custom highlight.
    func lmk_configureCellHighlight(_ cell: UITableViewCell) {
        cell.lmk_configureCustomHighlight()
    }
}
