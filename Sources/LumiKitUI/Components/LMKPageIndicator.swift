//
//  LMKPageIndicator.swift
//  LumiKit
//
//  Page indicator: dots (or an expanding pill) with a sliding window for
//  many pages, per-dot hit targets, and a VoiceOver-adjustable value.
//

import UIKit

/// Page indicator replacing `UIPageControl`.
///
/// Tap-to-navigate and the VoiceOver adjustable gestures are active only while
/// `onPageChange` is set. Without a handler the indicator is display-only, so
/// the highlight can never drift from a host that drives pages itself.
///
/// ```swift
/// let indicator = LMKPageIndicator()
/// indicator.numberOfPages = 12
/// indicator.maxVisibleDots = 7
/// indicator.onPageChange = { page in print("Page: \(page)") }
/// ```
public final class LMKPageIndicator: UIView, LMKThemeApplying {
    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// `nil` = 8.
        public var dotSize: CGFloat?
        /// Edge dots of a windowed indicator; `nil` = 5.
        public var smallDotSize: CGFloat?
        /// Width of the active dot when `expandsActiveDot`; `nil` = 24.
        public var activePillWidth: CGFloat?
        /// `nil` = 8.
        public var spacing: CGFloat?
        /// `nil` = `primary`.
        public var activeColor: UIColor?
        /// `nil` = `fillStrong`.
        public var inactiveColor: UIColor?
        /// The active dot grows into a pill; `nil` = no.
        public var expandsActiveDot: Bool?
        /// Height of the tappable row; `nil` = `minimumTouchTarget`.
        public var rowHeight: CGFloat?

        public init(
            dotSize: CGFloat? = nil,
            smallDotSize: CGFloat? = nil,
            activePillWidth: CGFloat? = nil,
            spacing: CGFloat? = nil,
            activeColor: UIColor? = nil,
            inactiveColor: UIColor? = nil,
            expandsActiveDot: Bool? = nil,
            rowHeight: CGFloat? = nil
        ) {
            self.dotSize = dotSize
            self.smallDotSize = smallDotSize
            self.activePillWidth = activePillWidth
            self.spacing = spacing
            self.activeColor = activeColor
            self.inactiveColor = inactiveColor
            self.expandsActiveDot = expandsActiveDot
            self.rowHeight = rowHeight
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                dotSize: other.dotSize ?? dotSize,
                smallDotSize: other.smallDotSize ?? smallDotSize,
                activePillWidth: other.activePillWidth ?? activePillWidth,
                spacing: other.spacing ?? spacing,
                activeColor: other.activeColor ?? activeColor,
                inactiveColor: other.inactiveColor ?? inactiveColor,
                expandsActiveDot: other.expandsActiveDot ?? expandsActiveDot,
                rowHeight: other.rowHeight ?? rowHeight
            )
        }
    }

    // MARK: - Strings

    public nonisolated struct Strings: Sendable, Equatable {
        /// VoiceOver label of the indicator ("Page indicator").
        public var accessibilityLabel: String
        /// VoiceOver value format; receives the 1-based current page and the page count (`%lld of %lld`).
        public var pageFormat: String

        public init(
            accessibilityLabel: String = LMKLocalized("pageIndicator.accessibilityLabel"),
            pageFormat: String = LMKLocalized("pageIndicator.accessibilityValue")
        ) {
            self.accessibilityLabel = accessibilityLabel
            self.pageFormat = pageFormat
        }
    }

    /// Process-wide defaults; set at app launch to override.
    public nonisolated(unsafe) static var strings = Strings()

    /// Per-instance strings (default `Self.strings`).
    public var strings: Strings = LMKPageIndicator.strings {
        didSet {
            accessibilityLabel = strings.accessibilityLabel
            updateAccessibilityValue()
        }
    }

    // MARK: - Public API

    /// Number of pages.
    public var numberOfPages = 0 {
        didSet {
            guard numberOfPages != oldValue else { return }
            rebuildDots()
            invalidateIntrinsicContentSize()
        }
    }

    /// Currently active page.
    public var currentPage = 0 {
        didSet {
            guard currentPage != oldValue else { return }
            updateDots(animated: true)
        }
    }

    /// Convenience for `style.expandsActiveDot`.
    public var expandsActiveDot: Bool {
        get { resolved.expandsActiveDot ?? false }
        set { style.expandsActiveDot = newValue }
    }

    /// Maximum dots shown at once (odd, for symmetry); more pages slide a window. Default `7`.
    public var maxVisibleDots = 7 {
        didSet {
            guard maxVisibleDots != oldValue else { return }
            rebuildDots()
            invalidateIntrinsicContentSize()
        }
    }

    /// Called when the user changes the page (tap or VoiceOver). While `nil`, input is ignored.
    public var onPageChange: ((Int) -> Void)? {
        didSet { accessibilityTraits = onPageChange == nil ? [] : .adjustable }
    }

    /// Per-instance style; `nil` fields resolve from `theme.pageIndicator`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKPageIndicator) -> Void)?

    /// The dot views, leading to trailing.
    public private(set) var dotViews: [UIView] = []

    // MARK: - Private

    private var resolved = Style()
    private var dotSize: CGFloat { resolved.dotSize ?? 8 }
    private var smallDotSize: CGFloat { resolved.smallDotSize ?? 5 }
    private var activePillWidth: CGFloat { resolved.activePillWidth ?? 24 }
    private var spacing: CGFloat { resolved.spacing ?? 8 }
    private var isWindowed: Bool { numberOfPages > maxVisibleDots }
    private var isRightToLeft: Bool { effectiveUserInterfaceLayoutDirection == .rightToLeft }

    /// The visible page range for the current page.
    private var visibleRange: ClosedRange<Int> {
        guard isWindowed else { return 0 ... max(0, numberOfPages - 1) }
        let half = maxVisibleDots / 2
        var start = currentPage - half
        var end = currentPage + half
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

    public init(style: Style = Style()) {
        self.style = style
        super.init(frame: .zero)
        setupUI()
        lmk_startApplyingTheme()
    }

    override public convenience init(frame: CGRect) {
        self.init(style: Style())
        self.frame = frame
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Intrinsic Size

    override public var intrinsicContentSize: CGSize {
        guard numberOfPages > 0 else { return .zero }
        let visibleCount = min(numberOfPages, maxVisibleDots)
        let activeWidth = expandsActiveDot ? activePillWidth : dotSize
        let inactiveTotalWidth = CGFloat(visibleCount - 1) * dotSize
        let spacingTotal = CGFloat(visibleCount - 1) * spacing
        return CGSize(width: inactiveTotalWidth + activeWidth + spacingTotal, height: dotSize)
    }

    // MARK: - Setup

    private func setupUI() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
        isAccessibilityElement = true
        accessibilityLabel = strings.accessibilityLabel
        // `.adjustable` arrives with `onPageChange` (see its `didSet`).
    }

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        resolved = theme.pageIndicator.merging(style)
        invalidateIntrinsicContentSize()
        updateDots(animated: false)
        didApplyStyle?(self)
    }

    // MARK: - Build

    private func rebuildDots() {
        dotViews.forEach { $0.removeFromSuperview() }
        dotViews.removeAll()
        let count = min(numberOfPages, maxVisibleDots)
        for _ in 0 ..< count {
            let dot = UIView()
            dot.clipsToBounds = true
            dot.isUserInteractionEnabled = false
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

    /// Frames for the visible dots in layout order (`viewIndex`), honoring the layout direction.
    private func dotFrames() -> [CGRect] {
        let range = visibleRange
        let centerY = bounds.midY - dotSize / 2
        var x = (bounds.width - intrinsicContentSize.width) / 2
        var frames: [CGRect] = []
        for viewIndex in dotViews.indices {
            let pageIndex = range.lowerBound + viewIndex
            let isActive = pageIndex == currentPage
            let isEdge = isWindowed && !isActive && (viewIndex == 0 || viewIndex == dotViews.count - 1)
            let width: CGFloat = if expandsActiveDot, isActive { activePillWidth } else if isEdge { smallDotSize } else { dotSize }
            let height = isEdge ? smallDotSize : dotSize
            frames.append(CGRect(x: x, y: centerY + (dotSize - height) / 2, width: width, height: height))
            x += width + spacing
        }
        if isRightToLeft {
            return frames.map { CGRect(x: bounds.width - $0.maxX, y: $0.minY, width: $0.width, height: $0.height) }
        }
        return frames
    }

    private func layoutDots(animated: Bool) {
        guard !dotViews.isEmpty else { return }
        for (dot, frame) in zip(dotViews, dotFrames()) {
            if animated, LMKAnimation.shouldAnimate {
                UIView.animate(
                    withDuration: LMKAnimation.Duration.fast,
                    delay: 0,
                    usingSpringWithDamping: LMKAnimation.spring.damping,
                    initialSpringVelocity: 0,
                    options: LMKAnimation.Curve.easeInOut.options
                ) {
                    dot.frame = frame
                    dot.layer.cornerRadius = frame.height / 2
                }
            } else {
                dot.frame = frame
                dot.layer.cornerRadius = frame.height / 2
            }
        }
    }

    private func updateDots(animated: Bool) {
        let range = visibleRange
        let active = resolved.activeColor ?? LMKColor.primary
        let inactive = resolved.inactiveColor ?? LMKColor.fillStrong
        for (viewIndex, dot) in dotViews.enumerated() {
            let color = range.lowerBound + viewIndex == currentPage ? active : inactive
            if animated, LMKAnimation.shouldAnimate {
                UIView.animate(withDuration: LMKAnimation.Duration.fast) { dot.backgroundColor = color }
            } else {
                dot.backgroundColor = color
            }
        }
        layoutDots(animated: animated)
        updateAccessibilityValue()
    }

    // MARK: - Hit testing

    override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard onPageChange != nil else { return bounds.contains(point) }
        return lmk_hitTestBounds(minimumSide: resolved.rowHeight ?? traitCollection.lmkTheme.layout.minimumTouchTarget).contains(point)
    }

    /// The page whose dot covers `point` (in the indicator's coordinates), with a gap-splitting hit area.
    public func page(at point: CGPoint) -> Int? {
        let range = visibleRange
        let rowHeight = resolved.rowHeight ?? traitCollection.lmkTheme.layout.minimumTouchTarget
        for (viewIndex, frame) in dotFrames().enumerated() {
            let hitArea = CGRect(x: frame.minX - spacing / 2, y: bounds.midY - rowHeight / 2, width: frame.width + spacing, height: rowHeight)
            if hitArea.contains(point) {
                return range.lowerBound + viewIndex
            }
        }
        return nil
    }

    // MARK: - Actions

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard onPageChange != nil, let page = page(at: gesture.location(in: self)), page != currentPage else { return }
        currentPage = page
        LMKHaptics.selection()
        onPageChange?(currentPage)
    }

    // MARK: - Accessibility

    override public func accessibilityIncrement() {
        guard onPageChange != nil, currentPage < numberOfPages - 1 else { return }
        currentPage += 1
        LMKHaptics.selection()
        onPageChange?(currentPage)
    }

    override public func accessibilityDecrement() {
        guard onPageChange != nil, currentPage > 0 else { return }
        currentPage -= 1
        LMKHaptics.selection()
        onPageChange?(currentPage)
    }

    private func updateAccessibilityValue() {
        accessibilityValue = String(format: strings.pageFormat, currentPage + 1, numberOfPages)
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKPageIndicator`.
    var pageIndicator: LMKPageIndicator.Style {
        get { self[LMKPageIndicator.Style.self] }
        set { self[LMKPageIndicator.Style.self] = newValue }
    }
}
