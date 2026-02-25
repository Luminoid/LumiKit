//
//  LMKButton.swift
//  LumiKit
//
//  Base button with closure-based tap handling and optional press animation.
//

import UIKit

/// Base button with closure-based tap handling.
open class LMKButton: UIButton {
    /// Simple tap handler (no reference to button). Use for fire-and-forget actions.
    public var tapHandler: (() -> Void)?

    /// Typed tap handler that receives the button instance. Use when you need a reference to the tapped button.
    public var didTapHandler: ((LMKButton) -> Void)?

    /// When `true`, plays press animation + haptic on touch down.
    public var pressAnimationEnabled: Bool = false

    public var imageContentMode: UIView.ContentMode = .scaleAspectFit {
        didSet { imageView?.contentMode = imageContentMode }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func initialize() {
        imageView?.contentMode = imageContentMode
        addTarget(self, action: #selector(didTap), for: .touchUpInside)
        addTarget(self, action: #selector(handleTouchDown), for: .touchDown)
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }

    @objc private func handleTouchDown() {
        guard pressAnimationEnabled else { return }
        LMKHapticFeedbackHelper.medium()
        guard LMKAnimationHelper.shouldAnimate else { return }
        LMKAnimationHelper.animateButtonPressDown(self)
    }

    @objc private func handleTouchUp() {
        guard pressAnimationEnabled, LMKAnimationHelper.shouldAnimate else { return }
        LMKAnimationHelper.animateButtonPressUp(self)
    }

    @objc open func didTap() {
        tapHandler?()
        didTapHandler?(self)
    }
}
