//
//  LMKTab.swift
//  LumiKit
//
//  One tab of an `LMKTabBarController`: identity, title, glyphs, badge, and
//  the factory that builds its root screen on first selection.
//

import UIKit

/// A tab definition for `LMKTabBarController`.
///
/// ```swift
/// LMKTab(identifier: "plants", title: "Plants", systemImage: "leaf.fill") { PlantsViewController() }
/// ```
///
/// The root screen is built lazily, the first time the tab is selected, unless `isLazy` is
/// `false`. `LMKTabBarController` wraps it in a navigation controller from its factory.
public struct LMKTab {
    /// What kind of `UITab` backs the definition.
    public nonisolated enum Role: Sendable, Hashable, CaseIterable {
        /// A regular tab.
        case standard
        /// A `UISearchTab` (iOS 18): pinned to the trailing end of the bar, a magnifying glass by
        /// default, and on iOS 26 it can activate its search field on selection
        /// (`LMKTabBarController.Style.automaticallyActivatesSearch`).
        case search
    }

    public var identifier: String
    public var title: String
    /// The glyph; a tab bar renders the selected state itself (an SF Symbol takes its filled variant).
    public var image: UIImage?
    /// Builds the root view controller (before the navigation wrapper).
    public var makeRoot: @MainActor () -> UIViewController
    /// `false` builds the root as soon as the tab bar loads.
    public var isLazy: Bool
    /// `nil` = no badge; `.count(n)` shows the number, `.dot` a dot, `.text` the text.
    public var badge: LMKBadgeView.Content?
    /// `nil` = the title.
    public var accessibilityLabel: String?
    /// Default `.standard`.
    public var role: Role

    public init(
        identifier: String,
        title: String,
        image: UIImage?,
        isLazy: Bool = true,
        badge: LMKBadgeView.Content? = nil,
        accessibilityLabel: String? = nil,
        role: Role = .standard,
        makeRoot: @escaping @MainActor () -> UIViewController
    ) {
        self.identifier = identifier
        self.title = title
        self.image = image
        self.isLazy = isLazy
        self.badge = badge
        self.accessibilityLabel = accessibilityLabel
        self.role = role
        self.makeRoot = makeRoot
    }

    /// A tab with SF Symbol glyphs.
    public init(
        identifier: String,
        title: String,
        systemImage: String,
        isLazy: Bool = true,
        badge: LMKBadgeView.Content? = nil,
        accessibilityLabel: String? = nil,
        role: Role = .standard,
        makeRoot: @escaping @MainActor () -> UIViewController
    ) {
        self.init(
            identifier: identifier,
            title: title,
            image: UIImage(systemName: systemImage),
            isLazy: isLazy,
            badge: badge,
            accessibilityLabel: accessibilityLabel,
            role: role,
            makeRoot: makeRoot
        )
    }

    /// A search tab (`UISearchTab`) with the system's magnifying glass and "Search" title; pass
    /// `title` / `image` to override them.
    public static func search(
        identifier: String = "search",
        title: String? = nil,
        image: UIImage? = nil,
        isLazy: Bool = true,
        makeRoot: @escaping @MainActor () -> UIViewController
    ) -> Self {
        Self(identifier: identifier, title: title ?? "", image: image, isLazy: isLazy, role: .search, makeRoot: makeRoot)
    }

    /// The `badgeValue` a `UITab` shows for `badge` (`nil` hides it, an empty string is a dot).
    public nonisolated static func badgeValue(for badge: LMKBadgeView.Content?) -> String? {
        switch badge {
        case nil: nil
        case let .count(count): count > 0 ? String(count) : nil
        case let .text(text): text.isEmpty ? nil : text
        case .dot: ""
        }
    }
}
