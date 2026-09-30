//
//  LMKDividerView.swift
//  LumiKit
//
//  Hairline separator, horizontal or vertical, drawn one physical pixel thick
//  on the display it is on.
//

import UIKit

/// Separator line.
///
/// ```swift
/// let divider = LMKDividerView()
/// stack.addArrangedSubview(divider)   // sizes itself to the resolved thickness
/// let dashed = LMKDividerView(style: LMKDividerView.Style(dash: [4, 2]))
/// ```
public final class LMKDividerView: UIView, LMKThemeApplying {
    // MARK: - Orientation

    public nonisolated enum Orientation: Sendable, Hashable, CaseIterable {
        case horizontal
        case vertical
    }

    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// `nil` = `divider`.
        public var color: UIColor?
        /// `nil` = one physical pixel on the view's display.
        public var thickness: CGFloat?
        /// Dash pattern in points; `nil` draws a solid line.
        public var dash: [CGFloat]?

        public init(color: UIColor? = nil, thickness: CGFloat? = nil, dash: [CGFloat]? = nil) {
            self.color = color
            self.thickness = thickness.map { max(0, $0) }
            self.dash = dash
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(color: other.color ?? color, thickness: other.thickness ?? thickness, dash: other.dash ?? dash)
        }
    }

    // MARK: - Properties

    /// Divider orientation.
    public var orientation: Orientation {
        didSet {
            guard orientation != oldValue else { return }
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    /// Per-instance style; `nil` fields resolve from `theme.divider`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// The thickness in effect (the style's, or one physical pixel).
    public var resolvedThickness: CGFloat {
        resolved.thickness ?? LMKLayout.hairline(for: self)
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKDividerView) -> Void)?

    private var resolved = Style()
    private let dashLayer = CAShapeLayer()

    // MARK: - Initialization

    public init(orientation: Orientation = .horizontal, style: Style = Style()) {
        self.orientation = orientation
        self.style = style
        super.init(frame: .zero)
        isAccessibilityElement = false
        accessibilityElementsHidden = true
        dashLayer.fillColor = nil
        dashLayer.isHidden = true
        layer.addSublayer(dashLayer)
        registerForTraitChanges([UITraitDisplayScale.self]) { (view: Self, _) in
            view.invalidateIntrinsicContentSize()
        }
        lmk_startApplyingTheme()
    }

    /// A divider with an explicit color and thickness.
    public convenience init(orientation: Orientation = .horizontal, color: UIColor?, thickness: CGFloat? = nil) {
        self.init(orientation: orientation, style: Style(color: color, thickness: thickness))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        resolved = theme.divider.merging(style)
        let color = resolved.color ?? LMKColor.divider
        if resolved.dash != nil {
            backgroundColor = .clear
            dashLayer.isHidden = false
            dashLayer.strokeColor = color.resolvedColor(with: traitCollection).cgColor
            setNeedsLayout()
        } else {
            backgroundColor = color
            dashLayer.isHidden = true
        }
        invalidateIntrinsicContentSize()
        didApplyStyle?(self)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        guard let dash = resolved.dash else { return }
        let thickness = resolvedThickness
        dashLayer.frame = bounds
        dashLayer.lineWidth = thickness
        dashLayer.lineDashPattern = dash.map { NSNumber(value: Double($0)) }
        dashLayer.strokeColor = (resolved.color ?? LMKColor.divider).resolvedColor(with: traitCollection).cgColor
        let path = UIBezierPath()
        switch orientation {
        case .horizontal:
            path.move(to: CGPoint(x: 0, y: bounds.midY))
            path.addLine(to: CGPoint(x: bounds.width, y: bounds.midY))
        case .vertical:
            path.move(to: CGPoint(x: bounds.midX, y: 0))
            path.addLine(to: CGPoint(x: bounds.midX, y: bounds.height))
        }
        dashLayer.path = path.cgPath
    }

    override public var intrinsicContentSize: CGSize {
        switch orientation {
        case .horizontal: CGSize(width: UIView.noIntrinsicMetric, height: resolvedThickness)
        case .vertical: CGSize(width: resolvedThickness, height: UIView.noIntrinsicMetric)
        }
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKDividerView`.
    var divider: LMKDividerView.Style {
        get { self[LMKDividerView.Style.self] }
        set { self[LMKDividerView.Style.self] = newValue }
    }
}
