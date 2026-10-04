//
//  LMKNavigationBar.swift
//  LumiKit
//
//  Custom navigation bar: a button row with back button, inline title and
//  subtitle, left and right items, an optional large title row, and a
//  separator, styled from `theme.navigationBar`. Accessory views and scroll
//  pinning live in +Accessories.
//

import SnapKit
import UIKit

/// Custom navigation bar with design-token styling.
///
/// The chrome follows the OS (`Style.appearance`): on iOS 26 items sit on Liquid Glass,
/// neighbours sharing one capsule, with no hairline under the bar; before iOS 26 they are
/// tinted glyphs and text over a hairline. `.classic` or `.glass` pins one look.
///
/// Two display modes match Apple's patterns:
///
/// **Large title** (root screens): a 44pt button row, then a 52pt large title row.
/// **Standard** (pushed screens): a 44pt row with the title centered between the
/// back button (or left items) and the right items. Both rows are floors that grow
/// with Dynamic Type.
///
/// ```swift
/// navigationController?.setNavigationBarHidden(true, animated: false)
///
/// let bar = LMKNavigationBar()
/// bar.title = "Items"
/// bar.subtitle = "12 due today"
/// bar.largeTitleEnabled = true
/// bar.setRightItems([.init(identifier: "add", systemName: "plus") { [weak self] in self?.addTapped() }])
/// bar.install(in: view)
/// bar.pinScrollView(tableView)
/// ```
public final class LMKNavigationBar: UIView, LMKThemeApplying {
    // MARK: - Vocabulary

    /// Where the large title sits in its row.
    public nonisolated enum LargeTitleAlignment: Sendable, Hashable, CaseIterable {
        case leading
        case center
    }

    /// How the bar draws its chrome.
    public nonisolated enum Appearance: Sendable, Hashable, CaseIterable {
        /// The running OS's look: `.glass` on iOS 26 and later, `.classic` before.
        case automatic
        /// Tinted glyph and text items on the bar's background over a hairline (the look through iOS 18).
        case classic
        /// Items on Liquid Glass: neighbours share one capsule, a prominent item takes its own in
        /// the tint, the back chevron sits in a circle, and the bar has no hairline (the iOS 26
        /// look). Before iOS 26 it draws as `.classic`.
        case glass
    }

    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// `nil` = `.automatic`.
        public var appearance: Appearance?
        /// Background (`backgroundPrimary`; `.blur` / `.glass` pair with `pinScrollView(_:edgeEffect:)`), border, shadow.
        public var surface: LMKSurfaceStyle
        /// Items and the back chevron; `nil` = `primary` (`textPrimary` on glass, as the system
        /// bar draws them; a prominent item's capsule stays `primary`).
        public var tintColor: UIColor?
        /// `nil` = 17pt semibold.
        public var titleTextStyle: LMKTextStyle?
        /// `nil` = `textPrimary`.
        public var titleColor: UIColor?
        /// `nil` = 34pt bold.
        public var largeTitleTextStyle: LMKTextStyle?
        /// `nil` = `textPrimary`.
        public var largeTitleColor: UIColor?
        /// `nil` = `caption`.
        public var subtitleTextStyle: LMKTextStyle?
        /// `nil` = `textSecondary`.
        public var subtitleColor: UIColor?
        /// Titles of text items; `nil` = `body`.
        public var itemTextStyle: LMKTextStyle?
        /// Base style of every item (a small ghost button in the bar tint); role styles layer on top.
        public var item: LMKButton.Style
        /// Layered on `.prominent` items (filled, small).
        public var prominentItem: LMKButton.Style
        /// Layered on the glass behind items (`.glass` appearance): regular, capsule, interactive.
        public var itemGlass: LMKGlassView.Style
        /// `nil` = yes on `.classic`, no on `.glass`.
        public var showsSeparator: Bool?
        /// `nil` = `divider`.
        public var separatorColor: UIColor?
        /// `nil` = one pixel.
        public var separatorThickness: CGFloat?
        /// Floor of the button row; `nil` = 44.
        public var buttonRowHeight: CGFloat?
        /// Floor of the large title row; `nil` = 52.
        public var largeTitleRowHeight: CGFloat?
        /// Minimum side of an item; `nil` = the minimum touch target.
        public var itemSize: CGFloat?
        /// Gap between items; `nil` = `spacing.xs`. On glass, the gap between capsules
        /// (`nil` = `spacing.small`); items inside one capsule touch.
        public var itemSpacing: CGFloat?
        /// Leading and trailing margin; `nil` = `spacing.large`.
        public var contentMargin: CGFloat?
        /// `nil` = "chevron.backward".
        public var backSymbol: String?
        /// `nil` = 17.
        public var backSymbolPointSize: CGFloat?
        /// Leading offset of the back button; `nil` = `spacing.small` (the content margin on glass).
        public var backChevronLeading: CGFloat?
        /// `nil` = `.leading`.
        public var largeTitleAlignment: LargeTitleAlignment?

        public init(
            appearance: Appearance? = nil,
            surface: LMKSurfaceStyle = LMKSurfaceStyle(),
            tintColor: UIColor? = nil,
            titleTextStyle: LMKTextStyle? = nil,
            titleColor: UIColor? = nil,
            largeTitleTextStyle: LMKTextStyle? = nil,
            largeTitleColor: UIColor? = nil,
            subtitleTextStyle: LMKTextStyle? = nil,
            subtitleColor: UIColor? = nil,
            itemTextStyle: LMKTextStyle? = nil,
            item: LMKButton.Style = LMKButton.Style(),
            prominentItem: LMKButton.Style = LMKButton.Style(),
            itemGlass: LMKGlassView.Style = LMKGlassView.Style(),
            showsSeparator: Bool? = nil,
            separatorColor: UIColor? = nil,
            separatorThickness: CGFloat? = nil,
            buttonRowHeight: CGFloat? = nil,
            largeTitleRowHeight: CGFloat? = nil,
            itemSize: CGFloat? = nil,
            itemSpacing: CGFloat? = nil,
            contentMargin: CGFloat? = nil,
            backSymbol: String? = nil,
            backSymbolPointSize: CGFloat? = nil,
            backChevronLeading: CGFloat? = nil,
            largeTitleAlignment: LargeTitleAlignment? = nil
        ) {
            self.appearance = appearance
            self.surface = surface
            self.tintColor = tintColor
            self.titleTextStyle = titleTextStyle
            self.titleColor = titleColor
            self.largeTitleTextStyle = largeTitleTextStyle
            self.largeTitleColor = largeTitleColor
            self.subtitleTextStyle = subtitleTextStyle
            self.subtitleColor = subtitleColor
            self.itemTextStyle = itemTextStyle
            self.item = item
            self.prominentItem = prominentItem
            self.itemGlass = itemGlass
            self.showsSeparator = showsSeparator
            self.separatorColor = separatorColor
            self.separatorThickness = separatorThickness
            self.buttonRowHeight = buttonRowHeight
            self.largeTitleRowHeight = largeTitleRowHeight
            self.itemSize = itemSize
            self.itemSpacing = itemSpacing
            self.contentMargin = contentMargin
            self.backSymbol = backSymbol
            self.backSymbolPointSize = backSymbolPointSize
            self.backChevronLeading = backChevronLeading
            self.largeTitleAlignment = largeTitleAlignment
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                appearance: other.appearance ?? appearance,
                surface: surface.merging(other.surface),
                tintColor: other.tintColor ?? tintColor,
                titleTextStyle: other.titleTextStyle ?? titleTextStyle,
                titleColor: other.titleColor ?? titleColor,
                largeTitleTextStyle: other.largeTitleTextStyle ?? largeTitleTextStyle,
                largeTitleColor: other.largeTitleColor ?? largeTitleColor,
                subtitleTextStyle: other.subtitleTextStyle ?? subtitleTextStyle,
                subtitleColor: other.subtitleColor ?? subtitleColor,
                itemTextStyle: other.itemTextStyle ?? itemTextStyle,
                item: item.merging(other.item),
                prominentItem: prominentItem.merging(other.prominentItem),
                itemGlass: itemGlass.merging(other.itemGlass),
                showsSeparator: other.showsSeparator ?? showsSeparator,
                separatorColor: other.separatorColor ?? separatorColor,
                separatorThickness: other.separatorThickness ?? separatorThickness,
                buttonRowHeight: other.buttonRowHeight ?? buttonRowHeight,
                largeTitleRowHeight: other.largeTitleRowHeight ?? largeTitleRowHeight,
                itemSize: other.itemSize ?? itemSize,
                itemSpacing: other.itemSpacing ?? itemSpacing,
                contentMargin: other.contentMargin ?? contentMargin,
                backSymbol: other.backSymbol ?? backSymbol,
                backSymbolPointSize: other.backSymbolPointSize ?? backSymbolPointSize,
                backChevronLeading: other.backChevronLeading ?? backChevronLeading,
                largeTitleAlignment: other.largeTitleAlignment ?? largeTitleAlignment
            )
        }
    }

    /// The inline title's default text style (17pt semibold, headline metrics).
    public static let defaultTitleTextStyle = LMKTextStyle.custom(LMKFontSpec(size: 17, weight: .semibold, textStyle: .headline, kind: .body))
    /// The large title's default text style (34pt bold, large-title metrics, capped at 44pt).
    public static let defaultLargeTitleTextStyle = LMKTextStyle.custom(LMKFontSpec(size: 34, weight: .bold, textStyle: .largeTitle, kind: .heading, maximumPointSize: 44))

    // MARK: - Strings

    public nonisolated struct Strings: Sendable, Equatable {
        /// VoiceOver label of the back chevron.
        public var backAccessibilityLabel: String

        public init(backAccessibilityLabel: String = LMKLocalized("navigationBar.back.accessibilityLabel")) {
            self.backAccessibilityLabel = backAccessibilityLabel
        }
    }

    /// Process-wide defaults; set at app launch to override.
    public nonisolated(unsafe) static var strings = Strings()

    /// Per-instance strings (default `Self.strings`).
    public var strings: Strings = LMKNavigationBar.strings {
        didSet {
            backButton.accessibilityLabel = strings.backAccessibilityLabel
            updateToolTip(of: backButton, to: strings.backAccessibilityLabel)
        }
    }

    // MARK: - Subviews

    /// The row holding the back button, left items, inline title, and right items.
    public let buttonRow = UIView()
    public let backButton = LMKButton(style: .iconOnly())
    public let leftItemsStack = UIStackView()
    public let rightItemsStack = UIStackView()
    /// Inline title and subtitle, centered in the button row.
    public let titleStack = UIStackView()
    public let titleLabel = UILabel()
    public let subtitleLabel = UILabel()
    /// The large title row (hidden unless `largeTitleEnabled`).
    public let largeTitleRow = UIView()
    public let largeTitleStack = UIStackView()
    public let largeTitleLabel = UILabel()
    public let largeSubtitleLabel = UILabel()
    public let separatorView = UIView()

    /// Buttons rendering `leftItems`, in order.
    public private(set) var leftItemButtons: [LMKButton] = []
    /// Buttons rendering `rightItems`, in order.
    public private(set) var rightItemButtons: [LMKButton] = []
    /// The glass capsules behind the back button and the item groups (`.glass` appearance), leading first.
    public private(set) var itemGlassViews: [LMKGlassView] = []

    /// The look in effect: `.glass` or `.classic`, never `.automatic`.
    public var resolvedAppearance: Appearance {
        let requested = resolved.appearance ?? .automatic
        guard requested != .classic else { return .classic }
        if #available(iOS 26, *) { return .glass }
        return .classic
    }

    // MARK: - Content

    /// The title, shown inline or as the large title.
    public var title: String? {
        didSet {
            titleLabel.lmk_setText(title)
            largeTitleLabel.lmk_setText(title)
            updateAccessibility()
        }
    }

    /// A secondary line under the title (inline: a caption under the centered title;
    /// large: a caption under the large title).
    public var subtitle: String? {
        didSet {
            subtitleLabel.lmk_setText(subtitle)
            largeSubtitleLabel.lmk_setText(subtitle)
            subtitleLabel.isHidden = subtitle == nil
            largeSubtitleLabel.isHidden = subtitle == nil
            updateRowHeights()
            updateAccessibility()
        }
    }

    /// Large title mode (bold, leading-aligned, in its own row). Default `false`.
    public var largeTitleEnabled = false {
        didSet {
            guard largeTitleEnabled != oldValue else { return }
            largeTitleRow.isHidden = !largeTitleEnabled
            titleStack.isHidden = largeTitleEnabled
            updateSeparatorConstraint()
            invalidateIntrinsicContentSize()
        }
    }

    /// Whether the back chevron shows (hidden while left items are set). Default `false`.
    public var showsBackButton = false {
        didSet {
            updateBackButtonVisibility()
            updateItemGlass()
        }
    }

    /// Replaces the default back action (popping the enclosing navigation controller).
    public var onBack: (() -> Void)?

    /// A view drawn behind the bar's content: a hero image, a gradient, an `LMKGlassView`.
    ///
    /// On iOS 26 it is hosted in a `UIBackgroundExtensionView`, so it extends under the
    /// adjacent safe-area and sidebar edges the way a system bar background does; before 26 it
    /// fills the bar's bounds. A `.blur` / `.glass` `surface` renders over it, so a translucent
    /// bar keeps blurring the hero as content scrolls under it.
    public var backgroundContentView: UIView? {
        didSet {
            guard backgroundContentView !== oldValue else { return }
            oldValue?.removeFromSuperview()
            installBackgroundContentView()
        }
    }

    /// The view hosting `backgroundContentView` (a `UIBackgroundExtensionView` on iOS 26).
    public private(set) var backgroundContentHost: UIView?

    /// Items on the leading side, replacing the back button while non-empty.
    public private(set) var leftItems: [LMKNavigationBarItem] = []
    /// Items on the trailing side.
    public private(set) var rightItems: [LMKNavigationBarItem] = []

    /// Per-instance style; `nil` fields resolve from `theme.navigationBar`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKNavigationBar) -> Void)?

    // MARK: - Internal state

    var resolved = Style()
    var badgeViews: [String: LMKBadgeView] = [:]
    var leftItemSizeConstraints: [Constraint] = []
    var rightItemSizeConstraints: [Constraint] = []
    var titleGapConstraints: [Constraint] = []
    var rightAccessoryGapConstraint: Constraint?
    var largeTitleAccessoryGapConstraint: Constraint?
    var largeTitleAccessoryTrailingConstraint: Constraint?
    var buttonRowHeightConstraint: Constraint?
    var largeTitleRowHeightConstraint: Constraint?
    var backLeadingConstraint: Constraint?
    var backSizeConstraint: Constraint?
    var leftMarginConstraint: Constraint?
    var rightMarginConstraint: Constraint?
    var largeTitleLeadingConstraint: Constraint?
    var largeTitleCenterConstraint: Constraint?
    var largeTitleTrailingConstraint: Constraint?
    var separatorHeightConstraint: Constraint?
    var buttonRowHeight: CGFloat = LMKNavigationBar.defaultButtonRowHeight
    var largeTitleRowHeight: CGFloat = LMKNavigationBar.defaultLargeTitleRowHeight
    var separatorThickness: CGFloat = 1
    weak var rightAccessoryView: UIView?
    weak var largeTitleAccessoryView: UIView?
    var scrollEdgeInteraction: UIInteraction?
    weak var pinnedScrollView: UIScrollView?
    var pinsScrollViewUnderBar = false
    /// The tooltips the bar set itself, by button, so a tooltip the host set is never replaced.
    var automaticToolTips: [ObjectIdentifier: String] = [:]

    static let defaultButtonRowHeight: CGFloat = 44
    static let defaultLargeTitleRowHeight: CGFloat = 52
    static let defaultBackSymbolPointSize: CGFloat = 17
    static let defaultBackSymbol = "chevron.backward"

    // MARK: - Initialization

    public init(style: Style = Style()) {
        self.style = style
        super.init(frame: .zero)
        setupUI()
        registerForTraitChanges([UITraitUserInterfaceIdiom.self]) { (bar: Self, _: UITraitCollection) in
            bar.updateToolTips()
        }
        lmk_startApplyingTheme()
    }

    override public convenience init(frame: CGRect) {
        self.init(style: Style())
        self.frame = frame
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Items

    /// Sets the leading items; while non-empty they replace the back button.
    public func setLeftItems(_ items: [LMKNavigationBarItem]) {
        leftItems = items
        (leftItemButtons, leftItemSizeConstraints) = rebuildItems(items, in: leftItemsStack, replacing: leftItemButtons)
        leftItemsStack.isHidden = items.isEmpty
        updateBackButtonVisibility()
        updateItemGlass()
    }

    /// Sets the trailing items.
    public func setRightItems(_ items: [LMKNavigationBarItem]) {
        rightItems = items
        (rightItemButtons, rightItemSizeConstraints) = rebuildItems(items, in: rightItemsStack, replacing: rightItemButtons)
        updateItemGlass()
    }

    /// Mutates the item with `identifier` on either side and re-renders its button in place.
    /// - Returns: Whether an item matched.
    @discardableResult
    public func updateItem(_ identifier: String, _ mutate: (inout LMKNavigationBarItem) -> Void) -> Bool {
        if let index = leftItems.firstIndex(where: { $0.identifier == identifier }) {
            mutate(&leftItems[index])
            configure(leftItemButtons[index], with: leftItems[index])
            updateItemGlass()
            return true
        }
        if let index = rightItems.firstIndex(where: { $0.identifier == identifier }) {
            mutate(&rightItems[index])
            configure(rightItemButtons[index], with: rightItems[index])
            updateItemGlass()
            return true
        }
        return false
    }

    /// The item with `identifier` on either side.
    public func item(withIdentifier identifier: String) -> LMKNavigationBarItem? {
        (leftItems + rightItems).first { $0.identifier == identifier }
    }

    /// The button rendering the item with `identifier`.
    public func button(forItem identifier: String) -> LMKButton? {
        if let index = leftItems.firstIndex(where: { $0.identifier == identifier }) { return leftItemButtons[index] }
        if let index = rightItems.firstIndex(where: { $0.identifier == identifier }) { return rightItemButtons[index] }
        return nil
    }

    // MARK: - Installation

    /// Adds the bar to `parent` pinned to its top, leading, and trailing edges.
    public func install(in parent: UIView) {
        if superview !== parent {
            parent.addSubview(self)
        }
        snp.remakeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(buttonRow)
        buttonRow.addSubview(backButton)
        buttonRow.addSubview(leftItemsStack)
        buttonRow.addSubview(titleStack)
        buttonRow.addSubview(rightItemsStack)
        addSubview(largeTitleRow)
        largeTitleRow.addSubview(largeTitleStack)
        addSubview(separatorView)

        // Both rows keep clear of the side safe areas (landscape, the Dynamic Island); the
        // surface and the background content stay full-bleed.
        buttonRow.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalTo(safeAreaLayoutGuide)
            buttonRowHeightConstraint = make.height.equalTo(Self.defaultButtonRowHeight).constraint
        }

        backButton.isHidden = true
        backButton.accessibilityLabel = strings.backAccessibilityLabel
        backButton.onTap = { [weak self] in self?.backTapped() }
        backButton.snp.makeConstraints { make in
            backLeadingConstraint = make.leading.equalToSuperview().offset(0).constraint
            make.centerY.equalToSuperview()
            backSizeConstraint = make.width.height.equalTo(Self.defaultButtonRowHeight).constraint
        }

        for stack in [leftItemsStack, rightItemsStack] {
            stack.axis = .horizontal
            stack.alignment = .center
        }
        leftItemsStack.isHidden = true
        leftItemsStack.snp.makeConstraints { make in
            leftMarginConstraint = make.leading.equalToSuperview().offset(0).constraint
            make.centerY.equalToSuperview()
        }
        rightItemsStack.snp.makeConstraints { make in
            rightMarginConstraint = make.trailing.equalToSuperview().inset(0).constraint
            make.centerY.equalToSuperview()
        }

        titleStack.axis = .vertical
        titleStack.alignment = .center
        titleStack.spacing = 0
        titleLabel.textAlignment = .center
        subtitleLabel.textAlignment = .center
        subtitleLabel.isHidden = true
        titleStack.addArrangedSubview(titleLabel)
        titleStack.addArrangedSubview(subtitleLabel)
        titleStack.snp.makeConstraints { make in
            // centerX yields to the right items: with many items the stack can cross the
            // center, and a required centerX would force UIKit to break a button's minimum.
            make.centerX.equalToSuperview().priority(.high)
            make.centerY.equalToSuperview()
            titleGapConstraints = [
                make.leading.greaterThanOrEqualTo(backButton.snp.trailing).offset(0).constraint,
                make.leading.greaterThanOrEqualTo(leftItemsStack.snp.trailing).offset(0).constraint,
                make.trailing.lessThanOrEqualTo(rightItemsStack.snp.leading).offset(0).constraint,
            ]
        }

        largeTitleRow.isHidden = true
        largeTitleRow.snp.makeConstraints { make in
            make.top.equalTo(buttonRow.snp.bottom)
            make.leading.trailing.equalTo(safeAreaLayoutGuide)
            largeTitleRowHeightConstraint = make.height.equalTo(Self.defaultLargeTitleRowHeight).constraint
        }
        largeTitleStack.axis = .vertical
        largeTitleStack.alignment = .leading
        largeTitleStack.spacing = 0
        largeSubtitleLabel.isHidden = true
        largeTitleStack.addArrangedSubview(largeTitleLabel)
        largeTitleStack.addArrangedSubview(largeSubtitleLabel)
        largeTitleStack.snp.makeConstraints { make in
            largeTitleLeadingConstraint = make.leading.equalToSuperview().offset(0).constraint
            largeTitleCenterConstraint = make.centerX.equalToSuperview().constraint
            largeTitleTrailingConstraint = make.trailing.lessThanOrEqualToSuperview().inset(0).constraint
            make.centerY.equalToSuperview()
        }
        largeTitleCenterConstraint?.deactivate()
        // Hug the text so an accessory hangs off the actual title, not the row.
        largeTitleLabel.setContentHuggingPriority(.required, for: .horizontal)
        largeTitleStack.setContentHuggingPriority(.required, for: .horizontal)

        titleStack.isUserInteractionEnabled = false
        largeTitleStack.isUserInteractionEnabled = false
        titleLabel.accessibilityTraits = .header
        largeTitleLabel.accessibilityTraits = .header

        updateSeparatorConstraint()
    }

    private func updateSeparatorConstraint() {
        separatorView.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview()
            separatorHeightConstraint = make.height.equalTo(separatorThickness).constraint
            make.top.equalTo(largeTitleEnabled ? largeTitleRow.snp.bottom : buttonRow.snp.bottom)
            make.bottom.equalToSuperview()
        }
    }

    private func updateBackButtonVisibility() {
        backButton.isHidden = !showsBackButton || !leftItems.isEmpty
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        lmk_layoutSurfaceIfNeeded()
        updatePinnedScrollViewInsets()
    }

    override public func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        invalidateIntrinsicContentSize()
    }

    override public var intrinsicContentSize: CGSize {
        let rows = buttonRowHeight + (largeTitleEnabled ? largeTitleRowHeight : 0)
        return CGSize(width: UIView.noIntrinsicMetric, height: safeAreaInsets.top + rows + separatorThickness)
    }

    // MARK: - Item rendering

    /// Builds one button per item in `stack`, replacing `old`; the size constraints come back
    /// with the buttons so a side's list is replaced, never appended to.
    private func rebuildItems(_ items: [LMKNavigationBarItem], in stack: UIStackView, replacing old: [LMKButton]) -> (buttons: [LMKButton], sizeConstraints: [Constraint]) {
        for button in old {
            button.removeFromSuperview()
            automaticToolTips[ObjectIdentifier(button)] = nil
        }
        let removedIdentifiers = Set(badgeViews.keys).subtracting((leftItems + rightItems).map(\.identifier))
        for identifier in removedIdentifiers {
            badgeViews[identifier]?.removeFromSuperview()
            badgeViews[identifier] = nil
        }
        var sizeConstraints: [Constraint] = []
        let buttons = items.map { item in
            let button = LMKButton(style: LMKButton.Style())
            stack.addArrangedSubview(button)
            button.snp.makeConstraints { make in
                sizeConstraints.append(make.width.height.greaterThanOrEqualTo(resolved.itemSize ?? Self.defaultButtonRowHeight).constraint)
            }
            configure(button, with: item)
            return button
        }
        return (buttons, sizeConstraints)
    }

    /// Applies `item`'s content, state, menu, badge, and role style to `button`.
    func configure(_ button: LMKButton, with item: LMKNavigationBarItem) {
        button.style = itemButtonStyle(for: item)
        button.title = item.title
        button.image = item.image
        button.isEnabled = item.isEnabled
        button.menu = item.menu
        button.showsMenuAsPrimaryAction = item.menu != nil && item.action == nil
        button.onTap = item.action
        button.accessibilityLabel = item.accessibilityLabel ?? item.title
        button.accessibilityIdentifier = item.identifier
        updateToolTip(of: button, to: item.image == nil ? nil : item.accessibilityLabel ?? item.title)
        updateBadge(for: item, on: button)
    }

    /// Under the Mac idiom a glyph item (and the back button) shows its label as a tooltip on
    /// hover, unless the host gave the button a tooltip of its own.
    func updateToolTips() {
        for (button, item) in Array(zip(leftItemButtons, leftItems)) + Array(zip(rightItemButtons, rightItems)) {
            updateToolTip(of: button, to: item.image == nil ? nil : item.accessibilityLabel ?? item.title)
        }
        updateToolTip(of: backButton, to: strings.backAccessibilityLabel)
    }

    func updateToolTip(of button: UIButton, to text: String?) {
        let key = ObjectIdentifier(button)
        guard Self.ownsToolTip(button.toolTip, automatic: automaticToolTips[key]) else { return }
        let wanted = traitCollection.userInterfaceIdiom == .mac ? text : nil
        button.toolTip = wanted
        automaticToolTips[key] = wanted
    }

    /// Whether the bar may set a button's tooltip: it has none, or the one the bar set itself.
    static func ownsToolTip(_ current: String?, automatic: String?) -> Bool {
        current == nil || current == automatic
    }

    private func updateBadge(for item: LMKNavigationBarItem, on button: LMKButton) {
        guard let content = item.badge else {
            badgeViews[item.identifier]?.removeFromSuperview()
            badgeViews[item.identifier] = nil
            return
        }
        let badge = badgeViews[item.identifier] ?? {
            let badge = LMKBadgeView()
            badge.isUserInteractionEnabled = false
            buttonRow.addSubview(badge)
            badgeViews[item.identifier] = badge
            return badge
        }()
        let nudge = traitCollection.lmkTheme.spacing.xs
        badge.snp.remakeConstraints { make in
            // On the item's top trailing corner, and inside the bar's safe area: a host that
            // clips the bar (a card, a rounded container) never cuts the badge.
            make.centerX.equalTo(button.snp.trailing).offset(-nudge).priority(.high)
            make.centerY.equalTo(button.snp.top).offset(nudge).priority(.high)
            make.top.greaterThanOrEqualTo(self)
            make.trailing.lessThanOrEqualTo(safeAreaLayoutGuide)
        }
        badge.configure(content)
    }

    /// The button style for `item`: the base item style in the bar tint, then the role's overrides.
    func itemButtonStyle(for item: LMKNavigationBarItem) -> LMKButton.Style {
        let theme = traitCollection.lmkTheme
        let isGlass = resolvedAppearance == .glass
        // A title needs room inside its capsule; a glyph is centered in the item's square.
        let horizontalInset = isGlass && item.title != nil ? theme.spacing.medium : theme.spacing.small
        var style = LMKButton.Style(
            variant: .ghost,
            size: .small,
            surface: LMKSurfaceStyle(corners: .capsule, contentInsets: .lmk_symmetric(vertical: theme.spacing.xs, horizontal: horizontalInset)),
            tintColor: itemTint,
            textStyle: resolved.itemTextStyle ?? .body,
            symbolPointSize: resolved.backSymbolPointSize ?? Self.defaultBackSymbolPointSize,
            pressAnimation: false,
            haptics: false
        ).merging(resolved.item)
        switch item.role {
        case .plain:
            break
        case .prominent:
            if isGlass {
                // The tinted capsule behind the item is the fill; the item draws on it.
                let fill = resolved.tintColor ?? LMKColor.primary
                style = style.merging(LMKButton.Style(foregroundColor: LMKColor.onFill(fill, preferred: LMKColor.onAccent), textStyle: .subbodyMedium))
                var prominent = resolved.prominentItem
                prominent.variant = nil
                style = style.merging(prominent)
            } else {
                style = style.merging(LMKButton.Style(variant: .filled, textStyle: .subbodyMedium)).merging(resolved.prominentItem)
            }
        case .destructive:
            style = style.merging(LMKButton.Style(role: .destructive, tintColor: LMKColor.error))
        }
        return style
    }

    /// Glyphs and titles: the bar tint, or the label color on glass (the system bar's choice).
    private var itemTint: UIColor {
        resolved.tintColor ?? (resolvedAppearance == .glass ? LMKColor.textPrimary : LMKColor.primary)
    }

    // MARK: - Glass

    /// A run of items that shares one capsule: neighbours, until a prominent item takes its own.
    struct ItemGroup: Equatable {
        var range: Range<Int>
        var isProminent: Bool
    }

    /// Groups `items` the way the system bar shares backgrounds.
    static func groups(for items: [LMKNavigationBarItem]) -> [ItemGroup] {
        var groups: [ItemGroup] = []
        for (index, item) in items.enumerated() {
            let isProminent = item.role == .prominent
            if !isProminent, let last = groups.last, !last.isProminent {
                groups[groups.count - 1].range = last.range.lowerBound ..< index + 1
            } else {
                groups.append(ItemGroup(range: index ..< index + 1, isProminent: isProminent))
            }
        }
        return groups
    }

    /// Rebuilds the capsules behind the back button and the item groups, and the gaps between
    /// groups. Without glass, every gap is the item spacing and no capsule shows.
    func updateItemGlass() {
        itemGlassViews.forEach { $0.removeFromSuperview() }
        itemGlassViews = []
        let theme = traitCollection.lmkTheme
        let isGlass = resolvedAppearance == .glass
        for (stack, buttons, items) in [(leftItemsStack, leftItemButtons, leftItems), (rightItemsStack, rightItemButtons, rightItems)] {
            stack.spacing = isGlass ? 0 : (resolved.itemSpacing ?? theme.spacing.xs)
            for button in buttons {
                stack.setCustomSpacing(UIStackView.spacingUseDefault, after: button)
            }
            guard isGlass else { continue }
            for group in Self.groups(for: items) {
                let members = Array(buttons[group.range])
                guard let first = members.first, let last = members.last else { continue }
                if group.range.upperBound < buttons.count {
                    stack.setCustomSpacing(resolved.itemSpacing ?? theme.spacing.small, after: last)
                }
                addItemGlass(from: first, to: last, isProminent: group.isProminent)
            }
        }
        if isGlass, !backButton.isHidden {
            addItemGlass(from: backButton, to: backButton, isProminent: false)
        }
    }

    private func addItemGlass(from first: UIView, to last: UIView, isProminent: Bool) {
        let tint = isProminent ? (resolved.tintColor ?? LMKColor.primary) : nil
        let glass = LMKGlassView(style: LMKGlassView.Style(variant: .regular, tintColor: tint, corners: .capsule, isInteractive: true).merging(resolved.itemGlass))
        // The items above the glass take the touches.
        glass.isUserInteractionEnabled = false
        glass.accessibilityElementsHidden = true
        buttonRow.insertSubview(glass, at: 0)
        glass.snp.makeConstraints { make in
            make.leading.equalTo(first)
            make.trailing.equalTo(last)
            make.top.bottom.equalTo(first)
        }
        itemGlassViews.append(glass)
    }

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        resolved = theme.navigationBar.merging(style)
        lmk_apply(
            surface: resolved.surface,
            defaults: LMKSurfaceStyle(background: .solid(LMKColor.backgroundPrimary), corners: LMKCornerStyle.square, shadow: LMKShadowSource.hidden),
            clipsContent: false
        )
        if let backgroundContentHost {
            // The surface may have inserted a blur or glass view at index 0; the hero stays beneath it.
            sendSubviewToBack(backgroundContentHost)
        }

        let titleStyle = resolved.titleTextStyle ?? Self.defaultTitleTextStyle
        let largeTitleStyle = resolved.largeTitleTextStyle ?? Self.defaultLargeTitleTextStyle
        let subtitleStyle = resolved.subtitleTextStyle ?? .caption
        titleLabel.lmk_apply(titleStyle, color: resolved.titleColor ?? LMKColor.textPrimary)
        largeTitleLabel.lmk_apply(largeTitleStyle, color: resolved.largeTitleColor ?? LMKColor.textPrimary)
        subtitleLabel.lmk_apply(subtitleStyle, color: resolved.subtitleColor ?? LMKColor.textSecondary)
        largeSubtitleLabel.lmk_apply(subtitleStyle, color: resolved.subtitleColor ?? LMKColor.textSecondary)

        let isGlass = resolvedAppearance == .glass
        backButton.style = LMKButton.Style(
            variant: .ghost,
            surface: LMKSurfaceStyle(corners: .circle),
            tintColor: itemTint,
            pressAnimation: false,
            haptics: false
        ).merging(resolved.item)
        backButton.setSymbol(resolved.backSymbol ?? Self.defaultBackSymbol, pointSize: resolved.backSymbolPointSize ?? Self.defaultBackSymbolPointSize, weight: .medium)
        updateToolTip(of: backButton, to: strings.backAccessibilityLabel)
        for (button, item) in zip(leftItemButtons, leftItems) {
            configure(button, with: item)
        }
        for (button, item) in zip(rightItemButtons, rightItems) {
            configure(button, with: item)
        }

        let itemSize = resolved.itemSize ?? theme.layout.minimumTouchTarget
        let margin = resolved.contentMargin ?? theme.spacing.large
        // On glass the chevron's circle starts at the content margin, like the items' capsules.
        backLeadingConstraint?.update(offset: resolved.backChevronLeading ?? (isGlass ? margin : theme.spacing.small))
        backSizeConstraint?.update(offset: itemSize)
        (leftItemSizeConstraints + rightItemSizeConstraints).forEach { $0.update(offset: itemSize) }
        leftMarginConstraint?.update(offset: margin)
        rightMarginConstraint?.update(inset: margin)
        let gap = theme.spacing.small
        for (index, constraint) in titleGapConstraints.enumerated() {
            constraint.update(offset: index == titleGapConstraints.count - 1 ? -gap : gap)
        }
        rightAccessoryGapConstraint?.update(offset: -gap)
        largeTitleAccessoryGapConstraint?.update(offset: gap)
        largeTitleAccessoryTrailingConstraint?.update(inset: margin)
        updateItemGlass()
        largeTitleLeadingConstraint?.update(offset: margin)
        largeTitleTrailingConstraint?.update(inset: margin)
        let alignment = resolved.largeTitleAlignment ?? .leading
        largeTitleStack.alignment = alignment == .center ? .center : .leading
        largeTitleLabel.textAlignment = alignment == .center ? .center : .natural
        largeSubtitleLabel.textAlignment = largeTitleLabel.textAlignment
        if alignment == .center {
            largeTitleLeadingConstraint?.deactivate()
            largeTitleCenterConstraint?.activate()
        } else {
            largeTitleCenterConstraint?.deactivate()
            largeTitleLeadingConstraint?.activate()
        }

        separatorView.isHidden = !(resolved.showsSeparator ?? !isGlass)
        separatorView.backgroundColor = resolved.separatorColor ?? LMKColor.divider
        separatorThickness = resolved.separatorThickness ?? LMKLayout.hairline(for: self)
        separatorHeightConstraint?.update(offset: separatorThickness)

        updateRowHeights()
        invalidateIntrinsicContentSize()
        didApplyStyle?(self)
    }

    /// (Re)installs `backgroundContentView` behind everything, in a `UIBackgroundExtensionView` on iOS 26.
    private func installBackgroundContentView() {
        backgroundContentHost?.removeFromSuperview()
        backgroundContentHost = nil
        guard let backgroundContentView else { return }
        backgroundContentView.removeFromSuperview()
        let host: UIView
        if #available(iOS 26, *) {
            let extensionView = UIBackgroundExtensionView()
            extensionView.contentView = backgroundContentView
            extensionView.automaticallyPlacesContentView = true
            host = extensionView
        } else {
            host = UIView()
            host.addSubview(backgroundContentView)
            backgroundContentView.snp.makeConstraints { $0.edges.equalToSuperview() }
        }
        host.isUserInteractionEnabled = false
        host.accessibilityElementsHidden = true
        insertSubview(host, at: 0)
        host.snp.makeConstraints { $0.edges.equalToSuperview() }
        backgroundContentHost = host
    }

    /// Recomputes both row floors from the current fonts (Dynamic Type) and the subtitle.
    func updateRowHeights() {
        let theme = traitCollection.lmkTheme
        let titleStyle = resolved.titleTextStyle ?? Self.defaultTitleTextStyle
        let largeTitleStyle = resolved.largeTitleTextStyle ?? Self.defaultLargeTitleTextStyle
        let subtitleStyle = resolved.subtitleTextStyle ?? .caption
        let subtitleHeight = subtitle == nil ? 0 : LMKTextMeasurement.lineHeight(of: subtitleStyle, traits: traitCollection)

        let titleHeight = LMKTextMeasurement.lineHeight(of: titleStyle, traits: traitCollection)
        buttonRowHeight = max(resolved.buttonRowHeight ?? Self.defaultButtonRowHeight, titleHeight + subtitleHeight + theme.spacing.xs * 2)
        buttonRowHeightConstraint?.update(offset: buttonRowHeight)

        let largeHeight = LMKTextMeasurement.lineHeight(of: largeTitleStyle, traits: traitCollection)
        largeTitleRowHeight = max(resolved.largeTitleRowHeight ?? Self.defaultLargeTitleRowHeight, largeHeight + subtitleHeight + theme.spacing.xs)
        largeTitleRowHeightConstraint?.update(offset: largeTitleRowHeight)
        invalidateIntrinsicContentSize()
    }

    // MARK: - Accessibility

    private func updateAccessibility() {
        let label = [title, subtitle].compactMap(\.self).joined(separator: ", ")
        titleLabel.accessibilityLabel = label.isEmpty ? nil : label
        largeTitleLabel.accessibilityLabel = titleLabel.accessibilityLabel
        subtitleLabel.isAccessibilityElement = false
        largeSubtitleLabel.isAccessibilityElement = false
    }

    // MARK: - Actions

    private func backTapped() {
        if let onBack {
            onBack()
        } else {
            findNavigationController()?.popViewController(animated: true)
        }
    }

    private func findNavigationController() -> UINavigationController? {
        var responder: UIResponder? = self
        while let next = responder?.next {
            if let navigation = next as? UINavigationController {
                return navigation
            }
            responder = next
        }
        return nil
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKNavigationBar`.
    var navigationBar: LMKNavigationBar.Style {
        get { self[LMKNavigationBar.Style.self] }
        set { self[LMKNavigationBar.Style.self] = newValue }
    }
}
