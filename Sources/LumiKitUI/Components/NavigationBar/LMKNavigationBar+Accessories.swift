//
//  LMKNavigationBar+Accessories.swift
//  LumiKit
//
//  Accessory views next to the items and the large title, scroll view pinning,
//  and the iOS 26 scroll-edge effect.
//

import SnapKit
import UIKit

public extension LMKNavigationBar {
    // MARK: - Accessory views

    /// Places a non-tappable view (activity indicator, sync status icon) immediately
    /// before the right items, vertically centered with the button row. Pass `nil` to
    /// remove it. The accessory lives outside the items stack, so `setRightItems(_:)`
    /// leaves it in place.
    func setRightAccessoryView(_ view: UIView?) {
        rightAccessoryView?.removeFromSuperview()
        rightAccessoryView = view
        guard let view else { return }
        buttonRow.addSubview(view)
        let theme = traitCollection.lmkTheme
        view.snp.makeConstraints { make in
            make.centerY.equalTo(rightItemsStack)
            rightAccessoryGapConstraint = make.trailing.equalTo(rightItemsStack.snp.leading).offset(-theme.spacing.small).constraint
        }
    }

    /// Places a non-tappable view after the large title text (the iOS Mail / Notes
    /// pattern for sync state next to a section title). Only meaningful with
    /// `largeTitleEnabled`. Pass `nil` to remove it. The title hugs its text, so the
    /// accessory hangs off the actual title, not the row.
    func setLargeTitleAccessoryView(_ view: UIView?) {
        largeTitleAccessoryView?.removeFromSuperview()
        largeTitleAccessoryView = view
        guard let view else { return }
        largeTitleRow.addSubview(view)
        let theme = traitCollection.lmkTheme
        view.snp.makeConstraints { make in
            largeTitleAccessoryGapConstraint = make.leading.equalTo(largeTitleLabel.snp.trailing).offset(theme.spacing.small).constraint
            make.centerY.equalTo(largeTitleLabel)
            largeTitleAccessoryTrailingConstraint = make.trailing.lessThanOrEqualToSuperview().inset(resolved.contentMargin ?? theme.spacing.large).constraint
        }
    }

    // MARK: - Scroll view pinning

    /// Pins `scrollView` below the bar (both must share a superview; add both first).
    ///
    /// With `edgeEffect`, the scroll view instead extends under the bar: its top content
    /// inset tracks the bar's height, and on iOS 26 the system scroll-edge effect renders
    /// behind a translucent bar (`style.surface.background = .blur(...)` or `.glass(...)`).
    /// Before iOS 26 the scroll view is inset the same way with no effect.
    func pinScrollView(_ scrollView: UIScrollView, edgeEffect: Bool = false) {
        pinnedScrollView = scrollView
        pinsScrollViewUnderBar = edgeEffect
        scrollView.snp.makeConstraints { make in
            if edgeEffect {
                make.top.equalTo(self.snp.top)
            } else {
                make.top.equalTo(self.snp.bottom)
            }
        }
        if edgeEffect {
            scrollView.contentInsetAdjustmentBehavior = .never
            attachScrollEdgeEffect(to: scrollView)
            updatePinnedScrollViewInsets()
        } else {
            detachScrollEdgeEffect()
        }
    }

    /// Keeps a scroll view pinned under the bar inset by the bar's current height.
    func updatePinnedScrollViewInsets() {
        guard pinsScrollViewUnderBar, let scrollView = pinnedScrollView else { return }
        let height = bounds.height
        guard scrollView.contentInset.top != height else { return }
        let wasAtTop = scrollView.contentOffset.y <= -scrollView.contentInset.top + 0.5
        scrollView.contentInset.top = height
        scrollView.verticalScrollIndicatorInsets.top = height
        if wasAtTop {
            scrollView.contentOffset.y = -height
        }
    }

    // MARK: - Scroll edge effect (iOS 26)

    /// Whether a scroll-edge effect is attached (always `false` before iOS 26).
    var hasScrollEdgeEffect: Bool { scrollEdgeInteraction != nil }

    /// Lets the system scroll-edge effect of `scrollView` render behind this bar (iOS 26):
    /// content scrolling under the bar fades out the way it does under a system navigation
    /// bar. Requires the bar to overlay the scroll view's top edge with a translucent
    /// background; an opaque bar hides the effect. No-op before iOS 26.
    func attachScrollEdgeEffect(to scrollView: UIScrollView) {
        detachScrollEdgeEffect()
        if #available(iOS 26, *) {
            let interaction = UIScrollEdgeElementContainerInteraction()
            interaction.scrollView = scrollView
            interaction.edge = .top
            addInteraction(interaction)
            scrollEdgeInteraction = interaction
        }
    }

    /// Removes the effect installed by ``attachScrollEdgeEffect(to:)``.
    func detachScrollEdgeEffect() {
        guard let scrollEdgeInteraction else { return }
        removeInteraction(scrollEdgeInteraction)
        self.scrollEdgeInteraction = nil
    }
}
