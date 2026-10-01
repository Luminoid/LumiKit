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
        /// Selection feedback when the user changes the page; `nil` = yes.
        public var haptics: Bool?

        public init(
            dotSize: CGFloat? = nil,
            smallDotSize: CGFloat? = nil,
            activePillWidth: CGFloat? = nil,
            spacing: CGFloat? = nil,
            activeColor: UIColor? = nil,
            inactiveColor: UIColor? = nil,
            expandsActiveDot: Bool? = nil,
            rowHeight: CGFloat? = nil,
            haptics: Bool? = nil
        ) {
            self.dotSize = dotSize
            self.smallDotSize = smallDotSize
            self.activePillWidth = activePillWidth
            self.spacing = spacing
            self.activeColor = activeColor
            self.inactiveColor = inactiveColor
            self.expandsActiveDot = expandsActiveDot
            self.rowHeight = rowHeight
            self.haptics = haptics
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
                rowHeight: other.rowHeight ?? rowHeight,
                haptics: other.haptics ?? haptics
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

    /// Number of pages (never below 0). With no pages the indicator is empty and invisible to
    /// VoiceOver; `currentPage` is clamped into the new range.
    public var numberOfPages = 0 {
        didSet {
            numberOfPages = max(0, numberOfPages)
            guard numberOfPages != oldValue else { return }
            isAccessibilityElement = numberOfPages > 0
            currentPage = min(currentPage, lastPageIndex)
            rebuildDots()
            invalidateIntrinsicContentSize()
        }
    }

    /// Currently active page, clamped to the pages that exist.
    public var currentPage = 0 {
        didSet {
            currentPage = min(max(0, currentPage), lastPageIndex)
            guard currentPage != oldValue else { return }
            updateDots(animated: true)
        }
    }

    /// Convenience for `style.expandsActiveDot`.
    public var expandsActiveDot: Bool {
        get { resolved.expandsActiveDot ?? false }
        set { style.expandsActiveDot = newValue }
    }

    /// Maximum dots shown at once (at least 1; odd counts center the active dot); more pages
    /// slide a window. Default `7`.
    public var maxVisibleDots = 7 {
        didSet {
            maxVisibleDots = max(1, maxVisibleDots)
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
    private var dotSize: CGFloat { resolved.dotSize ?? Self.defaultDotSize }
    private var smallDotSize: CGFloat { resolved.smallDotSize ?? Self.defaultSmallDotSize }
    private var activePillWidth: CGFloat { resolved.activePillWidth ?? Self.defaultActivePillWidth }
    private var spacing: CGFloat { resolved.spacing ?? Self.defaultSpacing }
    private var isWindowed: Bool { numberOfPages > maxVisibleDots }
    private var isRightToLeft: Bool { effectiveUserInterfaceLayoutDirection == .rightToLeft }
    private var lastPageIndex: Int { max(0, numberOfPages - 1) }
    /// Dots on screen: every page, or the window.
    private var visibleCount: Int { min(numberOfPages, maxVisibleDots) }

    private static let defaultDotSize: CGFloat = 8
    private static let defaultSmallDotSize: CGFloat = 5
    private static let defaultActivePillWidth: CGFloat = 24
    private static let defaultSpacing: CGFloat = 8

    /// The visible page range for the current page: the window starts so the active page sits
    /// at its center (or as close as the ends allow) and always holds `visibleCount` pages.
    private var visibleRange: ClosedRange<Int> {
        let count = visibleCount
        guard count > 0 else { return 0 ... 0 }
        let start = min(max(0, currentPage - count / 2), numberOfPages - count)
        return start ... start + count - 1
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
        let activeWidth = expandsActiveDot ? activePillWidth : dotSize
        let inactiveTotalWidth = CGFloat(visibleCount - 1) * dotSize
        let spacingTotal = CGFloat(visibleCount - 1) * spacing
        return CGSize(width: inactiveTotalWidth + activeWidth + spacingTotal, height: dotSize)
    }

    // MARK: - Setup

    private func setupUI() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
        // An element once it has pages; `.adjustable` arrives with `onPageChange` (see its `didSet`).
        isAccessibilityElement = false
        accessibilityLabel = strings.accessibilityLabel
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
        for _ in 0 ..< visibleCount {
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
    /// The row is centered on the dots as drawn (a windowed row's edge dots are smaller), so it
    /// does not shift as the active dot reaches an end.
    private func dotFrames() -> [CGRect] {
        let range = visibleRange
        let centerY = bounds.midY - dotSize / 2
        var sizes: [CGSize] = []
        for viewIndex in dotViews.indices {
            let pageIndex = range.lowerBound + viewIndex
            let isActive = pageIndex == currentPage
            let isEdge = isWindowed && !isActive && (viewIndex == 0 || viewIndex == dotViews.count - 1)
            let width: CGFloat = if expandsActiveDot, isActive { activePillWidth } else if isEdge { smallDotSize } else { dotSize }
            sizes.append(CGSize(width: width, height: isEdge ? smallDotSize : dotSize))
        }
        let rowWidth = sizes.reduce(0) { $0 + $1.width } + CGFloat(max(0, sizes.count - 1)) * spacing
        var x = (bounds.width - rowWidth) / 2
        var frames: [CGRect] = []
        for size in sizes {
            frames.append(CGRect(x: x, y: centerY + (dotSize - size.height) / 2, width: size.width, height: size.height))
            x += size.width + spacing
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
        userDidChangePage(to: page)
    }

    /// A page change the user made: moves the highlight, plays the haptic, reports it.
    private func userDidChangePage(to page: Int) {
        currentPage = page
        if resolved.haptics ?? true {
            LMKHaptics.selection()
        }
        onPageChange?(currentPage)
    }

    // MARK: - Accessibility

    override public func accessibilityIncrement() {
        guard onPageChange != nil, currentPage < lastPageIndex else { return }
        userDidChangePage(to: currentPage + 1)
    }

    override public func accessibilityDecrement() {
        guard onPageChange != nil, currentPage > 0 else { return }
        userDidChangePage(to: currentPage - 1)
    }

    private func updateAccessibilityValue() {
        accessibilityValue = String(format: strings.pageFormat, min(currentPage + 1, numberOfPages), numberOfPages)
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKPageIndicator`.
    var pageIndicator: LMKPageIndicator.Style {
        get { self[LMKPageIndicator.Style.self] }
        set { self[LMKPageIndicator.Style.self] = newValue }
    }
}
