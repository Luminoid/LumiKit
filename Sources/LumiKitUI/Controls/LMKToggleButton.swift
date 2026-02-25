//
//  LMKToggleButton.swift
//  LumiKit
//
//  Toggle button that switches between on/off states.
//

import UIKit

// MARK: - Configurable Strings

/// Configurable strings for toggle button accessibility, allowing localization.
public nonisolated struct LMKToggleButtonStrings: Sendable {
    public var onAccessibilityValue: String
    public var offAccessibilityValue: String

    public init(
        onAccessibilityValue: String = "On",
        offAccessibilityValue: String = "Off"
    ) {
        self.onAccessibilityValue = onAccessibilityValue
        self.offAccessibilityValue = offAccessibilityValue
    }
}

public nonisolated(unsafe) var lmkToggleButtonStrings = LMKToggleButtonStrings()

// MARK: - LMKToggleButton

/// Toggle button with on/off state and per-state title/image.
open class LMKToggleButton: LMKButton {
    public enum ToggleState {
        case on
        case off
    }

    /// Called when the toggle state changes. Receives the new state.
    public var stateChangedHandler: ((ToggleState) -> Void)?

    /// When `true`, tapping automatically flips the status.
    public var flipStatusOnTap: Bool = true

    public var status: ToggleState = .off {
        didSet { updateStyle() }
    }

    public var titleForStatusOn: String?
    public var titleForStatusOff: String?
    public var imageForStatusOn: UIImage?
    public var imageForStatusOff: UIImage?

    public init(
        titleForStatusOn: String? = nil,
        titleForStatusOff: String? = nil,
        imageForStatusOn: UIImage? = nil,
        imageForStatusOff: UIImage? = nil,
    ) {
        self.titleForStatusOn = titleForStatusOn
        self.titleForStatusOff = titleForStatusOff
        self.imageForStatusOn = imageForStatusOn
        self.imageForStatusOff = imageForStatusOff
        super.init(frame: .zero)
    }

    override open func initialize() {
        super.initialize()
        updateStyle()
    }

    open func updateStyle() {
        switch status {
        case .on:
            setTitle(titleForStatusOn, for: .normal)
            setImage(imageForStatusOn, for: .normal)
            accessibilityValue = lmkToggleButtonStrings.onAccessibilityValue
        case .off:
            setTitle(titleForStatusOff, for: .normal)
            setImage(imageForStatusOff, for: .normal)
            accessibilityValue = lmkToggleButtonStrings.offAccessibilityValue
        }
    }

    @objc override open func didTap() {
        if flipStatusOnTap {
            status = (status == .on) ? .off : .on
            if !pressAnimationEnabled {
                LMKHapticFeedbackHelper.selection()
            }
        }
        stateChangedHandler?(status)
        super.didTap()
    }
}
