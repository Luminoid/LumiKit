//
//  LMKActionSheet.swift
//  LumiKit
//
//  The action sheet namespace: models (Action, Page, Configuration), Style,
//  Strings, and the presenters. The view controller lives in
//  LMKActionSheetViewController, the row in LMKActionSheetRowView.
//

import UIKit

/// Custom action sheet presented as a bottom sheet with design-system styling.
///
/// Supports a list of actions with optional icons, subtitles, destructive styling,
/// a selected checkmark, an optional self-sizing custom view (a date picker), a
/// confirm button, and multi-level navigation where an action opens a sub-page.
///
/// ```swift
/// LMKActionSheet.present(
///     from: self,
///     title: "Photo Actions",
///     actions: [
///         .init(title: "Edit", icon: UIImage(systemName: "pencil")) { edit() },
///         .init(title: "Delete", style: .destructive) { delete() },
///     ]
/// )
///
/// LMKActionSheet.present(LMKActionSheet.Configuration(
///     title: "Select Date",
///     contentView: datePicker,
///     confirmTitle: "Save",
///     onConfirm: { save(datePicker.date) }
/// ), from: self)
/// ```
///
/// Action and confirm handlers run after the sheet has left the screen, so they can
/// present something else right away.
public enum LMKActionSheet {
    // MARK: - Models

    /// A tappable row.
    public struct Action {
        /// Visual style of a row.
        public nonisolated enum Style: Sendable, Hashable, CaseIterable {
            case `default`
            case destructive
        }

        public var title: String
        public var subtitle: String?
        public var icon: UIImage?
        public var style: Style
        /// Shows a checkmark (single-selection lists).
        public var isSelected: Bool
        /// A disabled row dims and ignores taps.
        public var isEnabled: Bool
        /// Runs after the sheet dismisses; `nil` for navigation actions.
        public var handler: (() -> Void)?
        /// A sub-page this action opens instead of dismissing.
        public var page: Page?

        /// A regular action: dismisses the sheet, then runs `handler`.
        public init(
            title: String,
            subtitle: String? = nil,
            style: Style = .default,
            icon: UIImage? = nil,
            isSelected: Bool = false,
            isEnabled: Bool = true,
            handler: @escaping () -> Void
        ) {
            self.title = title
            self.subtitle = subtitle
            self.style = style
            self.icon = icon
            self.isSelected = isSelected
            self.isEnabled = isEnabled
            self.handler = handler
            self.page = nil
        }

        /// A navigation action: pushes `page` inside the sheet.
        public init(
            title: String,
            subtitle: String? = nil,
            style: Style = .default,
            icon: UIImage? = nil,
            isEnabled: Bool = true,
            page: Page
        ) {
            self.title = title
            self.subtitle = subtitle
            self.style = style
            self.icon = icon
            self.isSelected = false
            self.isEnabled = isEnabled
            self.handler = nil
            self.page = page
        }
    }

    /// One page of the sheet (the root, or a sub-page an action opens).
    public struct Page {
        public var title: String?
        public var message: String?
        public var actions: [Action]
        /// A self-sizing view between the message and the actions.
        public var contentView: UIView?
        /// Title of a confirm button at the bottom; `nil` shows none.
        public var confirmTitle: String?
        /// Runs after the sheet dismisses from the confirm button.
        public var onConfirm: (() -> Void)?

        public init(
            title: String? = nil,
            message: String? = nil,
            actions: [Action] = [],
            contentView: UIView? = nil,
            confirmTitle: String? = nil,
            onConfirm: (() -> Void)? = nil
        ) {
            self.title = title
            self.message = message
            self.actions = actions
            self.contentView = contentView
            self.confirmTitle = confirmTitle
            self.onConfirm = onConfirm
        }
    }

    /// Everything a sheet needs: its root page, cancellation handler, style, and strings.
    public struct Configuration {
        public var title: String?
        public var message: String?
        public var actions: [Action]
        public var contentView: UIView?
        public var confirmTitle: String?
        public var onConfirm: (() -> Void)?
        /// Runs when the sheet goes away without an action or confirm (cancel, dimming tap, drag, key command).
        public var onCancel: (() -> Void)?
        public var style: LMKActionSheet.Style
        public var strings: Strings

        public init(
            title: String? = nil,
            message: String? = nil,
            actions: [Action] = [],
            contentView: UIView? = nil,
            confirmTitle: String? = nil,
            onConfirm: (() -> Void)? = nil,
            onCancel: (() -> Void)? = nil,
            style: LMKActionSheet.Style = LMKActionSheet.Style(),
            strings: Strings = LMKActionSheet.strings
        ) {
            self.title = title
            self.message = message
            self.actions = actions
            self.contentView = contentView
            self.confirmTitle = confirmTitle
            self.onConfirm = onConfirm
            self.onCancel = onCancel
            self.style = style
            self.strings = strings
        }

        /// The root page.
        public var rootPage: Page {
            Page(title: title, message: message, actions: actions, contentView: contentView, confirmTitle: confirmTitle, onConfirm: onConfirm)
        }
    }

    // MARK: - Style

    /// Appearance of one action row.
    public nonisolated struct RowStyle: Sendable, Equatable {
        /// `nil` = 48.
        public var minimumHeight: CGFloat?
        /// Row background (`backgroundSecondary`), corners (small), border, shadow, content insets (`large` horizontal, `small` vertical).
        public var surface: LMKSurfaceStyle
        /// `nil` = `body`.
        public var titleTextStyle: LMKTextStyle?
        /// `nil` = `caption`.
        public var subtitleTextStyle: LMKTextStyle?
        /// `nil` = `textPrimary`.
        public var titleColor: UIColor?
        /// `nil` = `textSecondary`.
        public var subtitleColor: UIColor?
        /// `nil` = `iconMedium`.
        public var iconSize: CGFloat?
        /// `nil` = `primary`.
        public var iconTint: UIColor?
        /// `nil` = `primary`.
        public var checkmarkColor: UIColor?
        /// Icon and title of destructive rows; `nil` = `error`.
        public var destructiveColor: UIColor?
        /// Pressed background; `nil` = `primary` at `alpha.xs`.
        public var highlightColor: UIColor?
        /// Gap between icon, text, and accessory; `nil` = `medium`.
        public var spacing: CGFloat?

        public init(
            minimumHeight: CGFloat? = nil,
            surface: LMKSurfaceStyle = LMKSurfaceStyle(),
            titleTextStyle: LMKTextStyle? = nil,
            subtitleTextStyle: LMKTextStyle? = nil,
            titleColor: UIColor? = nil,
            subtitleColor: UIColor? = nil,
            iconSize: CGFloat? = nil,
            iconTint: UIColor? = nil,
            checkmarkColor: UIColor? = nil,
            destructiveColor: UIColor? = nil,
            highlightColor: UIColor? = nil,
            spacing: CGFloat? = nil
        ) {
            self.minimumHeight = minimumHeight
            self.surface = surface
            self.titleTextStyle = titleTextStyle
            self.subtitleTextStyle = subtitleTextStyle
            self.titleColor = titleColor
            self.subtitleColor = subtitleColor
            self.iconSize = iconSize
            self.iconTint = iconTint
            self.checkmarkColor = checkmarkColor
            self.destructiveColor = destructiveColor
            self.highlightColor = highlightColor
            self.spacing = spacing
        }

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                minimumHeight: other.minimumHeight ?? minimumHeight,
                surface: surface.merging(other.surface),
                titleTextStyle: other.titleTextStyle ?? titleTextStyle,
                subtitleTextStyle: other.subtitleTextStyle ?? subtitleTextStyle,
                titleColor: other.titleColor ?? titleColor,
                subtitleColor: other.subtitleColor ?? subtitleColor,
                iconSize: other.iconSize ?? iconSize,
                iconTint: other.iconTint ?? iconTint,
                checkmarkColor: other.checkmarkColor ?? checkmarkColor,
                destructiveColor: other.destructiveColor ?? destructiveColor,
                highlightColor: other.highlightColor ?? highlightColor,
                spacing: other.spacing ?? spacing
            )
        }
    }

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// The sheet chrome (container, dimming, cancel button).
        public var sheet: LMKBottomSheetViewController.Style
        public var row: RowStyle
        /// `nil` = `h3`.
        public var titleTextStyle: LMKTextStyle?
        /// `nil` = `textPrimary`.
        public var titleColor: UIColor?
        /// `nil` = `caption`.
        public var messageTextStyle: LMKTextStyle?
        /// `nil` = `textSecondary`.
        public var messageColor: UIColor?
        /// Layered on the default confirm look (filled primary, 50pt).
        public var confirmButton: LMKButton.Style
        /// Layered on the sub-page back button (ghost chevron).
        public var backButton: LMKButton.Style
        /// Gap between title, message, content, and rows; `nil` = `medium`.
        public var sectionSpacing: CGFloat?
        /// Gap between rows; `nil` = `xs`.
        public var rowSpacing: CGFloat?
        /// Sub-page slide duration; `nil` = `animation.normal`.
        public var pageTransitionDuration: TimeInterval?

        public init(
            sheet: LMKBottomSheetViewController.Style = LMKBottomSheetViewController.Style(),
            row: RowStyle = RowStyle(),
            titleTextStyle: LMKTextStyle? = nil,
            titleColor: UIColor? = nil,
            messageTextStyle: LMKTextStyle? = nil,
            messageColor: UIColor? = nil,
            confirmButton: LMKButton.Style = LMKButton.Style(),
            backButton: LMKButton.Style = LMKButton.Style(),
            sectionSpacing: CGFloat? = nil,
            rowSpacing: CGFloat? = nil,
            pageTransitionDuration: TimeInterval? = nil
        ) {
            self.sheet = sheet
            self.row = row
            self.titleTextStyle = titleTextStyle
            self.titleColor = titleColor
            self.messageTextStyle = messageTextStyle
            self.messageColor = messageColor
            self.confirmButton = confirmButton
            self.backButton = backButton
            self.sectionSpacing = sectionSpacing
            self.rowSpacing = rowSpacing
            self.pageTransitionDuration = pageTransitionDuration
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                sheet: sheet.merging(other.sheet),
                row: row.merging(other.row),
                titleTextStyle: other.titleTextStyle ?? titleTextStyle,
                titleColor: other.titleColor ?? titleColor,
                messageTextStyle: other.messageTextStyle ?? messageTextStyle,
                messageColor: other.messageColor ?? messageColor,
                confirmButton: confirmButton.merging(other.confirmButton),
                backButton: backButton.merging(other.backButton),
                sectionSpacing: other.sectionSpacing ?? sectionSpacing,
                rowSpacing: other.rowSpacing ?? rowSpacing,
                pageTransitionDuration: other.pageTransitionDuration ?? pageTransitionDuration
            )
        }
    }

    // MARK: - Strings

    public nonisolated struct Strings: Sendable, Equatable {
        /// VoiceOver label of the sub-page back button.
        public var back: String
        /// VoiceOver hint on rows that open a sub-page.
        public var submenuAccessibilityHint: String

        public init(
            back: String = LMKLocalized("actionSheet.back"),
            submenuAccessibilityHint: String = LMKLocalized("actionSheet.submenu.accessibilityHint")
        ) {
            self.back = back
            self.submenuAccessibilityHint = submenuAccessibilityHint
        }
    }

    /// Process-wide defaults; set at app launch to override.
    public nonisolated(unsafe) static var strings = Strings()

    // MARK: - Presentation

    /// Presents a sheet built from `configuration` over `host`.
    @discardableResult
    public static func present(_ configuration: Configuration, from host: UIViewController) -> LMKActionSheetViewController {
        let sheet = LMKActionSheetViewController(configuration: configuration)
        sheet.present(from: host)
        return sheet
    }

    /// Presents a sheet with a title, message, and actions.
    @discardableResult
    public static func present(
        from host: UIViewController,
        title: String? = nil,
        message: String? = nil,
        actions: [Action],
        onCancel: (() -> Void)? = nil
    ) -> LMKActionSheetViewController {
        present(Configuration(title: title, message: message, actions: actions, onCancel: onCancel), from: host)
    }

    /// The action sheet currently presented over `host`, if any.
    public static func current(in host: UIViewController) -> LMKActionSheetViewController? {
        host.children.last { $0 is LMKActionSheetViewController } as? LMKActionSheetViewController
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKActionSheet`.
    var actionSheet: LMKActionSheet.Style {
        get { self[LMKActionSheet.Style.self] }
        set { self[LMKActionSheet.Style.self] = newValue }
    }
}
