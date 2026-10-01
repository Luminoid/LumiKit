//
//  LMKActionSheetRowView.swift
//  LumiKit
//
//  One row of an action sheet or enum picker: icon, title, subtitle, and a
//  chevron or checkmark accessory, styled from `theme.actionSheet.row`.
//

import SnapKit
import UIKit

/// A tappable row with an optional icon, subtitle, and a chevron (sub-page) or
/// checkmark (selected) accessory. Shared by `LMKActionSheet` and `LMKEnumPicker`.
public final class LMKActionSheetRowView: UIControl, LMKThemeApplying {
    // MARK: - Content

    /// What a row shows.
    public struct Content {
        public var title: String
        public var subtitle: String?
        public var icon: UIImage?
        public var isDestructive: Bool
        public var isSelected: Bool
        public var isEnabled: Bool
        /// Shows a chevron (and the sub-page hint) instead of a checkmark.
        public var opensPage: Bool

        public init(
            title: String,
            subtitle: String? = nil,
            icon: UIImage? = nil,
            isDestructive: Bool = false,
            isSelected: Bool = false,
            isEnabled: Bool = true,
            opensPage: Bool = false
        ) {
            self.title = title
            self.subtitle = subtitle
            self.icon = icon
            self.isDestructive = isDestructive
            self.isSelected = isSelected
            self.isEnabled = isEnabled
            self.opensPage = opensPage
        }

        public init(_ action: LMKActionSheet.Action) {
            self.init(
                title: action.title,
                subtitle: action.subtitle,
                icon: action.icon,
                isDestructive: action.style == .destructive,
                isSelected: action.isSelected && action.page == nil,
                isEnabled: action.isEnabled,
                opensPage: action.page != nil
            )
        }
    }

    // MARK: - Subviews

    public let containerView: UIView = LMKSurfaceView()
    public let contentStack = UIStackView()
    public let textStack = UIStackView()
    public let iconView = UIImageView()
    public let titleLabel = UILabel()
    public let subtitleLabel = UILabel()
    public let chevronView = UIImageView()
    public let checkmarkView = UIImageView()

    // MARK: - State

    public private(set) var content: Content?

    /// Per-instance style; `nil` fields resolve from `theme.actionSheet.row`, then the built-in look.
    public var style: LMKActionSheet.RowStyle {
        didSet {
            guard style != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    public var onTap: (() -> Void)?

    /// Per-instance strings for the sub-page hint (default `LMKActionSheet.strings`).
    public var strings: LMKActionSheet.Strings = LMKActionSheet.strings {
        didSet { updateAccessibility() }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKActionSheetRowView) -> Void)?

    override public var isHighlighted: Bool {
        didSet {
            guard isHighlighted != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    override public var isEnabled: Bool {
        didSet {
            guard isEnabled != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
            updateAccessibility()
        }
    }

    private var resolved = LMKActionSheet.RowStyle()
    private var iconSizeConstraint: Constraint?
    private var accessorySizeConstraints: [Constraint] = []
    private var minimumHeightConstraint: Constraint?
    private var contentInsetsConstraint: Constraint?

    static let defaultMinimumHeight: CGFloat = 48

    // MARK: - Initialization

    public init(style: LMKActionSheet.RowStyle = LMKActionSheet.RowStyle()) {
        self.style = style
        super.init(frame: .zero)
        setupUI()
        lmk_startApplyingTheme()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        containerView.isUserInteractionEnabled = false
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            minimumHeightConstraint = make.height.greaterThanOrEqualTo(Self.defaultMinimumHeight).constraint
        }

        iconView.contentMode = .scaleAspectFit
        iconView.isHidden = true
        iconView.snp.makeConstraints { make in
            iconSizeConstraint = make.width.height.equalTo(0).constraint
        }
        chevronView.image = UIImage(systemName: "chevron.forward")
        chevronView.contentMode = .scaleAspectFit
        chevronView.isHidden = true
        checkmarkView.image = UIImage(systemName: "checkmark")
        checkmarkView.contentMode = .scaleAspectFit
        checkmarkView.isHidden = true
        for accessory in [chevronView, checkmarkView] {
            accessory.snp.makeConstraints { make in
                accessorySizeConstraints.append(make.width.height.equalTo(0).constraint)
            }
        }

        subtitleLabel.numberOfLines = 2
        subtitleLabel.isHidden = true
        textStack.axis = .vertical
        textStack.spacing = 0
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)

        contentStack.axis = .horizontal
        contentStack.alignment = .center
        contentStack.addArrangedSubview(iconView)
        contentStack.addArrangedSubview(textStack)
        contentStack.addArrangedSubview(chevronView)
        contentStack.addArrangedSubview(checkmarkView)
        containerView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            contentInsetsConstraint = make.edges.equalToSuperview().inset(0).constraint
        }
        textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)

        addTarget(self, action: #selector(didTap), for: .touchUpInside)
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    // MARK: - Configuration

    /// Sets the row's content.
    public func configure(_ content: Content) {
        self.content = content
        titleLabel.lmk_setText(content.title)
        subtitleLabel.lmk_setText(content.subtitle)
        subtitleLabel.isHidden = content.subtitle == nil
        iconView.image = content.icon
        iconView.isHidden = content.icon == nil
        chevronView.isHidden = !content.opensPage
        checkmarkView.isHidden = content.opensPage || !content.isSelected
        isEnabled = content.isEnabled
        applyTheme(traitCollection.lmkTheme)
        updateAccessibility()
    }

    /// Sets the row's content from an action.
    public func configure(_ action: LMKActionSheet.Action) {
        configure(Content(action))
    }

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        resolved = theme.actionSheet.row.merging(style)
        let isDestructive = content?.isDestructive ?? false
        let accent = isDestructive ? (resolved.destructiveColor ?? LMKColor.error) : (resolved.iconTint ?? LMKColor.primary)
        let highlight = resolved.highlightColor ?? LMKColor.primary.withAlphaComponent(theme.alpha.xs)

        var surface = resolved.surface
        if isHighlighted {
            surface.background = .solid(highlight)
        }
        let applied = containerView.lmk_apply(
            surface: surface,
            defaults: LMKSurfaceStyle(
                background: .solid(LMKColor.backgroundSecondary),
                corners: .fixed(theme.cornerRadius.small),
                shadow: LMKShadowSource.hidden,
                contentInsets: .lmk_symmetric(vertical: theme.spacing.small, horizontal: theme.spacing.large)
            )
        )
        let insets = applied.contentInsets ?? .lmk_symmetric(vertical: theme.spacing.small, horizontal: theme.spacing.large)
        contentInsetsConstraint?.update(inset: UIEdgeInsets(top: insets.top, left: insets.leading, bottom: insets.bottom, right: insets.trailing))
        minimumHeightConstraint?.update(offset: resolved.minimumHeight ?? Self.defaultMinimumHeight)

        titleLabel.lmk_apply(resolved.titleTextStyle ?? .body, color: isDestructive ? accent : (resolved.titleColor ?? LMKColor.textPrimary))
        subtitleLabel.lmk_apply(resolved.subtitleTextStyle ?? .caption, color: resolved.subtitleColor ?? LMKColor.textSecondary)
        iconView.tintColor = accent
        chevronView.tintColor = LMKColor.textSecondary
        checkmarkView.tintColor = resolved.checkmarkColor ?? LMKColor.primary
        iconSizeConstraint?.update(offset: resolved.iconSize ?? theme.layout.iconMedium)
        accessorySizeConstraints.forEach { $0.update(offset: theme.layout.iconSmall) }
        contentStack.spacing = resolved.spacing ?? theme.spacing.medium
        alpha = isEnabled ? 1 : (resolved.disabled?.alpha ?? theme.alpha.disabled)
        didApplyStyle?(self)
    }

    // MARK: - Interaction

    /// A disabled row swallows its touches like a system control; an enabled one answers the
    /// minimum touch target.
    override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard !isHidden else { return false }
        guard isEnabled else { return bounds.contains(point) }
        return lmk_hitTestBounds(minimumSide: traitCollection.lmkTheme.layout.minimumTouchTarget, insets: lmk_hitTestInsets).contains(point)
    }

    // MARK: - Accessibility

    private func updateAccessibility() {
        guard let content else { return }
        accessibilityLabel = [content.title, content.subtitle].compactMap(\.self).joined(separator: ", ")
        var traits: UIAccessibilityTraits = .button
        if content.isSelected, !content.opensPage { traits.insert(.selected) }
        if !isEnabled { traits.insert(.notEnabled) }
        accessibilityTraits = traits
        accessibilityHint = content.opensPage ? strings.submenuAccessibilityHint : nil
    }

    // MARK: - Actions

    /// Runs the tap handler as a user tap would (ignored while disabled).
    @objc func didTap() {
        guard isEnabled else { return }
        onTap?()
    }
}
