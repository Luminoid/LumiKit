//
//  LMKSegmentedControl.swift
//  LumiKit
//
//  Segmented control with closure-based value change handling and optional scroll support.
//

import UIKit

/// Segmented control with closure-based value change handling.
///
/// Set ``isScrollable`` to `true` and embed inside ``makeScrollableContainer()``
/// when the control has too many segments to fit on screen.
open class LMKSegmentedControl: UISegmentedControl {
    /// Called when the selected segment changes. Receives the new selected index.
    public var valueChangedHandler: ((Int) -> Void)?

    /// Typed handler that receives the control itself.
    public var didValueChangeHandler: ((LMKSegmentedControl) -> Void)?

    /// When `true`, yields gesture priority to a parent scroll view so horizontal
    /// panning scrolls instead of switching segments.
    ///
    /// Since iOS 13 `UISegmentedControl` has a built-in pan gesture that steals
    /// horizontal pans from parent scroll views. This flag overrides
    /// `gestureRecognizerShouldBegin(_:)` to let the scroll view win.
    ///
    /// Pair with ``makeScrollableContainer()`` for a ready-to-use scrollable setup.
    public var isScrollable: Bool = false

    override public init(items: [Any]?) {
        super.init(items: items)
        initialize()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func initialize() {
        addTarget(self, action: #selector(valueChanged), for: .valueChanged)
    }

    // MARK: - Scrollable Support

    override open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        isScrollable ? true : super.gestureRecognizerShouldBegin(gestureRecognizer)
    }

    /// Returns a scroll view container configured for horizontal scrolling of this control.
    ///
    /// The returned `LMKControlScrollView` cancels touches on embedded controls so panning
    /// works reliably. The segmented control is pinned to the scroll view edges.
    ///
    /// - Returns: A configured scroll view with this control as its subview.
    public func makeScrollableContainer() -> LMKControlScrollView {
        isScrollable = true
        let scrollView = LMKControlScrollView()
        scrollView.addSubview(self)
        snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }
        return scrollView
    }

    // MARK: - Actions

    @objc private func valueChanged() {
        LMKHapticFeedbackHelper.selection()
        valueChangedHandler?(selectedSegmentIndex)
        didValueChangeHandler?(self)
    }
}

// MARK: - LMKControlScrollView

/// Scroll view that cancels touch tracking on embedded `UIControl` subviews.
///
/// By default `UIScrollView.touchesShouldCancel(in:)` returns `false` for `UIControl`,
/// preventing the scroll view from ever cancelling a control's touch to begin panning.
/// This subclass returns `true` for all views so horizontal panning always works.
public final class LMKControlScrollView: UIScrollView {
    override public init(frame: CGRect) {
        super.init(frame: frame)
        showsHorizontalScrollIndicator = false
        delaysContentTouches = false
        canCancelContentTouches = true
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func touchesShouldCancel(in view: UIView) -> Bool {
        true
    }
}
