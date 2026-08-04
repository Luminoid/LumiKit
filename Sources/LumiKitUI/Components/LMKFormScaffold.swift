//
//  LMKFormScaffold.swift
//  LumiKit
//
//  Static builders for form screens: a keyboard-aware scroll view, a content
//  stack, and a one-call installer that pins both into a host view.
//

import SnapKit
import UIKit

/// Static builders for form screens that are not `LMKScrollStackViewController`
/// subclasses — view controllers with their own base class that still want the
/// standard scroll + stack form layout and keyboard behavior.
///
/// ```swift
/// let scrollView = LMKFormScaffold.makeScrollView()
/// let stack = LMKFormScaffold.makeContentStack()
/// LMKFormScaffold.install(scrollView: scrollView, stack: stack, in: view, below: navBar)
/// ```
public enum LMKFormScaffold {
    /// Scroll view pre-configured for form content: keyboard dismiss on drag
    /// and keyboard-overlap avoidance (`lmk_enableKeyboardAdjustment()`)
    /// installed.
    ///
    /// - Parameter keyboardDismissMode: Default `.onDrag` — the drag posts the
    ///   keyboard-hide notification immediately, so the installed keyboard
    ///   adjuster restores its insets in one clean step instead of tracking an
    ///   interactive dismissal.
    public static func makeScrollView(keyboardDismissMode: UIScrollView.KeyboardDismissMode = .onDrag) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.keyboardDismissMode = keyboardDismissMode
        scrollView.lmk_enableKeyboardAdjustment()
        return scrollView
    }

    /// Vertical fill-aligned stack view for form rows.
    ///
    /// - Parameter spacing: Spacing between rows. Default ``LMKSpacing/large``.
    public static func makeContentStack(spacing: CGFloat = LMKSpacing.large) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = spacing
        stack.alignment = .fill
        return stack
    }

    /// Installs `scrollView` and `stack` into `view`: the scroll view spans
    /// from below `topAnchorView` (e.g. a custom navigation bar) — or the view
    /// top when nil — to the bottom safe area, and the stack fills the scroll
    /// content inset by `contentInsets`.
    ///
    /// - Parameters:
    ///   - scrollView: The scroll view to install. `stack` is added to it here;
    ///     both must not already have a superview.
    ///   - stack: The content stack, pinned inside the scroll view so it drives
    ///     the content size, with its width locked to the scroll frame.
    ///   - view: The host view.
    ///   - topAnchorView: When non-nil, the scroll view's top is pinned to this
    ///     view's bottom edge; it must already be in `view`'s hierarchy.
    ///   - contentInsets: Insets from the scroll content edges to the stack.
    ///     Default (`nil`) resolves to ``LMKSpacing/cardPadding`` on all sides.
    public static func install(
        scrollView: UIScrollView,
        stack: UIStackView,
        in view: UIView,
        below topAnchorView: UIView? = nil,
        contentInsets: UIEdgeInsets? = nil
    ) {
        let padding = LMKSpacing.cardPadding
        let insets = contentInsets ?? UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            if let topAnchorView {
                make.top.equalTo(topAnchorView.snp.bottom)
            } else {
                make.top.equalToSuperview()
            }
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        scrollView.addSubview(stack)
        stack.snp.makeConstraints { make in
            // Edges against the scroll view drive the content size; the width
            // constraint locks the stack to the frame so content only scrolls
            // vertically.
            make.edges.equalToSuperview().inset(insets)
            make.width.equalToSuperview().offset(-(insets.left + insets.right))
        }
    }
}
