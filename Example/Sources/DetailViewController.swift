//
//  DetailViewController.swift
//  LumiKitExample
//
//  Base class for all example detail pages. Uses LMKScrollStackViewController.
//

import LumiKitUI
import UIKit

class DetailViewController: LMKScrollStackViewController {
    /// Convenience alias so existing subclasses can keep using `stack`.
    var stack: UIStackView { stackView }
}
