//
//  UIViewController+LMKOrientation.swift
//  LumiKit
//
//  Interface orientation accessor.
//

import UIKit

public extension UIViewController {
    /// Current window orientation (available in `viewDidAppear`).
    ///
    /// Read from the scene's `effectiveGeometry`; `UIWindowScene.interfaceOrientation`
    /// is deprecated in iOS 26. Orientation is for camera / media rotation only:
    /// layout decisions belong to size classes and bounds (iOS 27 makes iOS apps
    /// resizable, and iPhone Duo's inner display is regular in every orientation).
    var lmk_windowOrientation: UIInterfaceOrientation {
        view.window?.windowScene?.effectiveGeometry.interfaceOrientation ?? .unknown
    }
}
