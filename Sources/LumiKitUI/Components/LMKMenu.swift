//
//  LMKMenu.swift
//  LumiKit
//
//  Option menus as native `UIMenu`s: sections of single choices, toggles,
//  sorts with a direction, commands, and submenus. The sections are rebuilt
//  from the host's state every time the menu opens. Anchors natively on
//  iPad / Mac and renders in Liquid Glass on iOS 26.
//

import UIKit

/// Builds option menus for bar buttons, `LMKNavigationBar` items, and `LMKButton`s.
///
/// ```swift
/// let menu = LMKMenu.make(sections: [
///     .sort(options: [.init(id: Sort.name, title: "Name"), .init(id: Sort.date, title: "Date")],
///           selected: { [weak self] in (self?.sort, self?.direction ?? .ascending) },
///           onSelect: { [weak self] sort, direction in self?.apply(sort, direction) }),
///     .single(title: "Layout",
///             options: [.init(id: Layout.list, title: "List", systemImageName: "list.bullet"),
///                       .init(id: Layout.grid, title: "Grid", systemImageName: "square.grid.2x2")],
///             selected: { [weak self] in self?.layout },
///             onSelect: { [weak self] in self?.layout = $0 }),
///     .multiple(title: "Show",
///               options: [.init(id: Filter.archived, title: "Archived")],
///               selected: { [weak self] in self?.filters ?? [] },
///               onToggle: { [weak self] filter, isOn in self?.set(filter, isOn) }),
///     .actions([.init(title: "Select…", systemImageName: "checkmark.circle") { [weak self] in self?.beginSelecting() }]),
/// ])
/// navigationItem.rightBarButtonItem = LMKMenu.makeBarButtonItem(menu: menu, systemImageName: "ellipsis", accessibilityLabel: "Options")
/// ```
///
/// A toggle and a re-tapped sort keep the menu open and update in place; any other row closes
/// it. `selected` closures are read each time the menu opens and after every row that keeps it
/// open, so the checkmarks always show the host's current values.
public enum LMKMenu {
    // MARK: - Vocabulary

    /// One choice in a `single`, `multiple`, or `sort` section.
    public nonisolated struct Option<ID: Hashable & Sendable>: Sendable, Hashable {
        public var id: ID
        public var title: String
        public var subtitle: String?
        /// A leading SF Symbol.
        public var systemImageName: String?
        public var isEnabled: Bool

        public init(id: ID, title: String, subtitle: String? = nil, systemImageName: String? = nil, isEnabled: Bool = true) {
            self.id = id
            self.title = title
            self.subtitle = subtitle
            self.systemImageName = systemImageName
            self.isEnabled = isEnabled
        }
    }

    /// One command in an `actions` section.
    public struct Action {
        public var title: String
        public var subtitle: String?
        public var systemImageName: String?
        public var isDestructive: Bool
        public var isEnabled: Bool
        public var handler: @MainActor () -> Void

        public init(
            title: String,
            subtitle: String? = nil,
            systemImageName: String? = nil,
            isDestructive: Bool = false,
            isEnabled: Bool = true,
            handler: @escaping @MainActor () -> Void
        ) {
            self.title = title
            self.subtitle = subtitle
            self.systemImageName = systemImageName
            self.isDestructive = isDestructive
            self.isEnabled = isEnabled
            self.handler = handler
        }
    }

    /// One group of rows. Sections show inline, separated by the system's dividers, except
    /// `submenu`, which shows one row that opens its own sections.
    public struct Section {
        /// The heading over the rows (a submenu's row title).
        public var title: String?
        let options: UIMenu.Options
        let systemImageName: String?
        let makeElements: @MainActor () -> [UIMenuElement]
        /// Stable across rebuilds, so an open submenu can be matched to its rebuilt self.
        let identifier = UIMenu.Identifier("lumikit.menu.section." + UUID().uuidString)

        /// The section as a menu, built from the host's current state.
        @MainActor
        func makeMenu() -> UIMenu {
            UIMenu(title: title ?? "", image: systemImageName.flatMap(UIImage.init(systemName:)), identifier: identifier, options: options, children: makeElements())
        }
    }

    /// One menu made by `make(title:sections:)`: what rebuilds it while it is open. The menu's
    /// deferred element keeps it alive for as long as any copy of the menu exists.
    @MainActor
    final class Root {
        let identifier = UIMenu.Identifier("lumikit.menu." + UUID().uuidString)
        let title: String
        let sections: [Section]

        init(title: String, sections: [Section]) {
            self.title = title
            self.sections = sections
        }

        /// The menu: one deferred element that reads the sections' state on each open.
        func makeMenu() -> UIMenu {
            let deferred = UIDeferredMenuElement.uncached { completion in
                completion(LMKMenu.makeElements(sections: self.sections))
            }
            return UIMenu(title: title, identifier: identifier, children: [deferred])
        }

        /// `visible` (this menu or one of its open submenus) with rows from the current state;
        /// `nil` when `visible` is not part of this menu.
        func refreshed(_ visible: UIMenu) -> UIMenu? {
            let elements = LMKMenu.makeElements(sections: sections)
            if visible.identifier == identifier {
                return visible.replacingChildren(elements)
            }
            return LMKMenu.menu(withIdentifier: visible.identifier, in: elements).map { visible.replacingChildren($0.children) }
        }
    }

    private struct WeakRoot {
        weak var root: Root?
    }

    /// The live menus by identifier. A `UIButton` or bar button stores a copy of its menu, and
    /// the identifier is what survives the copy.
    private static var roots: [UIMenu.Identifier: WeakRoot] = [:]

    // MARK: - Menus

    /// A menu of `sections`, rebuilt from their `selected` closures each time it opens and
    /// after every row that keeps it open.
    public static func make(title: String = "", sections: [Section]) -> UIMenu {
        let root = Root(title: title, sections: sections)
        roots = roots.filter { $0.value.root != nil }
        roots[root.identifier] = WeakRoot(root: root)
        return root.makeMenu()
    }

    /// The sections as menus (what the deferred element rebuilds on each open).
    static func makeElements(sections: [Section]) -> [UIMenuElement] {
        sections.map { $0.makeMenu() }
    }

    /// Rebuilds the menu `action` was chosen from while it stays open, so its checkmarks,
    /// arrows, and subtitles show the host's new state. The toggle and sort sections call this
    /// themselves; call it from the handler of a `.keepsMenuPresented` action in a `custom`
    /// section. (Changing `action.state` in a handler does not repaint an open menu.)
    ///
    /// Works for menus made by `make(title:sections:)` and shown from a bar button, a button,
    /// an `LMKNavigationBar` item, or a view's context menu interaction.
    public static func reloadVisibleMenu(presenting action: UIAction) {
        reloadVisibleMenu(presentedFrom: action.presentationSourceItem)
    }

    static func reloadVisibleMenu(presentedFrom source: (any UIPopoverPresentationControllerSourceItem)?) {
        if let item = source as? UIBarButtonItem {
            // A bar button has no interaction to update: a fresh menu with the same identifier takes over in place.
            if let root = item.menu.flatMap({ roots[$0.identifier]?.root }) {
                item.menu = root.makeMenu()
            }
            return
        }
        guard let view = source as? UIView else { return }
        let button = view as? UIButton
        let owned = button?.menu.flatMap { roots[$0.identifier]?.root }
        var interactions = view.interactions.compactMap { $0 as? UIContextMenuInteraction }
        if let interaction = button?.contextMenuInteraction, !interactions.contains(where: { $0 === interaction }) {
            interactions.append(interaction)
        }
        for interaction in interactions {
            interaction.updateVisibleMenu { visible in
                if let owned {
                    return owned.refreshed(visible) ?? visible
                }
                return roots.values.lazy.compactMap { $0.root?.refreshed(visible) }.first ?? visible
            }
        }
    }

    /// The menu with `identifier` among `elements` and their descendants.
    private static func menu(withIdentifier identifier: UIMenu.Identifier, in elements: [UIMenuElement]) -> UIMenu? {
        for case let menu as UIMenu in elements {
            if menu.identifier == identifier {
                return menu
            }
            if let found = Self.menu(withIdentifier: identifier, in: menu.children) {
                return found
            }
        }
        return nil
    }

    // MARK: - Anchors

    /// Point size and weight of an anchor glyph: `symbolRow`, medium. Bar glyphs at the symbol's
    /// natural size read larger than the text and chevrons beside them.
    public static var anchorSymbolConfiguration: UIImage.SymbolConfiguration {
        // A static anchor configuration: `LMKMenu` is a namespace with no theme or traits to read from.
        // swiftlint:disable:next no_global_token_proxies_in_components
        UIImage.SymbolConfiguration(pointSize: LMKLayout.symbolRow, weight: .medium)
    }

    /// The anchor glyph for `systemImageName` at the anchor size.
    public static func anchorImage(systemImageName: String) -> UIImage? {
        UIImage(systemName: systemImageName, withConfiguration: anchorSymbolConfiguration)
    }

    /// A system bar button that presents `menu`.
    public static func makeBarButtonItem(menu: UIMenu, systemImageName: String, accessibilityLabel: String) -> UIBarButtonItem {
        makeBarButtonItem(menu: menu, image: anchorImage(systemImageName: systemImageName), accessibilityLabel: accessibilityLabel)
    }

    /// A system bar button that presents `menu` from a custom image.
    public static func makeBarButtonItem(menu: UIMenu, image: UIImage?, accessibilityLabel: String) -> UIBarButtonItem {
        let item = UIBarButtonItem(image: image, menu: menu)
        item.accessibilityLabel = accessibilityLabel
        return item
    }

    /// An `LMKNavigationBar` item that presents `menu`. The bar sizes the glyph with its other items.
    public static func makeNavigationBarItem(identifier: String, menu: UIMenu, systemImageName: String, accessibilityLabel: String) -> LMKNavigationBarItem {
        LMKNavigationBarItem(identifier: identifier, image: UIImage(systemName: systemImageName), accessibilityLabel: accessibilityLabel, menu: menu)
    }

    /// A compact glyph button that presents `menu` as its primary action.
    ///
    /// - Parameters:
    ///   - menu: The menu the button presents.
    ///   - systemImageName: The button's SF Symbol.
    ///   - accessibilityLabel: What VoiceOver calls the button.
    ///   - style: Layered on the default: a tinted circle around a `symbolRow` glyph
    ///     (about 32pt across; the hit target is still 44pt).
    public static func makeButton(menu: UIMenu, systemImageName: String, accessibilityLabel: String, style: LMKButton.Style = LMKButton.Style()) -> LMKButton {
        var base = LMKButton.Style(role: .primary, variant: .tinted, surface: LMKSurfaceStyle(corners: .circle))
        // A static builder: the button it returns re-resolves its style against its own traits.
        // swiftlint:disable:next no_global_token_proxies_in_components
        base.symbolPointSize = LMKLayout.symbolRow
        base.symbolWeight = .medium
        let button = LMKButton(systemImage: systemImageName, style: base.merging(style))
        button.menu = menu
        button.showsMenuAsPrimaryAction = true
        button.accessibilityLabel = accessibilityLabel
        return button
    }
}

// MARK: - Sections

public extension LMKMenu.Section {
    /// One choice at a time: the chosen row carries the checkmark and a tap closes the menu.
    static func single<ID: Hashable & Sendable>(
        title: String? = nil,
        options: [LMKMenu.Option<ID>],
        selected: @escaping @MainActor () -> ID?,
        onSelect: @escaping @MainActor (ID) -> Void
    ) -> Self {
        Self(title: title, options: [.displayInline, .singleSelection], systemImageName: nil) {
            let current = selected()
            return options.map { option in
                UIAction(
                    title: option.title,
                    subtitle: option.subtitle,
                    image: option.systemImageName.flatMap(UIImage.init(systemName:)),
                    attributes: option.isEnabled ? [] : [.disabled],
                    state: option.id == current ? .on : .off
                ) { _ in
                    MainActor.assumeIsolated { onSelect(option.id) }
                }
            }
        }
    }

    /// Independent toggles: a tap flips the row's checkmark and, by default, keeps the menu
    /// open for the next one (the open menu is rebuilt from `selected`).
    static func multiple<ID: Hashable & Sendable>(
        title: String? = nil,
        options: [LMKMenu.Option<ID>],
        keepsMenuOpen: Bool = true,
        selected: @escaping @MainActor () -> Set<ID>,
        onToggle: @escaping @MainActor (ID, Bool) -> Void
    ) -> Self {
        Self(title: title, options: [.displayInline], systemImageName: nil) {
            let current = selected()
            return options.map { option in
                var attributes: UIMenuElement.Attributes = keepsMenuOpen ? [.keepsMenuPresented] : []
                if !option.isEnabled { attributes.insert(.disabled) }
                return UIAction(
                    title: option.title,
                    subtitle: option.subtitle,
                    image: option.systemImageName.flatMap(UIImage.init(systemName:)),
                    attributes: attributes,
                    state: current.contains(option.id) ? .on : .off
                ) { action in
                    MainActor.assumeIsolated {
                        // From the host's state, not the row's: a row that is not rebuilt (a
                        // menu nested in a host menu) would otherwise report the same value twice.
                        let isOn = !selected().contains(option.id)
                        action.state = isOn ? .on : .off
                        onToggle(option.id, isOn)
                        if keepsMenuOpen {
                            LMKMenu.reloadVisibleMenu(presenting: action)
                        }
                    }
                }
            }
        }
    }

    /// One sort at a time with a direction: the selected row shows the direction's arrow and
    /// name, a tap on it flips the direction and keeps the menu open (the arrow updates in
    /// place), and a tap on another row selects it ascending and closes the menu.
    static func sort<ID: Hashable & Sendable>(
        title: String? = nil,
        options: [LMKMenu.Option<ID>],
        strings: LMKSortMenu.Strings = LMKSortMenu.strings,
        selected: @escaping @MainActor () -> (sort: ID?, direction: LMKSortMenu.Direction),
        onSelect: @escaping @MainActor (ID, LMKSortMenu.Direction) -> Void
    ) -> Self {
        Self(title: title, options: [.displayInline, .singleSelection], systemImageName: nil) {
            let current = selected()
            return options.map { option in
                let isSelected = option.id == current.sort
                var attributes: UIMenuElement.Attributes = isSelected ? [.keepsMenuPresented] : []
                if !option.isEnabled { attributes.insert(.disabled) }
                // The kept-open row is tapped again and again: it carries its own direction.
                var direction = current.direction
                return UIAction(
                    title: option.title,
                    subtitle: isSelected ? strings.title(for: direction) : option.subtitle,
                    image: isSelected ? UIImage(systemName: direction.systemImageName) : option.systemImageName.flatMap(UIImage.init(systemName:)),
                    attributes: attributes,
                    state: isSelected ? .on : .off
                ) { action in
                    MainActor.assumeIsolated {
                        let resolved = LMKSortMenu.resolve(tapping: option.id, selected: isSelected ? option.id : current.sort, direction: direction)
                        if isSelected {
                            direction = resolved.direction
                            action.image = UIImage(systemName: resolved.direction.systemImageName)
                            action.subtitle = strings.title(for: resolved.direction)
                        }
                        onSelect(resolved.sort, resolved.direction)
                        if isSelected {
                            LMKMenu.reloadVisibleMenu(presenting: action)
                        }
                    }
                }
            }
        }
    }

    /// Commands: each row runs its handler and closes the menu.
    static func actions(title: String? = nil, _ actions: [LMKMenu.Action]) -> Self {
        Self(title: title, options: [.displayInline], systemImageName: nil) {
            actions.map { item in
                var attributes: UIMenuElement.Attributes = item.isDestructive ? [.destructive] : []
                if !item.isEnabled { attributes.insert(.disabled) }
                return UIAction(
                    title: item.title,
                    subtitle: item.subtitle,
                    image: item.systemImageName.flatMap(UIImage.init(systemName:)),
                    attributes: attributes
                ) { _ in
                    MainActor.assumeIsolated { item.handler() }
                }
            }
        }
    }

    /// One row that opens `sections` as a nested menu.
    static func submenu(title: String, systemImageName: String? = nil, sections: [Self]) -> Self {
        Self(title: title, options: [], systemImageName: systemImageName) {
            LMKMenu.makeElements(sections: sections)
        }
    }

    /// Any menu elements, for rows these builders do not cover.
    static func custom(title: String? = nil, elements: @escaping @MainActor () -> [UIMenuElement]) -> Self {
        Self(title: title, options: [.displayInline], systemImageName: nil, makeElements: elements)
    }
}
