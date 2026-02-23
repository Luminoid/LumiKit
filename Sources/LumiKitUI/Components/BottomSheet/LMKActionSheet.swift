//
//  LMKActionSheet.swift
//  LumiKit
//
//  Custom action sheet replacing UIAlertController(.actionSheet) with
//  design-token-driven styling, optional custom content views, and
//  multi-level in-sheet navigation.
//

import SnapKit
import UIKit

/// Custom action sheet presented as a bottom sheet with design system styling.
///
/// Supports a list of actions with optional icons, destructive styling,
/// an optional custom content view (e.g., date pickers), and multi-level
/// navigation where tapping an action can push a sub-page within the sheet.
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
///
/// Multi-level usage:
/// ```swift
/// LMKActionSheet.present(
///     in: self,
///     title: "Photo Actions",
///     actions: [
///         .init(title: "Edit Category", icon: UIImage(systemName: "tag"), page: .init(
///             title: "Select Category",
///             actions: categories.map { cat in .init(title: cat.name) { select(cat) } }
///         )),
///         .init(title: "Delete", style: .destructive) { delete() }
///     ]
/// )
/// ```
public final class LMKActionSheet: LMKBottomSheetController {
    // MARK: - Types

    /// Visual style for an action row.
    public enum ActionStyle {
        case `default`
        case destructive
    }

    /// A page of content within the action sheet. Used for multi-level navigation.
    public struct Page {
        public let title: String?
        public let message: String?
        public let actions: [Action]
        public let contentView: UIView?
        public let contentHeight: CGFloat
        public let confirmTitle: String?
        public let onConfirm: (() -> Void)?

        public init(
            title: String? = nil,
            message: String? = nil,
            actions: [Action] = [],
            contentView: UIView? = nil,
            contentHeight: CGFloat = 0,
            confirmTitle: String? = nil,
            onConfirm: (() -> Void)? = nil
        ) {
            self.title = title
            self.message = message
            self.actions = actions
            self.contentView = contentView
            self.contentHeight = contentHeight
            self.confirmTitle = confirmTitle
            self.onConfirm = onConfirm
        }
    }

    /// A single action displayed as a tappable row in the sheet.
    public struct Action {
        public let title: String
        public let subtitle: String?
        public let icon: UIImage?
        public let style: ActionStyle
        public let handler: () -> Void
        public let page: Page?

        /// Create a regular action that dismisses the sheet when tapped.
        public init(
            title: String,
            subtitle: String? = nil,
            style: ActionStyle = .default,
            icon: UIImage? = nil,
            handler: @escaping () -> Void
        ) {
            self.title = title
            self.subtitle = subtitle
            self.style = style
            self.icon = icon
            self.handler = handler
            self.page = nil
        }

        /// Create a navigation action that pushes a sub-page within the sheet.
        public init(
            title: String,
            subtitle: String? = nil,
            style: ActionStyle = .default,
            icon: UIImage? = nil,
            page: Page
        ) {
            self.title = title
            self.subtitle = subtitle
            self.style = style
            self.icon = icon
            self.handler = {}
            self.page = page
        }
    }

    /// Configurable strings for the action sheet.
    public nonisolated struct Strings: Sendable {
        public var back: String

        public init(back: String = "Back") {
            self.back = back
        }
    }

    // MARK: - Configurable Strings

    /// Configurable strings for the action sheet. Set before presenting.
    public nonisolated(unsafe) static var strings = Strings()

    // MARK: - Navigation Types

    private enum NavigationDirection {
        case forward
        case backward
        case none
    }

    private struct PageContentViews {
        let wrapper: UIView
        let actionRows: [ActionRowView]
    }

    // MARK: - Properties

    private let onDismissCallback: (() -> Void)?
    private var currentPage: Page
    private var navigationStack: [Page] = []
    private var currentPageViews: PageContentViews?
    private var currentActionRows: [ActionRowView] = []
    private var currentConfirmHandler: (() -> Void)?
    private var isTransitioning = false
    private var contentContainerTopConstraint: Constraint?

    // MARK: - Lazy Views

    private lazy var contentContainerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()

    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = LMKColor.primary
        button.isHidden = true
        button.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        button.accessibilityLabel = Self.strings.back
        button.accessibilityTraits = .button
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
        self.onDismissCallback = onDismiss
        self.currentPage = Page(
            title: title,
            message: message,
            actions: actions,
            confirmTitle: confirmTitle,
            onConfirm: onConfirm
        )
        super.init(cancelTitle: cancelTitle)
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
        self.onDismissCallback = onDismiss
        self.currentPage = Page(
            title: title,
            message: message,
            actions: actions,
            contentView: contentView,
            contentHeight: contentHeight,
            confirmTitle: confirmTitle,
            onConfirm: onConfirm
        )
        super.init(cancelTitle: cancelTitle)
    }

    // MARK: - Sheet Content

    override public func setupSheetContent() {
        containerView.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.top.equalTo(dragIndicator.snp.bottom).offset(LMKSpacing.xs)
            make.leading.equalToSuperview().offset(LMKSpacing.small)
            make.width.height.equalTo(LMKBottomSheetLayout.backButtonHeight)
        }

        containerView.addSubview(contentContainerView)
        contentContainerView.snp.makeConstraints { make in
            contentContainerTopConstraint = make.top
                .equalTo(dragIndicator.snp.bottom)
                .offset(LMKSpacing.large)
                .constraint
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(cancelButton.snp.top).offset(-LMKSpacing.large)
        }

        renderPage(currentPage, animated: false, direction: .none)
    }

    // MARK: - Page Rendering

    private func buildPageContent(for page: Page) -> PageContentViews {
        let wrapper = UIView()
        var actionRows: [ActionRowView] = []

        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = false

        let contentStackView = UIStackView(lmk_axis: .vertical, spacing: 0)

        scrollView.addSubview(contentStackView)
        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        if let title = page.title {
            let label = UILabel()
            label.text = title
            label.font = LMKTypography.h3
            label.textColor = LMKColor.textPrimary
            label.numberOfLines = 0
            let w = makeInsetWrapper(for: label)
            contentStackView.addArrangedSubview(w)
            contentStackView.setCustomSpacing(LMKSpacing.small, after: w)
        }

        if let message = page.message {
            let label = UILabel()
            label.text = message
            label.font = LMKTypography.caption
            label.textColor = LMKColor.textSecondary
            label.numberOfLines = 0
            let w = makeInsetWrapper(for: label)
            contentStackView.addArrangedSubview(w)
            contentStackView.setCustomSpacing(LMKSpacing.medium, after: w)
        }

        if let contentView = page.contentView {
            contentView.removeFromSuperview()
            let w = makeInsetWrapper(for: contentView)
            contentView.snp.makeConstraints { make in
                make.height.equalTo(page.contentHeight)
            }
            contentStackView.addArrangedSubview(w)
            contentStackView.setCustomSpacing(LMKSpacing.medium, after: w)
        }

        for (index, action) in page.actions.enumerated() {
            let row = ActionRowView(action: action)
            row.onTap = { [weak self] in self?.actionTapped(at: index) }
            actionRows.append(row)

            let w = makeInsetWrapper(for: row)
            let baseHeight = LMKBottomSheetLayout.rowHeight - 2 * LMKSpacing.xs
            row.snp.makeConstraints { make in
                if action.subtitle != nil {
                    make.height.greaterThanOrEqualTo(baseHeight)
                } else {
                    make.height.equalTo(baseHeight)
                }
            }
            contentStackView.addArrangedSubview(w)

            if index < page.actions.count - 1 {
                contentStackView.setCustomSpacing(LMKSpacing.xs, after: w)
            }
        }

        // Layout in wrapper
        wrapper.addSubview(scrollView)

        if let confirmTitle = page.confirmTitle {
            let confirmBtn = UIButton(type: .system)
            confirmBtn.setTitle(confirmTitle, for: .normal)
            confirmBtn.titleLabel?.font = LMKTypography.bodyMedium
            confirmBtn.setTitleColor(LMKColor.white, for: .normal)
            confirmBtn.backgroundColor = LMKColor.primary
            confirmBtn.layer.cornerRadius = LMKCornerRadius.medium
            confirmBtn.addTarget(self, action: #selector(pageConfirmTapped), for: .touchUpInside)

            wrapper.addSubview(confirmBtn)
            confirmBtn.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(LMKSpacing.xl)
                make.bottom.equalToSuperview()
                make.height.equalTo(LMKBottomSheetLayout.buttonHeight)
            }
            scrollView.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview()
                make.bottom.equalTo(confirmBtn.snp.top).offset(-LMKSpacing.small)
            }
        } else {
            scrollView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }

        scrollView.snp.makeConstraints { make in
            make.height.equalTo(contentStackView).priority(.high)
        }

        return PageContentViews(wrapper: wrapper, actionRows: actionRows)
    }

    private func renderPage(_ page: Page, animated: Bool, direction: NavigationDirection) {
        let oldPageViews = currentPageViews
        let newPageViews = buildPageContent(for: page)

        currentPageViews = newPageViews
        currentConfirmHandler = page.onConfirm
        currentActionRows = newPageViews.actionRows

        let showBack = !navigationStack.isEmpty

        if !animated || direction == .none {
            oldPageViews?.wrapper.removeFromSuperview()

            contentContainerView.addSubview(newPageViews.wrapper)
            newPageViews.wrapper.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            backButton.isHidden = !showBack
            updateContentContainerTop(showBack: showBack)
            return
        }

        guard let oldWrapper = oldPageViews?.wrapper else {
            contentContainerView.addSubview(newPageViews.wrapper)
            newPageViews.wrapper.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            backButton.isHidden = !showBack
            updateContentContainerTop(showBack: showBack)
            return
        }

        isTransitioning = true

        // Convert old wrapper to manual frame (remove auto layout)
        let oldFrame = oldWrapper.frame
        oldWrapper.snp.removeConstraints()
        oldWrapper.translatesAutoresizingMaskIntoConstraints = true
        oldWrapper.frame = oldFrame

        // Add new wrapper with auto layout
        contentContainerView.addSubview(newPageViews.wrapper)
        newPageViews.wrapper.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Position new wrapper off-screen
        let containerWidth = max(contentContainerView.bounds.width, 1)
        let slideIn = direction == .forward ? containerWidth : -containerWidth
        newPageViews.wrapper.transform = CGAffineTransform(translationX: slideIn, y: 0)

        // Update back button and top constraint
        backButton.isHidden = !showBack
        updateContentContainerTop(showBack: showBack)

        let duration = LMKAnimationHelper.shouldAnimate
            ? LMKAnimationHelper.Duration.actionSheet
            : 0

        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut) {
            oldWrapper.transform = CGAffineTransform(translationX: -slideIn, y: 0)
            oldWrapper.alpha = 0
            newPageViews.wrapper.transform = .identity
            self.containerView.superview?.layoutIfNeeded()
        } completion: { _ in
            oldWrapper.removeFromSuperview()
            self.isTransitioning = false
        }
    }

    private func updateContentContainerTop(showBack: Bool) {
        let topOffset = showBack
            ? LMKSpacing.xs + LMKBottomSheetLayout.backButtonHeight + LMKSpacing.xs
            : LMKSpacing.large
        contentContainerTopConstraint?.update(offset: topOffset)
    }

    // MARK: - Navigation

    private func navigateToPage(_ page: Page) {
        guard !isTransitioning else { return }
        navigationStack.append(currentPage)
        currentPage = page
        renderPage(page, animated: true, direction: .forward)
    }

    private func navigateBack() {
        guard !isTransitioning, let previousPage = navigationStack.popLast() else { return }
        currentPage = previousPage
        renderPage(previousPage, animated: true, direction: .backward)
    }

    // MARK: - Dynamic Colors

    override public func refreshSheetColors() {
        backButton.tintColor = LMKColor.primary
        for row in currentActionRows {
            row.refreshColors()
        }
    }

    // MARK: - Actions

    override public func onDismissTapped() {
        onDismissCallback?()
        dismissSheet()
    }

    @objc private func backTapped() {
        navigateBack()
    }

    @objc private func pageConfirmTapped() {
        let handler = currentConfirmHandler
        dismissSheet()
        handler?()
    }

    private func actionTapped(at index: Int) {
        guard index < currentPage.actions.count else { return }
        let action = currentPage.actions[index]

        if let page = action.page {
            navigateToPage(page)
        } else {
            dismissSheet()
            action.handler()
        }
    }

    // MARK: - Helpers

    private func makeInsetWrapper(for child: UIView) -> UIView {
        let wrapper = UIView()
        wrapper.addSubview(child)
        child.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(LMKSpacing.xl)
        }
        return wrapper
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
}

// MARK: - Action Row View

final class ActionRowView: UIControl {
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

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = LMKTypography.caption
        label.textColor = LMKColor.textSecondary
        label.numberOfLines = 2
        return label
    }()

    private lazy var chevronImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "chevron.right")
        iv.tintColor = LMKColor.textSecondary
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
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
        let hasSubtitle = action.subtitle != nil
        let hasChevron = action.page != nil

        containerView.addSubview(iconImageView)
        iconImageView.isHidden = !hasIcon
        iconImageView.image = action.icon
        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(LMKSpacing.large)
            make.centerY.equalToSuperview()
            make.width.equalTo(hasIcon ? LMKLayout.iconMedium : 0)
            make.height.equalTo(LMKLayout.iconMedium)
        }

        containerView.addSubview(chevronImageView)
        chevronImageView.isHidden = !hasChevron
        chevronImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(LMKSpacing.large)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(LMKLayout.iconSmall)
        }

        let textLeading: ConstraintRelatableTarget = hasIcon
            ? iconImageView.snp.trailing
            : containerView.snp.leading
        let textLeadingOffset = hasIcon ? LMKSpacing.medium : LMKSpacing.large

        let textTrailing: ConstraintRelatableTarget = hasChevron
            ? chevronImageView.snp.leading
            : containerView.snp.trailing
        let textTrailingOffset = hasChevron ? -LMKSpacing.small : -LMKSpacing.large

        if hasSubtitle {
            subtitleLabel.text = action.subtitle
            containerView.addSubview(titleLabel)
            containerView.addSubview(subtitleLabel)

            titleLabel.snp.makeConstraints { make in
                make.leading.equalTo(textLeading).offset(textLeadingOffset)
                make.trailing.lessThanOrEqualTo(textTrailing).offset(textTrailingOffset)
                make.top.equalToSuperview().offset(LMKSpacing.medium)
            }
            subtitleLabel.snp.makeConstraints { make in
                make.leading.equalTo(titleLabel)
                make.trailing.lessThanOrEqualTo(textTrailing).offset(textTrailingOffset)
                make.top.equalTo(titleLabel.snp.bottom).offset(LMKSpacing.xs)
                make.bottom.equalToSuperview().offset(-LMKSpacing.medium)
            }
        } else {
            containerView.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.leading.equalTo(textLeading).offset(textLeadingOffset)
                make.centerY.equalToSuperview()
                make.trailing.lessThanOrEqualTo(textTrailing).offset(textTrailingOffset)
            }
        }

        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    private func setupAccessibility() {
        isAccessibilityElement = true
        accessibilityLabel = if let subtitle = action.subtitle {
            "\(action.title), \(subtitle)"
        } else {
            action.title
        }
        accessibilityTraits = .button
        if action.page != nil {
            accessibilityHint = "Opens submenu"
        }
    }

    func refreshColors() {
        let isDestructive = action.style == .destructive
        containerView.backgroundColor = LMKColor.backgroundSecondary
        iconImageView.tintColor = isDestructive ? LMKColor.error : LMKColor.primary
        titleLabel.textColor = isDestructive ? LMKColor.error : LMKColor.textPrimary
        subtitleLabel.textColor = LMKColor.textSecondary
        chevronImageView.tintColor = LMKColor.textSecondary
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
