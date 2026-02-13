//
//  LMKButton.swift
//  LumiKit
//
//  Base button with closure-based tap handling and optional press animation.
//

import UIKit

/// Base button with closure-based tap handling.
@MainActor
open class LMKButton: UIButton {
    /// Simple tap handler (no typed reference).
    public var tapHandler: (() -> Void)?

    /// Typed tap handler (receives the button instance).
    public var didTapHandler: ((LMKButton) -> Void)?

    /// When `true`, plays press animation + haptic on touch down.
    public var pressAnimationEnabled: Bool = false

    public var imageContentMode: UIView.ContentMode = .scaleAspectFit {
        didSet { imageView?.contentMode = imageContentMode }
    }

    public override init(frame: CGRect) {
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
    }

    @objc open func didTap() {
        if pressAnimationEnabled {
            LMKAnimationHelper.animateButtonPress(self)
            LMKHapticFeedbackHelper.medium()
        }
        tapHandler?()
        didTapHandler?(self)
    }
}
