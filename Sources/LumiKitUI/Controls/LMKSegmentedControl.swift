//
//  LMKSegmentedControl.swift
//  LumiKit
//
//  Segmented control with closure-based value change handling.
//

import UIKit

/// Segmented control with closure-based value change handling.
@MainActor
open class LMKSegmentedControl: UISegmentedControl {
    /// Called when the selected segment changes. Receives the new selected index.
    public var valueChangedHandler: ((Int) -> Void)?

    /// Typed handler that receives the control itself.
    public var didValueChangeHandler: ((LMKSegmentedControl) -> Void)?

    public override init(items: [Any]?) {
        super.init(items: items)
        initialize()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initialize() {
        addTarget(self, action: #selector(valueChanged), for: .valueChanged)
    }

    @objc private func valueChanged() {
        valueChangedHandler?(selectedSegmentIndex)
        didValueChangeHandler?(self)
    }
}
