//
//  LMKNavigationBarItem.swift
//  LumiKit
//
//  One bar button of `LMKNavigationBar`: glyph or title, role, enabled state,
//  optional menu and badge, identified so it can be updated in place.
//

import UIKit

/// A bar button item for ``LMKNavigationBar``.
///
/// Items are values: build them, hand them to `setLeftItems(_:)` / `setRightItems(_:)`,
/// and change one later through `updateItem(_:_:)` using its `identifier`.
///
/// ```swift
/// bar.setRightItems([
///     .init(identifier: "add", systemName: "plus") { addTapped() },
///     .init(identifier: "more", systemName: "ellipsis.circle", menu: moreMenu),
/// ])
/// bar.updateItem("add") { $0.isEnabled = false }
/// ```
public struct LMKNavigationBarItem: Hashable {
    /// How the item renders.
    public nonisolated enum Role: Sendable, Hashable, CaseIterable {
        /// Tinted glyph or text.
        case plain
        /// A filled capsule, for the screen's primary action.
        case prominent
        /// Tinted with the error color.
        case destructive
    }

    /// Stable identity, for `updateItem(_:_:)` and `accessibilityIdentifier`.
    public let identifier: String
    public var image: UIImage?
    public var title: String?
    public var accessibilityLabel: String?
    public var role: Role
    public var isEnabled: Bool
    /// Shown on tap when `action` is nil, on long press when both are set.
    public var menu: UIMenu?
    /// A badge over the item's top-trailing corner.
    public var badge: LMKBadgeView.Content?
    public var action: (() -> Void)?

    public init(
        identifier: String = UUID().uuidString,
        image: UIImage?,
        title: String? = nil,
        accessibilityLabel: String? = nil,
        role: Role = .plain,
        isEnabled: Bool = true,
        menu: UIMenu? = nil,
        badge: LMKBadgeView.Content? = nil,
        action: (() -> Void)? = nil
    ) {
        self.identifier = identifier
        self.image = image
        self.title = title
        self.accessibilityLabel = accessibilityLabel
        self.role = role
        self.isEnabled = isEnabled
        self.menu = menu
        self.badge = badge
        self.action = action
    }

    public init(
        identifier: String = UUID().uuidString,
        systemName: String,
        accessibilityLabel: String? = nil,
        role: Role = .plain,
        isEnabled: Bool = true,
        menu: UIMenu? = nil,
        badge: LMKBadgeView.Content? = nil,
        action: (() -> Void)? = nil
    ) {
        self.init(
            identifier: identifier,
            image: UIImage(systemName: systemName),
            accessibilityLabel: accessibilityLabel,
            role: role,
            isEnabled: isEnabled,
            menu: menu,
            badge: badge,
            action: action
        )
    }

    public init(
        identifier: String = UUID().uuidString,
        title: String,
        accessibilityLabel: String? = nil,
        role: Role = .plain,
        isEnabled: Bool = true,
        menu: UIMenu? = nil,
        badge: LMKBadgeView.Content? = nil,
        action: (() -> Void)? = nil
    ) {
        self.init(
            identifier: identifier,
            image: nil,
            title: title,
            accessibilityLabel: accessibilityLabel ?? title,
            role: role,
            isEnabled: isEnabled,
            menu: menu,
            badge: badge,
            action: action
        )
    }

    /// Items are equal when they share an identifier.
    public nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.identifier == rhs.identifier
    }

    public nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}
