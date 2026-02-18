//
//  LMKActionSheet.swift
//  LumiKit
//
//  Custom action sheet replacing UIAlertController(.actionSheet) with
//  design-token-driven styling and optional custom content views.
//

import SnapKit
import UIKit

/// Custom action sheet presented as a bottom sheet with design system styling.
///
/// Supports a list of actions with optional icons, destructive styling,
/// and an optional custom content view (e.g., date pickers).
///
/// Usage:
/// ```swift
/// LMKActionSheet.present(
///     in: self,
///     title: "Photo Actions",
///     actions: [
///         .init(title: "Edit", icon: UIImage(systemName: "pencil")) { ... },
///         .init(title: "Delete", style: .destructive) { ... }
///     ]
/// )
/// ```
public final class LMKActionSheet: UIViewController {
    // MARK: - Types

    /// Visual style for an action row.
    public enum ActionStyle {
        case `default`
        case destructive
    }

    /// A single action displayed as a tappable row in the sheet.
    public struct Action {
        public let title: String
        public let icon: UIImage?
        public let style: ActionStyle
        public let handler: () -> Void

        public init(
            title: String,
            style: ActionStyle = .default,
            icon: UIImage? = nil,
            handler: @escaping () -> Void
        ) {
            self.title = title
            self.style = style
            self.icon = icon
            self.handler = handler
        }
    }

    // MARK: - Properties

    private let titleText: String?
    private let messageText: String?
    private let sheetActions: [Action]
    private let customContentView: UIView?
    private let customContentHeight: CGFloat
    private let confirmText: String?
    private let confirmHandler: (() -> Void)?
    private let cancelText: String
    private let onDismiss: (() -> Void)?

    private var containerBottomConstraint: Constraint?
    private var actionRows: [ActionRowView] = []

    // MARK: - Lazy Views

    private lazy var dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = LMKColor.black.withAlphaComponent(LMKAlpha.dimmingOverlay)
        view.alpha = 0
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dimmingViewTapped)))
        return view
    }()

    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = LMKColor.backgroundPrimary
        view.layer.cornerRadius = LMKCornerRadius.large
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()

    private lazy var dragIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = LMKColor.divider
        view.layer.cornerRadius = LMKBottomSheetLayout.dragIndicatorCornerRadius
        return view
    }()

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = true
        sv.alwaysBounceVertical = false
        return sv
    }()

    private lazy var contentStackView: UIStackView = {
        UIStackView(lmk_axis: .vertical, spacing: 0)
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = LMKTypography.h3
        label.textColor = LMKColor.textPrimary
        label.numberOfLines = 0
        return label
    }()

    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.font = LMKTypography.caption
        label.textColor = LMKColor.textSecondary
        label.numberOfLines = 0
        return label
    }()

    private lazy var confirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(confirmText, for: .normal)
        button.titleLabel?.font = LMKTypography.bodyMedium
        button.setTitleColor(LMKColor.white, for: .normal)
        button.backgroundColor = LMKColor.primary
        button.layer.cornerRadius = LMKCornerRadius.medium
        button.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        return button
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(cancelText, for: .normal)
        button.titleLabel?.font = LMKTypography.bodyMedium
        button.setTitleColor(LMKColor.textPrimary, for: .normal)
        button.backgroundColor = LMKColor.backgroundSecondary
        button.layer.cornerRadius = LMKCornerRadius.medium
        button.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Initialization

    /// Create an action sheet with a list of actions.
    public init(
        title: String? = nil,
        message: String? = nil,
        actions: [Action],
        confirmTitle: String? = nil,
        onConfirm: (() -> Void)? = nil,
        cancelTitle: String? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.titleText = title
        self.messageText = message
        self.sheetActions = actions
        self.customContentView = nil
        self.customContentHeight = 0
        self.confirmText = confirmTitle
        self.confirmHandler = onConfirm
        self.cancelText = cancelTitle ?? LMKAlertPresenter.strings.cancel
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
    }

    /// Create an action sheet with custom content and actions.
    public init(
        title: String? = nil,
        message: String? = nil,
        contentView: UIView,
        contentHeight: CGFloat,
        actions: [Action],
        confirmTitle: String? = nil,
        onConfirm: (() -> Void)? = nil,
        cancelTitle: String? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.titleText = title
        self.messageText = message
        self.sheetActions = actions
        self.customContentView = contentView
        self.customContentHeight = contentHeight
        self.confirmText = confirmTitle
        self.confirmHandler = onConfirm
        self.cancelText = cancelTitle ?? LMKAlertPresenter.strings.cancel
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: LMKActionSheet, _: UITraitCollection) in
            self.refreshDynamicColors()
        }
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateIn()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .clear

        view.addSubview(dimmingView)
        dimmingView.snp.makeConstraints { make in make.edges.equalToSuperview() }

        view.addSubview(containerView)
        let screenHeight = view.window?.windowScene?.screen.bounds.height
            ?? LMKSceneUtil.getKeyWindow()?.screen.bounds.height
            ?? view.bounds.height
        let maxHeight = screenHeight * LMKBottomSheetLayout.maxScreenHeightRatio
        containerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.lessThanOrEqualTo(maxHeight)
            containerBottomConstraint = make.bottom.equalToSuperview().offset(maxHeight).constraint
        }

        containerView.addSubview(dragIndicator)
        dragIndicator.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(LMKSpacing.small)
            make.centerX.equalToSuperview()
            make.width.equalTo(LMKBottomSheetLayout.dragIndicatorWidth)
            make.height.equalTo(LMKBottomSheetLayout.dragIndicatorHeight)
        }

        containerView.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(LMKSpacing.xl)
            make.bottom.equalTo(containerView.safeAreaLayoutGuide.snp.bottom).inset(LMKSpacing.xl)
            make.height.equalTo(LMKBottomSheetLayout.buttonHeight)
        }

        let scrollBottomAnchor: ConstraintRelatableTarget
        if confirmText != nil {
            containerView.addSubview(confirmButton)
            confirmButton.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(LMKSpacing.xl)
                make.bottom.equalTo(cancelButton.snp.top).offset(-LMKSpacing.small)
                make.height.equalTo(LMKBottomSheetLayout.buttonHeight)
            }
            scrollBottomAnchor = confirmButton.snp.top
        } else {
            scrollBottomAnchor = cancelButton.snp.top
        }

        containerView.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(dragIndicator.snp.bottom).offset(LMKSpacing.large)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(scrollBottomAnchor).offset(-LMKSpacing.large)
        }

        scrollView.addSubview(contentStackView)
        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        scrollView.snp.makeConstraints { make in
            make.height.equalTo(contentStackView).priority(.high)
        }

        setupContent()
    }

    private func setupContent() {
        if let titleText {
            titleLabel.text = titleText
            let wrapper = makeInsetWrapper(for: titleLabel)
            contentStackView.addArrangedSubview(wrapper)
            contentStackView.setCustomSpacing(LMKSpacing.small, after: wrapper)
        }

        if let messageText {
            messageLabel.text = messageText
            let wrapper = makeInsetWrapper(for: messageLabel)
            contentStackView.addArrangedSubview(wrapper)
            contentStackView.setCustomSpacing(LMKSpacing.medium, after: wrapper)
        }

        if let customContentView {
            let wrapper = makeInsetWrapper(for: customContentView)
            customContentView.snp.makeConstraints { make in
                make.height.equalTo(customContentHeight)
            }
            contentStackView.addArrangedSubview(wrapper)
            contentStackView.setCustomSpacing(LMKSpacing.medium, after: wrapper)
        }

        for (index, action) in sheetActions.enumerated() {
            let row = ActionRowView(action: action)
            row.onTap = { [weak self] in self?.actionTapped(at: index) }
            actionRows.append(row)

            let wrapper = makeInsetWrapper(for: row)
            row.snp.makeConstraints { make in make.height.equalTo(LMKBottomSheetLayout.rowHeight - 2 * LMKSpacing.xs) }
            contentStackView.addArrangedSubview(wrapper)

            if index < sheetActions.count - 1 {
                contentStackView.setCustomSpacing(LMKSpacing.xs, after: wrapper)
            }
        }
    }

    private func makeInsetWrapper(for child: UIView) -> UIView {
        let wrapper = UIView()
        wrapper.addSubview(child)
        child.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(LMKSpacing.xl)
        }
        return wrapper
    }

    // MARK: - Dynamic Colors

    private func refreshDynamicColors() {
        dimmingView.backgroundColor = LMKColor.black.withAlphaComponent(LMKAlpha.dimmingOverlay)
        containerView.backgroundColor = LMKColor.backgroundPrimary
        dragIndicator.backgroundColor = LMKColor.divider
        titleLabel.textColor = LMKColor.textPrimary
        messageLabel.textColor = LMKColor.textSecondary
        if confirmText != nil {
            confirmButton.setTitleColor(LMKColor.white, for: .normal)
            confirmButton.backgroundColor = LMKColor.primary
        }
        cancelButton.setTitleColor(LMKColor.textPrimary, for: .normal)
        cancelButton.backgroundColor = LMKColor.backgroundSecondary
        for row in actionRows {
            row.refreshColors()
        }
    }

    // MARK: - Animation

    private func animateIn() {
        containerBottomConstraint?.update(offset: 0)
        let duration = LMKAnimationHelper.shouldAnimate ? LMKAnimationHelper.Duration.modalPresentation : 0
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut) {
            self.view.layoutIfNeeded()
            self.dimmingView.alpha = 1
        }
    }

    private func animateOut(completion: @escaping () -> Void) {
        containerBottomConstraint?.update(offset: containerView.frame.height)
        let duration = LMKAnimationHelper.shouldAnimate ? LMKAnimationHelper.Duration.actionSheet : 0
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseIn) {
            self.view.layoutIfNeeded()
            self.dimmingView.alpha = 0
        } completion: { _ in completion() }
    }

    // MARK: - Actions

    @objc private func confirmTapped() {
        let handler = confirmHandler
        dismissSheet()
        handler?()
    }

    @objc private func cancelTapped() {
        onDismiss?()
        dismissSheet()
    }

    @objc private func dimmingViewTapped() {
        onDismiss?()
        dismissSheet()
    }

    private func actionTapped(at index: Int) {
        let action = sheetActions[index]
        dismissSheet()
        action.handler()
    }

    // MARK: - Dismissal

    private func dismissSheet() {
        animateOut { [weak self] in
            guard let self else { return }
            self.willMove(toParent: nil)
            self.view.removeFromSuperview()
            self.removeFromParent()
        }
    }

    // MARK: - Static Convenience

    /// Present an action sheet with a list of actions.
    public static func present(
        in viewController: UIViewController,
        title: String? = nil,
        message: String? = nil,
        actions: [Action],
        confirmTitle: String? = nil,
        onConfirm: (() -> Void)? = nil,
        cancelTitle: String? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        let sheet = LMKActionSheet(
            title: title,
            message: message,
            actions: actions,
            confirmTitle: confirmTitle,
            onConfirm: onConfirm,
            cancelTitle: cancelTitle,
            onDismiss: onDismiss
        )
        addAsChild(sheet, in: viewController)
    }

    /// Present an action sheet with custom content and actions.
    public static func present(
        in viewController: UIViewController,
        title: String? = nil,
        message: String? = nil,
        contentView: UIView,
        contentHeight: CGFloat,
        actions: [Action] = [],
        confirmTitle: String? = nil,
        onConfirm: (() -> Void)? = nil,
        cancelTitle: String? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        let sheet = LMKActionSheet(
            title: title,
            message: message,
            contentView: contentView,
            contentHeight: contentHeight,
            actions: actions,
            confirmTitle: confirmTitle,
            onConfirm: onConfirm,
            cancelTitle: cancelTitle,
            onDismiss: onDismiss
        )
        addAsChild(sheet, in: viewController)
    }

    private static func addAsChild(_ sheet: LMKActionSheet, in parent: UIViewController) {
        parent.addChild(sheet)
        sheet.view.frame = parent.view.bounds
        sheet.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        parent.view.addSubview(sheet.view)
        sheet.didMove(toParent: parent)
    }
}

// MARK: - Action Row View

private final class ActionRowView: UIControl {
    private let action: LMKActionSheet.Action

    var onTap: (() -> Void)?

    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = LMKColor.backgroundSecondary
        view.layer.cornerRadius = LMKCornerRadius.small
        view.isUserInteractionEnabled = false
        return view
    }()

    private lazy var iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = action.style == .destructive ? LMKColor.error : LMKColor.primary
        return iv
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = action.title
        label.font = LMKTypography.body
        label.textColor = action.style == .destructive ? LMKColor.error : LMKColor.textPrimary
        return label
    }()

    init(action: LMKActionSheet.Action) {
        self.action = action
        super.init(frame: .zero)
        setupUI()
        setupAccessibility()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        addSubview(containerView)
        containerView.snp.makeConstraints { make in make.edges.equalToSuperview() }

        let hasIcon = action.icon != nil
        containerView.addSubview(iconImageView)
        iconImageView.isHidden = !hasIcon
        iconImageView.image = action.icon
        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(LMKSpacing.large)
            make.centerY.equalToSuperview()
            make.width.equalTo(hasIcon ? LMKLayout.iconMedium : 0)
            make.height.equalTo(LMKLayout.iconMedium)
        }

        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            if hasIcon {
                make.leading.equalTo(iconImageView.snp.trailing).offset(LMKSpacing.medium)
            } else {
                make.leading.equalToSuperview().offset(LMKSpacing.large)
            }
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview().inset(LMKSpacing.large)
        }

        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    private func setupAccessibility() {
        isAccessibilityElement = true
        accessibilityLabel = action.title
        accessibilityTraits = .button
    }

    func refreshColors() {
        let isDestructive = action.style == .destructive
        containerView.backgroundColor = LMKColor.backgroundSecondary
        iconImageView.tintColor = isDestructive ? LMKColor.error : LMKColor.primary
        titleLabel.textColor = isDestructive ? LMKColor.error : LMKColor.textPrimary
    }

    override var isHighlighted: Bool {
        didSet {
            let duration = LMKAnimationHelper.shouldAnimate ? LMKAnimationHelper.Duration.uiShort : 0
            UIView.animate(withDuration: duration) {
                self.containerView.backgroundColor = self.isHighlighted
                    ? LMKColor.primary.withAlphaComponent(LMKAlpha.overlayMedium)
                    : LMKColor.backgroundSecondary
            }
        }
    }

    @objc private func tapped() {
        onTap?()
    }
}
