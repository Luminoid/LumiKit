//
//  ExampleCatalog.swift
//  LumiKitExample
//
//  The catalog: every example page, grouped by what a developer comes looking
//  for. Foundations first, then what people touch, read, and move through,
//  then feedback, sheets, media, and the helpers underneath.
//

import UIKit

// MARK: - Model

struct ExampleItem {
    let title: String
    let subtitle: String
    let iconName: String
    let makeViewController: @MainActor () -> UIViewController

    /// Whether the title or subtitle contains every word of `query`.
    func matches(_ query: String) -> Bool {
        let haystack = "\(title) \(subtitle)".lowercased()
        return query.lowercased().split(separator: " ").allSatisfy { haystack.contains($0) }
    }
}

struct ExampleSection {
    let title: String
    /// One line under the group: what it holds.
    let summary: String
    let items: [ExampleItem]
}

/// The catalog as a flat page list, for the scripted sweep (`ExampleSweepRunner`).
enum ExampleCatalog {
    struct Page {
        let title: String
        let make: @MainActor () -> UIViewController
    }

    static var pages: [Page] {
        exampleSections.flatMap { section in section.items.map { Page(title: $0.title, make: $0.makeViewController) } }
    }

    /// The sections with only the items matching `query`; every section for an empty query.
    static func sections(matching query: String) -> [ExampleSection] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return exampleSections }
        return exampleSections.compactMap { section in
            let items = section.items.filter { $0.matches(trimmed) }
            return items.isEmpty ? nil : ExampleSection(title: section.title, summary: section.summary, items: items)
        }
    }
}

// MARK: - Catalog

let exampleSections: [ExampleSection] = [
    ExampleSection(title: "Foundations", summary: "Tokens and the theme every component draws from.", items: [
        ExampleItem(title: "Colors", subtitle: "LMKColor roles: accents, status, text, backgrounds", iconName: "paintpalette", makeViewController: { ColorsDetailViewController() }),
        ExampleItem(title: "Typography", subtitle: "LMKTextStyle headings, body, captions, Dynamic Type", iconName: "textformat", makeViewController: { TypographyDetailViewController() }),
        ExampleItem(
            title: "Theme Switcher",
            subtitle: "LMKTheme.apply at runtime: every component re-renders live",
            iconName: "paintbrush.pointed",
            makeViewController: { ThemeSwitcherDetailViewController() }
        ),
        ExampleItem(title: "Shadows", subtitle: "LMKShadow levels and lmk_applyShadow", iconName: "shadow", makeViewController: { ShadowDetailViewController() }),
        ExampleItem(
            title: "Borders & Radius",
            subtitle: "Hairline borders, corner styles, concentric corners, circles",
            iconName: "square.dashed",
            makeViewController: { BorderDetailViewController() }
        ),
        ExampleItem(title: "Gradient", subtitle: "LMKGradientView: linear, angled, and radial", iconName: "rectangle.fill", makeViewController: { GradientDetailViewController() }),
        ExampleItem(
            title: "Glass",
            subtitle: "LMKGlassView: Liquid Glass on iOS 26, material fallback before",
            iconName: "circle.hexagongrid.fill",
            makeViewController: { GlassDetailViewController() }
        ),
        ExampleItem(
            title: "Device & Display",
            subtitle: "LMKDevice tiers, size classes, safe areas, live on resize",
            iconName: "iphone.gen3",
            makeViewController: { DeviceDisplayDetailViewController() }
        ),
    ]),
    ExampleSection(title: "Buttons & Controls", summary: "What people tap, toggle, and drag.", items: [
        ExampleItem(
            title: "Buttons",
            subtitle: "LMKButton roles, variants, sizes, loading, menus",
            iconName: "rectangle.and.hand.point.up.left",
            makeViewController: { ButtonsDetailViewController() }
        ),
        ExampleItem(title: "Toggle Button", subtitle: "LMKButton.isToggle with on and off content", iconName: "togglepower", makeViewController: { ToggleButtonDetailViewController() }),
        ExampleItem(title: "Switch", subtitle: "LMKSwitch with a spring thumb and custom tints", iconName: "switch.2", makeViewController: { SwitchDetailViewController() }),
        ExampleItem(title: "Checkbox & Rating", subtitle: "LMKCheckbox and LMKRatingControl", iconName: "star.leadinghalf.filled", makeViewController: { CheckboxRatingDetailViewController() }),
        ExampleItem(
            title: "Segmented Control",
            subtitle: "Draggable indicator, fit-content and scrolling layouts",
            iconName: "rectangle.split.3x1",
            makeViewController: { SegmentedControlDetailViewController() }
        ),
        ExampleItem(title: "Slider", subtitle: "Caption, live readout, steps, negative range", iconName: "slider.horizontal.3", makeViewController: { SliderDetailViewController() }),
        ExampleItem(title: "Action Tile", subtitle: "LMKActionTile grid with counts and accent colors", iconName: "square.grid.2x2", makeViewController: { ActionTileDetailViewController() }),
        ExampleItem(title: "Floating Button", subtitle: "Draggable action button that snaps to a corner", iconName: "circle.circle", makeViewController: { FloatingButtonDetailViewController() }),
        ExampleItem(
            title: "Photo Button & Copyable Label",
            subtitle: "LMKPhotoButton photo well, LMKCopyableLabel long-press copy",
            iconName: "person.crop.circle.badge.plus",
            makeViewController: { PhotoButtonCopyableLabelDetailViewController() }
        ),
    ]),
    ExampleSection(title: "Text Input & Forms", summary: "Fields, the form layout, and the keyboard.", items: [
        ExampleItem(title: "Text Field", subtitle: "Validation states, icons, helper text, counter", iconName: "character.cursor.ibeam", makeViewController: { TextFieldDetailViewController() }),
        ExampleItem(title: "Text View", subtitle: "Multi-line input that grows, with a character limit", iconName: "text.alignleft", makeViewController: { TextViewDetailViewController() }),
        ExampleItem(title: "Search Bar", subtitle: "LMKSearchBar with cancel, debounce, and focus", iconName: "magnifyingglass", makeViewController: { SearchBarDetailViewController() }),
        ExampleItem(
            title: "Form Scaffold",
            subtitle: "LMKFormScaffold: scroll and stack layout with keyboard avoidance",
            iconName: "square.and.pencil",
            makeViewController: { FormScaffoldDetailViewController() }
        ),
        ExampleItem(
            title: "Keyboard Dismiss",
            subtitle: "Dismiss on Return and on a tap outside a field",
            iconName: "keyboard.chevron.compact.down",
            makeViewController: { KeyboardDismissDetailViewController() }
        ),
        ExampleItem(
            title: "Readable Width & Key Commands",
            subtitle: "lmk_pinReadableWidth, lmk_readableWidthGuide, lmk_formKeyCommands",
            iconName: "rectangle.compress.vertical",
            makeViewController: { ReadableWidthDetailViewController() }
        ),
    ]),
    ExampleSection(title: "Labels & Indicators", summary: "Small pieces that label, count, and separate.", items: [
        ExampleItem(title: "Badges", subtitle: "Count, text, and dot badges", iconName: "app.badge", makeViewController: { BadgesDetailViewController() }),
        ExampleItem(title: "Chips", subtitle: "Filled, tinted, outlined, dismissible, and selectable", iconName: "tag", makeViewController: { ChipsDetailViewController() }),
        ExampleItem(
            title: "Filter Chip Bar",
            subtitle: "Single or multiple selection with an optional All chip",
            iconName: "line.3.horizontal.decrease.circle",
            makeViewController: { FilterChipBarDetailViewController() }
        ),
        ExampleItem(title: "Divider", subtitle: "Hairline separators, horizontal and vertical", iconName: "minus", makeViewController: { DividerDetailViewController() }),
        ExampleItem(title: "Page Indicator", subtitle: "Page dots with an expanding pill and a window", iconName: "circle.circle", makeViewController: { PageIndicatorDetailViewController() }),
        ExampleItem(title: "Markdown", subtitle: "LMKMarkdownRenderer: attributed text, links, tables", iconName: "text.badge.checkmark", makeViewController: { MarkdownDetailViewController() }),
    ]),
    ExampleSection(title: "Cards & Lists", summary: "Surfaces for content and the rows inside them.", items: [
        ExampleItem(title: "Cards", subtitle: "LMKCardView presets: cell, elevated, flat, outlined", iconName: "rectangle.on.rectangle", makeViewController: { CardsDetailViewController() }),
        ExampleItem(
            title: "Detail Cards",
            subtitle: "LMKDetailPageViewController: cards from a model, rows updated in place",
            iconName: "rectangle.stack.badge.person.crop",
            makeViewController: { DetailCardsDetailViewController() }
        ),
        ExampleItem(
            title: "List Row",
            subtitle: "LMKListRowConfiguration: symbol or thumbnail, text, accessories",
            iconName: "list.bullet.circle",
            makeViewController: { ListRowDetailViewController() }
        ),
        ExampleItem(title: "Checkbox Cell", subtitle: "Check-off row with a struck-through title", iconName: "checkmark.circle", makeViewController: { CheckboxCellDetailViewController() }),
        ExampleItem(title: "Cell Highlight", subtitle: "lmk_applyCustomHighlight and lmk_configureCustomHighlight", iconName: "hand.tap.fill", makeViewController: { HighlightDetailViewController() }),
        ExampleItem(title: "Overscroll Footer", subtitle: "A footer revealed by pulling past the end", iconName: "arrow.down.to.line", makeViewController: { OverscrollFooterDetailViewController() }),
    ]),
    ExampleSection(title: "Dates", summary: "Showing, picking, and formatting dates.", items: [
        ExampleItem(
            title: "Month Calendar",
            subtitle: "LMKMonthCalendarView: paging, selection modes, dots, badges, glyphs",
            iconName: "calendar",
            makeViewController: { MonthCalendarDetailViewController() }
        ),
        ExampleItem(title: "Date Picker", subtitle: "Single date, range, calendar range, and notes", iconName: "calendar.badge.plus", makeViewController: { DatePickerDetailViewController() }),
        ExampleItem(
            title: "Date Formatting",
            subtitle: "LMKDateFormat styles, ranges, clock times; LMKFormat numbers",
            iconName: "calendar.badge.clock",
            makeViewController: { DateFormattingDetailViewController() }
        ),
    ]),
    ExampleSection(title: "Navigation", summary: "Bars, tabs, pages, and menus.", items: [
        ExampleItem(
            title: "Navigation Bar",
            subtitle: "Glass on iOS 26, classic before; titles, items, badges",
            iconName: "menubar.rectangle",
            makeViewController: { NavigationBarDetailViewController() }
        ),
        ExampleItem(
            title: "Navigation Controller",
            subtitle: "Swipe back with the system bar hidden",
            iconName: "arrow.backward.circle",
            makeViewController: { NavigationControllerDetailViewController() }
        ),
        ExampleItem(
            title: "Tab Bar",
            subtitle: "LMKTabBarController: lazy roots, badges, sidebar, iOS 26 accessory",
            iconName: "square.grid.3x1.below.line.grid.1x2",
            makeViewController: { TabBarDetailViewController() }
        ),
        ExampleItem(
            title: "Segmented Pages",
            subtitle: "Pages under a segmented control, swiped with the finger",
            iconName: "rectangle.split.2x1",
            makeViewController: { SegmentedPagesDetailViewController() }
        ),
        ExampleItem(title: "Card Page", subtitle: "A header and pages that push inside a card", iconName: "square.stack", makeViewController: { CardPageDetailViewController() }),
        ExampleItem(
            title: "Menus",
            subtitle: "LMKMenu: choices, toggles, commands, submenus; LMKSortMenu",
            iconName: "filemenu.and.selection",
            makeViewController: { MenusDetailViewController() }
        ),
    ]),
    ExampleSection(title: "Feedback & Status", summary: "Telling people what happened and what is loading.", items: [
        ExampleItem(title: "Toast", subtitle: "Status toasts, actions, undo, persistent, queueing", iconName: "bell", makeViewController: { ToastDetailViewController() }),
        ExampleItem(title: "Banners", subtitle: "Inline or over a screen, with an action", iconName: "exclamationmark.bubble", makeViewController: { BannerDetailViewController() }),
        ExampleItem(
            title: "Alerts & Errors",
            subtitle: "Confirmation, text input, countdown, LMKErrorHandler",
            iconName: "exclamationmark.triangle",
            makeViewController: { AlertsDetailViewController() }
        ),
        ExampleItem(title: "Progress", subtitle: "Determinate and indeterminate progress", iconName: "gauge.with.dots.needle.33percent", makeViewController: { ProgressDetailViewController() }),
        ExampleItem(
            title: "Empty State",
            subtitle: "Full screen, card, and inline, with actions",
            iconName: "square.dashed",
            makeViewController: { EmptyStateDetailViewController() }
        ),
        ExampleItem(title: "Loading State", subtitle: "Inline, overlay, and skeleton loading", iconName: "progress.indicator", makeViewController: { LoadingStateDetailViewController() }),
        ExampleItem(
            title: "Pull to Refresh",
            subtitle: "LMKLottieRefreshControl with the bundled ring",
            iconName: "arrow.clockwise.circle",
            makeViewController: { RefreshControlDetailViewController() }
        ),
        ExampleItem(title: "Tip View", subtitle: "Centered and pointed tips with custom surfaces", iconName: "lightbulb", makeViewController: { TipViewDetailViewController() }),
        ExampleItem(title: "Haptics", subtitle: "Notification, impact, and selection feedback", iconName: "iphone.radiowaves.left.and.right", makeViewController: { HapticsDetailViewController() }),
    ]),
    ExampleSection(title: "Sheets & Panels", summary: "Content that slides over the screen.", items: [
        ExampleItem(
            title: "Bottom Sheet",
            subtitle: "The base sheet, with keyboard avoidance",
            iconName: "rectangle.bottomthird.inset.filled",
            makeViewController: { BottomSheetDetailViewController() }
        ),
        ExampleItem(title: "Action Sheet", subtitle: "Actions with icons, sub-pages, and custom content", iconName: "list.bullet", makeViewController: { ActionSheetDetailViewController() }),
        ExampleItem(title: "Enum Selection", subtitle: "LMKEnumPicker: single and multiple choice", iconName: "checklist", makeViewController: { EnumSelectionDetailViewController() }),
        ExampleItem(title: "Card Panel", subtitle: "A floating card in an overlay window", iconName: "rectangle.inset.filled", makeViewController: { CardPanelDetailViewController() }),
    ]),
    ExampleSection(title: "Photos & Media", summary: "Browsing, cropping, sharing, and reading images.", items: [
        ExampleItem(title: "Photo Grid", subtitle: "Pinch columns, drag to select, sort, fit or fill", iconName: "square.grid.2x2", makeViewController: { PhotoGridDetailViewController() }),
        ExampleItem(title: "Photo Browser", subtitle: "Paging, zoom, swipe to dismiss, Live Photos", iconName: "photo.on.rectangle", makeViewController: { PhotoBrowserDetailViewController() }),
        ExampleItem(title: "Photo Crop", subtitle: "Crop frame with aspect ratios and zoom", iconName: "crop", makeViewController: { PhotoCropDetailViewController() }),
        ExampleItem(
            title: "Pick & Crop",
            subtitle: "Pick, square-crop, and store; the single photo viewer",
            iconName: "photo.badge.plus",
            makeViewController: { PickCropDetailViewController() }
        ),
        ExampleItem(title: "Share", subtitle: "Share preview sheet and LMKShare", iconName: "square.and.arrow.up", makeViewController: { ShareDetailViewController() }),
        ExampleItem(
            title: "Image Utilities",
            subtitle: "LMKImage.downsample and sizes; LMKPhotoMetadata read and write",
            iconName: "photo.stack",
            makeViewController: { ImageUtilitiesDetailViewController() }
        ),
        ExampleItem(
            title: "Dominant Color",
            subtitle: "Histogram color extraction, with a subject-lifted mode",
            iconName: "eyedropper.halffull",
            makeViewController: { DominantColorDetailViewController() }
        ),
        ExampleItem(title: "QR Code", subtitle: "Generate QR codes from text", iconName: "qrcode", makeViewController: { QRCodeDetailViewController() }),
    ]),
    ExampleSection(title: "Utilities", summary: "Helpers on UIKit types.", items: [
        ExampleItem(title: "UIColor", subtitle: "Hex initializers, dynamic colors, brightness, contrast", iconName: "swatchpalette", makeViewController: { UIColorDetailViewController() }),
        ExampleItem(title: "Fade Animations", subtitle: "LMKAnimation.fadeIn and fadeOut", iconName: "circle.lefthalf.filled", makeViewController: { FadeDetailViewController() }),
    ]),
    ExampleSection(title: "Debug", summary: "Tools that ship in DEBUG builds only.", items: [
        ExampleItem(
            title: "Network History",
            subtitle: "LMKNetworkLogger capture with redaction, LMKNetworkHistoryViewController",
            iconName: "network",
            makeViewController: { NetworkHistoryDetailViewController() }
        ),
    ]),
]
