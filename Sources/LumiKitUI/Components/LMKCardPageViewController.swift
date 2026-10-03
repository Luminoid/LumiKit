//
//  LMKCardPageViewController.swift
//  LumiKit
//
//  Base class for pages inside a card or panel: a header with leading and
//  trailing items, a centered title, an optional drag indicator and separator,
//  and multi-page content navigation with slide animations, styled from
//  `theme.cardPage`.
//

import SnapKit
import UIKit

/// Base class for card-embedded pages with design-token styling.
///
/// The header shows `leadingItem` (a back chevron by default), the title, and
/// `trailingItem` (none by default). Items render as a glyph in a circle or as a
/// titled capsule, honor their `role` and `badge`, and the leading button always
/// pops while content is stacked. Subclasses override `setupContent()` to build
/// their content in `contentContainerView`; `pushContentView(_:title:)` and
/// `popContentView()` slide between content views.
///
/// ```swift
/// final class SettingsPage: LMKCardPageViewController {
///     init() {
///         super.init(title: "Settings")
///         trailingItem = .init(systemName: "xmark") { [weak self] in self?.lmk_cardPanel?.dismiss() }
///         style.showsHeaderSeparator = true
///         style.showsDragIndicator = true   // in a sheet the user can drag down
///     }
///
///     override func setupContent() { ... }
/// }
/// ```
///
/// Designed for a `UINavigationController` with a hidden system bar (the header
/// replaces it) or an `LMKCardPanelViewController`: the default back action pops
/// the navigation stack, and dismisses the enclosing panel from its root page.
/// Pushed onto a stack whose bar is showing, the page hides its header and hands its
/// title and items to that bar (``usesSystemNavigationBar``), so it looks like the
/// screens around it.
open class LMKCardPageViewController: UIViewController, LMKThemeApplying {
    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// Header background (`backgroundPrimary`), border, shadow.
        public var header: LMKSurfaceStyle
        /// Page background; `nil` = `backgroundPrimary`.
        public var backgroundColor: UIColor?
        /// Header height floor below the top safe area (and the drag indicator); `nil` = 52. Grows with Dynamic Type.
        public var headerHeight: CGFloat?
        /// `nil` = `bodyBold`.
        public var titleTextStyle: LMKTextStyle?
        /// `nil` = `textPrimary`.
        public var titleColor: UIColor?
        /// Visual side of a glyph button, and the height of a titled one; `nil` = 32 (the hit
        /// target stays 44). A titled item grows wider than this to fit its text.
        public var buttonSize: CGFloat?
        /// `nil` = `secondary`.
        public var buttonTint: UIColor?
        /// `nil` = 16.
        public var symbolPointSize: CGFloat?
        /// `nil` = `.medium`.
        public var symbolWeight: UIImage.SymbolWeight?
        /// `nil` = no.
        public var showsHeaderSeparator: Bool?
        /// `nil` = `divider`.
        public var separatorColor: UIColor?
        /// `nil` = one pixel.
        public var separatorThickness: CGFloat?
        /// `nil` = `animation.slow`.
        public var pageTransitionDuration: TimeInterval?
        /// A drag indicator at the top of the header, for a page in a sheet the user can drag
        /// down to dismiss; `nil` = no. The header grows by the room it takes.
        public var showsDragIndicator: Bool?
        /// `nil` = 40 × 5.
        public var dragIndicatorSize: CGSize?
        /// `nil` = `divider`.
        public var dragIndicatorColor: UIColor?

        public init(
            header: LMKSurfaceStyle = LMKSurfaceStyle(),
            backgroundColor: UIColor? = nil,
            headerHeight: CGFloat? = nil,
            titleTextStyle: LMKTextStyle? = nil,
            titleColor: UIColor? = nil,
            buttonSize: CGFloat? = nil,
            buttonTint: UIColor? = nil,
            symbolPointSize: CGFloat? = nil,
            symbolWeight: UIImage.SymbolWeight? = nil,
            showsHeaderSeparator: Bool? = nil,
            separatorColor: UIColor? = nil,
            separatorThickness: CGFloat? = nil,
            pageTransitionDuration: TimeInterval? = nil,
            showsDragIndicator: Bool? = nil,
            dragIndicatorSize: CGSize? = nil,
            dragIndicatorColor: UIColor? = nil
        ) {
            self.header = header
            self.backgroundColor = backgroundColor
            self.headerHeight = headerHeight
            self.titleTextStyle = titleTextStyle
            self.titleColor = titleColor
            self.buttonSize = buttonSize
            self.buttonTint = buttonTint
            self.symbolPointSize = symbolPointSize
            self.symbolWeight = symbolWeight
            self.showsHeaderSeparator = showsHeaderSeparator
            self.separatorColor = separatorColor
            self.separatorThickness = separatorThickness
            self.pageTransitionDuration = pageTransitionDuration
            self.showsDragIndicator = showsDragIndicator
            self.dragIndicatorSize = dragIndicatorSize
            self.dragIndicatorColor = dragIndicatorColor
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                header: header.merging(other.header),
                backgroundColor: other.backgroundColor ?? backgroundColor,
                headerHeight: other.headerHeight ?? headerHeight,
                titleTextStyle: other.titleTextStyle ?? titleTextStyle,
                titleColor: other.titleColor ?? titleColor,
                buttonSize: other.buttonSize ?? buttonSize,
                buttonTint: other.buttonTint ?? buttonTint,
                symbolPointSize: other.symbolPointSize ?? symbolPointSize,
                symbolWeight: other.symbolWeight ?? symbolWeight,
                showsHeaderSeparator: other.showsHeaderSeparator ?? showsHeaderSeparator,
                separatorColor: other.separatorColor ?? separatorColor,
                separatorThickness: other.separatorThickness ?? separatorThickness,
                pageTransitionDuration: other.pageTransitionDuration ?? pageTransitionDuration,
                showsDragIndicator: other.showsDragIndicator ?? showsDragIndicator,
                dragIndicatorSize: other.dragIndicatorSize ?? dragIndicatorSize,
                dragIndicatorColor: other.dragIndicatorColor ?? dragIndicatorColor
            )
        }
    }

    // MARK: - Strings

    public nonisolated struct Strings: Sendable, Equatable {
        /// VoiceOver label of the leading (back) button when its item has none.
        public var leadingButtonAccessibilityLabel: String
        /// VoiceOver label of the trailing button when its item has none.
        public var trailingButtonAccessibilityLabel: String

        public init(
            leadingButtonAccessibilityLabel: String = LMKLocalized("cardPage.leadingButton.accessibilityLabel"),
            trailingButtonAccessibilityLabel: String = LMKLocalized("cardPage.trailingButton.accessibilityLabel")
        ) {
            self.leadingButtonAccessibilityLabel = leadingButtonAccessibilityLabel
            self.trailingButtonAccessibilityLabel = trailingButtonAccessibilityLabel
        }
    }

    /// Process-wide defaults; set at app launch to override.
    public nonisolated(unsafe) static var strings = Strings()

    /// Per-instance strings (default `Self.strings`).
    public var strings: Strings = LMKCardPageViewController.strings {
        didSet { configureHeaderButtons() }
    }

    // MARK: - Subviews

    public let headerView: UIView = LMKSurfaceView()
    public let headerTitleLabel = UILabel()
    public let leadingButton = LMKButton(style: .iconOnly())
    public let trailingButton = LMKButton(style: .iconOnly())
    public let headerSeparator = UIView()
    /// The grabber at the top of the header; hidden unless `style.showsDragIndicator`.
    public let dragIndicator: UIView = LMKSurfaceView()
    /// The root content; subclasses add their views here in `setupContent()`.
    public let contentContainerView = UIView()
    private let pageContainerView = UIView()
    private var leadingBadgeView: LMKBadgeView?
    private var trailingBadgeView: LMKBadgeView?

    // MARK: - State

    /// The leading header item; a back chevron by default, `nil` for none. An item without
    /// an action calls `leadingButtonTapped()`. While content is stacked the button shows the
    /// back chevron and pops, whatever the item says.
    public var leadingItem: LMKNavigationBarItem? {
        didSet { configureHeaderButtons() }
    }

    /// The trailing header item; `nil` (the default) shows none.
    public var trailingItem: LMKNavigationBarItem? {
        didSet { configureHeaderButtons() }
    }

    /// The header title; `title` on the controller and the label stay in step.
    override open var title: String? {
        didSet { headerTitleLabel.lmk_setText(title) }
    }

    /// Per-instance style; `nil` fields resolve from `theme.cardPage`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue, isViewLoaded else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKCardPageViewController) -> Void)?

    /// The style last resolved against the theme.
    public private(set) var resolvedStyle = Style()

    /// Whether pushed content can be popped.
    public var canPopContent: Bool { !pageStack.isEmpty }

    /// Whether the page hands its title and items to the system navigation bar instead of
    /// drawing its header: `true` while it sits in a navigation controller whose bar is showing,
    /// where the header would stack a second bar under the first (under the Mac idiom, under the
    /// window toolbar that bar becomes). Settled each time the page appears.
    public private(set) var usesSystemNavigationBar = false

    private struct PageSnapshot {
        let contentView: UIView
        let title: String?
    }

    private var pageStack: [PageSnapshot] = []
    private var isTransitioning = false
    private var headerHeightConstraint: Constraint?
    private var buttonHeightConstraints: [Constraint] = []
    private var buttonWidthConstraints: [Constraint] = []
    private var buttonEdgeConstraints: [Constraint] = []
    private var separatorHeightConstraint: Constraint?
    private var dragIndicatorTopConstraint: Constraint?
    private var dragIndicatorWidthConstraint: Constraint?
    private var dragIndicatorHeightConstraint: Constraint?
    private var headerContentTopConstraint: Constraint?
    /// The header below the drag indicator: the buttons and the title center in it.
    private let headerContentGuide = UILayoutGuide()
    private var titleLeadingToButton: Constraint?
    private var titleLeadingToEdge: Constraint?
    private var titleTrailingToButton: Constraint?
    private var titleTrailingToEdge: Constraint?
    /// The content's top: under the header, or under the system bar while the page uses it.
    private var pageTopToHeader: Constraint?
    private var pageTopToSafeArea: Constraint?
    /// The navigation item carries the page's items (set while `usesSystemNavigationBar`).
    private var installedNavigationItems = false
    /// The glyph button look resolved by the last `applyTheme`; items layer their role on it.
    private var itemButtonStyle = LMKButton.Style()

    static let defaultHeaderHeight: CGFloat = 52
    static let defaultButtonSize: CGFloat = 32
    static let defaultSymbolPointSize: CGFloat = 16
    static let defaultDragIndicatorSize = CGSize(width: 40, height: 5)
    static let backItemIdentifier = "lmk.cardPage.back"
    private static var backItem: LMKNavigationBarItem {
        LMKNavigationBarItem(identifier: backItemIdentifier, systemName: "chevron.backward")
    }

    // MARK: - Initialization

    public init(title: String, style: Style = Style()) {
        self.style = style
        super.init(nibName: nil, bundle: nil)
        self.title = title
        leadingItem = Self.backItem
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override open func viewDidLoad() {
        super.viewDidLoad()
        setupHeader()
        setupPageContainer()
        setupContent()
        lmk_startApplyingTheme()
    }

    override open func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        updateHeaderPlacement()
    }

    // MARK: - Template methods

    /// Override to add content to `contentContainerView`. Called from `viewDidLoad`.
    open func setupContent() {}

    /// Called when the leading item has no action and no content is stacked. Pops the
    /// enclosing navigation controller by default; from the root page of an
    /// `LMKCardPanelViewController` it dismisses the panel.
    open func leadingButtonTapped() {
        if let navigationController, navigationController.viewControllers.first !== self {
            navigationController.popViewController(animated: true)
        } else if let panel = lmk_cardPanel {
            panel.dismiss()
        }
    }

    /// Called at the end of every `applyTheme`, before `didApplyStyle`, for subclasses to
    /// style their own content from `theme` and `resolvedStyle`.
    open func applyContentTheme(_ theme: LMKTheme) {}

    // MARK: - Setup

    private func setupHeader() {
        headerTitleLabel.text = title
        headerTitleLabel.textAlignment = .center
        headerTitleLabel.accessibilityTraits = .header

        // The surface is full-bleed; what it holds stays inside the header's safe area, so a page
        // that fills the screen keeps its buttons and title clear of the status bar, the Mac
        // window controls, and the landscape sensor housing. A card away from the edges has none.
        view.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        let safeArea = headerView.safeAreaLayoutGuide

        dragIndicator.isHidden = true
        dragIndicator.isUserInteractionEnabled = false
        dragIndicator.isAccessibilityElement = false
        headerView.addSubview(dragIndicator)
        dragIndicator.snp.makeConstraints { make in
            dragIndicatorTopConstraint = make.top.equalTo(safeArea).offset(0).constraint
            make.centerX.equalTo(safeArea)
            dragIndicatorWidthConstraint = make.width.equalTo(Self.defaultDragIndicatorSize.width).constraint
            dragIndicatorHeightConstraint = make.height.equalTo(Self.defaultDragIndicatorSize.height).constraint
        }
        headerView.addLayoutGuide(headerContentGuide)
        headerContentGuide.snp.makeConstraints { make in
            headerContentTopConstraint = make.top.equalTo(safeArea).offset(0).constraint
            make.leading.trailing.equalTo(safeArea)
            make.bottom.equalToSuperview()
            headerHeightConstraint = make.height.equalTo(Self.defaultHeaderHeight).constraint
        }

        leadingButton.onTap = { [weak self] in self?.leadingTapped() }
        trailingButton.onTap = { [weak self] in self?.trailingItem?.action?() }
        for button in [leadingButton, trailingButton] {
            // A titled item keeps its text whole; the title label gives way instead.
            button.setContentCompressionResistancePriority(.required, for: .horizontal)
            button.setContentHuggingPriority(.required, for: .horizontal)
            headerView.addSubview(button)
        }
        leadingButton.snp.makeConstraints { make in
            buttonEdgeConstraints.append(make.leading.equalTo(headerContentGuide).inset(0).constraint)
            make.centerY.equalTo(headerContentGuide)
            buttonHeightConstraints.append(make.height.equalTo(Self.defaultButtonSize).constraint)
            buttonWidthConstraints.append(make.width.greaterThanOrEqualTo(Self.defaultButtonSize).constraint)
        }
        trailingButton.snp.makeConstraints { make in
            buttonEdgeConstraints.append(make.trailing.equalTo(headerContentGuide).inset(0).constraint)
            make.centerY.equalTo(headerContentGuide)
            buttonHeightConstraints.append(make.height.equalTo(Self.defaultButtonSize).constraint)
            buttonWidthConstraints.append(make.width.greaterThanOrEqualTo(Self.defaultButtonSize).constraint)
        }

        headerView.addSubview(headerTitleLabel)
        headerTitleLabel.snp.makeConstraints { make in
            make.centerX.equalTo(headerContentGuide)
            make.centerY.equalTo(headerContentGuide)
            titleLeadingToButton = make.leading.greaterThanOrEqualTo(leadingButton.snp.trailing).offset(0).constraint
            titleLeadingToEdge = make.leading.greaterThanOrEqualTo(headerContentGuide).inset(0).constraint
            titleTrailingToButton = make.trailing.lessThanOrEqualTo(trailingButton.snp.leading).offset(0).constraint
            titleTrailingToEdge = make.trailing.lessThanOrEqualTo(headerContentGuide).inset(0).constraint
        }

        headerView.addSubview(headerSeparator)
        headerSeparator.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            separatorHeightConstraint = make.height.equalTo(1).constraint
        }
    }

    private func setupPageContainer() {
        pageContainerView.clipsToBounds = true
        view.addSubview(pageContainerView)
        pageContainerView.snp.makeConstraints { make in
            pageTopToHeader = make.top.equalTo(headerView.snp.bottom).constraint
            make.leading.trailing.bottom.equalToSuperview()
        }
        // Built inactive: activated beside the header pin, it conflicts with the header's height.
        pageContainerView.snp.prepareConstraints { make in
            pageTopToSafeArea = make.top.equalTo(view.safeAreaLayoutGuide).constraint
        }
        pageContainerView.addSubview(contentContainerView)
        contentContainerView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    // MARK: - Header items

    private func configureHeaderButtons() {
        guard isViewLoaded else { return }
        let showsLeading = leadingItem != nil || canPopContent
        let showsTrailing = trailingItem != nil
        // Stacked content owns the leading button: the back chevron, enabled, without the item's menu.
        let leading = canPopContent ? Self.backItem : (leadingItem ?? Self.backItem)
        configure(leadingButton, with: leading, fallbackLabel: strings.leadingButtonAccessibilityLabel)
        leadingBadgeView = updateBadge(leadingBadgeView, for: showsLeading ? leading : nil, on: leadingButton)
        if let trailingItem {
            configure(trailingButton, with: trailingItem, fallbackLabel: strings.trailingButtonAccessibilityLabel)
        }
        trailingBadgeView = updateBadge(trailingBadgeView, for: trailingItem, on: trailingButton)
        configureNavigationItem()
        leadingButton.isHidden = !showsLeading
        trailingButton.isHidden = !showsTrailing
        if showsLeading {
            titleLeadingToEdge?.deactivate()
            titleLeadingToButton?.activate()
        } else {
            titleLeadingToButton?.deactivate()
            titleLeadingToEdge?.activate()
        }
        if showsTrailing {
            titleTrailingToEdge?.deactivate()
            titleTrailingToButton?.activate()
        } else {
            titleTrailingToButton?.deactivate()
            titleTrailingToEdge?.activate()
        }
    }

    // MARK: - System bar

    /// Shows the header, or hides it and hands the title and items to the system bar when the
    /// page sits in a stack whose bar is showing. Runs as the page appears.
    func updateHeaderPlacement() {
        let usesBar = navigationController.map { !$0.isNavigationBarHidden } ?? false
        usesSystemNavigationBar = usesBar
        headerView.isHidden = usesBar
        if usesBar {
            pageTopToHeader?.deactivate()
            pageTopToSafeArea?.activate()
        } else {
            pageTopToSafeArea?.deactivate()
            pageTopToHeader?.activate()
        }
        configureHeaderButtons()
    }

    /// Mirrors the header items onto `navigationItem` while the page uses the system bar (the
    /// title follows `title` on its own). Stacked content takes the back position, since the bar's
    /// back button would pop the whole page; a leading item with neither an action nor a menu
    /// stands for going back, which the back button already does.
    private func configureNavigationItem() {
        guard usesSystemNavigationBar else {
            guard installedNavigationItems else { return }
            installedNavigationItems = false
            navigationItem.leftBarButtonItems = nil
            navigationItem.rightBarButtonItems = nil
            navigationItem.hidesBackButton = false
            navigationItem.leftItemsSupplementBackButton = false
            return
        }
        installedNavigationItems = true
        let leading: LMKNavigationBarItem?
        if canPopContent {
            var back = Self.backItem
            back.accessibilityLabel = strings.leadingButtonAccessibilityLabel
            back.action = { [weak self] in self?.popContentView(animated: true) }
            leading = back
        } else {
            leading = leadingItem.flatMap { $0.action == nil && $0.menu == nil ? nil : $0 }
        }
        navigationItem.hidesBackButton = canPopContent
        navigationItem.leftItemsSupplementBackButton = !canPopContent
        navigationItem.lmk_setItems(leading: leading.map { [$0] } ?? [], trailing: trailingItem.map { [$0] } ?? [])
    }

    private func configure(_ button: LMKButton, with item: LMKNavigationBarItem, fallbackLabel: String) {
        button.style = buttonStyle(for: item)
        button.image = item.image
        button.title = item.title
        button.isEnabled = item.isEnabled
        button.menu = item.menu
        button.showsMenuAsPrimaryAction = item.menu != nil && item.action == nil
        button.accessibilityLabel = item.accessibilityLabel ?? item.title ?? fallbackLabel
        button.accessibilityIdentifier = item.identifier
    }

    /// The glyph look from the last `applyTheme`, opened into a capsule for a titled item,
    /// then the role's overrides (filled for `prominent`, the error tint for `destructive`).
    private func buttonStyle(for item: LMKNavigationBarItem) -> LMKButton.Style {
        let theme = traitCollection.lmkTheme
        var style = itemButtonStyle
        if item.title != nil {
            style.surface.corners = .capsule
            style.surface.contentInsets = .lmk_symmetric(vertical: 0, horizontal: theme.spacing.small)
            style.textStyle = .body
        }
        switch item.role {
        case .plain:
            break
        case .prominent:
            style = style.merging(LMKButton.Style(variant: .filled, textStyle: .subbodyMedium))
        case .destructive:
            style = style.merging(LMKButton.Style(role: .destructive, tintColor: LMKColor.error))
        }
        return style
    }

    /// Keeps a badge over `button`'s top trailing corner while `item` carries one.
    private func updateBadge(_ badgeView: LMKBadgeView?, for item: LMKNavigationBarItem?, on button: LMKButton) -> LMKBadgeView? {
        guard let content = item?.badge else {
            badgeView?.removeFromSuperview()
            return nil
        }
        let badge = badgeView ?? {
            let badge = LMKBadgeView()
            badge.isUserInteractionEnabled = false
            headerView.addSubview(badge)
            return badge
        }()
        // Remade on every pass (`applyTheme` comes through here), so the theme's inset holds.
        let inset = traitCollection.lmkTheme.spacing.xs
        badge.snp.remakeConstraints { make in
            make.centerX.equalTo(button.snp.trailing).offset(-inset).priority(.high)
            make.centerY.equalTo(button.snp.top).offset(inset).priority(.high)
            make.top.greaterThanOrEqualTo(headerContentGuide)
            make.trailing.lessThanOrEqualToSuperview()
        }
        badge.configure(content)
        return badge
    }

    private func leadingTapped() {
        if canPopContent {
            popContentView(animated: true)
        } else if let action = leadingItem?.action {
            action()
        } else {
            leadingButtonTapped()
        }
    }

    // MARK: - Theme

    open func applyTheme(_ theme: LMKTheme) {
        resolvedStyle = theme.cardPage.merging(style)
        let resolved = resolvedStyle
        view.backgroundColor = resolved.backgroundColor ?? LMKColor.backgroundPrimary
        headerView.lmk_apply(
            surface: resolved.header,
            defaults: LMKSurfaceStyle(background: .solid(LMKColor.backgroundPrimary), corners: LMKCornerStyle.square, shadow: LMKShadowSource.hidden),
            clipsContent: false
        )
        let titleStyle = resolved.titleTextStyle ?? .bodyBold
        headerTitleLabel.lmk_apply(titleStyle, color: resolved.titleColor ?? LMKColor.textPrimary)

        itemButtonStyle = LMKButton.Style(
            variant: .ghost,
            surface: LMKSurfaceStyle(corners: .circle, contentInsets: .lmk_all(0)),
            tintColor: resolved.buttonTint ?? LMKColor.secondary,
            symbolPointSize: resolved.symbolPointSize ?? Self.defaultSymbolPointSize,
            symbolWeight: resolved.symbolWeight ?? .medium,
            pressAnimation: false,
            haptics: false
        )
        let buttonSize = resolved.buttonSize ?? Self.defaultButtonSize
        buttonHeightConstraints.forEach { $0.update(offset: buttonSize) }
        buttonWidthConstraints.forEach { $0.update(offset: buttonSize) }
        buttonEdgeConstraints.forEach { $0.update(inset: theme.spacing.large) }
        titleLeadingToButton?.update(offset: theme.spacing.small)
        titleTrailingToButton?.update(offset: -theme.spacing.small)
        titleLeadingToEdge?.update(inset: theme.spacing.large)
        titleTrailingToEdge?.update(inset: theme.spacing.large)
        configureHeaderButtons()

        headerSeparator.isHidden = !(resolved.showsHeaderSeparator ?? false)
        headerSeparator.backgroundColor = resolved.separatorColor ?? LMKColor.divider
        separatorHeightConstraint?.update(offset: resolved.separatorThickness ?? LMKLayout.hairline(for: view))

        let showsIndicator = resolved.showsDragIndicator ?? false
        let indicatorSize = resolved.dragIndicatorSize ?? Self.defaultDragIndicatorSize
        dragIndicator.isHidden = !showsIndicator
        dragIndicator.lmk_apply(surface: LMKSurfaceStyle(background: .solid(resolved.dragIndicatorColor ?? LMKColor.divider), corners: .capsule))
        dragIndicatorTopConstraint?.update(offset: theme.spacing.small)
        dragIndicatorWidthConstraint?.update(offset: indicatorSize.width)
        dragIndicatorHeightConstraint?.update(offset: indicatorSize.height)
        // The indicator's band sits over the header's own height, so the title keeps its room.
        let indicatorBand = showsIndicator ? theme.spacing.small + indicatorSize.height : 0
        headerContentTopConstraint?.update(offset: indicatorBand)

        // The row the buttons and title center in; the header adds the band and the top safe area.
        let lineHeight = LMKTextMeasurement.lineHeight(of: titleStyle, traits: traitCollection)
        let floor = max(lineHeight, buttonSize) + theme.spacing.small * 2
        headerHeightConstraint?.update(offset: max(resolved.headerHeight ?? Self.defaultHeaderHeight, floor))
        applyContentTheme(theme)
        didApplyStyle?(self)
    }

    // MARK: - Multi-page navigation

    /// Pushes `contentView` with a forward slide, keeping the current content and title on a
    /// stack. The leading button shows for back navigation while content is stacked.
    public func pushContentView(_ contentView: UIView, title: String? = nil, animated: Bool = true) {
        guard !isTransitioning else { return }
        let current = pageContainerView.subviews.first ?? contentContainerView
        pageStack.append(PageSnapshot(contentView: current, title: self.title))
        if let title {
            self.title = title
        }
        configureHeaderButtons()
        transition(to: contentView, direction: .forward, animated: animated)
    }

    /// Pops to the previous content with a backward slide.
    public func popContentView(animated: Bool = true) {
        guard !isTransitioning, let snapshot = pageStack.popLast() else { return }
        if let previousTitle = snapshot.title {
            title = previousTitle
        }
        configureHeaderButtons()
        transition(to: snapshot.contentView, direction: .backward, animated: animated)
    }

    private func transition(to newView: UIView, direction: LMKPageTransition.Direction, animated: Bool) {
        let oldView = pageContainerView.subviews.first
        isTransitioning = true
        // A view that slid out earlier comes back faded and translated: show it whole again.
        newView.alpha = 1
        newView.transform = .identity
        LMKPageTransition.run(
            in: pageContainerView,
            from: oldView,
            to: newView,
            direction: direction,
            duration: resolvedStyle.pageTransitionDuration ?? LMKAnimation.Duration.slow,
            animated: animated,
            layoutRoot: view
        ) { [weak self] in
            self?.isTransitioning = false
        }
        UIAccessibility.post(notification: .screenChanged, argument: usesSystemNavigationBar ? nil : headerTitleLabel)
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKCardPageViewController`.
    var cardPage: LMKCardPageViewController.Style {
        get { self[LMKCardPageViewController.Style.self] }
        set { self[LMKCardPageViewController.Style.self] = newValue }
    }
}
