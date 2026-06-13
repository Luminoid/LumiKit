//
//  DetailViewController.swift
//  LumiKitExample
//
//  Base class for all example detail pages. Uses LMKScrollStackViewController.
//

import LumiKitUI
import UIKit

/// Base class for all example detail pages.
class DetailViewController: LMKScrollStackViewController {
    /// Convenience alias so existing subclasses can keep using `stack`.
    var stack: UIStackView { stackView }

    /// Fill to the screen bottom rather than stopping at the safe area; the
    /// scroll view's `.automatic` content inset keeps content clear of the home
    /// indicator while letting it scroll under, and the indicator runs full height.
    override var scrollViewUseSafeArea: Bool { false }
}
