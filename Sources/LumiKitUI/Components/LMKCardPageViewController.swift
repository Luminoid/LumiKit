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
/// `trailingItem` (none by default). Subclasses override `setupContent()` to build
/// their content in `contentContainerView`; `pushContentView(_:title:)` and
/// `popContentView()` slide between content views, and the leading button pops
/// while pages are stacked.
///
/// ```swift
/// final class SettingsPage: LMKCardPageViewController {
///     init() {
///         super.init(title: "Settings")
///         trailingItem = .init(systemName: "xmark") { [weak self] in self?.dismiss(animated: true) }
///         style.showsHeaderSeparator = true
///         style.showsDragIndicator = true   // in a sheet the user can drag down
///     }
///
///     override func setupContent() { ... }
/// }
/// ```
///
/// Designed for a `UINavigationController` with a hidden system bar (the header
/// replaces it) or an `LMKCardPanelViewController`.
open class LMKCardPageViewController: UIViewController, LMKThemeApplying {
    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// Header background (`backgroundPrimary`), border, shadow.
        public var header: LMKSurfaceStyle
        /// Page background; `nil` = `backgroundPrimary`.
        public var backgroundColor: UIColor?
        /// Header height floor; `nil` = 52. Grows with Dynamic Type.
        public var headerHeight: CGFloat?
        /// `nil` = `bodyBold`.
        public var titleTextStyle: LMKTextStyle?
        /// `nil` = `textPrimary`.
        public var titleColor: UIColor?
        /// Visual side of the header buttons; `nil` = 32 (the hit target stays 44).
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

    // MARK: - State

    /// The leading header item; a back chevron by default, `nil` for none. An item without
    /// an action calls `leadingButtonTapped()`.
    public var leadingItem: LMKNavigationBarItem? {
        didSet { configureHeaderButtons() }
    }

    /// The trailing header item; `nil` (the default) shows none.
    public var trailingItem: LMKNavigationBarItem? {
        didSet { configureHeaderButtons() }
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

    private struct PageSnapshot {
        let contentView: UIView
        let title: String?
    }

    private var pageStack: [PageSnapshot] = []
    private var isTransitioning = false
    private var headerHeightConstraint: Constraint?
    private var buttonSizeConstraints: [Constraint] = []
    private var separatorHeightConstraint: Constraint?
    private var dragIndicatorWidthConstraint: Constraint?
    private var dragIndicatorHeightConstraint: Constraint?
    private var headerContentTopConstraint: Constraint?
    /// The header below the drag indicator: the buttons and the title center in it.
    private let headerContentGuide = UILayoutGuide()
    private var titleLeadingToButton: Constraint?
    private var titleLeadingToEdge: Constraint?
    private var titleTrailingToButton: Constraint?
    private var titleTrailingToEdge: Constraint?

    static let defaultHeaderHeight: CGFloat = 52
    static let defaultButtonSize: CGFloat = 32
    static let defaultSymbolPointSize: CGFloat = 16
    static let defaultDragIndicatorSize = CGSize(width: 40, height: 5)
    static let backItemIdentifier = "lmk.cardPage.back"

    // MARK: - Initialization

    public init(title: String, style: Style = Style()) {
        self.style = style
        super.init(nibName: nil, bundle: nil)
        self.title = title
        leadingItem = LMKNavigationBarItem(identifier: Self.backItemIdentifier, systemName: "chevron.backward")
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
        configureHeaderButtons()
        lmk_startApplyingTheme()
    }

    // MARK: - Template methods

    /// Override to add content to `contentContainerView`. Called from `viewDidLoad`.
    open func setupContent() {}

    /// Called when the leading item has no action and no content is stacked. Pops the
    /// enclosing navigation controller by default.
    open func leadingButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Setup

    private func setupHeader() {
        headerTitleLabel.text = title
        headerTitleLabel.textAlignment = .center
        headerTitleLabel.accessibilityTraits = .header

        view.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            headerHeightConstraint = make.height.equalTo(Self.defaultHeaderHeight).constraint
        }

        dragIndicator.isHidden = true
        dragIndicator.isUserInteractionEnabled = false
        dragIndicator.isAccessibilityElement = false
        headerView.addSubview(dragIndicator)
        dragIndicator.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(LMKSpacing.small)
            make.centerX.equalToSuperview()
            dragIndicatorWidthConstraint = make.width.equalTo(Self.defaultDragIndicatorSize.width).constraint
            dragIndicatorHeightConstraint = make.height.equalTo(Self.defaultDragIndicatorSize.height).constraint
        }
        headerView.addLayoutGuide(headerContentGuide)
        headerContentGuide.snp.makeConstraints { make in
            headerContentTopConstraint = make.top.equalToSuperview().offset(0).constraint
            make.leading.trailing.bottom.equalToSuperview()
        }

        leadingButton.onTap = { [weak self] in self?.leadingTapped() }
        trailingButton.onTap = { [weak self] in self?.trailingItem?.action?() }
        headerView.addSubview(leadingButton)
        leadingButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(LMKSpacing.large)
            make.centerY.equalTo(headerContentGuide)
            buttonSizeConstraints.append(make.size.equalTo(Self.defaultButtonSize).constraint)
        }
        headerView.addSubview(trailingButton)
        trailingButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(LMKSpacing.large)
            make.centerY.equalTo(headerContentGuide)
            buttonSizeConstraints.append(make.size.equalTo(Self.defaultButtonSize).constraint)
        }

        headerView.addSubview(headerTitleLabel)
        headerTitleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(headerContentGuide)
            titleLeadingToButton = make.leading.greaterThanOrEqualTo(leadingButton.snp.trailing).offset(LMKSpacing.small).constraint
            titleLeadingToEdge = make.leading.greaterThanOrEqualToSuperview().inset(LMKSpacing.large).constraint
            titleTrailingToButton = make.trailing.lessThanOrEqualTo(trailingButton.snp.leading).offset(-LMKSpacing.small).constraint
            titleTrailingToEdge = make.trailing.lessThanOrEqualToSuperview().inset(LMKSpacing.large).constraint
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
            make.top.equalTo(headerView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        pageContainerView.addSubview(contentContainerView)
        contentContainerView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    // MARK: - Header items

    private func configureHeaderButtons() {
        guard isViewLoaded else { return }
        let showsLeading = leadingItem != nil || canPopContent
        let showsTrailing = trailingItem != nil
        configure(leadingButton, with: leadingItem ?? LMKNavigationBarItem(identifier: Self.backItemIdentifier, systemName: "chevron.backward"), fallbackLabel: strings.leadingButtonAccessibilityLabel)
        if let trailingItem {
            configure(trailingButton, with: trailingItem, fallbackLabel: strings.trailingButtonAccessibilityLabel)
        }
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

    private func configure(_ button: LMKButton, with item: LMKNavigationBarItem, fallbackLabel: String) {
        button.image = item.image
        button.title = item.title
        button.isEnabled = item.isEnabled
        button.menu = item.menu
        button.showsMenuAsPrimaryAction = item.menu != nil && item.action == nil
        button.accessibilityLabel = item.accessibilityLabel ?? item.title ?? fallbackLabel
        button.accessibilityIdentifier = item.identifier
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
            defaults: LMKSurfaceStyle(background: .solid(LMKColor.backgroundPrimary), corners: LMKCornerStyle.none, shadow: LMKShadowSource.none),
            clipsContent: false
        )
        let titleStyle = resolved.titleTextStyle ?? .bodyBold
        headerTitleLabel.lmk_apply(titleStyle, color: resolved.titleColor ?? LMKColor.textPrimary)

        let buttonStyle = LMKButton.Style(
            variant: .ghost,
            surface: LMKSurfaceStyle(corners: .circle, contentInsets: .lmk_all(0)),
            tintColor: resolved.buttonTint ?? LMKColor.secondary,
            symbolPointSize: resolved.symbolPointSize ?? Self.defaultSymbolPointSize,
            symbolWeight: resolved.symbolWeight ?? .medium,
            pressAnimation: false,
            haptics: false
        )
        leadingButton.style = buttonStyle
        trailingButton.style = buttonStyle
        let buttonSize = resolved.buttonSize ?? Self.defaultButtonSize
        buttonSizeConstraints.forEach { $0.update(offset: buttonSize) }

        headerSeparator.isHidden = !(resolved.showsHeaderSeparator ?? false)
        headerSeparator.backgroundColor = resolved.separatorColor ?? LMKColor.divider
        separatorHeightConstraint?.update(offset: resolved.separatorThickness ?? LMKLayout.hairline(for: view))

        let showsIndicator = resolved.showsDragIndicator ?? false
        let indicatorSize = resolved.dragIndicatorSize ?? Self.defaultDragIndicatorSize
        dragIndicator.isHidden = !showsIndicator
        dragIndicator.lmk_apply(surface: LMKSurfaceStyle(background: .solid(resolved.dragIndicatorColor ?? LMKColor.divider), corners: .capsule))
        dragIndicatorWidthConstraint?.update(offset: indicatorSize.width)
        dragIndicatorHeightConstraint?.update(offset: indicatorSize.height)
        // The indicator's band sits over the header's own height, so the title keeps its room.
        let indicatorBand = showsIndicator ? theme.spacing.small + indicatorSize.height : 0
        headerContentTopConstraint?.update(offset: indicatorBand)

        let lineHeight = LMKTextMeasurement.lineHeight(of: titleStyle, traits: traitCollection)
        let floor = max(lineHeight, buttonSize) + theme.spacing.small * 2
        headerHeightConstraint?.update(offset: max(resolved.headerHeight ?? Self.defaultHeaderHeight, floor) + indicatorBand)
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
            headerTitleLabel.lmk_setText(title)
        }
        configureHeaderButtons()
        transition(to: contentView, direction: .forward, animated: animated)
    }

    /// Pops to the previous content with a backward slide.
    public func popContentView(animated: Bool = true) {
        guard !isTransitioning, let snapshot = pageStack.popLast() else { return }
        if let previousTitle = snapshot.title {
            title = previousTitle
            headerTitleLabel.lmk_setText(previousTitle)
        }
        configureHeaderButtons()
        transition(to: snapshot.contentView, direction: .backward, animated: animated)
    }

    private func transition(to newView: UIView, direction: LMKPageTransition.Direction, animated: Bool) {
        let oldView = pageContainerView.subviews.first
        isTransitioning = true
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
        UIAccessibility.post(notification: .screenChanged, argument: headerTitleLabel)
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKCardPageViewController`.
    var cardPage: LMKCardPageViewController.Style {
        get { self[LMKCardPageViewController.Style.self] }
        set { self[LMKCardPageViewController.Style.self] = newValue }
    }
}
