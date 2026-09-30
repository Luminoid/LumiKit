//
//  LMKTabBarAppearance.swift
//  LumiKit
//
//  `LMKTabBarController.Style` and the `UITabBarAppearance` builder that
//  applies it to one tab bar or to the appearance proxy.
//

import UIKit

public extension LMKTabBarController {
    nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// Bar background; `nil` = `backgroundPrimary` before iOS 26 (Liquid Glass on 26 unless
        /// `forcesOpaqueBackground`).
        public var backgroundColor: UIColor?
        /// Selected item tint; `nil` = `primary`.
        public var selectedTint: UIColor?
        /// Unselected item tint; `nil` = `textTertiary`.
        public var normalTint: UIColor?
        /// Item title text style; `nil` = `.extraSmall`.
        public var titleTextStyle: LMKTextStyle?
        /// `nil` = `error`.
        public var badgeBackgroundColor: UIColor?
        /// `nil` = `onAccent`.
        public var badgeTextColor: UIColor?
        /// Opts out of Liquid Glass on iOS 26 with an opaque bar; `nil` = no.
        public var forcesOpaqueBackground: Bool?
        /// iOS 26 `tabBarMinimizeBehavior = .onScrollDown`; `nil` = the system default.
        public var minimizesOnScroll: Bool?
        /// `mode = .tabSidebar` in regular-width iPad and Mac windows; `nil` = no.
        public var prefersSidebarOnIPad: Bool?

        /// Whether a `.search` tab activates its search field when selected (iOS 26
        /// `UISearchTab.automaticallyActivatesSearch`); `nil` = the system default. No effect before 26.
        public var automaticallyActivatesSearch: Bool?

        public init(
            backgroundColor: UIColor? = nil,
            selectedTint: UIColor? = nil,
            normalTint: UIColor? = nil,
            titleTextStyle: LMKTextStyle? = nil,
            badgeBackgroundColor: UIColor? = nil,
            badgeTextColor: UIColor? = nil,
            forcesOpaqueBackground: Bool? = nil,
            minimizesOnScroll: Bool? = nil,
            prefersSidebarOnIPad: Bool? = nil,
            automaticallyActivatesSearch: Bool? = nil
        ) {
            self.backgroundColor = backgroundColor
            self.selectedTint = selectedTint
            self.normalTint = normalTint
            self.titleTextStyle = titleTextStyle
            self.badgeBackgroundColor = badgeBackgroundColor
            self.badgeTextColor = badgeTextColor
            self.forcesOpaqueBackground = forcesOpaqueBackground
            self.minimizesOnScroll = minimizesOnScroll
            self.prefersSidebarOnIPad = prefersSidebarOnIPad
            self.automaticallyActivatesSearch = automaticallyActivatesSearch
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                backgroundColor: other.backgroundColor ?? backgroundColor,
                selectedTint: other.selectedTint ?? selectedTint,
                normalTint: other.normalTint ?? normalTint,
                titleTextStyle: other.titleTextStyle ?? titleTextStyle,
                badgeBackgroundColor: other.badgeBackgroundColor ?? badgeBackgroundColor,
                badgeTextColor: other.badgeTextColor ?? badgeTextColor,
                forcesOpaqueBackground: other.forcesOpaqueBackground ?? forcesOpaqueBackground,
                minimizesOnScroll: other.minimizesOnScroll ?? minimizesOnScroll,
                prefersSidebarOnIPad: other.prefersSidebarOnIPad ?? prefersSidebarOnIPad,
                automaticallyActivatesSearch: other.automaticallyActivatesSearch ?? automaticallyActivatesSearch
            )
        }
    }
}

/// Builds and applies `UITabBarAppearance` from an `LMKTabBarController.Style`.
///
/// `LMKTabBarController` applies its style itself; use this for a plain
/// `UITabBarController` (`apply(_:to:)`) or once at launch for every tab bar (`applyGlobally`).
public enum LMKTabBarAppearance {
    /// The appearance for `style` resolved against `theme` (its `tabBar` slot layered under `style`).
    public static func makeAppearance(_ style: LMKTabBarController.Style = LMKTabBarController.Style(), theme: LMKTheme = .current, traits: UITraitCollection? = nil) -> UITabBarAppearance {
        let resolved = theme.tabBar.merging(style)
        let appearance = UITabBarAppearance()
        let opaque = resolved.forcesOpaqueBackground ?? false
        if opaque {
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = resolved.backgroundColor ?? LMKColor.backgroundPrimary
        } else if #available(iOS 26, *) {
            // Liquid Glass: leave the background to the system.
            appearance.configureWithDefaultBackground()
        } else {
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = resolved.backgroundColor ?? LMKColor.backgroundPrimary
        }
        let selected = resolved.selectedTint ?? LMKColor.primary
        let normal = resolved.normalTint ?? LMKColor.textTertiary
        let font = LMKTypography.font(for: resolved.titleTextStyle ?? .extraSmall, compatibleWith: traits)
        let badgeBackground = resolved.badgeBackgroundColor ?? LMKColor.error
        let badgeText = resolved.badgeTextColor ?? LMKColor.onAccent
        for layout in [appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance] {
            layout.selected.iconColor = selected
            layout.selected.titleTextAttributes = [.foregroundColor: selected, .font: font]
            layout.normal.iconColor = normal
            layout.normal.titleTextAttributes = [.foregroundColor: normal, .font: font]
            layout.normal.badgeBackgroundColor = badgeBackground
            layout.normal.badgeTextAttributes = [.foregroundColor: badgeText]
            layout.selected.badgeBackgroundColor = badgeBackground
            layout.selected.badgeTextAttributes = [.foregroundColor: badgeText]
        }
        return appearance
    }

    /// Applies `style` to `tabBar` (standard and scroll-edge appearance, tint).
    public static func apply(_ style: LMKTabBarController.Style = LMKTabBarController.Style(), to tabBar: UITabBar, theme: LMKTheme = .current) {
        let appearance = makeAppearance(style, theme: theme, traits: tabBar.traitCollection)
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = theme.tabBar.merging(style).selectedTint ?? LMKColor.primary
    }

    /// Applies `style` to the `UITabBar` appearance proxy (every tab bar created afterwards).
    public static func applyGlobally(_ style: LMKTabBarController.Style = LMKTabBarController.Style(), theme: LMKTheme = .current) {
        let appearance = makeAppearance(style, theme: theme)
        let proxy = UITabBar.appearance()
        proxy.standardAppearance = appearance
        proxy.scrollEdgeAppearance = appearance
        proxy.tintColor = theme.tabBar.merging(style).selectedTint ?? LMKColor.primary
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKTabBarController` and `LMKTabBarAppearance`.
    var tabBar: LMKTabBarController.Style {
        get { self[LMKTabBarController.Style.self] }
        set { self[LMKTabBarController.Style.self] = newValue }
    }
}
