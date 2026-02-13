//
//  UIViewController+LMKOrientation.swift
//  LumiKit
//
//  Interface orientation accessor.
//

import UIKit

public extension UIViewController {
    /// Current window orientation (available in `viewDidAppear`).
    var lmk_windowOrientation: UIInterfaceOrientation {
        view.window?.windowScene?.interfaceOrientation ?? .unknown
    }
}
