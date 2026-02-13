//
//  LMKToggleButton.swift
//  LumiKit
//
//  Toggle button that switches between on/off states.
//

import UIKit

/// Toggle button with on/off state and per-state title/image.
open class LMKToggleButton: LMKButton {
    public enum Status {
        case on
        case off
    }

    /// When `true`, tapping automatically flips the status.
    public var flipStatusOnTap: Bool = true

    public var status: Status = .off {
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
        case .off:
            setTitle(titleForStatusOff, for: .normal)
            setImage(imageForStatusOff, for: .normal)
        }
    }

    @objc override open func didTap() {
        if flipStatusOnTap {
            status = (status == .on) ? .off : .on
        }
        super.didTap()
    }
}
