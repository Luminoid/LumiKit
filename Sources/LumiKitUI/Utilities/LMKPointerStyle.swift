//
//  LMKPointerStyle.swift
//  LumiKit
//
//  Window-safe UIPointerStyle factories for UIPointerInteractionDelegate.
//

import UIKit

/// Window-safe `UIPointerStyle` factories for `UIPointerInteractionDelegate`.
///
/// `UITargetedPreview(view:)` asserts that its view is in a window, and aborts the process
/// (`NSInternalInconsistencyException` / `BUG_IN_CLIENT_OF_TARGETED_PREVIEW__VIEW_IS_NOT_IN_A_WINDOW`)
/// when it is not. The initializer is not failable, so there is nothing to catch.
///
/// UIKit computes a pointer region and queries its style at different moments in the same
/// run loop turn, so a delegate can be called with a view that has since left the hierarchy:
/// a cell recycled by scrolling, a snapshot applied under the cursor, a sheet dismissed
/// mid-hover, a view controller popped while the pointer rests on a row. Guarding
/// `interaction.view != nil` does not cover this — the interaction stays attached to a
/// recycled cell whose `window` is already nil. `superview` is not equivalent either,
/// since reuse pools and detached containers keep one.
///
/// Every factory here takes an optional view and returns `nil` unless that view is both
/// non-nil and in a window, so the result can be returned straight from the delegate:
///
/// ```swift
/// extension MyCell: UIPointerInteractionDelegate {
///     func pointerInteraction(_ interaction: UIPointerInteraction, styleFor _: UIPointerRegion) -> UIPointerStyle? {
///         LMKPointerStyle.lift(for: interaction.view)
///     }
/// }
/// ```
///
/// When the effect targets the delegate itself, pass `self`:
///
/// ```swift
/// LMKPointerStyle.hover(for: self)
/// ```
///
/// `nil` is the documented "no pointer effect for this region" answer, so the only visible
/// consequence is a missing hover effect for the frame in which the view leaves the hierarchy.
public enum LMKPointerStyle {
    /// `.automatic` effect targeting `view`, or `nil` if `view` is nil or not in a window.
    public static func automatic(for view: UIView?) -> UIPointerStyle? {
        preview(for: view).map { UIPointerStyle(effect: .automatic($0)) }
    }

    /// `.highlight` effect targeting `view`, or `nil` if `view` is nil or not in a window.
    public static func highlight(for view: UIView?) -> UIPointerStyle? {
        preview(for: view).map { UIPointerStyle(effect: .highlight($0)) }
    }

    /// `.lift` effect targeting `view`, or `nil` if `view` is nil or not in a window.
    public static func lift(for view: UIView?) -> UIPointerStyle? {
        preview(for: view).map { UIPointerStyle(effect: .lift($0)) }
    }

    /// `.hover` effect targeting `view`, or `nil` if `view` is nil or not in a window.
    ///
    /// Parameter defaults match `UIPointerEffect.hover`.
    public static func hover(
        for view: UIView?,
        preferredTintMode: UIPointerEffect.TintMode = .overlay,
        prefersShadow: Bool = false,
        prefersScaledContent: Bool = true
    ) -> UIPointerStyle? {
        preview(for: view).map {
            UIPointerStyle(effect: .hover(
                $0,
                preferredTintMode: preferredTintMode,
                prefersShadow: prefersShadow,
                prefersScaledContent: prefersScaledContent
            ))
        }
    }

    /// `UITargetedPreview` for `view`, or `nil` unless `view` is non-nil and in a window.
    ///
    /// The window check that makes every factory above safe. Use directly only for an effect
    /// this type does not wrap, or for a `UIPointerStyle` shape other than `init(effect:)`;
    /// prefer the named factories otherwise.
    public static func preview(for view: UIView?) -> UITargetedPreview? {
        guard let view, view.window != nil else { return nil }
        return UITargetedPreview(view: view)
    }
}
