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
    /// Pins the view's horizontal extent inside `container` the readable way: centered, never
    /// wider than `maxWidth`, never closer than `horizontalInset` to the container's edges, and
    /// filling the remaining width on narrow screens.
    ///
    /// Vertical constraints are the caller's. The fill constraint sits just below required (999),
    /// so content-size chains (a long single-line label, required hugging beside a wrapped title)
    /// never win over filling the width; the cap, the edge insets, and the bound to the
    /// container's own width are required. The width bound is what keeps wide content inside
    /// the viewport when `container` is a scroll view, where the edge constraints describe the
    /// content area instead of the frame.
    ///
    /// - Parameters:
    ///   - container: The view to lay out against; default the superview (the view must already be added).
    ///   - maxWidth: Width cap; `nil` = `LMKLayout.readableContentMaxWidth`.
    ///   - horizontalInset: Minimum distance to the container's leading and trailing edges; `nil` = `LMKSpacing.large`.
    func lmk_pinReadableWidth(in container: UIView? = nil, maxWidth: CGFloat? = nil, horizontalInset: CGFloat? = nil) {
        guard let container = container ?? superview else {
            preconditionFailure("lmk_pinReadableWidth needs a container or a superview")
        }
        let cap = maxWidth ?? LMKLayout.readableContentMaxWidth
        let inset = horizontalInset ?? LMKSpacing.large
        snp.makeConstraints { make in
            make.centerX.equalTo(container)
            make.width.lessThanOrEqualTo(cap)
            make.leading.greaterThanOrEqualTo(container).offset(inset)
            make.trailing.lessThanOrEqualTo(container).offset(-inset)
            make.width.lessThanOrEqualTo(container).offset(-inset * 2)
            make.width.equalTo(container).offset(-inset * 2).priority(999)
        }
    }

    /// A layout guide centered in the view whose width is the readable width: the view's width
    /// minus `LMKSpacing.large` on each side, capped at `LMKLayout.readableContentMaxWidth`.
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
        guide.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualTo(LMKLayout.readableContentMaxWidth)
            make.leading.greaterThanOrEqualToSuperview().offset(inset)
            make.trailing.lessThanOrEqualToSuperview().offset(-inset)
            make.width.equalToSuperview().offset(-inset * 2).priority(999)
        }
        objc_setAssociatedObject(self, &lmk_readableWidthGuideKey, guide, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return guide
    }
}
