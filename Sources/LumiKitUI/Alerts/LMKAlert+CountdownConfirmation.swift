//
//  LMKAlert+CountdownConfirmation.swift
//  LumiKit
//
//  A modal confirmation whose confirm button stays disabled for a countdown,
//  preventing accidental taps on critical actions. Drawn in UIKit (not
//  UIAlertController) so the live countdown renders identically on iOS and
//  Mac Catalyst. Styled from `theme.countdownAlert`.
//

import LumiKitCore
import SnapKit
import UIKit

/// Control over a presented countdown confirmation.
public final class LMKCountdownHandle {
    private weak var controller: LMKCountdownAlertViewController?

    init(controller: LMKCountdownAlertViewController) {
        self.controller = controller
    }

    /// Whether the confirm button is tappable yet.
    public var isConfirmEnabled: Bool { controller?.isConfirmEnabled ?? false }

    /// Seconds left before the confirm button enables (0 once enabled).
    public var remainingSeconds: Int { controller?.remainingSeconds ?? 0 }

    /// Dismisses the dialog as a cancel would (`onCancel` runs once; later calls do nothing).
    public func dismiss() {
        controller?.handleCancel()
    }
}

public extension LMKAlert {
    /// Appearance of the countdown confirmation.
    nonisolated struct CountdownStyle: Sendable, Equatable, LMKThemeExtension {
        /// Card background (`backgroundPrimary`), corners (`xxl`), border (`divider`, 1pt), shadow (`level3`), content insets.
        public var surface: LMKSurfaceStyle
        /// `nil` = 340.
        public var cardWidth: CGFloat?
        /// `nil` = `scrim`.
        public var dimmingColor: UIColor?
        /// `nil` = `alpha.large`.
        public var dimmingAlpha: CGFloat?
        /// `nil` = `h3`.
        public var titleTextStyle: LMKTextStyle?
        /// `nil` = `textPrimary`.
        public var titleColor: UIColor?
        /// `nil` = `body`.
        public var messageTextStyle: LMKTextStyle?
        /// `nil` = `textSecondary`.
        public var messageColor: UIColor?
        /// Layered on the cancel button (filled `backgroundSecondary`).
        public var cancelButton: LMKButton.Style
        /// Layered on the confirm button (filled in the confirm role).
        public var confirmButton: LMKButton.Style
        /// `nil` = 48.
        public var buttonHeight: CGFloat?

        public init(
            surface: LMKSurfaceStyle = LMKSurfaceStyle(),
            cardWidth: CGFloat? = nil,
            dimmingColor: UIColor? = nil,
            dimmingAlpha: CGFloat? = nil,
            titleTextStyle: LMKTextStyle? = nil,
            titleColor: UIColor? = nil,
            messageTextStyle: LMKTextStyle? = nil,
            messageColor: UIColor? = nil,
            cancelButton: LMKButton.Style = LMKButton.Style(),
            confirmButton: LMKButton.Style = LMKButton.Style(),
            buttonHeight: CGFloat? = nil
        ) {
            self.surface = surface
            self.cardWidth = cardWidth
            self.dimmingColor = dimmingColor
            self.dimmingAlpha = dimmingAlpha
            self.titleTextStyle = titleTextStyle
            self.titleColor = titleColor
            self.messageTextStyle = messageTextStyle
            self.messageColor = messageColor
            self.cancelButton = cancelButton
            self.confirmButton = confirmButton
            self.buttonHeight = buttonHeight
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                surface: surface.merging(other.surface),
                cardWidth: other.cardWidth ?? cardWidth,
                dimmingColor: other.dimmingColor ?? dimmingColor,
                dimmingAlpha: other.dimmingAlpha ?? dimmingAlpha,
                titleTextStyle: other.titleTextStyle ?? titleTextStyle,
                titleColor: other.titleColor ?? titleColor,
                messageTextStyle: other.messageTextStyle ?? messageTextStyle,
                messageColor: other.messageColor ?? messageColor,
                cancelButton: cancelButton.merging(other.cancelButton),
                confirmButton: confirmButton.merging(other.confirmButton),
                buttonHeight: other.buttonHeight ?? buttonHeight
            )
        }
    }

    /// Presents a confirmation whose confirm button counts down before it enables.
    /// - Parameters:
    ///   - host: The view controller that presents the dialog.
    ///   - title: The dialog's title.
    ///   - message: An optional line under the title.
    ///   - confirmTitle: Base title of the confirm button; while it counts, `strings.countdownConfirmTitleFormat` adds the seconds left.
    ///   - cancelTitle: Title of the cancel button; `nil` = the localized default.
    ///   - countdownSeconds: Seconds before confirm enables. Default 3.
    ///   - confirmRole: The confirm button's role; `.destructive` by default.
    ///   - style: Per-dialog style, layered over the theme's.
    ///   - onConfirm: Called when the user confirms.
    ///   - onCancel: Called when the user cancels.
    /// - Returns: A handle to query the countdown or dismiss the dialog.
    @discardableResult
    static func presentCountdownConfirmation(
        from host: UIViewController,
        title: String,
        message: String? = nil,
        confirmTitle: String,
        cancelTitle: String? = nil,
        countdownSeconds: Int = 3,
        confirmRole: LMKButton.Role = .destructive,
        style: CountdownStyle = CountdownStyle(),
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) -> LMKCountdownHandle {
        let dialog = LMKCountdownAlertViewController(
            title: title,
            message: message,
            confirmTitle: confirmTitle,
            cancelTitle: cancelTitle ?? strings.cancel,
            countdownSeconds: countdownSeconds,
            confirmRole: confirmRole,
            style: style,
            strings: strings,
            onConfirm: onConfirm,
            onCancel: onCancel
        )
        host.present(dialog, animated: true)
        return LMKCountdownHandle(controller: dialog)
    }
}

/// The countdown dialog. Hosts use `LMKAlert.presentCountdownConfirmation` and the handle.
final class LMKCountdownAlertViewController: UIViewController, LMKThemeApplying {
    let confirmTitle: String
    let countdownSeconds: Int
    private(set) var remainingSeconds: Int

    // Test hooks.
    var confirmDisplayedTitle: String { confirmButton.title ?? "" }
    var isConfirmEnabled: Bool { confirmButton.isEnabled }
    var cancelDisplayedTitle: String { cancelButton.title ?? "" }

    private let dialogTitle: String
    private let dialogMessage: String?
    private let cancelTitle: String
    private let confirmRole: LMKButton.Role
    private let style: LMKAlert.CountdownStyle
    private let strings: LMKAlert.Strings
    private let onConfirm: () -> Void
    private let onCancel: (() -> Void)?
    private var countdownTask: Task<Void, Never>?
    private var resolved = LMKAlert.CountdownStyle()
    private var isDismissing = false
    private var cardWidthConstraint: Constraint?
    private var buttonHeightConstraint: Constraint?
    private var contentInsetsConstraint: Constraint?

    let dimmingView = UIView()
    let cardView: UIView = LMKSurfaceView()
    let titleLabel = UILabel()
    let messageLabel = UILabel()
    let cancelButton = LMKButton(style: LMKButton.Style())
    let confirmButton = LMKButton(style: LMKButton.Style())
    /// Hosts the title and message, so a long message at a large text size scrolls inside
    /// the card instead of pushing the buttons off screen.
    let textScrollView = UIScrollView()
    private let textStack = UIStackView()
    private let buttonStack = UIStackView()
    private let containerStack = UIStackView()

    static let defaultCardWidth: CGFloat = 340
    static let defaultButtonHeight: CGFloat = 48
    private static let cardHorizontalInset: CGFloat = 32
    private static let cardVerticalInset: CGFloat = 16

    init(
        title: String,
        message: String?,
        confirmTitle: String,
        cancelTitle: String,
        countdownSeconds: Int,
        confirmRole: LMKButton.Role,
        style: LMKAlert.CountdownStyle,
        strings: LMKAlert.Strings,
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)?
    ) {
        dialogTitle = title
        dialogMessage = message
        self.confirmTitle = confirmTitle
        self.cancelTitle = cancelTitle
        self.countdownSeconds = max(0, countdownSeconds)
        remainingSeconds = max(0, countdownSeconds)
        self.confirmRole = confirmRole
        self.style = style
        self.strings = strings
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
        isModalInPresentation = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        countdownTask?.cancel()
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupViews()
        lmk_startApplyingTheme()
        startCountdown()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIAccessibility.post(notification: .screenChanged, argument: titleLabel)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        countdownTask?.cancel()
    }

    override var keyCommands: [UIKeyCommand]? {
        lmk_formKeyCommands(save: nil)
    }

    override func lmk_cancelFromKeyCommand() {
        handleCancel()
    }

    override func accessibilityPerformEscape() -> Bool {
        handleCancel()
        return true
    }

    // MARK: - Setup

    private func setupViews() {
        view.addSubview(dimmingView)
        dimmingView.snp.makeConstraints { $0.edges.equalToSuperview() }

        view.addSubview(cardView)
        cardView.accessibilityViewIsModal = true
        cardView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            // Preferred width; on narrow screens the required insets win so the card never overflows.
            cardWidthConstraint = make.width.equalTo(Self.defaultCardWidth).priority(.high).constraint
            make.leading.greaterThanOrEqualToSuperview().inset(Self.cardHorizontalInset)
            make.trailing.lessThanOrEqualToSuperview().inset(Self.cardHorizontalInset)
            make.top.greaterThanOrEqualTo(view.safeAreaLayoutGuide).inset(Self.cardVerticalInset)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).inset(Self.cardVerticalInset)
        }

        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.accessibilityTraits = .header
        titleLabel.text = dialogTitle
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        // The text is never squeezed: when the card is bounded, the scroll view gives way instead.
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        messageLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        if let dialogMessage, !dialogMessage.isEmpty {
            messageLabel.text = dialogMessage
        } else {
            messageLabel.isHidden = true
        }

        cancelButton.title = cancelTitle
        cancelButton.onTap = { [weak self] in self?.handleCancel() }
        confirmButton.title = countdownTitle(seconds: countdownSeconds)
        confirmButton.isEnabled = countdownSeconds <= 0
        confirmButton.accessibilityLabel = confirmTitle
        confirmButton.accessibilityValue = countdownSeconds > 0 ? LMKFormat.number(countdownSeconds) : nil
        confirmButton.onTap = { [weak self] in self?.handleConfirm() }

        textStack.axis = .vertical
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(messageLabel)
        textScrollView.alwaysBounceVertical = false
        textScrollView.addSubview(textStack)
        textStack.snp.makeConstraints { make in
            make.edges.equalTo(textScrollView.contentLayoutGuide)
            make.width.equalTo(textScrollView.frameLayoutGuide)
        }
        textScrollView.snp.makeConstraints { make in
            // The text shows in full whenever the card fits; the required card bounds win otherwise.
            make.height.equalTo(textScrollView.contentLayoutGuide).priority(.high)
        }

        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.addArrangedSubview(cancelButton)
        buttonStack.addArrangedSubview(confirmButton)
        buttonStack.snp.makeConstraints { make in
            buttonHeightConstraint = make.height.greaterThanOrEqualTo(Self.defaultButtonHeight).constraint
        }
        containerStack.axis = .vertical
        containerStack.addArrangedSubview(textScrollView)
        containerStack.addArrangedSubview(buttonStack)
        cardView.addSubview(containerStack)
        containerStack.snp.makeConstraints { make in
            contentInsetsConstraint = make.edges.equalToSuperview().inset(0).constraint
        }
    }

    // MARK: - Theme

    func applyTheme(_ theme: LMKTheme) {
        resolved = theme.countdownAlert.merging(style)
        dimmingView.backgroundColor = (resolved.dimmingColor ?? LMKColor.scrim).withAlphaComponent(resolved.dimmingAlpha ?? theme.alpha.large)
        let applied = cardView.lmk_apply(
            surface: resolved.surface,
            defaults: LMKSurfaceStyle(
                background: .solid(LMKColor.backgroundPrimary),
                corners: .fixed(theme.cornerRadius.xxl),
                border: .solid(LMKColor.divider, width: 1),
                shadow: .level(.level3),
                contentInsets: .lmk_all(theme.spacing.large)
            )
        )
        let insets = applied.contentInsets ?? .lmk_all(theme.spacing.large)
        contentInsetsConstraint?.update(inset: UIEdgeInsets(top: insets.top, left: insets.leading, bottom: insets.bottom, right: insets.trailing))
        cardWidthConstraint?.update(offset: resolved.cardWidth ?? Self.defaultCardWidth)
        buttonHeightConstraint?.update(offset: resolved.buttonHeight ?? Self.defaultButtonHeight)
        textStack.spacing = theme.spacing.small
        buttonStack.spacing = theme.spacing.medium
        containerStack.spacing = theme.spacing.large
        titleLabel.lmk_apply(resolved.titleTextStyle ?? .h3, color: resolved.titleColor ?? LMKColor.textPrimary)
        messageLabel.lmk_apply(resolved.messageTextStyle ?? .body, color: resolved.messageColor ?? LMKColor.textSecondary)
        cancelButton.style = LMKButton.Style(
            variant: .filled,
            surface: LMKSurfaceStyle(background: .solid(LMKColor.backgroundSecondary)),
            foregroundColor: LMKColor.textPrimary
        ).merging(resolved.cancelButton)
        confirmButton.style = LMKButton.Style.filled(confirmRole).merging(resolved.confirmButton)
    }

    // MARK: - Countdown

    private func countdownTitle(seconds: Int) -> String {
        guard seconds > 0 else { return confirmTitle }
        return String(format: strings.countdownConfirmTitleFormat, confirmTitle, seconds)
    }

    private func startCountdown() {
        guard countdownSeconds > 0 else { return }
        countdownTask = Task { [weak self] in
            guard let self else { return }
            for tick in stride(from: countdownSeconds - 1, through: 0, by: -1) {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                remainingSeconds = tick
                if tick > 0 {
                    confirmButton.title = countdownTitle(seconds: tick)
                    confirmButton.accessibilityValue = LMKFormat.number(tick)
                } else {
                    enableConfirm()
                }
            }
        }
    }

    private func enableConfirm() {
        confirmButton.title = confirmTitle
        confirmButton.accessibilityValue = nil
        confirmButton.isEnabled = true
        UIAccessibility.post(notification: .announcement, argument: confirmTitle)
    }

    // MARK: - Actions

    /// Cancels once: a second call while the dismissal runs is ignored.
    func handleCancel() {
        guard !isDismissing else { return }
        isDismissing = true
        countdownTask?.cancel()
        let handler = onCancel
        dismiss(animated: true) {
            handler?()
        }
    }

    private func handleConfirm() {
        guard !isDismissing else { return }
        isDismissing = true
        countdownTask?.cancel()
        let handler = onConfirm
        dismiss(animated: true) {
            handler()
        }
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for the countdown confirmation.
    var countdownAlert: LMKAlert.CountdownStyle {
        get { self[LMKAlert.CountdownStyle.self] }
        set { self[LMKAlert.CountdownStyle.self] = newValue }
    }
}
