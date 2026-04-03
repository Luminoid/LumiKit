//
//  LMKPageIndicator.swift
//  LumiKit
//
//  Custom page indicator with optional expanding pill and windowed dot display.
//

import UIKit

/// Custom page indicator replacing `UIPageControl`.
///
/// Supports two display modes:
/// - **Dots only** (default): All dots same size, active dot uses primary color
/// - **Expanding pill** (`expandsActiveDot = true`): Active dot expands into a pill shape
///
/// When `numberOfPages > maxVisibleDots`, a sliding window shows only
/// `maxVisibleDots` dots at a time. The leftmost and rightmost visible dots
/// are drawn smaller to hint at more pages beyond.
///
/// ```swift
/// let indicator = LMKPageIndicator()
/// indicator.numberOfPages = 12
/// indicator.maxVisibleDots = 7
/// indicator.currentPage = 0
/// indicator.pageChangedHandler = { page in print("Page: \(page)") }
/// ```
public final class LMKPageIndicator: UIView {
    // MARK: - Constants

    private static let dotSize: CGFloat = 8
    private static let smallDotSize: CGFloat = 5
    private static let activePillWidth: CGFloat = 24
    private static let dotSpacing: CGFloat = 8

    // MARK: - Public API

    /// Number of pages.
    public var numberOfPages: Int = 0 {
        didSet {
            guard numberOfPages != oldValue else { return }
            rebuildDots()
            invalidateIntrinsicContentSize()
        }
    }

    /// Currently active page.
    public var currentPage: Int = 0 {
        didSet {
            guard currentPage != oldValue else { return }
            updateDots(animated: true)
        }
    }

    /// When `true`, the active dot expands into a pill shape. Default is `false`.
    public var expandsActiveDot: Bool = false {
        didSet {
            guard expandsActiveDot != oldValue else { return }
            invalidateIntrinsicContentSize()
            updateDots(animated: false)
        }
    }

    /// Maximum number of dots visible at once. When `numberOfPages` exceeds this,
    /// a sliding window is used and edge dots are drawn smaller.
    /// Must be odd (for center symmetry). Default is `7`.
    public var maxVisibleDots: Int = 7 {
        didSet {
            guard maxVisibleDots != oldValue else { return }
            invalidateIntrinsicContentSize()
            updateDots(animated: false)
        }
    }

    /// Closure called when page changes via user tap.
    public var pageChangedHandler: ((Int) -> Void)?

    // MARK: - Private

    private var dotViews: [UIView] = []

    /// Whether windowing is needed (more pages than maxVisibleDots).
    private var isWindowed: Bool { numberOfPages > maxVisibleDots }

    /// Computes the visible page range for the current page.
    private var visibleRange: ClosedRange<Int> {
        guard isWindowed else { return 0 ... max(0, numberOfPages - 1) }
        let half = maxVisibleDots / 2
        var start = currentPage - half
        var end = currentPage + half

        // Clamp to bounds
        if start < 0 {
            end -= start
            start = 0
        }
        if end >= numberOfPages {
            start -= (end - numberOfPages + 1)
            end = numberOfPages - 1
        }
        start = max(0, start)
        return start ... end
    }

    // MARK: - Initialization

    public init() {
        super.init(frame: .zero)
        setupUI()
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Intrinsic Size

    override public var intrinsicContentSize: CGSize {
        guard numberOfPages > 0 else { return .zero }
        let visibleCount = min(numberOfPages, maxVisibleDots)
        let activeWidth = expandsActiveDot ? Self.activePillWidth : Self.dotSize
        let inactiveCount = visibleCount - 1
        let inactiveTotalWidth = CGFloat(inactiveCount) * Self.dotSize
        let spacingTotal = CGFloat(visibleCount - 1) * Self.dotSpacing
        return CGSize(width: inactiveTotalWidth + activeWidth + spacingTotal, height: Self.dotSize)
    }

    // MARK: - Setup

    private func setupUI() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)

        isAccessibilityElement = true
        accessibilityTraits = .adjustable

        _ = registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _: UITraitCollection) in
            self.refreshColors()
        }
    }

    // MARK: - Build

    private func rebuildDots() {
        dotViews.forEach { $0.removeFromSuperview() }
        dotViews.removeAll()

        let count = min(numberOfPages, maxVisibleDots)
        for _ in 0 ..< count {
            let dot = UIView()
            dot.clipsToBounds = true
            addSubview(dot)
            dotViews.append(dot)
        }

        updateDots(animated: false)
    }

    // MARK: - Layout

    override public func layoutSubviews() {
        super.layoutSubviews()
        layoutDots(animated: false)
    }

    private func layoutDots(animated: Bool) {
        guard !dotViews.isEmpty else { return }

        let range = visibleRange
        let centerY = bounds.midY - Self.dotSize / 2
        var x = (bounds.width - intrinsicContentSize.width) / 2

        for (viewIndex, dot) in dotViews.enumerated() {
            let pageIndex = range.lowerBound + viewIndex
            let isActive = pageIndex == currentPage
            let isEdge = isWindowed && !isActive && (viewIndex == 0 || viewIndex == dotViews.count - 1)

            // Determine dot width
            let dotWidth: CGFloat = if expandsActiveDot, isActive {
                Self.activePillWidth
            } else if isEdge {
                Self.smallDotSize
            } else {
                Self.dotSize
            }

            // Determine dot height (edge dots are smaller, but never the active dot)
            let dotHeight = isEdge ? Self.smallDotSize : Self.dotSize
            let yOffset = centerY + (Self.dotSize - dotHeight) / 2

            let frame = CGRect(x: x, y: yOffset, width: dotWidth, height: dotHeight)

            if animated, LMKAnimationHelper.shouldAnimate {
                UIView.animate(
                    withDuration: LMKAnimationHelper.Duration.uiShort,
                    delay: 0,
                    usingSpringWithDamping: LMKAnimationHelper.Spring.damping,
                    initialSpringVelocity: 0,
                    options: .curveEaseInOut
                ) {
                    dot.frame = frame
                    dot.layer.cornerRadius = dotHeight / 2
                }
            } else {
                dot.frame = frame
                dot.layer.cornerRadius = dotHeight / 2
            }

            x += dotWidth + Self.dotSpacing
        }
    }

    private func updateDots(animated: Bool) {
        let range = visibleRange

        for (viewIndex, dot) in dotViews.enumerated() {
            let pageIndex = range.lowerBound + viewIndex
            let isActive = pageIndex == currentPage
            let color = isActive ? LMKColor.primary : LMKColor.graySoft

            if animated, LMKAnimationHelper.shouldAnimate {
                UIView.animate(withDuration: LMKAnimationHelper.Duration.uiShort) {
                    dot.backgroundColor = color
                }
            } else {
                dot.backgroundColor = color
            }
        }

        layoutDots(animated: animated)
        updateAccessibilityValue()
    }

    // MARK: - Actions

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        let range = visibleRange

        for (viewIndex, dot) in dotViews.enumerated() {
            let hitArea = dot.frame.insetBy(dx: -Self.dotSpacing / 2, dy: -8)
            if hitArea.contains(location) {
                let pageIndex = range.lowerBound + viewIndex
                guard pageIndex != currentPage else { return }
                currentPage = pageIndex
                LMKHapticFeedbackHelper.selection()
                pageChangedHandler?(currentPage)
                return
            }
        }
    }

    // MARK: - Accessibility

    override public func accessibilityIncrement() {
        guard currentPage < numberOfPages - 1 else { return }
        currentPage += 1
        LMKHapticFeedbackHelper.selection()
        pageChangedHandler?(currentPage)
    }

    override public func accessibilityDecrement() {
        guard currentPage > 0 else { return }
        currentPage -= 1
        LMKHapticFeedbackHelper.selection()
        pageChangedHandler?(currentPage)
    }

    private func updateAccessibilityValue() {
        accessibilityValue = "\(currentPage + 1) of \(numberOfPages)"
    }

    // MARK: - Dynamic Colors

    private func refreshColors() {
        let range = visibleRange
        for (viewIndex, dot) in dotViews.enumerated() {
            let pageIndex = range.lowerBound + viewIndex
            dot.backgroundColor = pageIndex == currentPage ? LMKColor.primary : LMKColor.graySoft
        }
    }
}
