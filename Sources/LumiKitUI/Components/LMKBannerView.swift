//
//  LMKBannerView.swift
//  LumiKit
//
//  Persistent banner: status icon, message, optional action button, and a
//  dismiss button. Inline in a stack, or shown over a screen, where it sits
//  under the navigation bar and insets the scroll content it would cover.
//

import SnapKit
import UIKit

/// Persistent banner for status messages, warnings, or actionable notifications.
///
/// Stays until dismissed by the user or the host. Add it to a stack to make it part of
/// the layout, or call `show(in:)` to float it at the top of a screen: it takes its place
/// under the screen's `LMKNavigationBar` (or the safe area) and adds its height to the top
/// inset of the scroll view below, so content starts under the banner, not behind it.
/// ```swift
/// let banner = LMKBannerView(status: .warning, message: "No internet connection")
/// banner.actionTitle = "Settings"
/// banner.onAction = { openSettings() }
/// banner.show(in: self)
/// ```
public final class LMKBannerView: UIView, LMKThemeApplying {
    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// Background (default the status color at `xs` over `backgroundPrimary`, opaque), border
        /// (the status color at `medium`, hairline), corners (`medium`), shadow (none inline,
        /// `level2` while shown over a screen), insets (`small` vertical, `medium` horizontal).
        public var surface: LMKSurfaceStyle
        /// `nil` = `captionMedium`.
        public var textStyle: LMKTextStyle?
        /// `nil` = `textPrimary`.
        public var messageColor: UIColor?
        /// `nil` = the status color.
        public var iconTint: UIColor?
        /// `nil` = `iconSmall`.
        public var iconSize: CGFloat?
        /// Style of the action button; `nil` = ghost, tinted with the status color, small.
        public var actionButton: LMKButton.Style?
        /// `nil` = `textSecondary`.
        public var dismissTint: UIColor?
        /// Point size of the dismiss glyph; `nil` = `symbolAccessory`.
        public var dismissSymbolPointSize: CGFloat?
        /// From the host's edges while shown over a screen; `nil` = `cardPadding`.
        public var horizontalMargin: CGFloat?
        /// Gap above the banner (and under it, before the inset content) while shown over a
        /// screen; `nil` = `small`.
        public var verticalMargin: CGFloat?
        /// Widest the banner grows while shown over a screen; `nil` = `readableContentMaxWidth`.
        public var maxWidth: CGFloat?

        public init(
            surface: LMKSurfaceStyle = LMKSurfaceStyle(),
            textStyle: LMKTextStyle? = nil,
            messageColor: UIColor? = nil,
            iconTint: UIColor? = nil,
            iconSize: CGFloat? = nil,
            actionButton: LMKButton.Style? = nil,
            dismissTint: UIColor? = nil,
            dismissSymbolPointSize: CGFloat? = nil,
            horizontalMargin: CGFloat? = nil,
            verticalMargin: CGFloat? = nil,
            maxWidth: CGFloat? = nil
        ) {
            self.surface = surface
            self.textStyle = textStyle
            self.messageColor = messageColor
            self.iconTint = iconTint
            self.iconSize = iconSize
            self.actionButton = actionButton
            self.dismissTint = dismissTint
            self.dismissSymbolPointSize = dismissSymbolPointSize
            self.horizontalMargin = horizontalMargin
            self.verticalMargin = verticalMargin
            self.maxWidth = maxWidth
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                surface: surface.merging(other.surface),
                textStyle: other.textStyle ?? textStyle,
                messageColor: other.messageColor ?? messageColor,
                iconTint: other.iconTint ?? iconTint,
                iconSize: other.iconSize ?? iconSize,
                actionButton: other.actionButton.map { actionButton?.merging($0) ?? $0 } ?? actionButton,
                dismissTint: other.dismissTint ?? dismissTint,
                dismissSymbolPointSize: other.dismissSymbolPointSize ?? dismissSymbolPointSize,
                horizontalMargin: other.horizontalMargin ?? horizontalMargin,
                verticalMargin: other.verticalMargin ?? verticalMargin,
                maxWidth: other.maxWidth ?? maxWidth
            )
        }
    }

    // MARK: - Strings

    public nonisolated struct Strings: Sendable, Equatable {
        public var dismissAccessibilityLabel: String

        public init(dismissAccessibilityLabel: String = LMKLocalized("banner.dismiss.accessibilityLabel")) {
            self.dismissAccessibilityLabel = dismissAccessibilityLabel
        }
    }

    /// Process-wide defaults; set at app launch to override.
    public nonisolated(unsafe) static var strings = Strings()

    /// Per-instance strings (default `Self.strings`).
    public var strings: Strings = LMKBannerView.strings {
        didSet { dismissButton.accessibilityLabel = strings.dismissAccessibilityLabel }
    }

    // MARK: - Subviews

    public let messageLabel = UILabel()
    public let iconView = UIImageView()
    public let actionButton = LMKButton(style: .ghost().size(.small))
    public let dismissButton = LMKButton(style: .iconOnly(.neutral))

    // MARK: - State

    public let status: LMKStatus

    /// The message (also the accessibility label).
    public var message: String {
        didSet { messageLabel.lmk_setText(message) }
    }

    /// Per-instance style; `nil` fields resolve from `theme.banner`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Optional action button title. When set, shows an action button.
    public var actionTitle: String? {
        didSet {
            actionButton.title = actionTitle
            actionButton.isHidden = actionTitle == nil
            updateAccessibilityElements()
        }
    }

    /// Handler called when the action button is tapped.
    public var onAction: (() -> Void)?

    /// Handler called after the banner is dismissed (by the user or `dismiss()`).
    public var onDismiss: (() -> Void)?

    /// Whether the banner shows a dismiss (X) button. Defaults to `true`.
    public var showsDismissButton = true {
        didSet {
            dismissButton.isHidden = !showsDismissButton
            applyTheme(traitCollection.lmkTheme)
            updateAccessibilityElements()
        }
    }

    /// Whether the banner is shown over a screen (`show(in:)`), as opposed to inline in a layout.
    public private(set) var isFloating = false

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKBannerView) -> Void)?

    private var iconSizeConstraint: Constraint?
    private var contentInsetsConstraint: Constraint?
    private var minimumHeightConstraint: Constraint?
    private let row = UIStackView()
    private var resolved = Style()
    /// The scroll view whose top inset holds the banner's height while it floats.
    private weak var insetScrollView: UIScrollView?
    private var appliedTopInset: CGFloat = 0

    // MARK: - Initialization

    public init(status: LMKStatus, message: String, style: Style = Style()) {
        self.status = status
        self.message = message
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
        iconView.image = status.systemImageName.flatMap { UIImage(systemName: $0) }
        iconView.isHidden = iconView.image == nil
        iconView.contentMode = .scaleAspectFit
        iconView.snp.makeConstraints { make in
            iconSizeConstraint = make.width.height.equalTo(0).constraint
        }

        messageLabel.text = message
        messageLabel.numberOfLines = 0
        messageLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        actionButton.isHidden = true
        actionButton.onTap = { [weak self] in self?.onAction?() }
        actionButton.setContentHuggingPriority(.required, for: .horizontal)
        actionButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        dismissButton.setSymbol("xmark")
        dismissButton.accessibilityLabel = strings.dismissAccessibilityLabel
        dismissButton.onTap = { [weak self] in self?.dismiss() }
        dismissButton.setContentHuggingPriority(.required, for: .horizontal)

        row.axis = .horizontal
        row.alignment = .center
        row.addArrangedSubview(iconView)
        row.addArrangedSubview(messageLabel)
        row.addArrangedSubview(actionButton)
        row.addArrangedSubview(dismissButton)
        addSubview(row)
        row.snp.makeConstraints { make in
            contentInsetsConstraint = make.edges.equalToSuperview().constraint
            // On the row, not the banner: a constraint on the banner itself would take it out of
            // frame-based layouts.
            minimumHeightConstraint = make.height.greaterThanOrEqualTo(0).constraint
        }

        isAccessibilityElement = false
        updateAccessibilityElements()
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        lmk_layoutSurfaceIfNeeded()
        updateScrollInset(animated: false)
    }

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        resolved = theme.banner.merging(style)
        let statusColor = status.color
        let defaults = LMKSurfaceStyle(
            // Opaque: a banner over a screen must not let the content under it show through.
            background: .solid(statusColor.lmk_composited(over: LMKColor.backgroundPrimary, alpha: theme.alpha.xs)),
            corners: .fixed(theme.cornerRadius.medium),
            border: .solid(statusColor.withAlphaComponent(theme.alpha.medium)),
            shadow: isFloating ? .level(.level2) : LMKShadowSource.none,
            contentInsets: NSDirectionalEdgeInsets(
                top: theme.spacing.small,
                leading: theme.spacing.medium,
                bottom: theme.spacing.small,
                // The dismiss button brings its own padding.
                trailing: showsDismissButton ? theme.spacing.small : theme.spacing.medium
            )
        )
        let applied = lmk_apply(surface: resolved.surface, defaults: defaults, clipsContent: false)
        let insets = applied.contentInsets ?? .lmk_all(theme.spacing.medium)
        contentInsetsConstraint?.update(inset: UIEdgeInsets(top: insets.top, left: insets.leading, bottom: insets.bottom, right: insets.trailing))
        minimumHeightConstraint?.update(offset: max(0, theme.layout.minimumTouchTarget - insets.top - insets.bottom))
        row.spacing = theme.spacing.small
        iconView.tintColor = resolved.iconTint ?? statusColor
        iconSizeConstraint?.update(offset: resolved.iconSize ?? theme.layout.iconSmall)
        messageLabel.lmk_apply(resolved.textStyle ?? .captionMedium, color: resolved.messageColor ?? LMKColor.textPrimary)
        actionButton.style = resolved.actionButton ?? LMKButton.Style.ghost().tint(statusColor).size(.small)
        // A small glyph in a compact frame; the button still answers a 44pt hit target.
        var dismissStyle = LMKButton.Style.iconOnly(.neutral).tint(resolved.dismissTint ?? LMKColor.textSecondary)
        dismissStyle.surface.contentInsets = .lmk_all(theme.spacing.xs)
        dismissStyle.symbolPointSize = resolved.dismissSymbolPointSize ?? theme.layout.symbolAccessory
        dismissStyle.symbolWeight = .semibold
        dismissButton.style = dismissStyle
        dismissButton.setSymbol("xmark")
        didApplyStyle?(self)
    }

    private func updateAccessibilityElements() {
        var elements: [Any] = [messageLabel]
        if !actionButton.isHidden { elements.append(actionButton) }
        if !dismissButton.isHidden { elements.append(dismissButton) }
        accessibilityElements = elements
    }

    // MARK: - Show / Dismiss

    /// Shows the banner at the top of `viewController`'s view, replacing any banner there.
    ///
    /// It sits under the view's `LMKNavigationBar` when there is one, else at the top of the
    /// safe area, and the first scroll view under it gets the banner's height as extra top inset.
    public func show(in viewController: UIViewController) {
        guard let view = viewController.view else { return }
        show(in: view)
    }

    /// Shows the banner at the top of `hostView`, replacing any banner there.
    ///
    /// - Parameters:
    ///   - hostView: The view the banner is added to.
    ///   - anchor: The view the banner sits under; `nil` = the host's `LMKNavigationBar` when it
    ///     has one, else the top of its safe area.
    ///   - scrollView: The scroll view that makes room for the banner through its top content
    ///     inset; `nil` = the first scroll view in `hostView`. Pass `insetsScrollView: false` to
    ///     leave every scroll view alone.
    ///   - insetsScrollView: Whether a scroll view makes room for the banner. Default `true`.
    public func show(in hostView: UIView, below anchor: UIView? = nil, insetting scrollView: UIScrollView? = nil, insetsScrollView: Bool = true) {
        for case let banner as Self in hostView.subviews where banner !== self {
            banner.dismiss()
        }
        isFloating = true
        hostView.addSubview(self)
        let theme = traitCollection.lmkTheme
        applyTheme(theme)
        let margin = resolved.horizontalMargin ?? LMKSpacing.cardPadding
        let topSpacing = resolved.verticalMargin ?? theme.spacing.small
        let anchor = anchor ?? hostView.subviews.first { $0 is LMKNavigationBar }
        snp.remakeConstraints { make in
            if let anchor {
                make.top.equalTo(anchor.snp.bottom).offset(topSpacing)
            } else {
                make.top.equalTo(hostView.safeAreaLayoutGuide.snp.top).offset(topSpacing)
            }
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualTo(hostView.safeAreaLayoutGuide).offset(margin)
            make.trailing.lessThanOrEqualTo(hostView.safeAreaLayoutGuide).offset(-margin)
            make.width.lessThanOrEqualTo(resolved.maxWidth ?? theme.layout.readableContentMaxWidth)
            // Fill unless capped: just below required, so the cap and the margins win.
            make.width.equalTo(hostView.safeAreaLayoutGuide).offset(-margin * 2).priority(999)
        }
        if insetsScrollView {
            insetScrollView = scrollView ?? Self.firstScrollView(in: hostView)
        }
        hostView.layoutIfNeeded()
        updateScrollInset(animated: false)

        if LMKAnimation.shouldAnimate {
            alpha = 0
            transform = CGAffineTransform(translationX: 0, y: -theme.spacing.xl)
            UIView.animate(withDuration: LMKAnimation.Duration.moderate) {
                self.alpha = 1
                self.transform = .identity
            }
        }
        UIAccessibility.post(notification: .layoutChanged, argument: messageLabel)
    }

    /// Dismisses the banner with animation.
    public func dismiss() {
        let animates = LMKAnimation.shouldAnimate && window != nil
        let restore = { [weak self] in
            guard let self else { return }
            alpha = 0
            if isFloating { transform = CGAffineTransform(translationX: 0, y: -traitCollection.lmkTheme.spacing.xl) }
            releaseScrollInset()
        }
        let finish = { [weak self] in
            guard let self else { return }
            removeFromSuperview()
            transform = .identity
            isFloating = false
            onDismiss?()
        }
        guard animates else {
            restore()
            finish()
            return
        }
        UIView.animate(withDuration: LMKAnimation.Duration.normal, animations: restore, completion: { _ in finish() })
    }

    // MARK: - Scroll inset

    /// The first scroll view in `view`, breadth first, so a screen's main scroll view wins over
    /// one nested in its content.
    private static func firstScrollView(in view: UIView) -> UIScrollView? {
        var queue = view.subviews
        while !queue.isEmpty {
            let next = queue.removeFirst()
            if let scrollView = next as? UIScrollView { return scrollView }
            queue.append(contentsOf: next.subviews)
        }
        return nil
    }

    /// Keeps the scroll view's extra top inset at the banner's height plus the gap under it.
    /// A scroll view resting at its top moves with the inset, so its first row stays in view.
    private func updateScrollInset(animated: Bool) {
        guard isFloating, let scrollView = insetScrollView, superview != nil, bounds.height > 0 else { return }
        let spacing = resolved.verticalMargin ?? traitCollection.lmkTheme.spacing.small
        // Only the part of the banner that overlaps the scroll view needs room.
        let bannerBottom = convert(CGPoint(x: 0, y: bounds.maxY), to: scrollView.superview).y
        let contentTop = scrollView.frame.minY + scrollView.adjustedContentInset.top - appliedTopInset
        // Whole points, with a hair of slack so a float's rounding error never adds one.
        let needed = max(0, (bannerBottom + spacing - contentTop - 0.01).rounded(.up))
        guard abs(needed - appliedTopInset) > 0.5 else { return }
        let wasAtTop = scrollView.contentOffset.y <= -scrollView.adjustedContentInset.top + 0.5
        let change = needed - appliedTopInset
        let apply = {
            scrollView.contentInset.top += change
            scrollView.verticalScrollIndicatorInsets.top += change
            if wasAtTop { scrollView.contentOffset.y = -scrollView.adjustedContentInset.top }
        }
        appliedTopInset = needed
        if animated, LMKAnimation.shouldAnimate {
            UIView.animate(withDuration: LMKAnimation.Duration.moderate, animations: apply)
        } else {
            apply()
        }
    }

    private func releaseScrollInset() {
        guard let scrollView = insetScrollView, appliedTopInset > 0 else { return }
        let wasAtTop = scrollView.contentOffset.y <= -scrollView.adjustedContentInset.top + 0.5
        scrollView.contentInset.top -= appliedTopInset
        scrollView.verticalScrollIndicatorInsets.top -= appliedTopInset
        if wasAtTop { scrollView.contentOffset.y = -scrollView.adjustedContentInset.top }
        appliedTopInset = 0
        insetScrollView = nil
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKBannerView`.
    var banner: LMKBannerView.Style {
        get { self[LMKBannerView.Style.self] }
        set { self[LMKBannerView.Style.self] = newValue }
    }
}
