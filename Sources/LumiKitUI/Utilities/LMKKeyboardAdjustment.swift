//
//  LMKKeyboardAdjustment.swift
//  LumiKit
//
//  One-call keyboard avoidance for scroll views, installed via associated object.
//  Grows the bottom content inset to match the keyboard overlap and scrolls the
//  focused field into the visible area above the keyboard.
//

import UIKit

private nonisolated(unsafe) var lmk_keyboardAdjusterKey: UInt8 = 0

public extension UIScrollView {
    /// Installs keyboard avoidance on this scroll view: when the keyboard appears,
    /// the bottom content inset (and scroll indicator inset) grows to match the
    /// overlap and the focused field scrolls into the visible area above the
    /// keyboard. Safe to call multiple times; only the first call installs.
    ///
    /// The adjuster is retained as an associated object on the scroll view, so it
    /// lives as long as the scroll view does. On Mac Catalyst there is no software
    /// keyboard, so keyboard notifications never fire and this is a no-op.
    func lmk_enableKeyboardAdjustment() {
        guard objc_getAssociatedObject(self, &lmk_keyboardAdjusterKey) == nil else { return }
        let adjuster = LMKKeyboardScrollAdjuster(scrollView: self)
        objc_setAssociatedObject(self, &lmk_keyboardAdjusterKey, adjuster, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

/// Adjusts a scroll view's bottom content inset when the software keyboard appears,
/// and scrolls the focused text field / text view into the visible area above the keyboard.
/// Installed once per scroll view via `UIScrollView.lmk_enableKeyboardAdjustment()`.
private final class LMKKeyboardScrollAdjuster {
    private weak var scrollView: UIScrollView?
    private var originalBottomInset: CGFloat = 0
    private var originalIndicatorBottomInset: CGFloat = 0
    private var isAdjusting = false

    init(scrollView: UIScrollView) {
        self.scrollView = scrollView
        let center = NotificationCenter.default
        center.addObserver(
            self,
            selector: #selector(keyboardWillChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func keyboardWillChange(_ note: Notification) {
        guard let scrollView,
              scrollView.window != nil,
              let focused = Self.firstResponder(in: scrollView),
              let endFrame = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              let duration = note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }

        let frameInScroll = scrollView.convert(endFrame, from: nil)
        let overlap = frameInScroll.intersection(scrollView.bounds)

        if overlap.height > 0 {
            if !isAdjusting {
                originalBottomInset = scrollView.contentInset.bottom
                originalIndicatorBottomInset = scrollView.verticalScrollIndicatorInsets.bottom
                isAdjusting = true
            }

            var insets = scrollView.contentInset
            insets.bottom = originalBottomInset + overlap.height
            var indicator = scrollView.verticalScrollIndicatorInsets
            indicator.bottom = originalIndicatorBottomInset + overlap.height

            UIView.animate(withDuration: duration) {
                scrollView.contentInset = insets
                scrollView.verticalScrollIndicatorInsets = indicator
            }
        } else {
            // Keyboard doesn't visually overlap the scroll view, typically because
            // iOS auto-shrinks the presented page sheet for the keyboard on iPhone.
            // The scroll view's bounds shrink in the same animation, so no inset
            // growth is needed, but a focused field near the bottom of a tall form
            // can still fall below the new visible area.
            restoreInsets(duration: duration)
        }

        // Always scroll the focused field into the visible (post-inset,
        // post-sheet-shrink) area. Deferred to the next runloop so the sheet's
        // resize animation has had a chance to update `scrollView.bounds` before
        // the scroll target is computed; otherwise it would be computed against
        // the pre-shrink bounds and decide the field is "already visible."
        DispatchQueue.main.async { [weak focused, weak scrollView] in
            guard let focused, let scrollView else { return }
            let focusedRect = focused.convert(focused.bounds, to: scrollView)
            let padded = focusedRect.insetBy(dx: 0, dy: -LMKSpacing.medium)
            scrollView.scrollRectToVisible(padded, animated: true)
        }
    }

    @objc private func keyboardWillHide(_ note: Notification) {
        let duration = note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        restoreInsets(duration: duration)
    }

    private func restoreInsets(duration: Double) {
        guard let scrollView, isAdjusting else { return }
        isAdjusting = false

        var insets = scrollView.contentInset
        insets.bottom = originalBottomInset
        var indicator = scrollView.verticalScrollIndicatorInsets
        indicator.bottom = originalIndicatorBottomInset

        UIView.animate(withDuration: duration) {
            scrollView.contentInset = insets
            scrollView.verticalScrollIndicatorInsets = indicator
        }
    }

    private static func firstResponder(in view: UIView) -> UIView? {
        if view.isFirstResponder { return view }
        for subview in view.subviews {
            if let found = firstResponder(in: subview) {
                return found
            }
        }
        return nil
    }
}
