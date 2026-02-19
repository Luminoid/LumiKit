//
//  LMKOverscrollFooterHelper.swift
//  LumiKit
//
//  Manages positioning of an overscroll footer view within a scroll view.
//  The footer stays below the visible area and is only revealed on overscroll.
//

import UIKit

/// Positions a footer view below the visible scroll area, revealing it only on overscroll.
///
/// ```swift
/// let helper = LMKOverscrollFooterHelper(
///     footerView: myFooter,
///     scrollView: tableView,
///     footerHeight: 160
/// )
///
/// // In viewDidLayoutSubviews / scrollViewDidScroll:
/// helper.updatePosition()
///
/// // Read overscroll amount for effects (e.g. alpha transitions):
/// myFooter.updateAlpha(overscrollAmount: helper.overscrollAmount)
/// ```
public final class LMKOverscrollFooterHelper {
    // MARK: - Properties

    private let footerView: UIView
    private weak var scrollView: UIScrollView?
    private let footerHeight: CGFloat

    /// Current overscroll amount in points (0 when not overscrolling).
    public private(set) var overscrollAmount: CGFloat = 0

    // MARK: - Initialization

    /// Attaches the footer view to the scroll view.
    /// - Parameters:
    ///   - footerView: The view to display on overscroll.
    ///   - scrollView: The scroll view to attach to.
    ///   - footerHeight: The height of the footer view.
    public init(footerView: UIView, scrollView: UIScrollView, footerHeight: CGFloat) {
        self.footerView = footerView
        self.scrollView = scrollView
        self.footerHeight = footerHeight
        scrollView.addSubview(footerView)
    }

    // MARK: - Public

    /// Updates the footer position and overscroll amount.
    /// Call from `viewDidLayoutSubviews()` and `scrollViewDidScroll(_:)`.
    public func updatePosition() {
        guard let scrollView, scrollView.contentSize.height > 0 else { return }

        let footerY = max(scrollView.contentSize.height, scrollView.bounds.height)
        footerView.frame = CGRect(
            x: 0,
            y: footerY,
            width: scrollView.bounds.width,
            height: footerHeight
        )

        let rawOverscroll = scrollView.contentOffset.y + scrollView.bounds.height - footerY
        overscrollAmount = max(rawOverscroll, 0)
    }
}
