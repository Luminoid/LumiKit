//
//  LMKSegmentedControl.swift
//  LumiKit
//
//  Segmented control with a sliding indicator: equal-width, content-fitting,
//  or horizontally scrolling segments, styled from `theme.segmentedControl`.
//  Layout math lives in +Layout, touch handling in +Gestures.
//

import SnapKit
import UIKit

/// Custom segmented control with a sliding pill indicator and spring animations.
///
/// Replaces `UISegmentedControl` with a design-system-native control. The selected
/// segment sits under a filled indicator that slides between positions and can be
/// dragged. `Style.layout` picks how segments share the width: equal widths,
/// content-fitting widths, or natural widths inside a horizontal scroll view that
/// the control owns.
///
/// ```swift
/// let control = LMKSegmentedControl(items: ["List", "Month"])
/// control.onValueChange = { index in print("Selected: \(index)") }
///
/// let filters = LMKSegmentedControl(items: titles, style: .scrollable)
/// ```
///
/// `selectedSegmentIndex` is `-1` for no selection (the indicator hides), matching
/// `UISegmentedControl.noSegment`. Programmatic changes are silent; user taps and
/// drags fire `onValueChange` and `.valueChanged`.
public final class LMKSegmentedControl: UIControl, LMKThemeApplying {
    // MARK: - Vocabulary

    /// Corner shape of the container and the indicator.
    public nonisolated enum Corners: Sendable, Hashable, CaseIterable {
        /// Capsule (radius = height / 2).
        case pill
        /// The theme's medium corner radius.
        case rounded
    }

    /// How segments share the width.
    public nonisolated enum Layout: Sendable, Hashable {
        /// Every segment gets the same width; the control stretches to its host.
        case equalWidth
        /// Each segment hugs its title plus `itemPadding`; the control hugs its content.
        case fitContent
        /// Natural widths (floored at the minimum touch target) in a horizontal scroll view the
        /// control owns. `padding` is per side of each segment (`nil` = `spacing.large`), `spacing`
        /// the gap between segments (`nil` = `spacing.medium`).
        case scrollable(padding: CGFloat? = nil, spacing: CGFloat? = nil)

        /// Whether segments scroll horizontally.
        public var isScrollable: Bool {
            if case .scrollable = self { return true }
            return false
        }
    }

    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// `nil` = `.equalWidth`.
        public var layout: Layout?
        /// `nil` = `.pill`.
        public var corners: Corners?
        /// Container background (`backgroundTertiary`), corners (from `corners`), border, shadow.
        public var surface: LMKSurfaceStyle
        /// Indicator background (`primary` at `alpha.xs`), corners, border, shadow.
        public var indicator: LMKSurfaceStyle
        /// Padding between the container edge and the segments; `nil` = 4.
        public var contentInset: CGFloat?
        /// Gap between a segment and the indicator; `nil` = 2.
        public var indicatorInset: CGFloat?
        /// Unselected titles; `nil` = `subbodyMedium`.
        public var textStyle: LMKTextStyle?
        /// The selected title; `nil` = `bodyMedium`.
        public var selectedTextStyle: LMKTextStyle?
        /// `nil` = `textSecondary`.
        public var textColor: UIColor?
        /// `nil` = `primary`.
        public var selectedTextColor: UIColor?
        /// Horizontal padding per side of each title; `nil` = `spacing.medium`.
        public var itemPadding: CGFloat?
        /// Height floor; `nil` = the minimum touch target. Grows with Dynamic Type.
        public var height: CGFloat?
        /// Haptic on selection; `nil` = yes.
        public var haptics: Bool?
        /// The segment under a touch (`alpha`).
        public var highlighted: LMKControlStateStyle?
        /// The selected segment: `foregroundColor` colors its title; `background`, `border`,
        /// and `shadow` style the indicator.
        public var selected: LMKControlStateStyle?
        /// The whole control, or a single disabled segment (`alpha`).
        public var disabled: LMKControlStateStyle?

        public init(
            layout: Layout? = nil,
            corners: Corners? = nil,
            surface: LMKSurfaceStyle = LMKSurfaceStyle(),
            indicator: LMKSurfaceStyle = LMKSurfaceStyle(),
            contentInset: CGFloat? = nil,
            indicatorInset: CGFloat? = nil,
            textStyle: LMKTextStyle? = nil,
            selectedTextStyle: LMKTextStyle? = nil,
            textColor: UIColor? = nil,
            selectedTextColor: UIColor? = nil,
            itemPadding: CGFloat? = nil,
            height: CGFloat? = nil,
            haptics: Bool? = nil,
            highlighted: LMKControlStateStyle? = nil,
            selected: LMKControlStateStyle? = nil,
            disabled: LMKControlStateStyle? = nil
        ) {
            self.layout = layout
            self.corners = corners
            self.surface = surface
            self.indicator = indicator
            self.contentInset = contentInset
            self.indicatorInset = indicatorInset
            self.textStyle = textStyle
            self.selectedTextStyle = selectedTextStyle
            self.textColor = textColor
            self.selectedTextColor = selectedTextColor
            self.itemPadding = itemPadding
            self.height = height
            self.haptics = haptics
            self.highlighted = highlighted
            self.selected = selected
            self.disabled = disabled
        }

        public static let defaultValue = Self()
        /// Medium corner radius instead of a capsule.
        public static let rounded = Self(corners: .rounded)
        /// Segments hug their titles.
        public static let fitContent = Self(layout: .fitContent)
        /// Segments scroll horizontally at their natural widths.
        public static let scrollable = Self(layout: .scrollable())

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                layout: other.layout ?? layout,
                corners: other.corners ?? corners,
                surface: surface.merging(other.surface),
                indicator: indicator.merging(other.indicator),
                contentInset: other.contentInset ?? contentInset,
                indicatorInset: other.indicatorInset ?? indicatorInset,
                textStyle: other.textStyle ?? textStyle,
                selectedTextStyle: other.selectedTextStyle ?? selectedTextStyle,
                textColor: other.textColor ?? textColor,
                selectedTextColor: other.selectedTextColor ?? selectedTextColor,
                itemPadding: other.itemPadding ?? itemPadding,
                height: other.height ?? height,
                haptics: other.haptics ?? haptics,
                highlighted: LMKControlStateStyle.merge(highlighted, other.highlighted),
                selected: LMKControlStateStyle.merge(selected, other.selected),
                disabled: LMKControlStateStyle.merge(disabled, other.disabled)
            )
        }
    }

    // MARK: - Subviews

    /// Hosts the container; scrolls only in the `.scrollable` layout.
    public let scrollView = UIScrollView()
    /// The background surface.
    public let containerView: UIView = LMKSurfaceView()
    /// The sliding selection indicator.
    public let indicatorView: UIView = LMKSurfaceView()
    /// Holds one label per segment.
    public let segmentStack = UIStackView()
    /// One label per segment, in order.
    public private(set) var segmentLabels: [UILabel] = []

    // MARK: - Content

    /// Segment titles, in order.
    public private(set) var items: [String]

    /// Number of segments.
    public var numberOfSegments: Int { items.count }

    /// The selected segment, or `-1` for none. Setting it moves the indicator without
    /// animation and fires no handler.
    public var selectedSegmentIndex: Int = 0 {
        didSet {
            guard selectedSegmentIndex != oldValue, !isRebuilding else { return }
            if !isDragging, !suppressesIndicatorMove { moveIndicator(animated: false) }
            updateSegmentAppearance()
        }
    }

    /// Called with the new index after a user tap or drag changes the selection.
    public var onValueChange: ((Int) -> Void)?

    /// Per-instance style; `nil` fields resolve from `theme.segmentedControl`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKSegmentedControl) -> Void)?

    override public var isEnabled: Bool {
        didSet {
            guard isEnabled != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    // MARK: - Internal state

    var resolved = Style()
    var resolvedHeight: CGFloat = LMKSegmentedControl.defaultHeight
    /// Per-item width at the selected (wider) text style, so widths never shift on selection.
    var segmentReferenceWidths: [CGFloat] = []
    var segmentWidthConstraints: [Constraint] = []
    var disabledSegments: Set<Int> = []
    var highlightedSegmentIndex: Int?
    var indicatorLeading: Constraint?
    var indicatorTrailing: Constraint?
    var indicatorVerticalConstraint: Constraint?
    var stackInsetsConstraint: Constraint?
    var heightConstraint: Constraint?
    var containerFillWidthConstraint: Constraint?
    var containerMinWidthConstraint: Constraint?
    var panGesture: UIPanGestureRecognizer?
    var panStartOffset: CGFloat = 0
    var isDragging = false
    var preDragIndex = 0
    var suppressesIndicatorMove = false
    private var isRebuilding = false

    // MARK: - Initialization

    public init(items: [String], style: Style = Style()) {
        self.items = items
        self.style = style
        super.init(frame: .zero)
        setupUI()
        buildSegments()
        lmk_startApplyingTheme()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Selection

    /// Selects `index` (or `-1` for none), sliding the indicator when `animated`. Silent.
    /// An index past the last segment is ignored.
    public func setSelectedSegmentIndex(_ index: Int, animated: Bool) {
        guard index < items.count else { return }
        let target = max(index, -1)
        guard target != selectedSegmentIndex else { return }
        suppressesIndicatorMove = true
        selectedSegmentIndex = target
        suppressesIndicatorMove = false
        moveIndicator(animated: animated)
    }

    // MARK: - Items

    /// Replaces every segment. The selection is kept when still in range, else cleared.
    public func setItems(_ items: [String]) {
        isRebuilding = true
        self.items = items
        disabledSegments = []
        if !items.indices.contains(selectedSegmentIndex) {
            selectedSegmentIndex = -1
        }
        isRebuilding = false
        buildSegments()
        applyTheme(traitCollection.lmkTheme)
    }

    /// Inserts a segment; the selection follows its segment.
    public func insertSegment(withTitle title: String, at index: Int) {
        let index = min(max(index, 0), items.count)
        isRebuilding = true
        items.insert(title, at: index)
        disabledSegments = Set(disabledSegments.map { $0 >= index ? $0 + 1 : $0 })
        if selectedSegmentIndex >= index {
            selectedSegmentIndex += 1
        }
        isRebuilding = false
        buildSegments()
        applyTheme(traitCollection.lmkTheme)
    }

    /// Removes a segment; removing the selected one clears the selection.
    public func removeSegment(at index: Int) {
        guard items.indices.contains(index) else { return }
        isRebuilding = true
        items.remove(at: index)
        disabledSegments = Set(disabledSegments.compactMap { $0 == index ? nil : ($0 > index ? $0 - 1 : $0) })
        if selectedSegmentIndex == index {
            selectedSegmentIndex = -1
        } else if selectedSegmentIndex > index {
            selectedSegmentIndex -= 1
        }
        isRebuilding = false
        buildSegments()
        applyTheme(traitCollection.lmkTheme)
    }

    /// The title at `index`, or `nil` when out of range.
    public func title(forSegmentAt index: Int) -> String? {
        items[lmk_safe: index]
    }

    /// Enables or disables one segment: a disabled segment dims and ignores taps and drags.
    public func setEnabled(_ enabled: Bool, forSegmentAt index: Int) {
        guard items.indices.contains(index) else { return }
        if enabled {
            disabledSegments.remove(index)
        } else {
            disabledSegments.insert(index)
        }
        updateSegmentAppearance()
    }

    /// Whether the segment at `index` accepts selection.
    public func isEnabledForSegment(at index: Int) -> Bool {
        !disabledSegments.contains(index)
    }

    // MARK: - Setup

    private func setupUI() {
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delaysContentTouches = false
        scrollView.canCancelContentTouches = true
        scrollView.isScrollEnabled = false
        scrollView.clipsToBounds = false
        scrollView.contentInsetAdjustmentBehavior = .never
        addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }

        scrollView.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.height.equalTo(scrollView.frameLayoutGuide)
            containerFillWidthConstraint = make.width.equalTo(scrollView.frameLayoutGuide).constraint
            containerMinWidthConstraint = make.width.greaterThanOrEqualTo(scrollView.frameLayoutGuide).constraint
        }
        containerMinWidthConstraint?.deactivate()

        indicatorView.isUserInteractionEnabled = false
        segmentStack.axis = .horizontal
        segmentStack.distribution = .fillEqually
        segmentStack.alignment = .fill
        segmentStack.isUserInteractionEnabled = false
        containerView.addSubview(indicatorView)
        containerView.addSubview(segmentStack)
        segmentStack.snp.makeConstraints { make in
            stackInsetsConstraint = make.edges.equalToSuperview().inset(Self.defaultContentInset).constraint
        }
        indicatorView.snp.makeConstraints { make in
            indicatorVerticalConstraint = make.top.bottom.equalTo(segmentStack).inset(Self.defaultIndicatorInset).constraint
        }

        // High, not required: a host may pin a shorter height (compact toolbars) without a
        // conflict; `point(inside:)` keeps the touch target at the minimum regardless.
        snp.makeConstraints { make in
            heightConstraint = make.height.equalTo(Self.defaultHeight).priority(.high).constraint
        }
        setContentHuggingPriority(.defaultHigh, for: .horizontal)
        setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(pan)
        panGesture = pan

        isAccessibilityElement = false
        accessibilityContainerType = .semanticGroup
    }

    private func buildSegments() {
        segmentWidthConstraints.forEach { $0.deactivate() }
        segmentWidthConstraints.removeAll()
        segmentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        segmentLabels.removeAll()
        indicatorLeading = nil
        indicatorTrailing = nil

        for title in items {
            let label = UILabel()
            label.text = title
            label.textAlignment = .center
            label.isUserInteractionEnabled = false
            label.isAccessibilityElement = true
            label.accessibilityLabel = title
            label.accessibilityTraits = .button
            segmentLabels.append(label)
            segmentStack.addArrangedSubview(label)
        }
        updateSegmentAppearance()
        moveIndicator(animated: false)
        invalidateIntrinsicContentSize()
    }

    override public var intrinsicContentSize: CGSize {
        intrinsicSize(theme: traitCollection.lmkTheme)
    }

    override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard isEnabled, !isHidden else { return bounds.contains(point) }
        return lmk_hitTestBounds(minimumSide: traitCollection.lmkTheme.layout.minimumTouchTarget).contains(point)
    }

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        resolved = theme.segmentedControl.merging(style)
        let corners = resolved.corners ?? .pill
        let contentInset = resolved.contentInset ?? Self.defaultContentInset
        let indicatorInset = resolved.indicatorInset ?? Self.defaultIndicatorInset
        let mediumRadius = theme.cornerRadius.medium

        containerView.lmk_apply(
            surface: resolved.surface,
            defaults: LMKSurfaceStyle(
                background: .solid(LMKColor.backgroundTertiary),
                corners: corners == .pill ? .capsule : .fixed(mediumRadius),
                shadow: LMKShadowSource.none
            )
        )
        var indicator = resolved.indicator
        if let background = resolved.selected?.background { indicator.background = background }
        if let border = resolved.selected?.border { indicator.border = border }
        if let shadow = resolved.selected?.shadow { indicator.shadow = shadow }
        indicatorView.lmk_apply(
            surface: indicator,
            defaults: LMKSurfaceStyle(
                background: .solid(LMKColor.primary.withAlphaComponent(theme.alpha.xs)),
                corners: corners == .pill ? .capsule : .fixed(max(0, mediumRadius - contentInset - indicatorInset)),
                shadow: LMKShadowSource.none
            )
        )
        stackInsetsConstraint?.update(inset: contentInset)
        indicatorVerticalConstraint?.update(inset: indicatorInset)

        applyLayoutMode(theme)
        recomputeReferenceWidths()
        applySegmentWidthConstraints(theme)
        updateSegmentAppearance()

        let lineHeight = LMKTextMeasurement.lineHeight(of: resolved.selectedTextStyle ?? .bodyMedium, traits: traitCollection)
        resolvedHeight = max(resolved.height ?? theme.layout.minimumTouchTarget, lineHeight + (contentInset + indicatorInset) * 2)
        heightConstraint?.update(offset: resolvedHeight)
        alpha = isEnabled ? 1 : (resolved.disabled?.alpha ?? theme.alpha.disabled)
        invalidateIntrinsicContentSize()
        didApplyStyle?(self)
    }

    /// Re-applies fonts, colors, alpha, and accessibility traits to every segment label.
    func updateSegmentAppearance() {
        let theme = traitCollection.lmkTheme
        let textStyle = resolved.textStyle ?? .subbodyMedium
        let selectedTextStyle = resolved.selectedTextStyle ?? .bodyMedium
        let textColor = resolved.textColor ?? LMKColor.textSecondary
        let selectedTextColor = resolved.selected?.foregroundColor ?? resolved.selectedTextColor ?? LMKColor.primary

        for (index, label) in segmentLabels.enumerated() {
            let isSelected = index == selectedSegmentIndex
            label.lmk_apply(isSelected ? selectedTextStyle : textStyle, color: isSelected ? selectedTextColor : textColor)

            var labelAlpha: CGFloat = 1
            if !isEnabledForSegment(at: index) {
                labelAlpha = resolved.disabled?.alpha ?? theme.alpha.disabled
            }
            if index == highlightedSegmentIndex, let highlightAlpha = resolved.highlighted?.alpha {
                labelAlpha = min(labelAlpha, highlightAlpha)
            }
            label.alpha = labelAlpha

            var traits: UIAccessibilityTraits = .button
            if isSelected { traits.insert(.selected) }
            if !isEnabled || !isEnabledForSegment(at: index) { traits.insert(.notEnabled) }
            label.accessibilityTraits = traits
        }
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKSegmentedControl`.
    var segmentedControl: LMKSegmentedControl.Style {
        get { self[LMKSegmentedControl.Style.self] }
        set { self[LMKSegmentedControl.Style.self] = newValue }
    }
}
