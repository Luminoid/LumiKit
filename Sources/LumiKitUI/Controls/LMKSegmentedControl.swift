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

    /// The number of segments.
    public var numberOfSegments: Int { items.count }

    /// The currently selected segment index. Setting this updates the UI without animation.
    public var selectedSegmentIndex: Int = 0 {
        didSet {
            guard selectedSegmentIndex != oldValue else { return }
            if !isDragging { moveIndicator(animated: false) }
            updateLabelColors()
            updateAccessibility()
        }
    }

    /// Horizontal padding added to each side of every segment label.
    /// Increases the overall width of the control. Default is `LMKSpacing.medium` (12pt).
    public var itemPadding: CGFloat = LMKSpacing.medium {
        didSet {
            guard itemPadding != oldValue else { return }
            invalidateIntrinsicContentSize()
        }
    }

    /// When `true`, yields gesture priority to a parent scroll view so horizontal
    /// panning scrolls instead of switching segments.
    public var isScrollable: Bool = false

    /// Horizontal padding inside each segment when scrollable.
    /// Only used after calling `makeScrollableContainer()`. Default is `LMKSpacing.large` (16pt).
    public var scrollableItemPadding: CGFloat = LMKSpacing.large

    // MARK: - Private

    private var items: [String] = []
    private var segmentLabels: [UILabel] = []

    private let containerView = UIView()
    private let indicatorView = UIView()
    private let segmentStack = UIStackView()
    private let inset: CGFloat = 4
    private let indicatorInset: CGFloat = 2

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

    /// Create a segmented control with `[Any]?` for compatibility (only strings are used).
    public convenience init(items: [Any]?) {
        let strings = (items ?? []).compactMap { $0 as? String }
        self.init(items: strings)
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
    /// When scrollable, segments use their natural text width plus padding
    /// instead of equal-width distribution.
    public func makeScrollableContainer() -> UIScrollView {
        isScrollable = true
        panGesture?.isEnabled = false

        // Switch to natural sizing so content can exceed the visible width
        segmentStack.distribution = .fill
        segmentStack.spacing = LMKSpacing.medium

        // Give each label horizontal padding for breathing room
        for label in segmentLabels {
            label.snp.makeConstraints { make in
                make.width.greaterThanOrEqualTo(LMKLayout.minimumTouchTarget + scrollableItemPadding * 2)
            }
        }

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

    // MARK: - Intrinsic Size

    override open var intrinsicContentSize: CGSize {
        let labelsWidth = segmentLabels.reduce(CGFloat(0)) { total, label in
            total + label.intrinsicContentSize.width
        }
        let totalItemPadding = itemPadding * 2 * CGFloat(items.count)
        let width = labelsWidth + totalItemPadding + inset * 2
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

        snp.makeConstraints { make in
            make.height.equalTo(LMKLayout.minimumTouchTarget)
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

        updateLabelColors()
        invalidateIntrinsicContentSize()
        // Set initial indicator position via constraints
        moveIndicator(animated: false)
    }

    // MARK: - Indicator Positioning (Constraint-Based)

    private func moveIndicator(animated: Bool) {
        guard !segmentLabels.isEmpty, selectedSegmentIndex < segmentLabels.count else { return }
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
