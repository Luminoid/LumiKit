//
//  LMKSegmentedControl.swift
//  LumiKit
//
//  Fully custom segmented control with sliding pill indicator.
//

import SnapKit
import UIKit

/// Custom segmented control with a sliding pill indicator and spring animations.
///
/// Replaces `UISegmentedControl` with a design-system-native component.
/// The selected segment is highlighted with a filled pill that slides
/// between positions with spring animation.
///
/// ```swift
/// let control = LMKSegmentedControl(items: ["List", "Month"])
/// control.valueChangedHandler = { index in print("Selected: \(index)") }
/// ```
open class LMKSegmentedControl: UIControl {
    /// Corner style for the segmented control.
    public enum CornerStyle {
        /// Fully rounded capsule (corner radius = height / 2).
        case pill
        /// Fixed medium corner radius from the design system.
        case rounded
    }

    // MARK: - Public API

    /// Corner style for the container and indicator. Default is `.pill`.
    public var cornerStyle: CornerStyle = .pill {
        didSet {
            guard cornerStyle != oldValue else { return }
            setNeedsLayout()
        }
    }

    /// Called when the selected segment changes. Receives the new selected index.
    public var valueChangedHandler: ((Int) -> Void)?

    /// The currently selected segment index. Setting this updates the UI without animation.
    ///
    /// Set to `-1` (or any out-of-range value) to represent "no selection" —
    /// the sliding indicator is hidden and every label renders in the
    /// unselected style. This matches `UISegmentedControl.noSegment` semantics.
    public var selectedSegmentIndex: Int = 0 {
        didSet {
            guard selectedSegmentIndex != oldValue else { return }
            if !isDragging { moveIndicator(animated: false) }
            updateLabelColors()
            updateAccessibility()
        }
    }

    /// Horizontal padding added to each side of every segment label.
    /// Increases the overall width of the control. In `fitsSegmentsToContent`
    /// mode this padding is baked into each segment's pinned width.
    /// Default is `LMKSpacing.medium` (12pt).
    public var itemPadding: CGFloat = LMKSpacing.medium {
        didSet {
            guard itemPadding != oldValue else { return }
            applySegmentWidthConstraintsIfNeeded()
            invalidateIntrinsicContentSize()
        }
    }

    /// When `true`, each segment sizes to its own content width (measured at the
    /// wider selected-state font so widths stay stable as labels swap fonts on
    /// selection) plus `itemPadding` on each side, and the whole control hugs
    /// its content horizontally (won't stretch inside a `.fill` parent stack).
    /// Useful when labels have very different widths (e.g. a rating control
    /// where labels range from "★" to "★★★★★"). Default `false`.
    ///
    /// Composes with `makeScrollableContainer()`: when both are enabled the
    /// fit-mode exact-width per segment wins, and `scrollableItemPadding` is
    /// ignored (use `itemPadding` to tune breathing room).
    public var fitsSegmentsToContent: Bool = false {
        didSet {
            guard fitsSegmentsToContent != oldValue else { return }
            updateSegmentDistribution()
            setContentHuggingPriority(
                fitsSegmentsToContent ? .required : .defaultHigh,
                for: .horizontal
            )
            applySegmentWidthConstraintsIfNeeded()
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    /// When `true`, yields gesture priority to a parent scroll view so horizontal
    /// panning scrolls instead of switching segments. Setting this directly
    /// does not install a parent scroll view — prefer `makeScrollableContainer()`
    /// when you need horizontal scrolling.
    public var isScrollable: Bool = false {
        didSet {
            guard isScrollable != oldValue else { return }
            updateSegmentDistribution()
            applySegmentWidthConstraintsIfNeeded()
        }
    }

    /// Horizontal padding inside each segment when scrollable and
    /// `fitsSegmentsToContent == false`. Only used after calling
    /// `makeScrollableContainer()`. Default is `LMKSpacing.large` (16pt).
    public var scrollableItemPadding: CGFloat = LMKSpacing.large {
        didSet {
            guard scrollableItemPadding != oldValue else { return }
            applySegmentWidthConstraintsIfNeeded()
            invalidateIntrinsicContentSize()
        }
    }

    /// Gap between adjacent segments when scrollable. Only takes effect after
    /// calling `makeScrollableContainer()`; non-scrollable mode always uses 0
    /// spacing since the sliding pill spans full segment bounds.
    /// Default is `LMKSpacing.medium` (12pt).
    public var itemSpacing: CGFloat = LMKSpacing.medium {
        didSet {
            guard itemSpacing != oldValue, isScrollable else { return }
            segmentStack.spacing = itemSpacing
            invalidateIntrinsicContentSize()
        }
    }

    // MARK: - Private

    private var items: [String] = []
    private var segmentLabels: [UILabel] = []

    private let containerView = UIView()
    private let indicatorView = UIView()
    private let segmentStack = UIStackView()
    private let inset: CGFloat = 4
    private let indicatorInset: CGFloat = 2

    /// Per-segment width measured at the wider (selected-state) font so the
    /// per-item layout stays stable as labels swap fonts on selection change.
    private var segmentReferenceWidths: [CGFloat] = []
    /// Width constraints applied per label when `fitsSegmentsToContent == true`.
    private var segmentWidthConstraints: [Constraint] = []
    /// Minimum-width constraints applied per label in scrollable non-fit mode so
    /// short labels still meet the minimum touch target. Suppressed when
    /// `fitsSegmentsToContent == true` since the exact-width constraint wins.
    private var segmentMinWidthConstraints: [Constraint] = []

    /// Constraint anchoring the indicator to the selected label.
    private var indicatorLeading: Constraint?
    private var indicatorTrailing: Constraint?

    /// The pan gesture for dragging the indicator.
    private var panGesture: UIPanGestureRecognizer?
    /// Pan drag state: offset from indicator center at touch-down.
    private var panStartOffset: CGFloat = 0
    /// Whether the indicator is being dragged (constraints suspended).
    private var isDragging = false
    /// The selected index before the drag began.
    private var preDragIndex = 0

    // MARK: - Initialization

    /// Create a segmented control with string items.
    public init(items: [String]) {
        self.items = items
        super.init(frame: .zero)
        setupUI()
        buildSegments()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Methods

    /// Animate to a new selected index.
    public func setSelectedSegmentIndex(_ index: Int, animated: Bool) {
        guard index >= 0, index < items.count, index != selectedSegmentIndex else { return }
        selectedSegmentIndex = index
        moveIndicator(animated: animated)
        updateLabelColors()
        updateAccessibility()
    }

    /// Returns a scroll view container configured for horizontal scrolling of this control.
    ///
    /// In scrollable mode, segments use their natural text width plus padding
    /// instead of equal-width distribution. Combine with
    /// `fitsSegmentsToContent = true` for exact per-segment sizing (uses
    /// `itemPadding`); otherwise each segment gets a `minimumTouchTarget +
    /// scrollableItemPadding*2` floor so short labels stay tappable.
    public func makeScrollableContainer() -> UIScrollView {
        panGesture?.isEnabled = false
        segmentStack.spacing = itemSpacing

        // Triggers `isScrollable.didSet`, which switches distribution to `.fill`
        // and reapplies per-label width constraints (min-width floor in
        // non-fit mode, nothing extra in fit mode).
        isScrollable = true

        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delaysContentTouches = false
        scrollView.canCancelContentTouches = true
        scrollView.addSubview(self)
        snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }
        return scrollView
    }

    // MARK: - Gesture Priority

    override open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        isScrollable ? true : super.gestureRecognizerShouldBegin(gestureRecognizer)
    }

    // MARK: - Touch Target

    /// Keeps the HIG 44pt minimum touch target when a host constrains the
    /// control shorter or narrower: touches in the inflated band still land on
    /// the control (the tap and indicator-pan recognizers both route through
    /// this hit test).
    override open func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let dx = min(0, (bounds.width - LMKLayout.minimumTouchTarget) / 2)
        let dy = min(0, (bounds.height - LMKLayout.minimumTouchTarget) / 2)
        return bounds.insetBy(dx: dx, dy: dy).contains(point)
    }

    // MARK: - Intrinsic Size

    override open var intrinsicContentSize: CGSize {
        let count = items.count
        let totalSpacing = isScrollable ? itemSpacing * CGFloat(max(count - 1, 0)) : 0
        let pinnedWidth: CGFloat = if fitsSegmentsToContent, !segmentReferenceWidths.isEmpty {
            // Fit mode: each label == refWidth + itemPadding*2 (exact).
            segmentReferenceWidths.reduce(0, +) + itemPadding * 2 * CGFloat(count)
        } else if isScrollable, !segmentReferenceWidths.isEmpty {
            // Scrollable non-fit: each label == max(refWidth, minTouchTarget) + scrollableItemPadding*2 (exact).
            // Uses the wider selected-state refWidth so selection font swap doesn't resize segments.
            segmentReferenceWidths
                .reduce(0) { total, ref in total + max(ref, LMKLayout.minimumTouchTarget) }
                + scrollableItemPadding * 2 * CGFloat(count)
        } else {
            // Plain mode: no per-label width constraint; estimate from live intrinsic widths + itemPadding.
            segmentLabels.reduce(CGFloat(0)) { total, label in
                total + label.intrinsicContentSize.width
            } + itemPadding * 2 * CGFloat(count)
        }
        let width = pinnedWidth + totalSpacing + inset * 2
        return CGSize(width: width, height: LMKLayout.minimumTouchTarget)
    }

    // MARK: - Layout

    override open func layoutSubviews() {
        super.layoutSubviews()
        switch cornerStyle {
        case .pill:
            containerView.layer.cornerRadius = bounds.height / 2
            let indicatorHeight = bounds.height - (inset + indicatorInset) * 2
            indicatorView.layer.cornerRadius = indicatorHeight / 2
        case .rounded:
            containerView.layer.cornerRadius = LMKCornerRadius.medium
            indicatorView.layer.cornerRadius = LMKCornerRadius.medium - inset - indicatorInset
        }
    }

    // MARK: - Setup

    private func setupUI() {
        // Container — the full background
        containerView.backgroundColor = LMKColor.backgroundTertiary
        containerView.clipsToBounds = true

        // Indicator — the sliding selected pill (soft tint)
        indicatorView.backgroundColor = LMKColor.primary.withAlphaComponent(LMKAlpha.overlayMedium)
        indicatorView.clipsToBounds = true

        // Stack for segment labels
        segmentStack.axis = .horizontal
        segmentStack.distribution = .fillEqually
        segmentStack.alignment = .fill
        segmentStack.spacing = 0

        addSubview(containerView)
        containerView.addSubview(indicatorView)
        containerView.addSubview(segmentStack)

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        segmentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(inset)
        }

        // Indicator initial constraints (will be updated in moveIndicator)
        indicatorView.snp.makeConstraints { make in
            make.top.bottom.equalTo(segmentStack).inset(indicatorInset)
        }

        // High, not required: hosts may pin a shorter height (compact
        // toolbars), and a required default would conflict with theirs and
        // force UIKit to break one side at random. point(inside:) keeps the
        // effective touch target at the 44pt minimum regardless.
        snp.makeConstraints { make in
            make.height.equalTo(LMKLayout.minimumTouchTarget).priority(.high)
        }

        setContentHuggingPriority(.defaultHigh, for: .horizontal)
        setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(pan)
        panGesture = pan

        _ = registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _: UITraitCollection) in
            self.refreshColors()
        }

        // Accessibility
        isAccessibilityElement = false
        accessibilityTraits = .tabBar
    }

    private func buildSegments() {
        segmentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        segmentLabels.removeAll()

        for (index, title) in items.enumerated() {
            let label = UILabel()
            label.text = title
            label.textAlignment = .center
            label.font = LMKTypography.subbodyMedium
            label.adjustsFontForContentSizeCategory = true
            label.isUserInteractionEnabled = false

            // Accessibility per segment
            label.isAccessibilityElement = true
            label.accessibilityLabel = title
            label.accessibilityTraits = index == selectedSegmentIndex ? [.button, .selected] : .button

            segmentLabels.append(label)
            segmentStack.addArrangedSubview(label)
        }

        recomputeReferenceWidths()
        applySegmentWidthConstraintsIfNeeded()

        updateLabelColors()
        invalidateIntrinsicContentSize()
        // Set initial indicator position via constraints
        moveIndicator(animated: false)
    }

    /// Measure each item's rendered width using the wider (selected-state) font.
    /// These widths are used to pin each label's width and compute intrinsic
    /// size, so nothing shifts horizontally when selection changes the font.
    private func recomputeReferenceWidths() {
        let referenceFont = LMKTypography.bodyMedium
        segmentReferenceWidths = items.map { title in
            (title as NSString)
                .size(withAttributes: [.font: referenceFont])
                .width
                .rounded(.up)
        }
    }

    /// Apply (or remove) per-label width constraints. Two exclusive modes:
    ///
    /// - `fitsSegmentsToContent == true` (including while scrollable): pin each
    ///   label to an exact width of `referenceWidth + itemPadding*2` so
    ///   selection font changes don't reflow the stack and sum-of-widths
    ///   matches the stack's intrinsic width.
    /// - `fitsSegmentsToContent == false` and `isScrollable == true`: pin each
    ///   label to `max(refWidth, minimumTouchTarget) + scrollableItemPadding*2`
    ///   (exact). Using the wider selected-state refWidth keeps segment widths
    ///   stable as labels swap fonts on selection; the `minimumTouchTarget`
    ///   floor keeps short labels tappable.
    ///
    /// In plain (non-fit, non-scrollable) mode, no per-label width constraint
    /// is installed — `distribution = .fillEqually` handles layout.
    private func applySegmentWidthConstraintsIfNeeded() {
        segmentWidthConstraints.forEach { $0.deactivate() }
        segmentWidthConstraints.removeAll()
        segmentMinWidthConstraints.forEach { $0.deactivate() }
        segmentMinWidthConstraints.removeAll()

        guard segmentLabels.count == segmentReferenceWidths.count else { return }

        if fitsSegmentsToContent {
            for (label, referenceWidth) in zip(segmentLabels, segmentReferenceWidths) {
                label.snp.makeConstraints { make in
                    let c = make.width.equalTo(referenceWidth + itemPadding * 2).constraint
                    segmentWidthConstraints.append(c)
                }
            }
        } else if isScrollable {
            for (label, referenceWidth) in zip(segmentLabels, segmentReferenceWidths) {
                let pinned = max(referenceWidth, LMKLayout.minimumTouchTarget) + scrollableItemPadding * 2
                label.snp.makeConstraints { make in
                    let c = make.width.equalTo(pinned).constraint
                    segmentMinWidthConstraints.append(c)
                }
            }
        }
    }

    /// `.fill` whenever segments have individual widths (fit mode or scrollable);
    /// `.fillEqually` only in plain mode.
    private func updateSegmentDistribution() {
        segmentStack.distribution = (fitsSegmentsToContent || isScrollable) ? .fill : .fillEqually
    }

    // MARK: - Indicator Positioning (Constraint-Based)

    private func moveIndicator(animated: Bool) {
        guard !segmentLabels.isEmpty else { return }

        // Out-of-range index (e.g. -1) means "no selection" — hide the indicator.
        guard selectedSegmentIndex >= 0, selectedSegmentIndex < segmentLabels.count else {
            indicatorLeading?.deactivate()
            indicatorTrailing?.deactivate()
            indicatorLeading = nil
            indicatorTrailing = nil
            indicatorView.isHidden = true
            return
        }

        indicatorView.isHidden = false
        let targetLabel = segmentLabels[selectedSegmentIndex]

        // Remove old horizontal constraints and set new ones
        indicatorLeading?.deactivate()
        indicatorTrailing?.deactivate()

        indicatorView.snp.makeConstraints { make in
            indicatorLeading = make.leading.equalTo(targetLabel).offset(indicatorInset).constraint
            indicatorTrailing = make.trailing.equalTo(targetLabel).offset(-indicatorInset).constraint
        }

        if animated, LMKAnimationHelper.shouldAnimate {
            UIView.animate(
                withDuration: LMKAnimationHelper.Duration.uiShort,
                delay: 0,
                usingSpringWithDamping: LMKAnimationHelper.Spring.damping,
                initialSpringVelocity: 0,
                options: .curveEaseInOut
            ) { [self] in
                layoutIfNeeded()
            }
        }
    }

    // MARK: - Label Colors

    private func updateLabelColors() {
        for (index, label) in segmentLabels.enumerated() {
            let isSelected = index == selectedSegmentIndex
            label.textColor = isSelected ? LMKColor.primary : LMKColor.textSecondary
            label.font = isSelected ? LMKTypography.bodyMedium : LMKTypography.subbodyMedium
        }
    }

    private func updateAccessibility() {
        for (index, label) in segmentLabels.enumerated() {
            label.accessibilityTraits = index == selectedSegmentIndex ? [.button, .selected] : .button
        }
    }

    // MARK: - Actions

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: segmentStack)
        for (index, label) in segmentLabels.enumerated() where label.frame.contains(location) {
            guard index != selectedSegmentIndex else { return }
            selectedSegmentIndex = index
            moveIndicator(animated: true)
            updateLabelColors()
            updateAccessibility()
            LMKHapticFeedbackHelper.selection()
            valueChangedHandler?(index)
            sendActions(for: .valueChanged)
            return
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: containerView)

        switch gesture.state {
        case .began:
            // Require a current selection before dragging — without it the
            // indicator is hidden and its frame is undefined.
            guard selectedSegmentIndex >= 0, selectedSegmentIndex < segmentLabels.count else {
                gesture.state = .cancelled
                return
            }
            // Only start dragging if touch is on or near the indicator
            let hitArea = indicatorView.frame.insetBy(dx: -LMKSpacing.small, dy: -LMKSpacing.small)
            guard hitArea.contains(location) else {
                gesture.state = .cancelled
                return
            }
            isDragging = true
            preDragIndex = selectedSegmentIndex
            panStartOffset = location.x - indicatorView.center.x

        case .changed:
            guard isDragging else { return }
            // Move indicator to follow finger, clamped within the container
            let indicatorWidth = indicatorView.bounds.width
            let totalInset = inset + indicatorInset
            let minX = totalInset + indicatorWidth / 2
            let maxX = containerView.bounds.width - totalInset - indicatorWidth / 2
            let targetX = min(max(location.x - panStartOffset, minX), maxX)

            // Suspend constraints and position directly
            indicatorLeading?.deactivate()
            indicatorTrailing?.deactivate()
            indicatorView.center.x = targetX

            // Update highlighted segment based on indicator center
            let stackLocation = CGPoint(x: targetX - inset, y: segmentStack.bounds.midY)
            if let index = segmentIndex(at: stackLocation), index != selectedSegmentIndex {
                selectedSegmentIndex = index
                updateLabelColors()
                updateAccessibility()
                LMKHapticFeedbackHelper.selection()
            }

        case .ended, .cancelled:
            guard isDragging else { return }
            isDragging = false
            // Snap indicator to the current segment with spring animation
            moveIndicator(animated: true)
            // Fire value changed only if selection changed
            if selectedSegmentIndex != preDragIndex {
                valueChangedHandler?(selectedSegmentIndex)
                sendActions(for: .valueChanged)
            }

        default:
            break
        }
    }

    /// Returns the segment index at the given point in the stack, or `nil` if outside.
    private func segmentIndex(at point: CGPoint) -> Int? {
        for (index, label) in segmentLabels.enumerated() where label.frame.contains(point) {
            return index
        }
        // If beyond edges, return first or last
        guard !segmentLabels.isEmpty else { return nil }
        if point.x <= 0 { return 0 }
        if point.x >= segmentStack.bounds.width { return segmentLabels.count - 1 }
        return nil
    }

    // MARK: - Dynamic Colors

    private func refreshColors() {
        containerView.backgroundColor = LMKColor.backgroundTertiary
        indicatorView.backgroundColor = LMKColor.primary.withAlphaComponent(LMKAlpha.overlayMedium)
        updateLabelColors()
    }
}
