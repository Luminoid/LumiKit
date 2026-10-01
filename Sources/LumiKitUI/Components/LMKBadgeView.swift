//
//  LMKBadgeView.swift
//  LumiKit
//
//  Count, text, or dot badge: a capsule whose metrics and colors come from
//  `theme.badge` and the instance style.
//

import LumiKitCore
import SnapKit
import UIKit

/// Small badge for notification counts, "New" labels, or status dots.
///
/// ```swift
/// let badge = LMKBadgeView()
/// badge.configure(.count(5))
/// badge.configure(.text("New"))
/// badge.configure(.dot)
/// ```
public final class LMKBadgeView: UIView, LMKThemeApplying {
    // MARK: - Content

    /// What the badge shows.
    public nonisolated enum Content: Sendable, Hashable {
        /// A number; `0` or less hides the badge, values past 99 show `overflowText`.
        case count(Int)
        /// Custom text; empty text hides the badge.
        case text(String)
        /// A small dot with no text.
        case dot
    }

    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// Background (default `error`), corners (capsule), border (`backgroundPrimary`, 1.5pt).
        public var surface: LMKSurfaceStyle
        /// `nil` = `onAccent`.
        public var textColor: UIColor?
        /// `nil` = `extraSmallSemibold`.
        public var textStyle: LMKTextStyle?
        /// `nil` = 18.
        public var minWidth: CGFloat?
        /// `nil` = 18.
        public var height: CGFloat?
        /// `nil` = 6.
        public var horizontalPadding: CGFloat?
        /// Dot diameter as a fraction of `height`; `nil` = 0.5.
        public var dotSizeRatio: CGFloat?
        /// Shown for counts above 99; `nil` = "99+".
        public var overflowText: String?

        public init(
            surface: LMKSurfaceStyle = LMKSurfaceStyle(),
            textColor: UIColor? = nil,
            textStyle: LMKTextStyle? = nil,
            minWidth: CGFloat? = nil,
            height: CGFloat? = nil,
            horizontalPadding: CGFloat? = nil,
            dotSizeRatio: CGFloat? = nil,
            overflowText: String? = nil
        ) {
            self.surface = surface
            self.textColor = textColor
            self.textStyle = textStyle
            self.minWidth = minWidth
            self.height = height
            self.horizontalPadding = horizontalPadding
            self.dotSizeRatio = dotSizeRatio
            self.overflowText = overflowText
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                surface: surface.merging(other.surface),
                textColor: other.textColor ?? textColor,
                textStyle: other.textStyle ?? textStyle,
                minWidth: other.minWidth ?? minWidth,
                height: other.height ?? height,
                horizontalPadding: other.horizontalPadding ?? horizontalPadding,
                dotSizeRatio: other.dotSizeRatio ?? dotSizeRatio,
                overflowText: other.overflowText ?? overflowText
            )
        }
    }

    // MARK: - Strings

    public nonisolated struct Strings: Sendable, Equatable {
        /// Accessibility label for a dot badge (no text).
        public var dotAccessibilityLabel: String

        public init(dotAccessibilityLabel: String = LMKLocalized("badge.dot.accessibilityLabel")) {
            self.dotAccessibilityLabel = dotAccessibilityLabel
        }
    }

    /// Process-wide defaults; set at app launch to override.
    public nonisolated(unsafe) static var strings = Strings()

    /// Per-instance strings (default `Self.strings`).
    public var strings: Strings = LMKBadgeView.strings {
        didSet { updateContent() }
    }

    // MARK: - Properties

    public let countLabel = UILabel()

    /// Per-instance style; `nil` fields resolve from `theme.badge`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// The current content (`nil` until configured).
    public private(set) var content: Content?

    /// Overrides the derived accessibility label (the count, the text, or the dot label).
    public var customAccessibilityLabel: String? {
        didSet { updateContent() }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKBadgeView) -> Void)?

    private var resolved = Style()

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

    // MARK: - Setup

    private func setupUI() {
        countLabel.textAlignment = .center
        addSubview(countLabel)
        countLabel.snp.makeConstraints { $0.center.equalToSuperview() }
        // A badge is as wide as its content: a stack or a row never stretches or squeezes it.
        for axis in [NSLayoutConstraint.Axis.horizontal, .vertical] {
            setContentHuggingPriority(.required, for: axis)
            setContentCompressionResistancePriority(.required, for: axis)
        }
        isAccessibilityElement = true
        accessibilityTraits = .staticText
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        lmk_layoutSurfaceIfNeeded()
    }

    // MARK: - Configuration

    /// Sets the content; a zero count or empty text hides the badge.
    public func configure(_ content: Content) {
        self.content = content
        updateContent()
    }

    private func updateContent() {
        switch content {
        case let .count(count)?:
            isHidden = count <= 0
            let formattedCount = LMKFormat.number(count)
            countLabel.lmk_setText(count > Self.overflowThreshold ? (resolved.overflowText ?? Self.defaultOverflowText) : formattedCount)
            accessibilityLabel = customAccessibilityLabel ?? formattedCount
        case let .text(text)?:
            isHidden = text.isEmpty
            countLabel.lmk_setText(text)
            accessibilityLabel = customAccessibilityLabel ?? text
        case .dot?:
            isHidden = false
            countLabel.lmk_setText(nil)
            accessibilityLabel = customAccessibilityLabel ?? strings.dotAccessibilityLabel
        case nil:
            isHidden = true
            countLabel.lmk_setText(nil)
            accessibilityLabel = customAccessibilityLabel
        }
        invalidateIntrinsicContentSize()
    }

    private static let overflowThreshold = 99
    private static let defaultOverflowText = "99+"
    private static let defaultMinWidth: CGFloat = 18
    private static let defaultHeight: CGFloat = 18
    private static let defaultHorizontalPadding: CGFloat = 6
    private static let defaultDotSizeRatio: CGFloat = 0.5
    private static let defaultBorderWidth: CGFloat = 1.5

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        resolved = theme.badge.merging(style)
        let defaults = LMKSurfaceStyle(
            background: .solid(LMKColor.error),
            corners: .capsule,
            border: .solid(LMKColor.backgroundPrimary, width: Self.defaultBorderWidth),
            shadow: LMKShadowSource.hidden
        )
        let applied = lmk_apply(surface: resolved.surface, defaults: defaults)
        let fill: UIColor = if case let .solid(color) = applied.background, let color { color } else { LMKColor.error }
        countLabel.lmk_apply(resolved.textStyle ?? .extraSmallSemibold, color: resolved.textColor ?? LMKColor.onFill(fill, preferred: LMKColor.onAccent))
        updateContent()
        didApplyStyle?(self)
    }

    override public var intrinsicContentSize: CGSize {
        let height = resolved.height ?? Self.defaultHeight
        if let text = countLabel.text, !text.isEmpty {
            let textSize = countLabel.intrinsicContentSize
            let width = max(resolved.minWidth ?? Self.defaultMinWidth, textSize.width + (resolved.horizontalPadding ?? Self.defaultHorizontalPadding) * 2)
            return CGSize(width: width, height: height)
        }
        let dotSize = height * (resolved.dotSizeRatio ?? Self.defaultDotSizeRatio)
        return CGSize(width: dotSize, height: dotSize)
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKBadgeView` (also the badge metrics other components reuse).
    var badge: LMKBadgeView.Style {
        get { self[LMKBadgeView.Style.self] }
        set { self[LMKBadgeView.Style.self] = newValue }
    }
}
