//
//  LMKTabBarController.swift
//  LumiKit
//
//  A `UITabBarController` built from `LMKTab`s on the iOS 18 `UITab` model:
//  lazy roots, identifier-based selection through `selectedTab`
//  (never the tab bar's own items), reordering, badges, ⌘1…N key commands,
//  themed appearance, and the iOS 26 minimize behavior and bottom accessory.
//

import UIKit

/// A themed tab bar controller.
///
/// ```swift
/// let tabBar = LMKTabBarController(tabs: [
///     LMKTab(identifier: "pets", title: "Pets", systemImage: "pawprint.fill") { PetsViewController() },
///     LMKTab(identifier: "calendar", title: "Calendar", systemImage: "calendar") { CalendarViewController() },
/// ])
/// tabBar.onTabSelect = { identifier in ... }
/// tabBar.selectTab(identifier: "calendar")
/// ```
///
/// Each root is wrapped by `navigationControllerFactory` (an `LMKNavigationController` by
/// default). Selection goes through `selectedTab`, the tab model's own API: it applies before the
/// view loads (a launch-tab preference set from `viewDidLoad`) and refreshes the highlight on Mac
/// Catalyst and iPad from menu and key-command paths where `selectedIndex` does not.
open class LMKTabBarController: UITabBarController, LMKThemeApplying {
    // MARK: - Properties

    /// The tab definitions, in display order (`reorderTabs(identifiers:)` filters this list;
    /// `tab(identifier:)` still knows every tab the controller was built with).
    public private(set) var tabDefinitions: [LMKTab]

    /// Wraps each root in a navigation controller.
    public let navigationControllerFactory: @MainActor (UIViewController) -> UINavigationController

    /// Per-instance style; `nil` fields resolve from `theme.tabBar`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue, isViewLoaded else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKTabBarController) -> Void)?

    /// The style last resolved against the theme.
    public private(set) var resolvedStyle = Style()

    /// Called once whenever the selected tab changes (a tap, a key command, or `selectTab`).
    public var onTabSelect: ((String) -> Void)?
    /// Called when the user taps the already-selected tab (UIKit pops its stack to the root).
    public var onTabReselect: ((String) -> Void)?

    /// Whether ⌘1…⌘9 select tabs. `nil` (the default) enables them except under the Mac idiom,
    /// where the app's menu bar owns those shortcuts.
    public var tabKeyCommandsEnabled: Bool?

    /// Every definition by identifier, never pruned: a tab filtered out by `reorderTabs` keeps
    /// its root factory and badge for when it is shown again.
    private var definitions: [String: LMKTab]
    private var uiTabs: [String: UITab] = [:]
    /// Definition identifiers by `UITab` identity (a `UISearchTab`'s own identifier is UIKit's).
    private var definitionIdentifiers: [ObjectIdentifier: String] = [:]
    /// Roots built so far, by identifier (a lazy tab's navigation controller holds a placeholder until then).
    private var roots: [String: UIViewController] = [:]
    private var bottomAccessoryView: UIView?
    private var lastReportedIdentifier: String?
    /// `UITabBarController` loads its view during `init`, before `tabs` is assigned, so a
    /// subclass's `viewDidLoad` runs while the tab list is still empty and any reorder or
    /// selection it makes would be lost. Until `init` finishes, those calls are recorded and
    /// replayed once the tabs are installed.
    private var isInstallingTabs = true
    private var pendingOrder: [String]?
    private var pendingSelection: String?

    // MARK: - Initialization

    public init(
        tabs: [LMKTab],
        style: Style = Style(),
        navigationControllerFactory: (@MainActor (UIViewController) -> UINavigationController)? = nil
    ) {
        tabDefinitions = tabs
        definitions = Dictionary(tabs.map { ($0.identifier, $0) }, uniquingKeysWith: { first, _ in first })
        self.style = style
        self.navigationControllerFactory = navigationControllerFactory ?? { LMKNavigationController(rootViewController: $0) }
        super.init(nibName: nil, bundle: nil)
        self.tabs = tabs.map(makeUITab)
        isInstallingTabs = false
        for tab in tabs where !tab.isLazy {
            loadRoot(for: tab.identifier)
        }
        if let pendingOrder {
            self.pendingOrder = nil
            reorderTabs(identifiers: pendingOrder)
        }
        if let pendingSelection {
            self.pendingSelection = nil
            selectTab(identifier: pendingSelection)
        }
        // `UITabBarController` loads its view (and ran `applyTheme` through `viewDidLoad`)
        // before the tabs existed; the per-tab settings need a pass over the real tabs.
        if isViewLoaded {
            applyTheme(traitCollection.lmkTheme)
        }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override open func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        if let selected = selectedTab.map(definitionIdentifier(of:)) {
            loadRoot(for: selected)
            lastReportedIdentifier = selected
        }
        registerForTraitChanges([UITraitHorizontalSizeClass.self]) { (controller: Self, _: UITraitCollection) in
            controller.updateMode()
        }
        lmk_startApplyingTheme()
    }

    // MARK: - Theme

    open func applyTheme(_ theme: LMKTheme) {
        resolvedStyle = theme.tabBar.merging(style)
        LMKTabBarAppearance.apply(resolvedStyle, to: tabBar, theme: theme)
        if #available(iOS 26, *), let minimizes = resolvedStyle.minimizesOnScroll {
            tabBarMinimizeBehavior = minimizes ? .onScrollDown : .never
        }
        if #available(iOS 26, *), let activates = resolvedStyle.automaticallyActivatesSearch {
            for case let search as UISearchTab in tabs {
                search.automaticallyActivatesSearch = activates
            }
        }
        updateMode()
        applyContentTheme(theme)
        didApplyStyle?(self)
    }

    /// Override to style what a subclass adds. Called from every `applyTheme(_:)` after the bar
    /// is styled and before `didApplyStyle`.
    open func applyContentTheme(_ theme: LMKTheme) {}

    private func updateMode() {
        let wantsSidebar = resolvedStyle.prefersSidebarOnIPad ?? false
        let regular = traitCollection.horizontalSizeClass == .regular && (traitCollection.userInterfaceIdiom == .pad || traitCollection.userInterfaceIdiom == .mac)
        mode = wantsSidebar && regular ? .tabSidebar : .tabBar
    }

    // MARK: - Tabs

    /// UIKit builds every tab's view controller when the tab bar loads, so a lazy tab starts with
    /// a placeholder root that `loadRoot(for:)` swaps for the real one on first selection.
    private func makeUITab(_ definition: LMKTab) -> UITab {
        let factory = navigationControllerFactory
        let provider: (UITab) -> UIViewController = { tab in
            let navigation = factory(LMKLazyTabPlaceholderViewController())
            navigation.tabBarItem.accessibilityLabel = definition.accessibilityLabel ?? (definition.title.isEmpty ? tab.title : definition.title)
            return navigation
        }
        let tab: UITab
        switch definition.role {
        case .standard:
            tab = UITab(title: definition.title, image: definition.image, identifier: definition.identifier, viewControllerProvider: provider)
        case .search:
            // The system supplies the title, glyph, and `identifier`; an explicit title or image
            // from the definition wins, and `definitionIdentifier(of:)` maps the system identifier back.
            let search = UISearchTab(viewControllerProvider: provider)
            if !definition.title.isEmpty { search.title = definition.title }
            if let image = definition.image { search.image = image }
            tab = search
        }
        tab.badgeValue = LMKTab.badgeValue(for: definition.badge)
        uiTabs[definition.identifier] = tab
        definitionIdentifiers[ObjectIdentifier(tab)] = definition.identifier
        return tab
    }

    /// The `LMKTab` identifier behind a `UITab` (a `UISearchTab` carries a system identifier).
    private func definitionIdentifier(of tab: UITab) -> String {
        definitionIdentifiers[ObjectIdentifier(tab)] ?? tab.identifier
    }

    /// Builds the tab's root (once) and installs it in its navigation controller.
    @discardableResult
    public func loadRoot(for identifier: String) -> UIViewController? {
        if let root = roots[identifier] { return root }
        guard let definition = definitions[identifier], let tab = uiTabs[identifier] else { return nil }
        let root = definition.makeRoot()
        roots[identifier] = root
        if let navigation = tab.viewController as? UINavigationController {
            navigation.setViewControllers([root], animated: false)
        }
        return root
    }

    /// The identifiers in display order.
    public var identifiers: [String] {
        tabs.map(definitionIdentifier(of:))
    }

    /// The selected tab's identifier; setting it selects that tab.
    public var selectedIdentifier: String? {
        get { selectedTab.map(definitionIdentifier(of:)) }
        set {
            if let newValue { selectTab(identifier: newValue) }
        }
    }

    /// Selects the tab with `identifier`. Returns `false` when there is none.
    @discardableResult
    public func selectTab(identifier: String) -> Bool {
        if isInstallingTabs {
            guard tabDefinitions.contains(where: { $0.identifier == identifier }) else { return false }
            pendingSelection = identifier
            return true
        }
        guard let tab = uiTabs[identifier], tabs.contains(where: { $0 === tab }) else { return false }
        loadRoot(for: identifier)
        // `selectedTab` is the `UITab` model's selection API and works before the view
        // is loaded (a launch-tab preference applied from `viewDidLoad`); assigning
        // `selectedViewController` there is ignored by a tab-model controller.
        selectedTab = tab
        reportSelectionIfChanged(identifier)
        return true
    }

    private func reportSelectionIfChanged(_ identifier: String) {
        guard identifier != lastReportedIdentifier else { return }
        lastReportedIdentifier = identifier
        onTabSelect?(identifier)
    }

    /// Reorders (and filters) the tabs; unknown identifiers are ignored, the selection is kept.
    /// A tab left out stays known to `tab(identifier:)` and can be shown again by a later call.
    public func reorderTabs(identifiers: [String]) {
        if isInstallingTabs {
            pendingOrder = identifiers
            return
        }
        let selected = selectedIdentifier
        let ordered = identifiers.compactMap { uiTabs[$0] }
        guard !ordered.isEmpty else { return }
        tabs = ordered
        tabDefinitions = identifiers.compactMap { definitions[$0] }
        if let selected, ordered.contains(where: { definitionIdentifier(of: $0) == selected }) {
            selectTab(identifier: selected)
        } else if let replacement = selectedIdentifier {
            // The selected tab was filtered out and UIKit moved the selection: build that
            // tab's root and report the change the way a tap would.
            loadRoot(for: replacement)
            reportSelectionIfChanged(replacement)
        }
    }

    /// The tab definition for `identifier`, whether or not it is currently shown.
    public func tab(identifier: String) -> LMKTab? {
        definitions[identifier]
    }

    /// The navigation controller wrapping the tab's root, once built.
    public func navigationController(for identifier: String) -> UINavigationController? {
        uiTabs[identifier]?.viewController as? UINavigationController
    }

    /// The tab's root view controller, once built (`loadRoot(for:)` builds it on demand).
    public func rootViewController(for identifier: String) -> UIViewController? {
        roots[identifier]
    }

    /// Whether the tab's root has been built yet.
    public func isRootLoaded(for identifier: String) -> Bool {
        roots[identifier] != nil
    }

    /// Sets or clears the tab's badge (kept for a tab that is currently filtered out).
    public func setBadge(_ content: LMKBadgeView.Content?, for identifier: String) {
        uiTabs[identifier]?.badgeValue = LMKTab.badgeValue(for: content)
        definitions[identifier]?.badge = content
        if let index = tabDefinitions.firstIndex(where: { $0.identifier == identifier }) {
            tabDefinitions[index].badge = content
        }
    }

    /// Installs (or removes, with `nil`) an iOS 26 bottom accessory above the tab bar; a no-op before.
    public func setBottomAccessory(_ view: UIView?) {
        bottomAccessoryView = view
        if #available(iOS 26, *) {
            bottomAccessory = view.map { UITabAccessory(contentView: $0) }
        }
    }

    /// The accessory installed with `setBottomAccessory(_:)`.
    public var bottomAccessoryContentView: UIView? {
        bottomAccessoryView
    }

    // MARK: - Key commands

    /// Whether ⌘1…⌘9 are provided in the current environment.
    public var providesTabKeyCommands: Bool {
        tabKeyCommandsEnabled ?? (traitCollection.userInterfaceIdiom != .mac)
    }

    override open var keyCommands: [UIKeyCommand]? {
        // A presented controller's responder chain reaches its presenter, so the shortcuts
        // would otherwise switch tabs under a modal.
        guard providesTabKeyCommands, presentedViewController == nil else { return super.keyCommands }
        let commands = tabs.prefix(9).enumerated().map { index, tab in
            let command = UIKeyCommand(title: tab.title, action: #selector(handleTabKeyCommand(_:)), input: String(index + 1), modifierFlags: .command, propertyList: definitionIdentifier(of: tab))
            command.discoverabilityTitle = tab.title
            return command
        }
        return commands + (super.keyCommands ?? [])
    }

    override open var canBecomeFirstResponder: Bool { true }

    @objc private func handleTabKeyCommand(_ command: UIKeyCommand) {
        guard let identifier = command.propertyList as? String else { return }
        selectTab(identifier: identifier)
    }
}

/// The root a lazy tab holds until its real root is built.
final class LMKLazyTabPlaceholderViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = LMKColor.backgroundPrimary
    }
}

// MARK: - UITabBarControllerDelegate

extension LMKTabBarController: UITabBarControllerDelegate {
    open func tabBarController(_: UITabBarController, shouldSelectTab tab: UITab) -> Bool {
        loadRoot(for: definitionIdentifier(of: tab))
        return true
    }

    open func tabBarController(_: UITabBarController, didSelectTab selectedTab: UITab, previousTab: UITab?) {
        let identifier = definitionIdentifier(of: selectedTab)
        loadRoot(for: identifier)
        if let previousTab, definitionIdentifier(of: previousTab) == identifier {
            onTabReselect?(identifier)
        } else {
            reportSelectionIfChanged(identifier)
        }
    }
}
