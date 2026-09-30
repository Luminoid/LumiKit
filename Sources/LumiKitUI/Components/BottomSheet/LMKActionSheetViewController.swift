//
//  LMKActionSheetViewController.swift
//  LumiKit
//
//  The action sheet's view controller: renders a page (title, message, custom
//  content, rows, confirm button) inside the bottom sheet chrome and slides
//  between sub-pages.
//

import SnapKit
import UIKit

/// The bottom sheet behind `LMKActionSheet.present(_:from:)`.
///
/// Hosts keep the returned controller to `dismiss()` it early or to update it; the
/// namespace's `current(in:)` finds one already on screen.
public final class LMKActionSheetViewController: LMKBottomSheetViewController {
    // MARK: - Properties

    public let configuration: LMKActionSheet.Configuration

    /// The page on screen (the root until an action pushes a sub-page).
    public private(set) var currentPage: LMKActionSheet.Page

    /// Whether a sub-page is showing.
    public var canGoBack: Bool { !pageStack.isEmpty }

    public let backButton = LMKButton(style: .iconOnly())
    public let contentContainerView = UIView()
    /// The rows of the current page, in order.
    public private(set) var currentRows: [LMKActionSheetRowView] = []
    /// The confirm button of the current page, when it has one.
    public private(set) var confirmButton: LMKButton?

    /// The action sheet style last resolved against the theme.
    public private(set) var resolvedActionSheetStyle = LMKActionSheet.Style()

    private var pageStack: [LMKActionSheet.Page] = []
    private var currentPageView: UIView?
    private var isTransitioning = false
    private var pendingHandler: (() -> Void)?
    private var isApplyingTheme = false
    private var contentTopConstraint: Constraint?
    private var backButtonSizeConstraint: Constraint?

    // MARK: - Initialization

    public init(configuration: LMKActionSheet.Configuration) {
        self.configuration = configuration
        self.currentPage = configuration.rootPage
        super.init(style: configuration.style.sheet)
    }

    // MARK: - Sheet content

    override public func setupSheetContent() {
        backButton.isHidden = true
        backButton.accessibilityLabel = configuration.strings.back
        backButton.onTap = { [weak self] in self?.goBack() }
        containerView.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.top.equalTo(dragIndicator.snp.bottom).offset(LMKSpacing.xs)
            make.leading.equalToSuperview().offset(LMKSpacing.small)
            backButtonSizeConstraint = make.width.height.equalTo(LMKLayout.minimumTouchTarget).constraint
        }

        contentContainerView.clipsToBounds = true
        containerView.addSubview(contentContainerView)
        contentContainerView.snp.makeConstraints { make in
            contentTopConstraint = make.top.equalTo(contentLayoutGuide.snp.top).offset(0).constraint
            make.leading.trailing.bottom.equalTo(contentLayoutGuide)
        }

        render(currentPage, direction: .none, animated: false)
    }

    // MARK: - Theme

    override public func applyTheme(_ theme: LMKTheme) {
        resolvedActionSheetStyle = theme.actionSheet.merging(configuration.style)
        // The sheet chrome resolves theme.bottomSheet <- theme.actionSheet.sheet <- configuration.style.sheet.
        let sheetStyle = theme.actionSheet.sheet.merging(configuration.style.sheet)
        if style != sheetStyle, !isApplyingTheme {
            isApplyingTheme = true
            style = sheetStyle
            isApplyingTheme = false
        }
        super.applyTheme(theme)

        backButton.style = LMKButton.Style(variant: .ghost, surface: LMKSurfaceStyle(corners: .circle), pressAnimation: false, haptics: false)
            .merging(resolvedActionSheetStyle.backButton)
        backButton.setSymbol("chevron.backward", pointSize: theme.layout.symbolProminent, weight: .medium)
        backButtonSizeConstraint?.update(offset: theme.layout.minimumTouchTarget)
        confirmButton?.style = confirmButtonStyle()
        for row in currentRows {
            row.style = resolvedActionSheetStyle.row
        }
        updateContentTop()
    }

    private func confirmButtonStyle() -> LMKButton.Style {
        LMKButton.Style(variant: .filled, minimumHeight: Self.defaultButtonHeight).merging(resolvedActionSheetStyle.confirmButton)
    }

    // MARK: - Navigation

    /// Pushes `page` with a forward slide.
    public func navigate(to page: LMKActionSheet.Page) {
        guard !isTransitioning else { return }
        pageStack.append(currentPage)
        currentPage = page
        render(page, direction: .forward, animated: true)
    }

    /// Pops to the previous page with a backward slide.
    public func goBack() {
        guard !isTransitioning, let previous = pageStack.popLast() else { return }
        currentPage = previous
        render(previous, direction: .backward, animated: true)
    }

    // MARK: - Dismissal

    override public func didDismiss(reason: DismissReason) {
        super.didDismiss(reason: reason)
        let handler = pendingHandler
        pendingHandler = nil
        if reason == .programmatic {
            handler?()
        } else {
            configuration.onCancel?()
        }
    }

    // MARK: - Rendering

    private func render(_ page: LMKActionSheet.Page, direction: LMKPageTransition.Direction, animated: Bool) {
        let built = buildPageView(for: page)
        currentRows = built.rows
        confirmButton = built.confirmButton
        let oldView = currentPageView
        currentPageView = built.view
        backButton.isHidden = pageStack.isEmpty
        updateContentTop()

        isTransitioning = true
        settleInFlightAnimation()
        LMKPageTransition.run(
            in: contentContainerView,
            from: oldView,
            to: built.view,
            direction: direction,
            duration: resolvedActionSheetStyle.pageTransitionDuration ?? LMKAnimation.Duration.normal,
            animated: animated,
            layoutRoot: view
        ) { [weak self] in
            self?.isTransitioning = false
        }
        if pageStack.isEmpty == false || direction != .none {
            UIAccessibility.post(notification: .screenChanged, argument: built.titleLabel ?? built.rows.first)
        }
    }

    private func updateContentTop() {
        let theme = traitCollection.lmkTheme
        let gap = theme.spacing.xs * 2 + theme.layout.minimumTouchTarget
        let insetTop = resolvedStyle.surface.contentInsets?.top ?? theme.spacing.large
        // The content guide already sits `insetTop` below the drag indicator; with a back
        // button showing, push the content past the button instead.
        contentTopConstraint?.update(offset: pageStack.isEmpty ? 0 : max(0, gap - insetTop))
    }

    private struct PageView {
        let view: UIView
        let rows: [LMKActionSheetRowView]
        let confirmButton: LMKButton?
        let titleLabel: UILabel?
    }

    private func buildPageView(for page: LMKActionSheet.Page) -> PageView {
        let theme = traitCollection.lmkTheme
        let resolved = resolvedActionSheetStyle
        let sectionSpacing = resolved.sectionSpacing ?? theme.spacing.medium
        let rowSpacing = resolved.rowSpacing ?? theme.spacing.xs
        let horizontalInset = resolvedStyle.surface.contentInsets?.leading ?? theme.spacing.xl

        let wrapper = UIView()
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = false
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        scrollView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        var titleLabel: UILabel?
        if let title = page.title {
            let label = UILabel.lmk_make(resolved.titleTextStyle ?? .h3, text: title, color: resolved.titleColor ?? LMKColor.textPrimary)
            label.accessibilityTraits = .header
            titleLabel = label
            let insetLabel = inset(label, by: horizontalInset)
            stack.addArrangedSubview(insetLabel)
            stack.setCustomSpacing(theme.spacing.small, after: insetLabel)
        }
        if let message = page.message {
            let label = UILabel.lmk_make(resolved.messageTextStyle ?? .caption, text: message, color: resolved.messageColor ?? LMKColor.textSecondary)
            let insetLabel = inset(label, by: horizontalInset)
            stack.addArrangedSubview(insetLabel)
            stack.setCustomSpacing(sectionSpacing, after: insetLabel)
        }
        if let contentView = page.contentView {
            contentView.removeFromSuperview()
            let insetContent = inset(contentView, by: horizontalInset)
            stack.addArrangedSubview(insetContent)
            stack.setCustomSpacing(sectionSpacing, after: insetContent)
        }

        var rows: [LMKActionSheetRowView] = []
        for (index, action) in page.actions.enumerated() {
            let row = LMKActionSheetRowView(style: resolved.row)
            row.strings = configuration.strings
            row.configure(action)
            row.onTap = { [weak self] in self?.actionTapped(at: index) }
            rows.append(row)
            let insetRow = inset(row, by: horizontalInset)
            stack.addArrangedSubview(insetRow)
            if index < page.actions.count - 1 {
                stack.setCustomSpacing(rowSpacing, after: insetRow)
            }
        }

        wrapper.addSubview(scrollView)
        var confirmButton: LMKButton?
        if let confirmTitle = page.confirmTitle {
            let button = LMKButton(title: confirmTitle, style: confirmButtonStyle())
            button.onTap = { [weak self] in self?.confirmTapped() }
            wrapper.addSubview(button)
            button.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(horizontalInset)
                make.bottom.equalToSuperview()
            }
            scrollView.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview()
                make.bottom.equalTo(button.snp.top).offset(-theme.spacing.small)
            }
            confirmButton = button
        } else {
            scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        }
        // Hug the content below the labels' compression resistance: at the height cap the
        // solver must break this, not crush every title toward zero.
        scrollView.snp.makeConstraints { make in
            make.height.equalTo(stack).priority(.medium)
        }
        return PageView(view: wrapper, rows: rows, confirmButton: confirmButton, titleLabel: titleLabel)
    }

    private func inset(_ child: UIView, by horizontalInset: CGFloat) -> UIView {
        let wrapper = UIView()
        wrapper.addSubview(child)
        child.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(horizontalInset)
        }
        return wrapper
    }

    // MARK: - Actions

    func actionTapped(at index: Int) {
        guard let action = currentPage.actions[lmk_safe: index], action.isEnabled else { return }
        if let page = action.page {
            navigate(to: page)
        } else {
            pendingHandler = action.handler
            dismiss(reason: .programmatic)
        }
    }

    func confirmTapped() {
        pendingHandler = currentPage.onConfirm
        dismiss(reason: .programmatic)
    }
}
