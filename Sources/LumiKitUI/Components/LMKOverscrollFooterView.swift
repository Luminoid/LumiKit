//
//  LMKOverscrollFooterView.swift
//  LumiKit
//
//  A footer parked below a scroll view's content and revealed on overscroll.
//  It observes the scroll view itself, so hosts install it and forget it.
//

import UIKit

/// A footer that sits below the visible scroll area and reveals on overscroll.
///
/// ```swift
/// let footer = LMKOverscrollFooterView(contentView: endOfListView, height: 160)
/// footer.attach(to: tableView)
/// footer.onRevealProgress = { progress in ... }   // 0 to 1
/// footer.onReveal = { loadMore() }                 // once per pull past the threshold
/// ```
///
/// The footer follows `contentSize`, `contentOffset`, and `bounds` changes through KVO and
/// respects the scroll view's adjusted bottom inset (home indicator, tab bars).
public final class LMKOverscrollFooterView: UIView {
    // MARK: - Properties

    /// The hosted content.
    public let contentView: UIView
    /// The footer's fixed height.
    public let footerHeight: CGFloat
    /// The scroll view the footer is attached to.
    public private(set) weak var scrollView: UIScrollView?

    /// Points scrolled past the end (0 while not overscrolling).
    public private(set) var overscrollAmount: CGFloat = 0

    /// Reveal fraction, 0 (hidden) to 1 (fully revealed).
    public var revealProgress: CGFloat {
        guard footerHeight > 0 else { return 0 }
        return min(overscrollAmount / footerHeight, 1)
    }

    /// Fraction of the height that counts as revealed for `onReveal`. Default 1.
    public var revealThreshold: CGFloat = 1

    /// Fades the footer with `revealProgress`. Default `true`.
    public var fadesWithProgress = true {
        didSet { updateAlpha() }
    }

    /// Called whenever `revealProgress` changes.
    public var onRevealProgress: ((CGFloat) -> Void)?

    /// Called once each time the footer is pulled past `revealThreshold`, re-armed once the
    /// scroll view settles back.
    public var onReveal: (() -> Void)?

    private var observations: [NSKeyValueObservation] = []
    private var hasFiredReveal = false

    // MARK: - Initialization

    public init(contentView: UIView, height: CGFloat) {
        self.contentView = contentView
        footerHeight = max(0, height)
        super.init(frame: .zero)
        clipsToBounds = true
        addSubview(contentView)
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.frame = bounds
        isUserInteractionEnabled = false
        updateAlpha()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        observations.forEach { $0.invalidate() }
    }

    // MARK: - Attachment

    /// Adds the footer to `scrollView` and starts following it.
    public func attach(to scrollView: UIScrollView) {
        detach()
        self.scrollView = scrollView
        scrollView.addSubview(self)
        let refresh: @Sendable (UIScrollView, Any) -> Void = { [weak self] _, _ in
            MainActor.assumeIsolated {
                self?.updatePosition()
            }
        }
        observations = [
            scrollView.observe(\.contentOffset, options: [.new], changeHandler: refresh),
            scrollView.observe(\.contentSize, options: [.new], changeHandler: refresh),
            scrollView.observe(\.bounds, options: [.new], changeHandler: refresh),
        ]
        updatePosition()
    }

    /// Stops following the scroll view and removes the footer.
    public func detach() {
        observations.forEach { $0.invalidate() }
        observations = []
        scrollView = nil
        removeFromSuperview()
    }

    // MARK: - Position

    /// Re-parks the footer below the content and recomputes the overscroll. Called
    /// automatically; call it after a layout the observations cannot see.
    public func updatePosition() {
        guard let scrollView, scrollView.contentSize.height > 0 else { return }
        let footerY = max(scrollView.contentSize.height + scrollView.adjustedContentInset.bottom, scrollView.bounds.height)
        frame = CGRect(x: 0, y: footerY, width: scrollView.bounds.width, height: footerHeight)
        contentView.frame = bounds

        let rawOverscroll = scrollView.contentOffset.y + scrollView.bounds.height - footerY
        let amount = max(rawOverscroll, 0)
        guard amount != overscrollAmount else { return }
        overscrollAmount = amount
        updateAlpha()
        onRevealProgress?(revealProgress)
        if revealProgress >= revealThreshold {
            if !hasFiredReveal {
                hasFiredReveal = true
                onReveal?()
            }
        } else if amount == 0 {
            hasFiredReveal = false
        }
    }

    private func updateAlpha() {
        alpha = fadesWithProgress ? revealProgress : 1
    }
}
