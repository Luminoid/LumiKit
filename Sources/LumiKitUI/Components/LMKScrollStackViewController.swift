//
//  LMKScrollStackViewController.swift
//  LumiKit
//
//  Base class for scroll + vertical stack screens, styled from
//  `theme.scrollStack`: spacing, insets, width mode, keyboard behavior, an
//  optional custom navigation bar, a refresh control, and content reloads.
//

import SnapKit
import UIKit

/// Base class for view controllers with a scrollable vertical stack layout.
///
/// Subclasses override `setupStackContent()` to populate `stackView`; spacing,
/// insets, width mode, and scroll behavior come from `style`. `navigationBar`
/// installs a custom bar above the scroll view; `makeRefreshControl()` adds
/// pull-to-refresh (skipped under the Mac idiom, where `UIRefreshControl` traps).
///
/// ```swift
/// final class DetailViewController: LMKScrollStackViewController {
///     init() {
///         super.init(style: LMKScrollStackViewController.Style(widthMode: .readable))
///     }
///
///     override func setupStackContent() {
///         addSectionHeader("Details")
///         stackView.addArrangedSubview(UILabel.lmk_make(.body, text: "Hello"))
///         addDivider()
///     }
/// }
/// ```
open class LMKScrollStackViewController: UIViewController, LMKThemeApplying {
    // MARK: - Vocabulary

    /// What the scroll view's bottom edge meets.
    public nonisolated enum BottomAnchor: Sendable, Hashable, CaseIterable {
        case safeArea
        case superview
    }

    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// `nil` = `spacing.large`.
        public var stackSpacing: CGFloat?
        /// From the content edges to the stack; `nil` = `cardPadding` on all sides.
        public var contentInsets: NSDirectionalEdgeInsets?
        /// `nil` = `.tokenInsets`.
        public var widthMode: LMKFormScaffold.WidthMode?
        /// `nil` = `backgroundPrimary`.
        public var backgroundColor: UIColor?
        /// `nil` = `.onDrag`.
        public var keyboardDismissMode: UIScrollView.KeyboardDismissMode?
        /// `nil` = no.
        public var alwaysBounceVertical: Bool?
        /// `nil` = `.safeArea`.
        public var bottomAnchor: BottomAnchor?
        /// iOS 26 scroll edge effects at the top and bottom; `nil` = the system default.
        public var showsScrollEdgeEffects: Bool?
        /// Section headers from `addSectionHeader(_:)`; `nil` = `h3`.
        public var sectionHeaderTextStyle: LMKTextStyle?
        /// `nil` = `textPrimary`.
        public var sectionHeaderColor: UIColor?

        public init(
            stackSpacing: CGFloat? = nil,
            contentInsets: NSDirectionalEdgeInsets? = nil,
            widthMode: LMKFormScaffold.WidthMode? = nil,
            backgroundColor: UIColor? = nil,
            keyboardDismissMode: UIScrollView.KeyboardDismissMode? = nil,
            alwaysBounceVertical: Bool? = nil,
            bottomAnchor: BottomAnchor? = nil,
            showsScrollEdgeEffects: Bool? = nil,
            sectionHeaderTextStyle: LMKTextStyle? = nil,
            sectionHeaderColor: UIColor? = nil
        ) {
            self.stackSpacing = stackSpacing
            self.contentInsets = contentInsets
            self.widthMode = widthMode
            self.backgroundColor = backgroundColor
            self.keyboardDismissMode = keyboardDismissMode
            self.alwaysBounceVertical = alwaysBounceVertical
            self.bottomAnchor = bottomAnchor
            self.showsScrollEdgeEffects = showsScrollEdgeEffects
            self.sectionHeaderTextStyle = sectionHeaderTextStyle
            self.sectionHeaderColor = sectionHeaderColor
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                stackSpacing: other.stackSpacing ?? stackSpacing,
                contentInsets: other.contentInsets ?? contentInsets,
                widthMode: other.widthMode ?? widthMode,
                backgroundColor: other.backgroundColor ?? backgroundColor,
                keyboardDismissMode: other.keyboardDismissMode ?? keyboardDismissMode,
                alwaysBounceVertical: other.alwaysBounceVertical ?? alwaysBounceVertical,
                bottomAnchor: other.bottomAnchor ?? bottomAnchor,
                showsScrollEdgeEffects: other.showsScrollEdgeEffects ?? showsScrollEdgeEffects,
                sectionHeaderTextStyle: other.sectionHeaderTextStyle ?? sectionHeaderTextStyle,
                sectionHeaderColor: other.sectionHeaderColor ?? sectionHeaderColor
            )
        }
    }

    // MARK: - Hooks

    /// A custom navigation bar pinned above the scroll view (read once during setup); `nil` = none.
    open var navigationBar: LMKNavigationBar? { nil }

    /// Installs scroll-view keyboard avoidance (`lmk_enableKeyboardAdjustment()`). Default `true`.
    open var installsKeyboardAdjustment: Bool { true }

    /// A pull-to-refresh control to install on the scroll view; `nil` (the default) installs none.
    /// Skipped under the Mac idiom, where `UIRefreshControl` is unsupported.
    open func makeRefreshControl() -> UIRefreshControl? {
        nil
    }

    /// Override to populate `stackView`. Called from `viewDidLoad` and from `reloadContent()`.
    open func setupStackContent() {}

    /// Subclass hook, called at the end of every `applyTheme(_:)` just before `didApplyStyle`, so
    /// a subclass's own theming (the views it added in `setupStackContent()`) never has to follow
    /// `super.applyTheme` and `didApplyStyle` always runs last. The base implementation does nothing.
    open func applyContentTheme(_ theme: LMKTheme) {}

    // MARK: - Views

    public let scrollView = UIScrollView()
    /// Intermediate content view inside the scroll view.
    public let contentView = UIView()
    /// The vertical stack subclasses add their content to.
    public let stackView = UIStackView()
    /// The refresh control installed from `makeRefreshControl()`, if any.
    public private(set) var refreshControl: UIRefreshControl?

    // MARK: - State

    /// Per-instance style; `nil` fields resolve from `theme.scrollStack`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue, isViewLoaded else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKScrollStackViewController) -> Void)?

    /// The style last resolved against the theme.
    public private(set) var resolvedStyle = Style()

    private var scrollBottomSafeAreaConstraint: Constraint?
    private var scrollBottomSuperviewConstraint: Constraint?
    /// The labels `addSectionHeader(_:)` made, the only ones `applyTheme` restyles.
    private var sectionHeaderLabels: [UILabel] = []
    /// The default inset the stack was last pinned with (`LMKSpacing.cardPadding` follows the
    /// window's size tier, so it is re-read after a resize).
    private var pinnedDefaultInset: CGFloat?

    // MARK: - Initialization

    public init(style: Style = Style()) {
        self.style = style
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override open func viewDidLoad() {
        super.viewDidLoad()
        setupScrollStack()
        setupStackContent()
        lmk_startApplyingTheme()
    }

    /// Re-pins the stack when the window moved to another size tier (a rotation never changes
    /// it; Slide Over, Stage Manager, and a resized Mac window can).
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // `cardPadding` is tiered by the window's canvas, not by the theme; this is the live re-read that follows a tier change.
        // swiftlint:disable:next no_global_token_proxies_in_components
        guard let pinnedDefaultInset, pinnedDefaultInset != LMKSpacing.cardPadding else { return }
        pinStack(resolvedStyle)
    }

    // MARK: - Setup

    private func setupScrollStack() {
        navigationBar?.install(in: view)

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            if let navigationBar {
                make.top.equalTo(navigationBar.snp.bottom)
            } else {
                make.top.equalToSuperview()
            }
            make.leading.trailing.equalToSuperview()
            scrollBottomSafeAreaConstraint = make.bottom.equalTo(view.safeAreaLayoutGuide).constraint
            scrollBottomSuperviewConstraint = make.bottom.equalToSuperview().constraint
        }
        scrollBottomSuperviewConstraint?.deactivate()

        if installsKeyboardAdjustment {
            scrollView.lmk_enableKeyboardAdjustment()
        }
        if let control = makeRefreshControl(), traitCollection.userInterfaceIdiom != .mac {
            scrollView.refreshControl = control
            refreshControl = control
        }

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        stackView.axis = .vertical
        stackView.alignment = .fill
        contentView.addSubview(stackView)
    }

    // MARK: - Theme

    open func applyTheme(_ theme: LMKTheme) {
        resolvedStyle = theme.scrollStack.merging(style)
        let resolved = resolvedStyle
        view.backgroundColor = resolved.backgroundColor ?? LMKColor.backgroundPrimary
        stackView.spacing = resolved.stackSpacing ?? theme.spacing.large
        scrollView.keyboardDismissMode = resolved.keyboardDismissMode ?? .onDrag
        scrollView.alwaysBounceVertical = resolved.alwaysBounceVertical ?? false
        if (resolved.bottomAnchor ?? .safeArea) == .safeArea {
            scrollBottomSuperviewConstraint?.deactivate()
            scrollBottomSafeAreaConstraint?.activate()
        } else {
            scrollBottomSafeAreaConstraint?.deactivate()
            scrollBottomSuperviewConstraint?.activate()
        }
        pinStack(resolved)
        if #available(iOS 26, *) {
            let showsEdgeEffects = resolved.showsScrollEdgeEffects ?? true
            scrollView.topEdgeEffect.isHidden = !showsEdgeEffects
            scrollView.bottomEdgeEffect.isHidden = !showsEdgeEffects
        }
        for header in sectionHeaderLabels {
            header.lmk_apply(resolved.sectionHeaderTextStyle ?? .h3, color: resolved.sectionHeaderColor ?? LMKColor.textPrimary, lineMetrics: true)
        }
        applyContentTheme(theme)
        didApplyStyle?(self)
    }

    /// Pins the stack per `resolved`; the default inset is the window-tiered card padding.
    private func pinStack(_ resolved: Style) {
        // `cardPadding` is tiered by the window's canvas, not by the theme; it has no per-theme twin.
        // swiftlint:disable:next no_global_token_proxies_in_components
        let defaultInset = LMKSpacing.cardPadding
        pinnedDefaultInset = resolved.contentInsets == nil ? defaultInset : nil
        LMKFormScaffold.pin(
            stackView,
            in: contentView,
            insets: resolved.contentInsets ?? .lmk_all(defaultInset),
            widthMode: resolved.widthMode ?? .tokenInsets
        )
    }

    // MARK: - Content

    /// Empties the stack and runs `setupStackContent()` again. Before the view loads it does
    /// nothing: `viewDidLoad` builds the content once.
    public func reloadContent() {
        guard isViewLoaded else { return }
        for view in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        sectionHeaderLabels.removeAll()
        setupStackContent()
    }

    /// Scrolls so `view` (a descendant of the stack) is visible.
    public func scrollTo(_ view: UIView, animated: Bool) {
        let rect = view.convert(view.bounds, to: scrollView)
        scrollView.scrollRectToVisible(rect, animated: animated && LMKAnimation.shouldAnimate)
    }

    /// Adds a section header (a `.header` accessibility element) to the stack. It follows the
    /// style's header text style and color; other labels in the stack are left alone.
    @discardableResult
    public func addSectionHeader(_ title: String) -> UILabel {
        let label = UILabel.lmk_make(resolvedStyle.sectionHeaderTextStyle ?? .h3, text: title, color: resolvedStyle.sectionHeaderColor ?? LMKColor.textPrimary)
        label.accessibilityTraits = .header
        stackView.addArrangedSubview(label)
        sectionHeaderLabels.append(label)
        return label
    }

    /// Adds a pixel-perfect divider to the stack.
    @discardableResult
    public func addDivider() -> LMKDividerView {
        let divider = LMKDividerView()
        stackView.addArrangedSubview(divider)
        return divider
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKScrollStackViewController`.
    var scrollStack: LMKScrollStackViewController.Style {
        get { self[LMKScrollStackViewController.Style.self] }
        set { self[LMKScrollStackViewController.Style.self] = newValue }
    }
}
