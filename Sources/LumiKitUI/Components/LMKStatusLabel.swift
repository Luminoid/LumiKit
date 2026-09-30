//
//  LMKStatusLabel.swift
//  LumiKit
//
//  Inline live readout: an optional status glyph and a short message, colored
//  by `LMKStatus`. For "Saved", "3 items selected", "Connection lost" lines
//  that sit inside a form rather than float over it.
//

import SnapKit
import UIKit

/// Inline status readout.
///
/// ```swift
/// statusLabel.show("Saved", status: .success)
/// statusLabel.clear()
/// ```
public final class LMKStatusLabel: UIView, LMKThemeApplying {
    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// `nil` = `caption`.
        public var textStyle: LMKTextStyle?
        /// `nil` = `symbolInline`.
        public var iconSize: CGFloat?
        /// Show the status glyph; `nil` = shown when the status has one.
        public var showsIcon: Bool?
        /// Gap between glyph and text; `nil` = `xs`.
        public var spacing: CGFloat?
        /// Per-status text and glyph colors; a missing status uses `LMKStatus.color`.
        public var colors: [LMKStatus: UIColor]?

        public init(textStyle: LMKTextStyle? = nil, iconSize: CGFloat? = nil, showsIcon: Bool? = nil, spacing: CGFloat? = nil, colors: [LMKStatus: UIColor]? = nil) {
            self.textStyle = textStyle
            self.iconSize = iconSize
            self.showsIcon = showsIcon
            self.spacing = spacing
            self.colors = colors
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                textStyle: other.textStyle ?? textStyle,
                iconSize: other.iconSize ?? iconSize,
                showsIcon: other.showsIcon ?? showsIcon,
                spacing: other.spacing ?? spacing,
                colors: other.colors.map { (colors ?? [:]).merging($0) { $1 } } ?? colors
            )
        }
    }

    // MARK: - Subviews

    public let iconView = UIImageView()
    public let textLabel = UILabel()
    private let row = UIStackView()

    // MARK: - State

    public private(set) var status: LMKStatus = .neutral
    public private(set) var message: String?

    /// Per-instance style; `nil` fields resolve from `theme.statusLabel`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Whether `show` posts a VoiceOver announcement (default `false`; the label is readable in place).
    public var announces = false

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKStatusLabel) -> Void)?

    private var iconSizeConstraint: Constraint?

    // MARK: - Initialization

    public init(style: Style = Style()) {
        self.style = style
        super.init(frame: .zero)
        setupUI()
        lmk_startApplyingTheme()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        iconView.contentMode = .scaleAspectFit
        iconView.snp.makeConstraints { make in
            iconSizeConstraint = make.width.height.equalTo(0).constraint
        }
        textLabel.numberOfLines = 0
        row.axis = .horizontal
        row.alignment = .center
        row.addArrangedSubview(iconView)
        row.addArrangedSubview(textLabel)
        addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview() }
        isAccessibilityElement = true
        accessibilityTraits = .staticText
        isHidden = true
    }

    // MARK: - Content

    /// Shows `message` colored for `status`; the view unhides itself.
    public func show(_ message: String, status: LMKStatus = .neutral) {
        self.message = message
        self.status = status
        isHidden = false
        accessibilityLabel = message
        applyTheme(traitCollection.lmkTheme)
        if announces {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }

    /// Clears the message and hides the view.
    public func clear() {
        message = nil
        status = .neutral
        isHidden = true
        accessibilityLabel = nil
        textLabel.lmk_setText(nil)
    }

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        let resolved = theme.statusLabel.merging(style)
        let color = resolved.colors?[status] ?? status.color
        iconView.image = status.systemImageName.flatMap { UIImage(systemName: $0) }
        iconView.isHidden = !(resolved.showsIcon ?? (iconView.image != nil))
        iconView.tintColor = color
        iconSizeConstraint?.update(offset: resolved.iconSize ?? theme.layout.symbolInline)
        row.spacing = resolved.spacing ?? theme.spacing.xs
        textLabel.lmk_apply(resolved.textStyle ?? .caption, color: color)
        textLabel.lmk_setText(message)
        didApplyStyle?(self)
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKStatusLabel`.
    var statusLabel: LMKStatusLabel.Style {
        get { self[LMKStatusLabel.Style.self] }
        set { self[LMKStatusLabel.Style.self] = newValue }
    }
}
