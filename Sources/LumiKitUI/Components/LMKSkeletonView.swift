//
//  LMKSkeletonView.swift
//  LumiKit
//
//  Loading placeholder: rows of shapes (lines, circles, rects) under a
//  shimmer that sweeps across them. `LMKSkeletonCell` hosts one per row.
//

import SnapKit
import UIKit

/// Skeleton placeholder with a shimmer.
///
/// ```swift
/// let skeleton = LMKSkeletonView(shapes: [.circle(diameter: 40), .line(), .line(width: 160)])
/// skeleton.startShimmer()
/// ```
public final class LMKSkeletonView: UIView, LMKThemeApplying {
    // MARK: - Shape

    /// One placeholder row.
    public nonisolated enum Shape: Sendable, Equatable {
        /// A text line; `nil` width fills the view, `nil` height uses the style's line height.
        case line(width: CGFloat? = nil, height: CGFloat? = nil)
        /// An avatar or icon placeholder.
        case circle(diameter: CGFloat)
        /// A block (image, card).
        case rect(width: CGFloat? = nil, height: CGFloat)
    }

    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// `nil` = `backgroundTertiary`.
        public var shapeColor: UIColor?
        /// `nil` = `backgroundSecondary`.
        public var shimmerColor: UIColor?
        /// One sweep; `nil` = the theme's shimmer duration.
        public var shimmerDuration: TimeInterval?
        /// Corners of lines and rects; `nil` = `fixed(xs)`.
        public var corners: LMKCornerStyle?
        /// Line height; `nil` = 12.
        public var lineHeight: CGFloat?
        /// Gap between rows; `nil` = `small`.
        public var spacing: CGFloat?
        /// Delay added per stagger index; `nil` = 0.1s.
        public var staggerDelay: TimeInterval?

        public init(
            shapeColor: UIColor? = nil,
            shimmerColor: UIColor? = nil,
            shimmerDuration: TimeInterval? = nil,
            corners: LMKCornerStyle? = nil,
            lineHeight: CGFloat? = nil,
            spacing: CGFloat? = nil,
            staggerDelay: TimeInterval? = nil
        ) {
            self.shapeColor = shapeColor
            self.shimmerColor = shimmerColor
            self.shimmerDuration = shimmerDuration
            self.corners = corners
            self.lineHeight = lineHeight
            self.spacing = spacing
            self.staggerDelay = staggerDelay
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                shapeColor: other.shapeColor ?? shapeColor,
                shimmerColor: other.shimmerColor ?? shimmerColor,
                shimmerDuration: other.shimmerDuration ?? shimmerDuration,
                corners: other.corners ?? corners,
                lineHeight: other.lineHeight ?? lineHeight,
                spacing: other.spacing ?? spacing,
                staggerDelay: other.staggerDelay ?? staggerDelay
            )
        }
    }

    // MARK: - Strings

    public nonisolated struct Strings: Sendable, Equatable {
        /// VoiceOver label of a loading placeholder.
        public var loadingAccessibilityLabel: String

        public init(loadingAccessibilityLabel: String = LMKLocalized("skeletonCell.loading.accessibilityLabel")) {
            self.loadingAccessibilityLabel = loadingAccessibilityLabel
        }
    }

    /// Process-wide defaults; set at app launch to override.
    public nonisolated(unsafe) static var strings = Strings()

    /// Per-instance strings (default `Self.strings`).
    public var strings: Strings = LMKSkeletonView.strings {
        didSet { accessibilityLabel = strings.loadingAccessibilityLabel }
    }

    // MARK: - Properties

    /// Three text lines, the last two shorter.
    public static let defaultShapes: [Shape] = [.line(), .line(width: 200), .line(width: 120)]

    /// The rows, top to bottom.
    public var shapes: [Shape] {
        didSet {
            guard shapes != oldValue else { return }
            rebuildShapes()
        }
    }

    /// Per-instance style; `nil` fields resolve from `theme.skeleton`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Whether the shimmer is running.
    public private(set) var isShimmering = false

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKSkeletonView) -> Void)?

    private let stack = UIStackView()
    private var shapeViews: [UIView] = []
    private let shimmerLayer = CAGradientLayer()
    private let shimmerMask = CAShapeLayer()
    private var resolved = Style()
    private var staggerIndex = 0

    private static let defaultLineHeight: CGFloat = 12
    private static let defaultStaggerDelay: TimeInterval = 0.1
    private static let shimmerKey = "shimmer"

    // MARK: - Initialization

    public init(shapes: [Shape] = LMKSkeletonView.defaultShapes, style: Style = Style()) {
        self.shapes = shapes
        self.style = style
        super.init(frame: .zero)
        setupUI()
        rebuildShapes()
        lmk_startApplyingTheme()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        isAccessibilityElement = true
        accessibilityTraits = .updatesFrequently
        accessibilityLabel = strings.loadingAccessibilityLabel

        stack.axis = .vertical
        stack.alignment = .leading
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
            make.bottom.equalToSuperview().priority(.high)
        }

        shimmerLayer.locations = [0, 0.5, 1]
        shimmerLayer.startPoint = CGPoint(x: 0, y: 0.5)
        shimmerLayer.endPoint = CGPoint(x: 1, y: 0.5)
        shimmerLayer.mask = shimmerMask
        shimmerLayer.isHidden = true
        layer.addSublayer(shimmerLayer)
    }

    private func rebuildShapes() {
        shapeViews.forEach { $0.removeFromSuperview() }
        shapeViews.removeAll()
        for _ in shapes {
            let view = UIView()
            view.isUserInteractionEnabled = false
            stack.addArrangedSubview(view)
            shapeViews.append(view)
        }
        applyTheme(traitCollection.lmkTheme)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        shimmerLayer.frame = bounds
        let path = UIBezierPath()
        for (shape, view) in zip(shapes, shapeViews) {
            let frame = view.convert(view.bounds, to: self)
            let radius: CGFloat = switch shape {
            case .circle: frame.height / 2
            case .line, .rect: view.layer.cornerRadius
            }
            path.append(UIBezierPath(roundedRect: frame, cornerRadius: radius))
        }
        shimmerMask.frame = bounds
        shimmerMask.path = path.cgPath
    }

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        resolved = theme.skeleton.merging(style)
        let shapeColor = resolved.shapeColor ?? LMKColor.backgroundTertiary
        let shimmerColor = resolved.shimmerColor ?? LMKColor.backgroundSecondary
        let corners = resolved.corners ?? .fixed(theme.cornerRadius.xs)
        let lineHeight = resolved.lineHeight ?? Self.defaultLineHeight
        stack.spacing = resolved.spacing ?? theme.spacing.small
        for (shape, view) in zip(shapes, shapeViews) {
            view.backgroundColor = shapeColor
            view.snp.remakeConstraints { make in
                switch shape {
                case let .line(width, height):
                    make.height.equalTo(height ?? lineHeight)
                    if let width { make.width.equalTo(width) } else { make.width.equalToSuperview() }
                case let .circle(diameter):
                    make.width.height.equalTo(diameter)
                case let .rect(width, height):
                    make.height.equalTo(height)
                    if let width { make.width.equalTo(width) } else { make.width.equalToSuperview() }
                }
            }
            switch shape {
            case .circle: view.lmk_applyCornerStyle(.circle)
            case .line, .rect: view.lmk_applyCornerStyle(corners)
            }
        }
        let resolvedShape = shapeColor.resolvedColor(with: traitCollection).cgColor
        shimmerLayer.colors = [resolvedShape, shimmerColor.resolvedColor(with: traitCollection).cgColor, resolvedShape]
        setNeedsLayout()
        didApplyStyle?(self)
    }

    // MARK: - Shimmer

    /// Starts the sweep; `staggerIndex` delays it by `staggerDelay` per index (rows of a list).
    public func startShimmer(staggerIndex: Int = 0) {
        self.staggerIndex = staggerIndex
        isShimmering = true
        shimmerLayer.isHidden = false
        guard LMKAnimation.shouldAnimate else { return }
        let animation = CAKeyframeAnimation(keyPath: "locations")
        animation.values = [
            [-1.0, -0.5, 0.0] as [NSNumber],
            [0.0, 0.5, 1.0] as [NSNumber],
            [1.0, 1.5, 2.0] as [NSNumber],
        ]
        animation.duration = resolved.shimmerDuration ?? traitCollection.lmkTheme.animation.shimmer
        animation.repeatCount = .infinity
        animation.timingFunction = LMKAnimation.Curve.easeInOut.timingFunction
        animation.beginTime = CACurrentMediaTime() + Double(staggerIndex) * (resolved.staggerDelay ?? Self.defaultStaggerDelay)
        shimmerLayer.add(animation, forKey: Self.shimmerKey)
    }

    /// Stops the sweep.
    public func stopShimmer() {
        isShimmering = false
        shimmerLayer.removeAnimation(forKey: Self.shimmerKey)
        shimmerLayer.isHidden = true
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKSkeletonView`.
    var skeleton: LMKSkeletonView.Style {
        get { self[LMKSkeletonView.Style.self] }
        set { self[LMKSkeletonView.Style.self] = newValue }
    }
}
