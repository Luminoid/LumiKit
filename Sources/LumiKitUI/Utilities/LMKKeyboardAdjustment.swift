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
        // `willChange` fires before iOS resizes a presented sheet for the keyboard,
        // so the insets and the scroll target it computes can be based on stale
        // bounds. `didChange` lands after that settles and corrects both.
        center.addObserver(
            self,
            selector: #selector(keyboardDidChange(_:)),
            name: UIResponder.keyboardDidChangeFrameNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        // Moving focus from one field to another while the keyboard is already up
        // posts no keyboard notification at all, so without these the new field is
        // never scrolled into view. Most visible on tall forms, where the field
        // tapped next (typically a Notes text view at the bottom) sits under the
        // keyboard and there is no way to reach it.
        for name in [UITextField.textDidBeginEditingNotification, UITextView.textDidBeginEditingNotification] {
            center.addObserver(self, selector: #selector(editingDidBegin(_:)), name: name, object: nil)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func keyboardWillChange(_ note: Notification) {
        applyKeyboardFrame(from: note)
    }

    @objc private func keyboardDidChange(_ note: Notification) {
        // Re-run against settled geometry: a presented sheet finishes resizing
        // between `willChange` and `didChange`, which changes both the overlap
        // and where the focused field ends up.
        applyKeyboardFrame(from: note, animated: false)
    }

    /// Focus moved to another field. Only the scroll target needs recomputing —
    /// the keyboard frame, and therefore the insets, have not changed. The target
    /// comes from the notification rather than a first-responder search, which is
    /// not yet settled when this fires.
    @objc private func editingDidBegin(_ note: Notification) {
        guard let scrollView,
              scrollView.window != nil,
              let field = note.object as? UIView,
              field.isDescendant(of: scrollView)
        else { return }
        // Immediate, not deferred: the keyboard geometry is already settled when
        // focus moves between fields. If this is instead the *first* focus, the
        // keyboard frame notifications that follow re-scroll against the grown
        // insets, so nothing is lost by acting early here.
        scroll(to: field)
    }

    private func applyKeyboardFrame(from note: Notification, animated: Bool = true) {
        guard let scrollView,
              scrollView.window != nil,
              Self.firstResponder(in: scrollView) != nil,
              let endFrame = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        else { return }

        let duration = animated
            ? (note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25)
            : 0

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

        scheduleScrollToFocused()
    }

    /// Scrolls the focused field into view on the next runloop, so an in-flight sheet
    /// resize has had a chance to update `scrollView.bounds` before the scroll target
    /// is computed; otherwise it would be computed against the pre-shrink bounds and
    /// decide the field is "already visible".
    private func scheduleScrollToFocused() {
        DispatchQueue.main.async { [weak self] in
            guard let self, let scrollView,
                  let focused = Self.firstResponder(in: scrollView) else { return }
            scroll(to: focused)
        }
    }

    /// Brings `target` into the band of the scroll view that is actually visible
    /// above the keyboard. Idempotent: a rect already inside the band produces no
    /// movement, so the extra passes cost nothing.
    ///
    /// Deliberately NOT `scrollRectToVisible`: that method tests visibility
    /// against the raw bounds and ignores `contentInset`, so a field sitting
    /// on-screen but under the keyboard counts as "already visible" and never
    /// moves — the exact case this adjuster exists for.
    private func scroll(to target: UIView) {
        guard let scrollView, scrollView.bounds.height > 0 else { return }
        let padded = target.convert(target.bounds, to: scrollView)
            .insetBy(dx: 0, dy: -LMKSpacing.medium)

        // Adjusted insets so the band excludes both the keyboard overlap grown
        // above and whatever the safe area contributes.
        let insets = scrollView.adjustedContentInset
        let visibleHeight = scrollView.bounds.height - insets.top - insets.bottom
        guard visibleHeight > 0 else { return }

        var offsetY = scrollView.contentOffset.y
        if padded.maxY > offsetY + insets.top + visibleHeight {
            offsetY = padded.maxY - insets.top - visibleHeight
        }
        // Re-test the top edge after any bottom-edge move, so a rect taller than
        // the band ends with its top on screen rather than its bottom.
        if padded.minY < offsetY + insets.top {
            offsetY = padded.minY - insets.top
        }

        let minOffsetY = -insets.top
        let maxOffsetY = max(minOffsetY, scrollView.contentSize.height + insets.bottom - scrollView.bounds.height)
        offsetY = min(max(offsetY, minOffsetY), maxOffsetY)

        guard abs(offsetY - scrollView.contentOffset.y) > 0.5 else { return }
        scrollView.setContentOffset(
            CGPoint(x: scrollView.contentOffset.x, y: offsetY),
            animated: LMKAnimationHelper.shouldAnimate
        )
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
