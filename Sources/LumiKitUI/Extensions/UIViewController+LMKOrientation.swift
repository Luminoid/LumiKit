//
//  UIViewController+LMKOrientation.swift
//  LumiKit
//
//  Interface orientation accessor.
//

import UIKit

extension UIViewController {
    /// Current window orientation (available in `viewDidAppear`).
    public var lmk_windowOrientation: UIInterfaceOrientation {
        view.window?.windowScene?.interfaceOrientation ?? .unknown
    }
}
