//
//  LMKCalendarDayCell.swift
//  LumiKit
//
//  One day of a month calendar: numeral, optional glyph, presence dots or
//  count badges, and the selection / today / range marks behind it. The one
//  subclass point of the calendar.
//

import LumiKitCore
import SnapKit
import UIKit

/// A day cell of `LMKMonthCalendarView`.
///
/// The calendar owns a pool of cells and re-applies `apply(state:decoration:style:theme:)`
/// whenever content, selection, or the theme changes. Subclass to add content: override
/// `apply` (call `super`) and add subviews around `numeralStack` / `decorationStack`.
open class LMKCalendarDayCell: UIControl {
    // MARK: - Vocabulary

    /// Where a day sits in a range selection.
    public nonisolated enum RangePosition: Sendable, Hashable, CaseIterable {
        case none
        /// The only selected day.
        case single
        case start
        case middle
        case end
    }

    /// Everything the calendar decides about a day; the cell only draws it.
    public nonisolated struct DayState: Sendable, Equatable {
        public var day: LMKCalendarDay
        /// The localized day number; empty for a hidden adjacent-month slot.
        public var numeral: String
        /// Whether the day belongs to the visible month (adjacent days render dimmed).
        public var isInMonth: Bool
        public var isToday: Bool
        public var isSelected: Bool
        public var rangePosition: RangePosition
        public var isEnabled: Bool
        /// The full date VoiceOver reads ("Today, Wednesday, September 16, 2026").
        public var accessibilityLabel: String

        public init(
            day: LMKCalendarDay,
            numeral: String,
            isInMonth: Bool = true,
            isToday: Bool = false,
            isSelected: Bool = false,
            rangePosition: RangePosition = .none,
            isEnabled: Bool = true,
            accessibilityLabel: String = ""
        ) {
            self.day = day
            self.numeral = numeral
            self.isInMonth = isInMonth
            self.isToday = isToday
            self.isSelected = isSelected
            self.rangePosition = rangePosition
            self.isEnabled = isEnabled
            self.accessibilityLabel = accessibilityLabel
        }
    }

    // MARK: - Properties

    /// The state last applied; `nil` before the first `apply`.
    public private(set) var dayState: DayState?
    /// The decoration last applied.
    public private(set) var decoration: LMKCalendarDayDecoration = .none
    /// The (theme-merged) style last applied.
    public private(set) var resolvedStyle = LMKMonthCalendarView.Style()

    /// Called with the day on tap (the calendar sets it).
    public var onTap: ((LMKCalendarDay) -> Void)?

    /// The numeral and its glyph.
    public let numeralStack = UIStackView()
    public let numeralLabel = UILabel()
    public let glyphView = UIImageView()
    /// Dots and badges under the numeral.
    public let decorationStack = UIStackView()
    public let dotsStack = UIStackView()
    public let badgesStack = UIStackView()
    /// The selection mark (circle, ring, or rounded rect) behind the numeral.
    public let selectionView = UIView()
    /// The today mark behind the numeral.
    public let todayView = UIView()
    /// The band across the middle of a range.
    public let rangeBandView = UIView()

    private var dotViews: [UIView] = []
    private var badgeViews: [LMKBadgeView] = []
    private var numeralCenterConstraint: Constraint?
    private var pressAnimates = true
    private var selectionGeometry: MarkGeometry?
    private var todayGeometry: MarkGeometry?

    private enum MarkGeometry: Equatable {
        case circle(radius: CGFloat)
        case roundedRect
    }

    // MARK: - Initialization

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        isAccessibilityElement = true
        accessibilityTraits = .button
        layer.masksToBounds = false

        for mark in [rangeBandView, todayView, selectionView] {
            mark.isUserInteractionEnabled = false
            mark.isHidden = true
            addSubview(mark)
        }

        numeralStack.axis = .horizontal
        numeralStack.alignment = .center
        numeralStack.spacing = 1
        numeralStack.isUserInteractionEnabled = false
        numeralLabel.textAlignment = .center
        glyphView.contentMode = .scaleAspectFit
        glyphView.isHidden = true
        numeralStack.addArrangedSubview(numeralLabel)
        numeralStack.addArrangedSubview(glyphView)
        addSubview(numeralStack)
        numeralStack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            numeralCenterConstraint = make.centerY.equalToSuperview().constraint
        }

        decorationStack.axis = .vertical
        decorationStack.alignment = .center
        decorationStack.isUserInteractionEnabled = false
        dotsStack.axis = .horizontal
        dotsStack.alignment = .center
        badgesStack.axis = .horizontal
        badgesStack.alignment = .center
        decorationStack.addArrangedSubview(dotsStack)
        decorationStack.addArrangedSubview(badgesStack)
        addSubview(decorationStack)
        decorationStack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(numeralStack.snp.bottom)
        }

        rangeBandView.snp.makeConstraints { make in
            make.centerY.equalTo(numeralStack)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(0)
        }

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        addTarget(self, action: #selector(handleTouchDown), for: .touchDown)
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        addInteraction(UIPointerInteraction(delegate: self))
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        lmk_layoutSurfaceIfNeeded()
    }

    /// The 44pt hit target the row height may not provide on its own. A disabled day absorbs
    /// its own bounds, as UIKit's controls do, so a tap on it never reaches what is underneath.
    override open func point(inside point: CGPoint, with _: UIEvent?) -> Bool {
        guard !isHidden else { return false }
        guard isEnabled else { return bounds.contains(point) }
        return lmk_hitTestBounds(minimumSide: traitCollection.lmkTheme.layout.minimumTouchTarget).contains(point)
    }

    // MARK: - Apply

    /// Renders `state` and `decoration` with `style` (already merged with the theme's slot).
    open func apply(state: DayState, decoration: LMKCalendarDayDecoration, style: LMKMonthCalendarView.Style, theme: LMKTheme) {
        dayState = state
        self.decoration = decoration
        resolvedStyle = style
        pressAnimates = style.pressAnimation ?? true
        isEnabled = state.isEnabled
        alpha = 1

        let accent = style.accent ?? LMKColor.primary
        let selectionTint = style.selectionTint ?? accent
        let todayTint = style.todayTint ?? accent
        let selectionStyle = style.selectionStyle ?? .filledCircle
        let todayStyle = style.todayStyle ?? .tintedCircle
        let showsToday = state.isToday && !(state.isSelected && (style.todayHiddenUnderSelection ?? true))
        let isDimmed = !state.isInMonth || !state.isEnabled

        _ = lmk_apply(surface: style.cellSurface, defaults: LMKSurfaceStyle(background: .clear), clipsContent: false)

        // Numeral
        numeralCenterConstraint?.update(offset: style.numeralCenterOffset ?? Self.defaultNumeralCenterOffset)
        let emphasized = state.isSelected || state.isToday
        let textStyle = emphasized ? (style.numeralEmphasisTextStyle ?? .bodyMedium) : (style.numeralTextStyle ?? .body)
        let numeralColor: UIColor = if isDimmed {
            style.numeralDisabledColor ?? LMKColor.textTertiary
        } else if state.isSelected {
            style.numeralSelectedColor ?? (selectionStyle == .filledCircle ? LMKColor.onAccent : selectionTint)
        } else if state.isToday {
            style.numeralTodayColor ?? todayTint
        } else {
            style.numeralColor ?? LMKColor.textPrimary
        }
        numeralLabel.lmk_apply(textStyle, color: numeralColor)
        numeralLabel.lmk_setText(state.numeral)
        numeralStack.isHidden = state.numeral.isEmpty

        // Glyph
        if let glyph = decoration.glyph, !state.numeral.isEmpty {
            glyphView.image = glyph
            glyphView.tintColor = state.isSelected && selectionStyle == .filledCircle ? numeralColor : (decoration.glyphTint ?? style.glyphTint ?? LMKColor.textSecondary)
            let size = style.glyphSize ?? theme.layout.symbolInline
            // Just below required: the numeral stack hides the glyph with its own constraint.
            glyphView.snp.remakeConstraints { make in
                make.width.height.equalTo(size).priority(999)
            }
            glyphView.isHidden = false
        } else {
            glyphView.image = nil
            glyphView.isHidden = true
        }

        // Marks
        let radius = style.circleRadius ?? Self.defaultCircleRadius
        let ringWidth = style.ringWidth ?? Self.defaultRingWidth
        let roundedRadius = style.roundedRectRadius ?? theme.cornerRadius.medium
        if state.isSelected, !state.numeral.isEmpty {
            switch selectionStyle {
            case .filledCircle:
                configureMark(selectionView, geometry: .circle(radius: radius), fill: selectionTint, ring: nil, ringWidth: ringWidth, cornerRadius: roundedRadius)
            case .ringCircle:
                configureMark(selectionView, geometry: .circle(radius: radius), fill: nil, ring: selectionTint, ringWidth: ringWidth, cornerRadius: roundedRadius)
            case .ringRoundedRect:
                configureMark(selectionView, geometry: .roundedRect, fill: nil, ring: selectionTint, ringWidth: ringWidth, cornerRadius: roundedRadius)
            }
            selectionView.isHidden = false
        } else {
            selectionView.isHidden = true
        }

        if showsToday, !state.numeral.isEmpty {
            switch todayStyle {
            case .tintedCircle:
                configureMark(
                    todayView,
                    geometry: .circle(radius: radius),
                    fill: todayTint.withAlphaComponent(style.todayCircleAlpha ?? theme.alpha.xs),
                    ring: nil,
                    ringWidth: ringWidth,
                    cornerRadius: roundedRadius
                )
                todayView.isHidden = false
            case .ringCircle:
                configureMark(todayView, geometry: .circle(radius: radius), fill: nil, ring: todayTint, ringWidth: ringWidth, cornerRadius: roundedRadius)
                todayView.isHidden = false
            case .ringRoundedRect:
                configureMark(todayView, geometry: .roundedRect, fill: nil, ring: todayTint, ringWidth: ringWidth, cornerRadius: roundedRadius)
                todayView.isHidden = false
            case .numeralOnly:
                todayView.isHidden = true
            }
        } else {
            todayView.isHidden = true
        }

        applyRangeBand(position: state.rangePosition, tint: selectionTint, alpha: style.rangeBandAlpha ?? theme.alpha.xs, radius: radius)

        // Decorations
        let invertsDecorations = state.isSelected && selectionStyle == .filledCircle
        applyDots(decoration.dots, style: style, theme: theme, inverted: invertsDecorations ? numeralColor : nil)
        applyBadges(decoration.badges, style: style, theme: theme, accent: accent)
        decorationStack.isHidden = state.numeral.isEmpty || (dotsStack.isHidden && badgesStack.isHidden)

        // Accessibility
        isAccessibilityElement = state.isInMonth && !state.numeral.isEmpty
        accessibilityLabel = state.accessibilityLabel
        accessibilityValue = decoration.accessibilityValue
        var traits: UIAccessibilityTraits = .button
        if state.isSelected { traits.insert(.selected) }
        if !state.isEnabled { traits.insert(.notEnabled) }
        accessibilityTraits = traits
    }

    private func configureMark(_ mark: UIView, geometry: MarkGeometry, fill: UIColor?, ring: UIColor?, ringWidth: CGFloat, cornerRadius: CGFloat) {
        let previous = mark === selectionView ? selectionGeometry : todayGeometry
        if previous != geometry {
            switch geometry {
            case let .circle(radius):
                mark.snp.remakeConstraints { make in
                    make.center.equalTo(numeralStack)
                    make.width.height.equalTo(radius * 2)
                }
            case .roundedRect:
                mark.snp.remakeConstraints { make in
                    make.edges.equalToSuperview().inset(1)
                }
            }
            if mark === selectionView { selectionGeometry = geometry } else { todayGeometry = geometry }
        }
        switch geometry {
        case let .circle(radius):
            mark.lmk_applyCornerStyle(.fixed(radius))
        case .roundedRect:
            mark.lmk_applyCornerStyle(.fixed(cornerRadius))
        }
        mark.backgroundColor = fill ?? .clear
        if let ring {
            mark.lmk_applyBorder(color: ring, width: ringWidth)
        } else {
            mark.lmk_removeBorder()
        }
    }

    private func applyRangeBand(position: RangePosition, tint: UIColor, alpha: CGFloat, radius: CGFloat) {
        guard position == .start || position == .middle || position == .end else {
            rangeBandView.isHidden = true
            return
        }
        rangeBandView.isHidden = false
        rangeBandView.backgroundColor = tint.withAlphaComponent(alpha)
        rangeBandView.snp.remakeConstraints { make in
            make.centerY.equalTo(numeralStack)
            make.height.equalTo(radius * 2)
            switch position {
            case .start:
                make.leading.equalTo(snp.centerX)
                make.trailing.equalToSuperview()
            case .end:
                make.leading.equalToSuperview()
                make.trailing.equalTo(snp.centerX)
            default:
                make.leading.trailing.equalToSuperview()
            }
        }
    }

    /// Built-in metrics, shared with the grid's row-height floor.
    static let defaultNumeralCenterOffset: CGFloat = -3
    static let defaultDotSize: CGFloat = 5
    static let defaultDotSpacing: CGFloat = 2
    static let defaultMaxDots = 3
    static let defaultCircleRadius: CGFloat = 18
    static let defaultRingWidth: CGFloat = 2

    /// The height of the band under the numeral that `decoration` fills: dots, badges, or both.
    static func decorationBandHeight(for decoration: LMKCalendarDayDecoration, style: LMKMonthCalendarView.Style, theme: LMKTheme) -> CGFloat {
        let showsDots = !decoration.dots.isEmpty && (style.maxDots ?? defaultMaxDots) > 0
        let showsBadges = !decoration.badges.isEmpty
        var height: CGFloat = 0
        if showsDots { height += style.dotSize ?? defaultDotSize }
        if showsBadges { height += (showsDots ? theme.spacing.xxs : 0) + (style.badge.height ?? theme.layout.symbolRow) }
        return height
    }

    private func applyDots(_ colors: [UIColor], style: LMKMonthCalendarView.Style, theme: LMKTheme, inverted: UIColor?) {
        let size = style.dotSize ?? Self.defaultDotSize
        let shown = Array(colors.prefix(max(0, style.maxDots ?? Self.defaultMaxDots)))
        dotsStack.spacing = style.dotSpacing ?? Self.defaultDotSpacing
        while dotViews.count < shown.count {
            let dot = UIView()
            dot.isUserInteractionEnabled = false
            dotViews.append(dot)
            dotsStack.addArrangedSubview(dot)
        }
        for (index, dot) in dotViews.enumerated() {
            let visible = index < shown.count
            dot.isHidden = !visible
            guard visible else { continue }
            dot.backgroundColor = inverted ?? shown[index]
            dot.lmk_applyCornerStyle(.fixed(size / 2))
            dot.snp.remakeConstraints { make in
                make.width.height.equalTo(size).priority(999)
            }
        }
        dotsStack.isHidden = shown.isEmpty
        decorationStack.spacing = theme.spacing.xxs
        decorationStack.snp.updateConstraints { make in
            make.top.equalTo(numeralStack.snp.bottom).offset(theme.spacing.xxs)
        }
    }

    private func applyBadges(_ badges: [LMKCalendarDayDecoration.Badge], style: LMKMonthCalendarView.Style, theme: LMKTheme, accent: UIColor) {
        badgesStack.spacing = theme.spacing.xxs
        while badgeViews.count < badges.count {
            let badge = LMKBadgeView()
            badge.isUserInteractionEnabled = false
            badgeViews.append(badge)
            badgesStack.addArrangedSubview(badge)
        }
        for (index, view) in badgeViews.enumerated() {
            let visible = index < badges.count
            view.isHidden = !visible
            guard visible else { continue }
            let badge = badges[index]
            let base = LMKBadgeView.Style(
                surface: LMKSurfaceStyle(background: .solid(badge.color ?? accent)),
                textColor: LMKColor.onAccent,
                textStyle: .extraExtraSmallSemibold,
                height: theme.layout.symbolRow
            )
            view.style = badge.color == nil ? base.merging(style.badge) : style.badge.merging(base)
            view.configure(.text(badge.text))
        }
        badgesStack.isHidden = badges.isEmpty
    }

    // MARK: - Actions

    /// The tap action (internal so tests can drive it without a window).
    @objc func handleTap() {
        guard isEnabled, let day = dayState?.day else { return }
        onTap?(day)
        sendActions(for: .primaryActionTriggered)
    }

    @objc private func handleTouchDown() {
        guard pressAnimates else { return }
        LMKAnimation.animateButtonPressDown(self)
    }

    @objc private func handleTouchUp() {
        guard pressAnimates else { return }
        LMKAnimation.animateButtonPressUp(self)
    }
}

// MARK: - UIPointerInteractionDelegate

extension LMKCalendarDayCell: UIPointerInteractionDelegate {
    public func pointerInteraction(_: UIPointerInteraction, styleFor _: UIPointerRegion) -> UIPointerStyle? {
        guard isEnabled else { return nil }
        return LMKPointerStyle.lift(for: self)
    }
}
