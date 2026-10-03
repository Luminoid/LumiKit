//
//  LMKEmptyStateView.swift
//  LumiKit
//
//  Empty state: icon, title, message, and up to two actions, laid out as a
//  centered column (full screen, card) or a row (inline).
//

import SnapKit
import UIKit

/// Empty state view for screens, cards, and inline rows without content.
///
/// ```swift
/// emptyState.configure(LMKEmptyStateView.Content(
///     title: "No plants yet",
///     message: "Add your first plant to start tracking waterings.",
///     icon: .system("leaf"),
///     primaryAction: .init(title: "Add plant", icon: "plus") { addPlant() }
/// ))
/// ```
///
/// **Sizing contract**: the content forms one centered column whose height is
/// content-driven, so it grows with multi-line messages and larger Dynamic Type
/// sizes. With no host-imposed height the view sizes itself to that content and
/// can sit in a stack view; a host-imposed height wins and centers the content.
public final class LMKEmptyStateView: UIView, LMKThemeApplying {
    // MARK: - Layout

    public nonisolated enum Layout: Sendable, Hashable, CaseIterable {
        /// Large icon, centered column.
        case fullScreen
        /// Compact column for a card or section.
        case card
        /// One row: small icon, message, and the primary action as a trailing button.
        case inline

        public var isHorizontal: Bool { self == .inline }
    }

    // MARK: - Content

    /// The icon above (or beside) the message.
    public enum Icon: Equatable {
        case system(String)
        case image(UIImage)

        var image: UIImage? {
            switch self {
            case let .system(name): UIImage(systemName: name)
            case let .image(image): image
            }
        }
    }

    /// A call to action.
    public struct Action {
        public var title: String
        /// Optional leading SF Symbol name.
        public var icon: String?
        /// Visual style; `nil` = the empty state's `primaryButton` / `secondaryButton` style.
        public var style: LMKButton.Style?
        public var handler: () -> Void

        public init(title: String, icon: String? = nil, style: LMKButton.Style? = nil, handler: @escaping () -> Void) {
            self.title = title
            self.icon = icon
            self.style = style
            self.handler = handler
        }
    }

    /// What the empty state shows.
    public struct Content {
        public var title: String?
        public var message: String
        public var icon: Icon?
        public var primaryAction: Action?
        public var secondaryAction: Action?

        public init(title: String? = nil, message: String, icon: Icon? = nil, primaryAction: Action? = nil, secondaryAction: Action? = nil) {
            self.title = title
            self.message = message
            self.icon = icon
            self.primaryAction = primaryAction
            self.secondaryAction = secondaryAction
        }
    }

    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// `nil` = `.fullScreen`.
        public var layout: Layout?
        /// Background, corners, insets around the content; the default is transparent with no insets
        /// (`.card` layout adds `large` insets).
        public var surface: LMKSurfaceStyle
        /// `nil` = 80 / 40 / 20 by layout.
        public var iconSize: CGFloat?
        /// `nil` = `textTertiary`.
        public var iconTint: UIColor?
        /// `nil` = `h3` / `body` / `caption` by layout.
        public var titleTextStyle: LMKTextStyle?
        /// `nil` = `body` / `caption` / `caption` by layout.
        public var messageTextStyle: LMKTextStyle?
        /// `nil` = `textPrimary`.
        public var titleColor: UIColor?
        /// `nil` = `textPrimary` (`textSecondary` when a title is present).
        public var messageColor: UIColor?
        /// Gap between icon, title, and message; `nil` = `small`.
        public var spacing: CGFloat?
        /// Gap above the actions; `nil` = `large`.
        public var actionSpacing: CGFloat?
        /// `nil` = filled primary.
        public var primaryButton: LMKButton.Style?
        /// `nil` = ghost primary.
        public var secondaryButton: LMKButton.Style?

        public init(
            layout: Layout? = nil,
            surface: LMKSurfaceStyle = LMKSurfaceStyle(),
            iconSize: CGFloat? = nil,
            iconTint: UIColor? = nil,
            titleTextStyle: LMKTextStyle? = nil,
            messageTextStyle: LMKTextStyle? = nil,
            titleColor: UIColor? = nil,
            messageColor: UIColor? = nil,
            spacing: CGFloat? = nil,
            actionSpacing: CGFloat? = nil,
            primaryButton: LMKButton.Style? = nil,
            secondaryButton: LMKButton.Style? = nil
        ) {
            self.layout = layout
            self.surface = surface
            self.iconSize = iconSize
            self.iconTint = iconTint
            self.titleTextStyle = titleTextStyle
            self.messageTextStyle = messageTextStyle
            self.titleColor = titleColor
            self.messageColor = messageColor
            self.spacing = spacing
            self.actionSpacing = actionSpacing
            self.primaryButton = primaryButton
            self.secondaryButton = secondaryButton
        }

        public static let defaultValue = Self()
        public static let fullScreen = Self(layout: .fullScreen)
        public static let card = Self(layout: .card)
        public static let inline = Self(layout: .inline)

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                layout: other.layout ?? layout,
                surface: surface.merging(other.surface),
                iconSize: other.iconSize ?? iconSize,
                iconTint: other.iconTint ?? iconTint,
                titleTextStyle: other.titleTextStyle ?? titleTextStyle,
                messageTextStyle: other.messageTextStyle ?? messageTextStyle,
                titleColor: other.titleColor ?? titleColor,
                messageColor: other.messageColor ?? messageColor,
                spacing: other.spacing ?? spacing,
                actionSpacing: other.actionSpacing ?? actionSpacing,
                primaryButton: other.primaryButton.map { primaryButton?.merging($0) ?? $0 } ?? primaryButton,
                secondaryButton: other.secondaryButton.map { secondaryButton?.merging($0) ?? $0 } ?? secondaryButton
            )
        }
    }

    // MARK: - Subviews

    public let iconView = UIImageView()
    public let titleLabel = UILabel()
    public let messageLabel = UILabel()
    /// The primary action's button (`nil` without a primary action). The same instance stays
    /// across theme and style changes, so `isLoading` or `isEnabled` set by the host hold.
    public private(set) var actionButton: LMKButton?
    /// The secondary action's button (`nil` without a secondary action; hidden inline).
    public private(set) var secondaryActionButton: LMKButton?
    private let containerStack = UIStackView()
    private let textStack = UIStackView()
    private let actionStack = UIStackView()

    // MARK: - State

    /// Per-instance style; `nil` fields resolve from `theme.emptyState`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// The current content (`nil` until configured).
    public private(set) var content: Content?

    /// The layout in effect.
    public var layout: Layout { resolved.layout ?? .fullScreen }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKEmptyStateView) -> Void)?

    private var resolved = Style()
    private var iconSizeConstraint: Constraint?
    private var containerInsetsConstraint: Constraint?
    /// The sides of the content: 999 in the stacked layouts, so the text takes its width from the
    /// view and wraps to it; 249 inline, where the row hugs its content.
    private var containerSidesConstraint: Constraint?
    /// The text column fills the stacked content's width (inactive inline).
    private var textFillConstraint: Constraint?
    /// The 999 guards that keep the content inside the view; they carry the same insets.
    private var containerLeadingTopGuard: Constraint?
    private var containerTrailingBottomGuard: Constraint?

    private static let iconAnimationScale: CGFloat = 0.95
    private static let iconAnimationDelay: TimeInterval = 0.05
    private static let labelAnimationDelay: TimeInterval = 0.1
    private static let buttonAnimationDelay: TimeInterval = 0.15

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
        backgroundColor = .clear
        isAccessibilityElement = true
        accessibilityTraits = .staticText

        addSubview(containerStack)
        containerStack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            // Vertical sizing contract: the guards keep the content inside the view whenever the host
            // height allows it (999, not required, so a too-short host height overflows silently
            // instead of breaking constraints); the hugging gives the view its content height when
            // the host imposes none. The hugging stays below UILabel's default vertical hugging (250),
            // so a taller host height centers the content instead of stretching the message.
            containerInsetsConstraint = make.top.bottom.equalToSuperview().priority(249).constraint
            // Horizontally a wrapping message must get its width from the view, never from its own
            // text: hugging it let an early zero-width pass leave the message one word per line.
            containerSidesConstraint = make.leading.trailing.equalToSuperview().priority(999).constraint
            containerLeadingTopGuard = make.top.leading.greaterThanOrEqualToSuperview().priority(999).constraint
            containerTrailingBottomGuard = make.bottom.trailing.lessThanOrEqualToSuperview().priority(999).constraint
        }

        iconView.contentMode = .scaleAspectFit
        iconView.isHidden = true
        iconView.snp.makeConstraints { make in
            iconSizeConstraint = make.width.height.equalTo(0).constraint
        }

        titleLabel.numberOfLines = 0
        titleLabel.isHidden = true
        messageLabel.numberOfLines = 0
        messageLabel.lineBreakMode = .byWordWrapping
        textStack.axis = .vertical
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(messageLabel)

        actionStack.axis = .horizontal
        actionStack.alignment = .center
        actionStack.isHidden = true
        // A `.center`-aligned stack has no height of its own beyond its buttons' `>=` bounds, so in a
        // host taller than the content it absorbed the spare height and the buttons drifted to its
        // middle, far below the message. Hugging it at 250 (above the 249 container pins) sends the
        // spare height around the content instead.
        actionStack.snp.makeConstraints { make in
            make.height.equalTo(0).priority(250)
        }

        containerStack.addArrangedSubview(iconView)
        containerStack.addArrangedSubview(textStack)
        containerStack.addArrangedSubview(actionStack)
        textStack.snp.makeConstraints { make in
            textFillConstraint = make.width.equalTo(containerStack).priority(999).constraint
        }
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        lmk_layoutSurfaceIfNeeded()
    }

    // MARK: - Configuration

    /// Sets the content and rebuilds the action buttons.
    ///
    /// - Parameters:
    ///   - content: The icon, title, message, and actions to show.
    ///   - animated: Whether the icon, text, and actions fade in (default `true`);
    ///     pass `false` for a reload that is still empty, so nothing flashes.
    public func configure(_ content: Content, animated: Bool = true) {
        self.content = content
        rebuildActions()
        applyTheme(traitCollection.lmkTheme)
        if animated {
            animateEntrance()
        }
    }

    /// Adds, replaces, or removes the primary action after `configure`.
    public func setAction(_ action: Action?) {
        content?.primaryAction = action
        rebuildActions()
        applyTheme(traitCollection.lmkTheme)
        if LMKAnimation.shouldAnimate, let actionButton {
            actionButton.alpha = 0
            UIView.animate(withDuration: LMKAnimation.Duration.normal, delay: Self.buttonAnimationDelay, options: LMKAnimation.Curve.easeOut.options) {
                actionButton.alpha = 1
            }
        }
    }

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        resolved = theme.emptyState.merging(style)
        let layout = layout
        let defaults = LMKSurfaceStyle(
            background: .clear,
            corners: LMKCornerStyle.square,
            shadow: LMKShadowSource.hidden,
            contentInsets: layout == .card ? .lmk_all(theme.spacing.large) : .lmk_all(0)
        )
        let applied = lmk_apply(surface: resolved.surface, defaults: defaults)
        let insets = applied.contentInsets ?? .lmk_all(0)
        containerInsetsConstraint?.update(inset: insets)
        containerSidesConstraint?.update(inset: insets)
        containerSidesConstraint?.update(priority: layout.isHorizontal ? 249 : 999)
        if layout.isHorizontal {
            textFillConstraint?.deactivate()
        } else {
            textFillConstraint?.activate()
        }
        // The guards hold the insets when the message wraps and the low-priority edges give.
        containerLeadingTopGuard?.update(inset: insets)
        containerTrailingBottomGuard?.update(inset: insets)

        // Content
        iconView.image = content?.icon?.image
        iconView.isHidden = iconView.image == nil
        iconView.tintColor = resolved.iconTint ?? LMKColor.textTertiary
        iconSizeConstraint?.update(offset: resolved.iconSize ?? Self.iconSize(for: layout))

        let hasTitle = content?.title.map { !$0.isEmpty } ?? false
        titleLabel.isHidden = !hasTitle
        titleLabel.lmk_apply(resolved.titleTextStyle ?? Self.titleTextStyle(for: layout), color: resolved.titleColor ?? LMKColor.textPrimary)
        titleLabel.lmk_setText(content?.title)
        messageLabel.lmk_apply(resolved.messageTextStyle ?? Self.messageTextStyle(for: layout), color: resolved.messageColor ?? (hasTitle ? LMKColor.textSecondary : LMKColor.textPrimary))
        messageLabel.lmk_setText(content?.message)

        // Layout
        containerStack.axis = layout.isHorizontal ? .horizontal : .vertical
        containerStack.alignment = .center
        containerStack.spacing = resolved.spacing ?? theme.spacing.small
        textStack.spacing = resolved.spacing ?? theme.spacing.xs
        titleLabel.textAlignment = layout.isHorizontal ? .natural : .center
        messageLabel.textAlignment = layout.isHorizontal ? .natural : .center
        containerStack.setCustomSpacing(resolved.actionSpacing ?? theme.spacing.large, after: textStack)
        styleActions()
        actionStack.spacing = theme.spacing.small
        updateAccessibility()
        invalidateIntrinsicContentSize()
        didApplyStyle?(self)
    }

    /// Creates the buttons for the content's actions; only `configure` and `setAction` call it,
    /// so a theme or style pass keeps the instances (and the state the host set on them).
    private func rebuildActions() {
        actionButton?.removeFromSuperview()
        secondaryActionButton?.removeFromSuperview()
        actionButton = nil
        secondaryActionButton = nil
        if let primary = content?.primaryAction {
            let button = makeButton(for: primary)
            actionStack.addArrangedSubview(button)
            actionButton = button
        }
        if let secondary = content?.secondaryAction {
            let button = makeButton(for: secondary)
            actionStack.addArrangedSubview(button)
            secondaryActionButton = button
        }
    }

    /// The buttons' styles from the actions, the style, and the layout (inline: the primary
    /// goes small and the secondary is hidden).
    private func styleActions() {
        if let actionButton, let primary = content?.primaryAction {
            var style = Self.buttonStyle(for: primary, defaultStyle: resolved.primaryButton ?? .filled())
            if layout.isHorizontal {
                style = style.size(.small)
            }
            actionButton.style = style
        }
        if let secondaryActionButton, let secondary = content?.secondaryAction {
            secondaryActionButton.style = Self.buttonStyle(for: secondary, defaultStyle: resolved.secondaryButton ?? .ghost())
            secondaryActionButton.isHidden = layout.isHorizontal
        }
        actionStack.isHidden = actionStack.arrangedSubviews.allSatisfy(\.isHidden)
    }

    private func makeButton(for action: Action) -> LMKButton {
        let button = LMKButton(title: action.title)
        if let icon = action.icon {
            button.setSymbol(icon)
        }
        button.onTap = action.handler
        // Hug the content: the button never stretches to the message width.
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }

    private static func buttonStyle(for action: Action, defaultStyle: LMKButton.Style) -> LMKButton.Style {
        action.style.map { defaultStyle.merging($0) } ?? defaultStyle
    }

    private static func iconSize(for layout: Layout) -> CGFloat {
        switch layout {
        case .fullScreen: 80
        case .card: 40
        case .inline: 20
        }
    }

    private static func titleTextStyle(for layout: Layout) -> LMKTextStyle {
        switch layout {
        case .fullScreen: .h3
        case .card: .bodyBold
        case .inline: .captionMedium
        }
    }

    private static func messageTextStyle(for layout: Layout) -> LMKTextStyle {
        switch layout {
        case .fullScreen: .body
        case .card: .caption
        case .inline: .caption
        }
    }

    private func animateEntrance() {
        guard LMKAnimation.shouldAnimate else {
            iconView.alpha = 1
            iconView.transform = .identity
            textStack.alpha = 1
            actionStack.alpha = 1
            return
        }
        if !iconView.isHidden {
            iconView.alpha = 0
            iconView.transform = CGAffineTransform(scaleX: Self.iconAnimationScale, y: Self.iconAnimationScale)
            UIView.animate(withDuration: LMKAnimation.Duration.normal, delay: Self.iconAnimationDelay, options: LMKAnimation.Curve.easeOut.options) {
                self.iconView.alpha = 1
                self.iconView.transform = .identity
            }
        }
        textStack.alpha = 0
        UIView.animate(withDuration: LMKAnimation.Duration.normal, delay: Self.labelAnimationDelay, options: LMKAnimation.Curve.easeOut.options) {
            self.textStack.alpha = 1
        }
        actionStack.alpha = 0
        UIView.animate(withDuration: LMKAnimation.Duration.normal, delay: Self.buttonAnimationDelay, options: LMKAnimation.Curve.easeOut.options) {
            self.actionStack.alpha = 1
        }
    }

    // MARK: - Accessibility

    /// Without actions the view is one static-text element (title and message as its label).
    /// With an action that element would swallow the button, so the view becomes a container
    /// exposing the labels and the buttons separately.
    private func updateAccessibility() {
        let label = [content?.title, content?.message].compactMap(\.self).filter { !$0.isEmpty }.joined(separator: ". ")
        if actionButton != nil || secondaryActionButton != nil {
            isAccessibilityElement = false
            accessibilityTraits = []
            accessibilityLabel = nil
            titleLabel.isAccessibilityElement = !titleLabel.isHidden
            messageLabel.isAccessibilityElement = true
            accessibilityElements = [titleLabel, messageLabel, actionButton, secondaryActionButton].compactMap(\.self).filter { !$0.isHidden }
        } else {
            isAccessibilityElement = true
            accessibilityTraits = .staticText
            accessibilityLabel = label
            accessibilityElements = nil
            titleLabel.isAccessibilityElement = false
            messageLabel.isAccessibilityElement = false
        }
    }

    // MARK: - Bridges

    /// The content as a `UIContentUnavailableConfiguration`, for hosts that use
    /// `contentUnavailableConfiguration` on a view controller.
    public func asContentUnavailableConfiguration() -> UIContentUnavailableConfiguration {
        var configuration = UIContentUnavailableConfiguration.empty()
        configuration.text = content?.title ?? content?.message
        configuration.secondaryText = content?.title == nil ? nil : content?.message
        configuration.image = content?.icon?.image
        if let primary = content?.primaryAction {
            var button = UIButton.Configuration.filled()
            button.title = primary.title
            button.image = primary.icon.flatMap { UIImage(systemName: $0) }
            configuration.button = button
            configuration.buttonProperties.primaryAction = UIAction { _ in primary.handler() }
        }
        if let secondary = content?.secondaryAction {
            var button = UIButton.Configuration.plain()
            button.title = secondary.title
            configuration.secondaryButton = button
            configuration.secondaryButtonProperties.primaryAction = UIAction { _ in secondary.handler() }
        }
        return configuration
    }

    /// Wraps this view for use as `tableView.backgroundView`.
    public func wrappedForTableBackground(backgroundColor: UIColor? = nil) -> UIView {
        let container = UIView()
        container.backgroundColor = backgroundColor ?? LMKColor.backgroundPrimary
        container.addSubview(self)
        snp.makeConstraints { $0.edges.equalToSuperview() }
        return container
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKEmptyStateView`.
    var emptyState: LMKEmptyStateView.Style {
        get { self[LMKEmptyStateView.Style.self] }
        set { self[LMKEmptyStateView.Style.self] = newValue }
    }
}
