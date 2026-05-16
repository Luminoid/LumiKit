//
//  LMKCountdownConfirmation.swift
//  LumiKit
//
//  Custom modal confirmation dialog where the destructive button is
//  disabled for a countdown period, preventing accidental taps on
//  critical actions. Drawn entirely in UIKit (no UIAlertController),
//  so the live title countdown and enable transition render identically
//  on iOS and Mac Catalyst.
//

import SnapKit
import UIKit

/// Presents a confirmation dialog with a timed countdown on the confirm button.
/// The confirm button is disabled for `countdownSeconds` and shows a live
/// countdown in its title. After the countdown completes, the button becomes
/// tappable.
public enum LMKCountdownConfirmation {
    /// Present a countdown confirmation dialog.
    /// - Parameters:
    ///   - viewController: The presenting view controller.
    ///   - title: Dialog title.
    ///   - message: Dialog message.
    ///   - confirmTitle: Base title for the confirm button (countdown appended while active).
    ///   - countdownSeconds: Seconds to wait before enabling confirm. Default is 3.
    ///   - onConfirm: Called when the user taps confirm after countdown.
    ///   - onCancel: Called when the user cancels.
    public static func present(
        on viewController: UIViewController,
        title: String,
        message: String? = nil,
        confirmTitle: String,
        countdownSeconds: Int = 3,
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        let dialog = LMKCountdownConfirmationViewController(
            title: title,
            message: message,
            confirmTitle: confirmTitle,
            countdownSeconds: countdownSeconds,
            onConfirm: onConfirm,
            onCancel: onCancel
        )
        viewController.present(dialog, animated: true)
    }
}

/// Custom modal view controller used by `LMKCountdownConfirmation`.
///
/// Public for testing only — host apps should call
/// `LMKCountdownConfirmation.present(...)` rather than instantiating
/// this type directly.
public final class LMKCountdownConfirmationViewController: UIViewController {
    // MARK: - Constants

    private enum Constants {
        static let cardWidth: CGFloat = 340
        static let cardHorizontalInset: CGFloat = 32
        static let dimmingAlpha: CGFloat = 0.5
    }

    // MARK: - Public State (read-only, for tests + accessibility)

    /// The base confirm title (without the countdown suffix).
    public let confirmTitle: String

    /// The configured countdown duration in seconds.
    public let countdownSeconds: Int

    /// The current text displayed on the confirm button.
    public var confirmDisplayedTitle: String {
        confirmButton.configuration?.title ?? ""
    }

    /// Whether the confirm button is currently tappable.
    public var isConfirmEnabled: Bool {
        confirmButton.isEnabled
    }

    /// The current text displayed on the cancel button.
    public var cancelDisplayedTitle: String {
        cancelButton.configuration?.title ?? ""
    }

    // MARK: - Private State

    private let dialogTitle: String
    private let dialogMessage: String?
    private let onConfirm: () -> Void
    private let onCancel: (() -> Void)?

    private var countdownTask: Task<Void, Never>?

    // MARK: - Subviews

    private lazy var dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(Constants.dimmingAlpha)
        return view
    }()

    private lazy var cardView: UIView = {
        let view = UIView()
        view.backgroundColor = LMKColor.backgroundPrimary
        view.layer.cornerRadius = LMKCornerRadius.large
        view.layer.cornerCurve = .continuous
        view.lmk_applyShadow(LMKShadow.card())
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = LMKTypography.h3
        label.textColor = LMKColor.textPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.font = LMKTypography.body
        label.textColor = LMKColor.textSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var cancelButton: LMKButton = {
        let button = LMKButton(
            title: LMKAlertPresenter.strings.cancel,
            style: .ghost(LMKColor.textPrimary)
        )
        // Match the filled confirm button's shape and padding so heights
        // align in the .fillEqually stack, but keep dark text on a soft
        // secondary fill (vs. the destructive red filled button).
        button.configuration?.background.backgroundColor = LMKColor.backgroundSecondary
        button.configuration?.cornerStyle = .capsule
        button.configuration?.contentInsets = NSDirectionalEdgeInsets(
            top: LMKSpacing.buttonPaddingVertical,
            leading: LMKSpacing.buttonPaddingHorizontal,
            bottom: LMKSpacing.buttonPaddingVertical,
            trailing: LMKSpacing.buttonPaddingHorizontal
        )
        button.tapHandler = { [weak self] in self?.handleCancel() }
        return button
    }()

    private lazy var confirmButton: LMKButton = {
        let initialTitle = countdownSeconds > 0
            ? "\(confirmTitle) (\(countdownSeconds))"
            : confirmTitle
        let button = LMKButton(
            title: initialTitle,
            style: .filled(LMKColor.error)
        )
        button.isEnabled = countdownSeconds <= 0
        button.alpha = countdownSeconds > 0 ? LMKAlpha.disabled : 1
        button.tapHandler = { [weak self] in self?.handleConfirm() }
        return button
    }()

    // MARK: - Init

    public init(
        title: String,
        message: String?,
        confirmTitle: String,
        countdownSeconds: Int,
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)?
    ) {
        dialogTitle = title
        dialogMessage = message
        self.confirmTitle = confirmTitle
        self.countdownSeconds = max(0, countdownSeconds)
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
        isModalInPresentation = true
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        countdownTask?.cancel()
    }

    // MARK: - Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupViews()
        titleLabel.text = dialogTitle
        if let dialogMessage, !dialogMessage.isEmpty {
            messageLabel.text = dialogMessage
        } else {
            messageLabel.isHidden = true
        }
        startCountdown()
    }

    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        countdownTask?.cancel()
    }

    // MARK: - Setup

    private func setupViews() {
        view.addSubview(dimmingView)
        dimmingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        view.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            // High-priority preferred width; on narrow screens the required
            // horizontal-inset constraints below override it so the card
            // never overflows the dimming overlay.
            make.width.equalTo(Constants.cardWidth).priority(.high)
            make.leading.greaterThanOrEqualToSuperview().inset(Constants.cardHorizontalInset)
            make.trailing.lessThanOrEqualToSuperview().inset(Constants.cardHorizontalInset)
        }

        let textStack = UIStackView(arrangedSubviews: [titleLabel, messageLabel])
        textStack.axis = .vertical
        textStack.spacing = LMKSpacing.small
        textStack.alignment = .fill

        let buttonStack = UIStackView(arrangedSubviews: [cancelButton, confirmButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = LMKSpacing.medium
        buttonStack.distribution = .fillEqually
        buttonStack.alignment = .fill

        let containerStack = UIStackView(arrangedSubviews: [textStack, buttonStack])
        containerStack.axis = .vertical
        containerStack.spacing = LMKSpacing.large
        containerStack.alignment = .fill

        cardView.addSubview(containerStack)
        containerStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(LMKSpacing.large)
        }
    }

    // MARK: - Countdown

    private func startCountdown() {
        guard countdownSeconds > 0 else { return }

        countdownTask = Task { [weak self] in
            guard let self else { return }
            let total = self.countdownSeconds
            for tick in stride(from: total - 1, through: 0, by: -1) {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                if tick > 0 {
                    self.setConfirmTitle("\(self.confirmTitle) (\(tick))")
                } else {
                    self.enableConfirm()
                }
            }
        }
    }

    private func setConfirmTitle(_ title: String) {
        confirmButton.configuration?.title = title
    }

    private func enableConfirm() {
        confirmButton.configuration?.title = confirmTitle
        confirmButton.isEnabled = true
        if LMKAnimationHelper.shouldAnimate {
            UIView.animate(withDuration: LMKAnimationHelper.Duration.uiShort) {
                self.confirmButton.alpha = 1
            }
        } else {
            confirmButton.alpha = 1
        }
    }

    // MARK: - Actions

    private func handleCancel() {
        countdownTask?.cancel()
        let cancelHandler = onCancel
        dismiss(animated: true) {
            cancelHandler?()
        }
    }

    private func handleConfirm() {
        countdownTask?.cancel()
        let confirmHandler = onConfirm
        dismiss(animated: true) {
            confirmHandler()
        }
    }
}
