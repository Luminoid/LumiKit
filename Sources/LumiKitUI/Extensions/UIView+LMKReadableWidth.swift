//
//  UIView+LMKReadableWidth.swift
//  LumiKit
//
//  Readable-width layout: content fills narrow screens and caps its width
//  on wide iPads and Mac windows so lines stay short.
//

import SnapKit
import UIKit

private nonisolated(unsafe) var lmk_readableWidthGuideKey: UInt8 = 0

public extension UIView {
    /// Pins the view's horizontal extent inside `container` the readable way: centered in the
    /// container's safe area, never wider than `maxWidth`, never closer than `horizontalInset` to
    /// the safe area's edges, and filling the remaining width on narrow screens. Measuring from
    /// the safe area keeps the content clear of a floating sidebar or inspector (iPad and Mac) and
    /// the landscape sensor housing.
    ///
    /// Vertical constraints are the caller's. The fill constraint sits just below required (999),
    /// so content-size chains (a long single-line label, required hugging beside a wrapped title)
    /// never win over filling the width; the cap, the edge insets, and the bound to the
    /// safe area's width are required. The width bound is what keeps wide content inside
    /// the viewport when `container` is a scroll view.
    ///
    /// - Parameters:
    ///   - container: The view to lay out against; default the superview (the view must already be added).
    ///   - maxWidth: Width cap; `nil` = `LMKLayout.readableContentMaxWidth`.
    ///   - horizontalInset: Minimum distance to the safe area's leading and trailing edges; `nil` = `LMKSpacing.large`.
    ///
    /// A view with neither a container nor a superview is left alone (an assertion in debug builds).
    func lmk_pinReadableWidth(in container: UIView? = nil, maxWidth: CGFloat? = nil, horizontalInset: CGFloat? = nil) {
        guard let container = container ?? superview else {
            assertionFailure("lmk_pinReadableWidth needs a container or a superview")
            return
        }
        let cap = maxWidth ?? LMKLayout.readableContentMaxWidth
        let inset = horizontalInset ?? LMKSpacing.large
        let safeArea = container.safeAreaLayoutGuide
        snp.makeConstraints { make in
            make.centerX.equalTo(safeArea)
            make.width.lessThanOrEqualTo(cap)
            make.leading.greaterThanOrEqualTo(safeArea).offset(inset)
            make.trailing.lessThanOrEqualTo(safeArea).offset(-inset)
            make.width.lessThanOrEqualTo(safeArea).offset(-inset * 2)
            make.width.equalTo(safeArea).offset(-inset * 2).priority(999)
        }
    }

    /// A layout guide centered in the view's safe area whose width is the readable width: the
    /// safe area's width minus `LMKSpacing.large` on each side, capped at
    /// `LMKLayout.readableContentMaxWidth`.
    ///
    /// Installed on first access and reused afterwards. Constrain content to its leading and
    /// trailing anchors to get the same treatment as `lmk_pinReadableWidth(in:maxWidth:horizontalInset:)`
    /// without touching the content's own constraints:
    /// ```swift
    /// stack.snp.makeConstraints { make in
    ///     make.leading.trailing.equalTo(view.lmk_readableWidthGuide)
    /// }
    /// ```
    var lmk_readableWidthGuide: UILayoutGuide {
        if let guide = objc_getAssociatedObject(self, &lmk_readableWidthGuideKey) as? UILayoutGuide {
            return guide
        }
        let guide = UILayoutGuide()
        guide.identifier = "LMKReadableWidthGuide"
        addLayoutGuide(guide)
        let inset = LMKSpacing.large
        let safeArea = safeAreaLayoutGuide
        guide.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.centerX.equalTo(safeArea)
            make.width.lessThanOrEqualTo(LMKLayout.readableContentMaxWidth)
            make.leading.greaterThanOrEqualTo(safeArea).offset(inset)
            make.trailing.lessThanOrEqualTo(safeArea).offset(-inset)
            make.width.equalTo(safeArea).offset(-inset * 2).priority(999)
        }
        objc_setAssociatedObject(self, &lmk_readableWidthGuideKey, guide, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return guide
    }
}
