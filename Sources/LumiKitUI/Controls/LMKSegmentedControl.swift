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
    // MARK: - Public API

    /// Called when the selected segment changes. Receives the new selected index.
    public var valueChangedHandler: ((Int) -> Void)?

    /// The number of segments.
    public var numberOfSegments: Int { items.count }

    /// The currently selected segment index. Setting this updates the UI without animation.
    public var selectedSegmentIndex: Int = 0 {
        didSet {
            guard selectedSegmentIndex != oldValue else { return }
            moveIndicator(animated: false)
            updateLabelColors()
            updateAccessibility()
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
    private let inset: CGFloat = 3

    /// Constraint anchoring the indicator to the selected label.
    private var indicatorLeading: Constraint?
    private var indicatorTrailing: Constraint?

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
        CGSize(width: UIView.noIntrinsicMetric, height: LMKLayout.minimumTouchTarget)
    }

    // MARK: - Layout

    override open func layoutSubviews() {
        super.layoutSubviews()
        containerView.layer.cornerRadius = LMKCornerRadius.medium
        indicatorView.layer.cornerRadius = LMKCornerRadius.medium - inset
    }

    // MARK: - Setup

    private func setupUI() {
        // Container — the full background
        containerView.backgroundColor = LMKColor.backgroundTertiary
        containerView.clipsToBounds = true
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = LMKColor.divider.cgColor

        // Indicator — the sliding selected pill
        indicatorView.backgroundColor = LMKColor.primary
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
            make.top.bottom.equalTo(segmentStack)
        }

        snp.makeConstraints { make in
            make.height.equalTo(LMKLayout.minimumTouchTarget)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)

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
            indicatorLeading = make.leading.equalTo(targetLabel).constraint
            indicatorTrailing = make.trailing.equalTo(targetLabel).constraint
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
            label.textColor = index == selectedSegmentIndex ? LMKColor.white : LMKColor.textSecondary
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

    // MARK: - Dynamic Colors

    private func refreshColors() {
        containerView.backgroundColor = LMKColor.backgroundTertiary
        containerView.layer.borderColor = LMKColor.divider.cgColor
        indicatorView.backgroundColor = LMKColor.primary
        updateLabelColors()
    }
}
