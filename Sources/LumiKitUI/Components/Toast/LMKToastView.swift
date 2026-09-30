//
//  LMKToastView.swift
//  LumiKit
//
//  The toast surface: icon, optional title, message, optional action button,
//  dismiss button for persistent toasts, and a countdown ring for undo toasts.
//

import SnapKit
import UIKit

/// Floating toast: an elevated card with a status icon and a message.
/// Presented through `LMKToast.show(_:)`; `show(in:completion:)` presents an
/// instance built by hand.
public final class LMKToastView: UIView, LMKThemeApplying {
    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// Background (default `backgroundPrimary`), corners (`large`), shadow (`level2`), insets (`medium`).
        public var surface: LMKSurfaceStyle
        /// `nil` = `body`.
        public var textStyle: LMKTextStyle?
        /// `nil` = `bodyBold`.
        public var titleTextStyle: LMKTextStyle?
        /// `nil` = `textPrimary`.
        public var messageColor: UIColor?
        /// `nil` = `textPrimary`.
        public var titleColor: UIColor?
        /// `nil` = the status color.
        public var iconTint: UIColor?
        /// `nil` = `iconSmall`.
        public var iconSize: CGFloat?
        /// Hide the status icon; `nil` = shown when the status has one.
        public var showsIcon: Bool?
        /// Style of the action button; `nil` = ghost, tinted with the status color, small.
        public var actionButton: LMKButton.Style?
        /// Style of a persistent toast's dismiss button; `nil` = a `symbolAccessory` glyph in
        /// `textSecondary`, as wide as the glyph and its padding.
        public var dismissButton: LMKButton.Style?
        /// Distance from the host's edges; `nil` = `cardPadding`.
        public var horizontalMargin: CGFloat?
        /// `nil` = `readableContentMaxWidth`.
        public var maxWidth: CGFloat?
        /// Distance from the safe area; `nil` = `medium`.
        public var verticalOffset: CGFloat?
        /// `nil` = the status color.
        public var countdownRingColor: UIColor?
        /// `nil` = 2.
        public var countdownRingWidth: CGFloat?

        public init(
            surface: LMKSurfaceStyle = LMKSurfaceStyle(),
            textStyle: LMKTextStyle? = nil,
            titleTextStyle: LMKTextStyle? = nil,
            messageColor: UIColor? = nil,
            titleColor: UIColor? = nil,
            iconTint: UIColor? = nil,
            iconSize: CGFloat? = nil,
            showsIcon: Bool? = nil,
            actionButton: LMKButton.Style? = nil,
            dismissButton: LMKButton.Style? = nil,
            horizontalMargin: CGFloat? = nil,
            maxWidth: CGFloat? = nil,
            verticalOffset: CGFloat? = nil,
            countdownRingColor: UIColor? = nil,
            countdownRingWidth: CGFloat? = nil
        ) {
            self.surface = surface
            self.textStyle = textStyle
            self.titleTextStyle = titleTextStyle
            self.messageColor = messageColor
            self.titleColor = titleColor
            self.iconTint = iconTint
            self.iconSize = iconSize
            self.showsIcon = showsIcon
            self.actionButton = actionButton
            self.dismissButton = dismissButton
            self.horizontalMargin = horizontalMargin
            self.maxWidth = maxWidth
            self.verticalOffset = verticalOffset
            self.countdownRingColor = countdownRingColor
            self.countdownRingWidth = countdownRingWidth
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                surface: surface.merging(other.surface),
                textStyle: other.textStyle ?? textStyle,
                titleTextStyle: other.titleTextStyle ?? titleTextStyle,
                messageColor: other.messageColor ?? messageColor,
                titleColor: other.titleColor ?? titleColor,
                iconTint: other.iconTint ?? iconTint,
                iconSize: other.iconSize ?? iconSize,
                showsIcon: other.showsIcon ?? showsIcon,
                actionButton: other.actionButton.map { actionButton?.merging($0) ?? $0 } ?? actionButton,
                dismissButton: other.dismissButton.map { dismissButton?.merging($0) ?? $0 } ?? dismissButton,
                horizontalMargin: other.horizontalMargin ?? horizontalMargin,
                maxWidth: other.maxWidth ?? maxWidth,
                verticalOffset: other.verticalOffset ?? verticalOffset,
                countdownRingColor: other.countdownRingColor ?? countdownRingColor,
                countdownRingWidth: other.countdownRingWidth ?? countdownRingWidth
            )
        }
    }

    // MARK: - Subviews

    public let containerView = UIView()
    public let iconView = UIImageView()
    public let titleLabel = UILabel()
    public let messageLabel = UILabel()
    public let actionButton = LMKButton(style: .ghost().size(.small))
    public let dismissButton = LMKButton(style: .iconOnly(.neutral).size(.small))
    private let textStack = UIStackView()
    private let countdownRing = CAShapeLayer()

    // MARK: - State

    public private(set) var configuration: LMKToastConfiguration

    /// Per-instance style; `nil` fields resolve from the configuration's style, `theme.toast`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Per-instance strings (default `LMKToast.strings`).
    public var strings: LMKToast.Strings = LMKToast.strings {
        didSet { dismissButton.accessibilityLabel = strings.dismissAccessibilityLabel }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKToastView) -> Void)?

    private weak var presenter: LMKToastPresenter?
    private var dismissTimer: Timer?
    private var isDismissing = false
    private var iconSizeConstraint: Constraint?
    private var contentInsetsConstraint: Constraint?
    private var slideOffset: CGFloat = 0

    // MARK: - Initialization

    public init(configuration: LMKToastConfiguration) {
        self.configuration = configuration
        style = configuration.style
        super.init(frame: .zero)
        setupUI()
        lmk_startApplyingTheme()
    }

    /// A status toast (the `LMKToast.show(_:message:duration:in:)` shape).
    public convenience init(status: LMKStatus, message: String, duration: TimeInterval = LMKToast.defaultDuration) {
        self.init(configuration: LMKToastConfiguration(status: status, message: message, duration: .seconds(duration)))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        // UIView deinit runs on the main thread; the timer must not outlive the view.
        MainActor.assumeIsolated {
            dismissTimer?.invalidate()
        }
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .clear
        isAccessibilityElement = true
        accessibilityLabel = [configuration.title, configuration.message].compactMap(\.self).joined(separator: ". ")
        accessibilityTraits = .staticText

        addSubview(containerView)
        containerView.snp.makeConstraints { $0.edges.equalToSuperview() }

        iconView.contentMode = .scaleAspectFit
        iconView.image = configuration.icon ?? configuration.status.systemImageName.flatMap { UIImage(systemName: $0) }
        iconView.isHidden = iconView.image == nil
        iconView.layer.addSublayer(countdownRing)
        countdownRing.fillColor = nil
        countdownRing.lineCap = .round
        countdownRing.isHidden = !configuration.showsCountdown

        titleLabel.text = configuration.title
        titleLabel.isHidden = configuration.title == nil
        titleLabel.numberOfLines = 0
        messageLabel.text = configuration.message
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .natural
        textStack.axis = .vertical
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(messageLabel)

        actionButton.title = configuration.action?.title
        actionButton.isHidden = configuration.action == nil
        actionButton.onTap = { [weak self] in self?.didTapAction() }
        actionButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        actionButton.setContentHuggingPriority(.required, for: .horizontal)

        // Both trailing buttons fit their content; the text takes the width that is left.
        dismissButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        dismissButton.setContentHuggingPriority(.required, for: .horizontal)
        textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        dismissButton.isHidden = configuration.duration != .persistent
        dismissButton.accessibilityLabel = strings.dismissAccessibilityLabel
        dismissButton.onTap = { [weak self] in self?.dismiss(reason: .tap) }

        let row = UIStackView(arrangedSubviews: [iconView, textStack, actionButton, dismissButton])
        row.axis = .horizontal
        row.alignment = .center
        containerView.addSubview(row)
        row.snp.makeConstraints { make in
            contentInsetsConstraint = make.edges.equalToSuperview().constraint
        }
        iconView.snp.makeConstraints { make in
            iconSizeConstraint = make.width.height.equalTo(0).constraint
        }
        row.setCustomSpacing(0, after: actionButton)
        rowStack = row

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapToast))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = configuration.tapToDismiss || configuration.action != nil || configuration.duration == .persistent

        var elements: [Any] = []
        if configuration.action != nil { elements.append(actionButton) }
        if configuration.duration == .persistent { elements.append(dismissButton) }
        if !elements.isEmpty {
            isAccessibilityElement = false
            accessibilityElements = [messageLabel] + elements
            messageLabel.accessibilityLabel = accessibilityLabel
        }
    }

    private var rowStack: UIStackView?

    override public func layoutSubviews() {
        super.layoutSubviews()
        lmk_layoutSurfaceIfNeeded()
        layoutCountdownRing()
    }

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        let resolved = theme.toast.merging(configuration.style).merging(style)
        let statusColor = configuration.status.color
        let defaults = LMKSurfaceStyle(
            background: .solid(LMKColor.backgroundPrimary),
            corners: .fixed(theme.cornerRadius.large),
            shadow: .level(.level2),
            contentInsets: .lmk_symmetric(vertical: theme.spacing.medium, horizontal: theme.spacing.medium)
        )
        let applied = lmk_apply(surface: resolved.surface, defaults: defaults, clipsContent: false)
        containerView.backgroundColor = .clear
        let insets = applied.contentInsets ?? .lmk_all(theme.spacing.medium)
        contentInsetsConstraint?.update(inset: UIEdgeInsets(top: insets.top, left: insets.leading, bottom: insets.bottom, right: insets.trailing))

        iconView.tintColor = resolved.iconTint ?? statusColor
        iconView.isHidden = !(resolved.showsIcon ?? (iconView.image != nil))
        iconSizeConstraint?.update(offset: resolved.iconSize ?? theme.layout.iconSmall)
        rowStack?.spacing = theme.spacing.small
        titleLabel.lmk_apply(resolved.titleTextStyle ?? .bodyBold, color: resolved.titleColor ?? LMKColor.textPrimary)
        messageLabel.lmk_apply(resolved.textStyle ?? .body, color: resolved.messageColor ?? LMKColor.textPrimary)
        actionButton.style = resolved.actionButton ?? LMKButton.Style.ghost().tint(statusColor).size(.small)
        // A small glyph in a compact frame; the button still answers a 44pt hit target.
        var dismissStyle = LMKButton.Style.iconOnly(.neutral).tint(LMKColor.textSecondary)
        dismissStyle.symbolPointSize = theme.layout.symbolAccessory
        dismissStyle.symbolWeight = .semibold
        dismissStyle.surface.contentInsets = .lmk_all(theme.spacing.xs)
        dismissButton.style = resolved.dismissButton.map { dismissStyle.merging($0) } ?? dismissStyle
        dismissButton.setSymbol("xmark")
        rowStack?.setCustomSpacing(configuration.duration == .persistent ? theme.spacing.xs : 0, after: actionButton)
        countdownRing.strokeColor = (resolved.countdownRingColor ?? statusColor).resolvedColor(with: traitCollection).cgColor
        countdownRing.lineWidth = resolved.countdownRingWidth ?? Self.defaultRingWidth
        slideOffset = configuration.position == .top ? -Self.slideDistance : Self.slideDistance
        layoutCountdownRing()
        didApplyStyle?(self)
    }

    private static let defaultRingWidth: CGFloat = 2
    private static let slideDistance: CGFloat = 200

    private func layoutCountdownRing() {
        guard configuration.showsCountdown else { return }
        let inset = countdownRing.lineWidth / 2
        countdownRing.frame = iconView.bounds
        countdownRing.path = UIBezierPath(ovalIn: iconView.bounds.insetBy(dx: inset, dy: inset)).cgPath
    }

    // MARK: - Content

    /// Replaces the message in place.
    public func setMessage(_ message: String) {
        configuration.message = message
        messageLabel.lmk_setText(message)
        accessibilityLabel = [configuration.title, message].compactMap(\.self).joined(separator: ". ")
    }

    // MARK: - Presentation

    /// Presents on `viewController`'s view (replacing any toast there).
    public func show(in viewController: UIViewController, completion: (() -> Void)? = nil) {
        guard let view = viewController.view else { return }
        _ = LMKToastPresenter.shared.present(self, in: view, completion: completion)
    }

    /// Presents on `view` (replacing any toast there).
    public func show(in view: UIView, completion: (() -> Void)? = nil) {
        _ = LMKToastPresenter.shared.present(self, in: view, completion: completion)
    }

    /// Dismisses the toast.
    public func dismiss() {
        dismiss(reason: .programmatic)
    }

    func present(in hostView: UIView, presenter: LMKToastPresenter, completion: (() -> Void)?) {
        self.presenter = presenter
        let theme = traitCollection.lmkTheme
        let resolved = theme.toast.merging(configuration.style).merging(style)
        hostView.addSubview(self)
        let margin = resolved.horizontalMargin ?? LMKSpacing.cardPadding
        let offset = resolved.verticalOffset ?? theme.spacing.medium
        snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().inset(margin)
            make.trailing.lessThanOrEqualToSuperview().inset(margin)
            make.width.lessThanOrEqualTo(resolved.maxWidth ?? theme.layout.readableContentMaxWidth)
            // Just below required: with an action button (required hugging) in the row, UIKit's
            // stack text-width disambiguation (950) would otherwise win and collapse the toast.
            make.width.equalToSuperview().inset(margin).priority(999)
            switch configuration.position {
            case .top: make.top.equalTo(hostView.safeAreaLayoutGuide.snp.top).offset(offset)
            case .bottom: make.bottom.equalTo(hostView.safeAreaLayoutGuide.snp.bottom).inset(offset)
            }
        }
        // Resolve constraints before animating so the toast never flashes at a stale frame.
        hostView.layoutIfNeeded()
        applyTheme(traitCollection.lmkTheme)

        transform = CGAffineTransform(translationX: 0, y: slideOffset)
        alpha = 0
        let animates = LMKAnimation.shouldAnimate
        UIView.animate(
            withDuration: animates ? LMKAnimation.Duration.moderate : 0, delay: 0,
            usingSpringWithDamping: LMKAnimation.spring.damping, initialSpringVelocity: 0,
            options: [.allowUserInteraction, LMKAnimation.Curve.easeOut.options],
            animations: { [weak self] in
                self?.transform = .identity
                self?.alpha = 1
            },
            completion: { _ in completion?() }
        )

        if case let .seconds(duration) = configuration.duration {
            dismissTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.dismiss(reason: .timeout)
                }
            }
            if configuration.showsCountdown {
                runCountdown(duration: duration)
            }
        }
        if configuration.haptic {
            configuration.status.playHaptic()
        }
        UIAccessibility.post(notification: .announcement, argument: configuration.message)
    }

    private func runCountdown(duration: TimeInterval) {
        countdownRing.strokeEnd = 1
        guard LMKAnimation.shouldAnimate else { return }
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = 1
        animation.toValue = 0
        animation.duration = duration
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        animation.timingFunction = LMKAnimation.Curve.linear.timingFunction
        countdownRing.add(animation, forKey: "countdown")
    }

    func dismiss(reason: LMKToastDismissReason) {
        guard !isDismissing else { return }
        isDismissing = true
        dismissTimer?.invalidate()
        dismissTimer = nil
        let onDismiss = configuration.onDismiss
        let animates = LMKAnimation.shouldAnimate
        UIView.animate(
            withDuration: animates ? LMKAnimation.Duration.normal : 0,
            delay: 0, options: [.allowUserInteraction, LMKAnimation.Curve.easeIn.options],
            animations: { [weak self] in
                guard let self else { return }
                transform = CGAffineTransform(translationX: 0, y: slideOffset)
                alpha = 0
            },
            completion: { [weak self] _ in
                guard let self else { return }
                removeFromSuperview()
                presenter?.toastDidDismiss(self)
                onDismiss?(reason)
            }
        )
    }

    // MARK: - Actions

    private func didTapAction() {
        configuration.action?.onAction()
        dismiss(reason: .action)
    }

    @objc private func didTapToast() {
        guard configuration.tapToDismiss else { return }
        dismiss(reason: .tap)
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKToastView`.
    var toast: LMKToastView.Style {
        get { self[LMKToastView.Style.self] }
        set { self[LMKToastView.Style.self] = newValue }
    }
}
