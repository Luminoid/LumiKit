//
//  LMKSortMenu.swift
//  LumiKit
//
//  The sort vocabulary (direction, the tap reduction, strings) and the sort
//  menu: `LMKMenu` with a sort section, an optional layout section, and any
//  further sections the screen needs.
//

import UIKit

/// Builds sort menus for bar buttons and `LMKButton`s.
///
/// ```swift
/// let menu = LMKSortMenu.makeMenu(
///     sortOptions: [.init(id: Sort.name, title: "Name"), .init(id: Sort.date, title: "Date")],
///     layoutOptions: [.init(id: Layout.list, title: "List", systemImageName: "list.bullet"),
///                     .init(id: Layout.grid, title: "Grid", systemImageName: "square.grid.2x2")],
///     state: { [weak self] in .init(selectedSort: self?.sort, direction: self?.direction ?? .ascending, selectedLayout: self?.layout) },
///     onSelectSort: { [weak self] sort, direction in self?.apply(sort: sort, direction: direction) },
///     onSelectLayout: { [weak self] layout in self?.layout = layout }
/// )
/// navigationItem.rightBarButtonItem = LMKSortMenu.makeBarButtonItem(menu: menu)
/// ```
///
/// Tapping the selected sort flips its direction and keeps the menu open (the arrow updates in
/// place); tapping another sort selects it ascending and closes the menu. `state` is read every
/// time the menu opens, so the checkmarks always reflect the host's current values.
///
/// `additionalSections` adds filters, toggles, or commands under the sort; a menu that is not
/// about sorting at all is an `LMKMenu`.
public enum LMKSortMenu {
    // MARK: - Vocabulary

    public nonisolated enum Direction: Sendable, Hashable, CaseIterable {
        case ascending
        case descending

        public var toggled: Self {
            self == .ascending ? .descending : .ascending
        }

        /// The arrow shown on the selected sort row.
        public var systemImageName: String {
            self == .ascending ? "arrow.up" : "arrow.down"
        }
    }

    /// One sort or layout choice.
    public typealias Option<ID: Hashable & Sendable> = LMKMenu.Option<ID>

    /// The host's current values, read when the menu opens.
    public nonisolated struct State<Sort: Hashable & Sendable, Layout: Hashable & Sendable>: Sendable, Hashable {
        public var selectedSort: Sort?
        public var direction: Direction
        public var selectedLayout: Layout?

        public init(selectedSort: Sort?, direction: Direction = .ascending, selectedLayout: Layout? = nil) {
            self.selectedSort = selectedSort
            self.direction = direction
            self.selectedLayout = selectedLayout
        }
    }

    // MARK: - Strings

    public nonisolated struct Strings: Sendable, Equatable {
        /// The anchor button's label.
        public var sortAccessibilityLabel: String
        /// The layout section's title.
        public var layoutSectionTitle: String
        /// Subtitle of the selected sort row.
        public var ascending: String
        public var descending: String

        public init(
            sortAccessibilityLabel: String = LMKLocalized("sortMenu.sort.accessibilityLabel"),
            layoutSectionTitle: String = LMKLocalized("sortMenu.layout.title"),
            ascending: String = LMKLocalized("sortMenu.ascending"),
            descending: String = LMKLocalized("sortMenu.descending")
        ) {
            self.sortAccessibilityLabel = sortAccessibilityLabel
            self.layoutSectionTitle = layoutSectionTitle
            self.ascending = ascending
            self.descending = descending
        }

        func title(for direction: Direction) -> String {
            direction == .ascending ? ascending : descending
        }
    }

    /// Process-wide defaults; set at app launch to override.
    public nonisolated(unsafe) static var strings = Strings()

    /// The anchor glyph.
    public static let systemImageName = "arrow.up.arrow.down"

    // MARK: - Reduction

    /// The selection after tapping `tapped`: the selected sort flips its direction, any other
    /// sort becomes selected ascending.
    public nonisolated static func resolve<Sort: Hashable>(tapping tapped: Sort, selected: Sort?, direction: Direction) -> (sort: Sort, direction: Direction) {
        tapped == selected ? (tapped, direction.toggled) : (tapped, .ascending)
    }

    // MARK: - Menus

    /// A sort menu with an optional layout section, then `additionalSections`. `state` is read
    /// each time the menu opens.
    public static func makeMenu<Sort: Hashable & Sendable, Layout: Hashable & Sendable>(
        sortOptions: [Option<Sort>],
        layoutOptions: [Option<Layout>] = [],
        additionalSections: [LMKMenu.Section] = [],
        strings: Strings = Self.strings,
        state: @escaping @MainActor () -> State<Sort, Layout>,
        onSelectSort: @escaping @MainActor (Sort, Direction) -> Void,
        onSelectLayout: (@MainActor (Layout) -> Void)? = nil
    ) -> UIMenu {
        LMKMenu.make(sections: makeMenuSections(
            sortOptions: sortOptions,
            layoutOptions: layoutOptions,
            strings: strings,
            state: state,
            onSelectSort: onSelectSort,
            onSelectLayout: onSelectLayout
        ) + additionalSections)
    }

    /// A sort-only menu, then `additionalSections`.
    public static func makeMenu<Sort: Hashable & Sendable>(
        sortOptions: [Option<Sort>],
        additionalSections: [LMKMenu.Section] = [],
        strings: Strings = Self.strings,
        state: @escaping @MainActor () -> (selectedSort: Sort?, direction: Direction),
        onSelectSort: @escaping @MainActor (Sort, Direction) -> Void
    ) -> UIMenu {
        makeMenu(
            sortOptions: sortOptions,
            layoutOptions: [Option<Never>](),
            additionalSections: additionalSections,
            strings: strings,
            state: {
                let current = state()
                return State<Sort, Never>(selectedSort: current.selectedSort, direction: current.direction)
            },
            onSelectSort: onSelectSort
        )
    }

    /// The sort section and, with layout options, the layout section.
    static func makeMenuSections<Sort: Hashable & Sendable, Layout: Hashable & Sendable>(
        sortOptions: [Option<Sort>],
        layoutOptions: [Option<Layout>],
        strings: Strings,
        state: @escaping @MainActor () -> State<Sort, Layout>,
        onSelectSort: @escaping @MainActor (Sort, Direction) -> Void,
        onSelectLayout: (@MainActor (Layout) -> Void)?
    ) -> [LMKMenu.Section] {
        var sections: [LMKMenu.Section] = [
            .sort(options: sortOptions, strings: strings, selected: {
                let current = state()
                return (current.selectedSort, current.direction)
            }, onSelect: onSelectSort),
        ]
        if !layoutOptions.isEmpty {
            sections.append(.single(title: strings.layoutSectionTitle, options: layoutOptions, selected: { state().selectedLayout }, onSelect: { onSelectLayout?($0) }))
        }
        return sections
    }

    // MARK: - Anchors

    /// A system bar button that presents `menu`; `image` replaces the sort glyph at the anchor size.
    public static func makeBarButtonItem(menu: UIMenu, image: UIImage? = nil, strings: Strings = Self.strings) -> UIBarButtonItem {
        LMKMenu.makeBarButtonItem(menu: menu, image: image ?? LMKMenu.anchorImage(systemImageName: systemImageName), accessibilityLabel: strings.sortAccessibilityLabel)
    }

    /// An `LMKNavigationBar` item that presents `menu`.
    public static func makeNavigationBarItem(identifier: String = "sort", menu: UIMenu, image: UIImage? = nil, strings: Strings = Self.strings) -> LMKNavigationBarItem {
        LMKNavigationBarItem(
            identifier: identifier,
            image: image ?? UIImage(systemName: systemImageName),
            accessibilityLabel: strings.sortAccessibilityLabel,
            menu: menu
        )
    }

    /// A glyph button that presents `menu` as its primary action.
    ///
    /// - Parameters:
    ///   - menu: The menu the button presents.
    ///   - style: Layered on a ghost circle around the sort glyph at the anchor size
    ///     (`symbolRow`); `.tinted()` gives the compact filled circle.
    ///   - strings: The button's accessibility label.
    public static func makeButton(menu: UIMenu, style: LMKButton.Style = LMKButton.Style(), strings: Strings = Self.strings) -> LMKButton {
        var base = LMKButton.Style.iconOnly()
        // A static builder: the button it returns re-resolves its style against its own traits.
        // swiftlint:disable:next no_global_token_proxies_in_components
        base.symbolPointSize = LMKLayout.symbolRow
        base.symbolWeight = .medium
        let button = LMKButton(systemImage: systemImageName, style: base.merging(style))
        button.menu = menu
        button.showsMenuAsPrimaryAction = true
        button.accessibilityLabel = strings.sortAccessibilityLabel
        return button
    }
}
