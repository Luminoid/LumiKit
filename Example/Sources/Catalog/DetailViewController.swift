//
//  DetailViewController.swift
//  LumiKitExample
//
//  Base class for all example detail pages. Uses LMKScrollStackViewController.
//

import LumiKitUI
import SnapKit
import UIKit

/// Base class for all example detail pages.
class DetailViewController: LMKScrollStackViewController {
    /// Convenience alias so existing subclasses can keep using `stack`.
    var stack: UIStackView { stackView }

    /// A horizontally scrolling host for a row whose content must never compress (a chip row at
    /// accessibility text sizes): the row keeps its natural width and scrolls sideways instead.
    func makeScrollingRow(_ content: UIView) -> UIView {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.clipsToBounds = false
        scrollView.addSubview(content)
        content.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.greaterThanOrEqualTo(scrollView.frameLayoutGuide)
        }
        scrollView.snp.makeConstraints { $0.height.equalTo(content) }
        return scrollView
    }

    /// Fill to the screen bottom rather than stopping at the safe area; the
    /// scroll view's `.automatic` content inset keeps content clear of the home
    /// indicator while letting it scroll under, and the indicator runs full height.
    init() {
        super.init(style: LMKScrollStackViewController.Style(bottomAnchor: .superview))
    }
}
