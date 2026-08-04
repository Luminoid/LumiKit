//
//  ExampleViewController.swift
//  LumiKitExample
//
//  Catalog list that navigates to detail pages for each component group.
//  Organized into sections: Design System, Controls, Components, Lists & Cells,
//  Navigation & Paging, Feedback, Overlays, Media, Extensions.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Catalog Data

private struct ExampleItem {
    let title: String
    let subtitle: String
    let iconName: String
    let makeViewController: @MainActor () -> UIViewController
}

private struct ExampleSection {
    let title: String
    let items: [ExampleItem]
}

private let exampleSections: [ExampleSection] = [
    // Foundation tokens — understand the design system first
    ExampleSection(title: "Design System", items: [
        ExampleItem(title: "Colors", subtitle: "LMKColor tokens — primary, semantic, text, background", iconName: "paintpalette", makeViewController: { ColorsDetailViewController() }),
        ExampleItem(title: "Typography", subtitle: "Headings, body, caption, scientific name", iconName: "textformat", makeViewController: { TypographyDetailViewController() }),
        ExampleItem(title: "Markdown", subtitle: "Render markdown as attributed strings", iconName: "text.badge.checkmark", makeViewController: { MarkdownDetailViewController() }),
    ]),
    // Interactive inputs — action → toggle → selection → text input
    ExampleSection(title: "Controls", items: [
        ExampleItem(title: "Buttons", subtitle: "Filled, outlined, ghost, icon-only, loading", iconName: "rectangle.and.hand.point.up.left", makeViewController: { ButtonsDetailViewController() }),
        ExampleItem(title: "Toggle Button", subtitle: "Text button with on/off states", iconName: "togglepower", makeViewController: { ToggleButtonDetailViewController() }),
        ExampleItem(title: "Switch", subtitle: "Custom toggle with spring animation", iconName: "switch.2", makeViewController: { SwitchDetailViewController() }),
        ExampleItem(title: "Segmented Control", subtitle: "Draggable pill indicator, corner styles", iconName: "rectangle.split.3x1", makeViewController: { SegmentedControlDetailViewController() }),
        ExampleItem(title: "Slider", subtitle: "Caption, live readout, step-snap, negative range", iconName: "slider.horizontal.3", makeViewController: { SliderDetailViewController() }),
        ExampleItem(title: "Text Field", subtitle: "Validation states, icons, helper text", iconName: "character.cursor.ibeam", makeViewController: { TextFieldDetailViewController() }),
        ExampleItem(title: "Text View", subtitle: "Multi-line input with character limit", iconName: "text.alignleft", makeViewController: { TextViewDetailViewController() }),
        ExampleItem(title: "Search Bar", subtitle: "Search input with cancel button", iconName: "magnifyingglass", makeViewController: { SearchBarDetailViewController() }),
    ]),
    // Static/display elements — simple → composite
    ExampleSection(title: "Components", items: [
        ExampleItem(title: "Divider", subtitle: "Pixel-perfect horizontal separator", iconName: "minus", makeViewController: { DividerDetailViewController() }),
        ExampleItem(title: "Gradient", subtitle: "Linear gradients with configurable directions", iconName: "rectangle.fill", makeViewController: { GradientDetailViewController() }),
        ExampleItem(title: "Badges", subtitle: "Count, text, and dot badges", iconName: "app.badge", makeViewController: { BadgesDetailViewController() }),
        ExampleItem(title: "Chips", subtitle: "Filled, outlined, dismissible, and toggle", iconName: "tag", makeViewController: { ChipsDetailViewController() }),
        ExampleItem(
            title: "Filter Chip Bar",
            subtitle: "Single/multi-select chip row with optional All chip and icons",
            iconName: "line.3.horizontal.decrease.circle",
            makeViewController: { FilterChipBarDetailViewController() }
        ),
        ExampleItem(title: "Cards", subtitle: "Card view and card factory", iconName: "rectangle.on.rectangle", makeViewController: { CardsDetailViewController() }),
        ExampleItem(title: "Banners", subtitle: "Persistent info, warning, and error banners", iconName: "exclamationmark.bubble", makeViewController: { BannerDetailViewController() }),
        ExampleItem(
            title: "Empty State",
            subtitle: "Full screen, card, and inline styles with optional action button",
            iconName: "square.dashed",
            makeViewController: { EmptyStateDetailViewController() }
        ),
        ExampleItem(title: "Loading State", subtitle: "Inline, overlay, and skeleton loading", iconName: "progress.indicator", makeViewController: { LoadingStateDetailViewController() }),
        ExampleItem(
            title: "Form Scaffold",
            subtitle: "LMKFormScaffold — scroll + stack form layout with keyboard avoidance",
            iconName: "square.and.pencil",
            makeViewController: { FormScaffoldDetailViewController() }
        ),
    ]),
    // Table and list rows — cells and row helpers
    ExampleSection(title: "Lists & Cells", items: [
        ExampleItem(title: "Checkbox Cell", subtitle: "Check-off row with strike-through title", iconName: "checkmark.circle", makeViewController: { CheckboxCellDetailViewController() }),
        ExampleItem(
            title: "Icon List Row",
            subtitle: "lmk_configureIconListRow — symbol in a tinted circle",
            iconName: "list.bullet.circle",
            makeViewController: { IconListRowDetailViewController() }
        ),
        ExampleItem(title: "Cell Highlight", subtitle: "lmk_applyCustomHighlight and lmk_configureCustomHighlight", iconName: "hand.tap.fill", makeViewController: { HighlightDetailViewController() }),
        ExampleItem(title: "Overscroll Footer", subtitle: "Footer revealed on overscroll", iconName: "arrow.down.to.line", makeViewController: { OverscrollFooterDetailViewController() }),
    ]),
    // Screen structure — bars, stacks, and paging
    ExampleSection(title: "Navigation & Paging", items: [
        ExampleItem(title: "Navigation Bar", subtitle: "Large title, inline, back button, bar items", iconName: "menubar.rectangle", makeViewController: { NavigationBarDetailViewController() }),
        ExampleItem(
            title: "Navigation Controller",
            subtitle: "Preserves swipe-to-go-back when system nav bar is hidden",
            iconName: "arrow.backward.circle",
            makeViewController: { NavigationControllerDetailViewController() }
        ),
        ExampleItem(title: "Page Indicator", subtitle: "Animated expanding pill page dots", iconName: "circle.circle", makeViewController: { PageIndicatorDetailViewController() }),
        ExampleItem(
            title: "Segmented Pages",
            subtitle: "Tab container with interactive finger-tracking swipe paging",
            iconName: "rectangle.split.2x1",
            makeViewController: { SegmentedPagesDetailViewController() }
        ),
    ]),
    // Transient notifications and user feedback
    ExampleSection(title: "Feedback", items: [
        ExampleItem(title: "Toast", subtitle: "Success, error, warning, info toasts", iconName: "bell", makeViewController: { ToastDetailViewController() }),
        ExampleItem(
            title: "Alerts & Errors",
            subtitle: "Confirmation, alert, text input, and error presentation",
            iconName: "exclamationmark.triangle",
            makeViewController: { AlertsDetailViewController() }
        ),
        ExampleItem(title: "Progress", subtitle: "Determinate and indeterminate progress", iconName: "gauge.with.dots.needle.33percent", makeViewController: { ProgressDetailViewController() }),
        ExampleItem(title: "Haptics", subtitle: "Success, warning, error, impact feedback", iconName: "iphone.radiowaves.left.and.right", makeViewController: { HapticsDetailViewController() }),
    ]),
    // Modal and floating presentations — bottom sheets → overlays → floating
    ExampleSection(title: "Overlays", items: [
        ExampleItem(
            title: "Bottom Sheet",
            subtitle: "Base sheet with built-in keyboard avoidance",
            iconName: "rectangle.bottomthird.inset.filled",
            makeViewController: { BottomSheetDetailViewController() }
        ),
        ExampleItem(title: "Action Sheet", subtitle: "Action sheets with icons and sub-pages", iconName: "list.bullet", makeViewController: { ActionSheetDetailViewController() }),
        ExampleItem(title: "Enum Selection", subtitle: "Generic enum picker bottom sheet", iconName: "checklist", makeViewController: { EnumSelectionDetailViewController() }),
        ExampleItem(title: "Date Picker", subtitle: "Single date, range, calendar range, and notes", iconName: "calendar", makeViewController: { DatePickerDetailViewController() }),
        ExampleItem(title: "Tip View", subtitle: "Centered and pointed onboarding tips", iconName: "lightbulb", makeViewController: { TipViewDetailViewController() }),
        ExampleItem(title: "Card Page", subtitle: "Card page with multi-page navigation", iconName: "square.stack", makeViewController: { CardPageDetailViewController() }),
        ExampleItem(title: "Card Panel", subtitle: "Floating card panel in overlay window", iconName: "rectangle.inset.filled", makeViewController: { CardPanelDetailViewController() }),
        ExampleItem(title: "Floating Button", subtitle: "Draggable floating action button", iconName: "circle.circle", makeViewController: { FloatingButtonDetailViewController() }),
    ]),
    // Photo pipeline (browse → view → crop → pick), then sharing, generation, analysis
    ExampleSection(title: "Media", items: [
        ExampleItem(title: "Photo Grid", subtitle: "Square grid with pinch zoom and sort", iconName: "square.grid.2x2", makeViewController: { PhotoGridDetailViewController() }),
        ExampleItem(title: "Photo Browser", subtitle: "Full-screen photo viewer with zoom", iconName: "photo.on.rectangle", makeViewController: { PhotoBrowserDetailViewController() }),
        ExampleItem(title: "Photo Crop", subtitle: "Crop with aspect ratios and zoom", iconName: "crop", makeViewController: { PhotoCropDetailViewController() }),
        ExampleItem(
            title: "Pick & Crop",
            subtitle: "Pick, square-crop, store — plus single photo viewer",
            iconName: "photo.badge.plus",
            makeViewController: { PickCropDetailViewController() }
        ),
        ExampleItem(title: "Share", subtitle: "Share preview sheet and share service", iconName: "square.and.arrow.up", makeViewController: { ShareDetailViewController() }),
        ExampleItem(title: "QR Code", subtitle: "Generate QR codes from text", iconName: "qrcode", makeViewController: { QRCodeDetailViewController() }),
        ExampleItem(
            title: "Dominant Color",
            subtitle: "Modal RGB-histogram color extraction with subject-lifted mode",
            iconName: "eyedropper.halffull",
            makeViewController: { DominantColorDetailViewController() }
        ),
    ]),
    // UIKit extension utilities — color, styling, animation, keyboard
    ExampleSection(title: "Extensions", items: [
        ExampleItem(title: "UIColor", subtitle: "UIColor+LMK — hex init, dynamic, brightness, contrast", iconName: "swatchpalette", makeViewController: { UIColorDetailViewController() }),
        ExampleItem(title: "Shadows", subtitle: "Shadow presets and lmk_applyShadow", iconName: "shadow", makeViewController: { ShadowDetailViewController() }),
        ExampleItem(
            title: "Borders & Radius",
            subtitle: "Borders (hairline default), corner radius, and circular views",
            iconName: "square.dashed",
            makeViewController: { BorderDetailViewController() }
        ),
        ExampleItem(title: "Fade Animations", subtitle: "lmk_fadeIn and lmk_fadeOut", iconName: "circle.lefthalf.filled", makeViewController: { FadeDetailViewController() }),
        ExampleItem(
            title: "Keyboard Dismiss",
            subtitle: "Dismiss on Return and on tap outside a field",
            iconName: "keyboard.chevron.compact.down",
            makeViewController: { KeyboardDismissDetailViewController() }
        ),
    ]),
]

// MARK: - About Section

private struct InfoItem {
    let title: String
    let detail: String
    let iconName: String
    let isLink: Bool

    init(_ title: String, detail: String, iconName: String, isLink: Bool = false) {
        self.title = title
        self.detail = detail
        self.iconName = iconName
        self.isLink = isLink
    }
}

private let aboutItems: [InfoItem] = [
    InfoItem("Version", detail: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—", iconName: "tag"),
    InfoItem("GitHub", detail: "Luminoid/LumiKit", iconName: "link", isLink: true),
    InfoItem("Platform", detail: "iOS 18+ · Mac Catalyst 18+", iconName: "iphone"),
    InfoItem("Swift", detail: "6.2 · Strict Concurrency", iconName: "swift"),
    InfoItem("License", detail: "MIT", iconName: "doc.text"),
]

// MARK: - ExampleViewController

final class ExampleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: - Constants

    private static let githubURL = URL(string: "https://github.com/Luminoid/LumiKit")!
    private static let aboutSectionIndex = exampleSections.count

    // MARK: - Properties

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tableView
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        LMKThemeManager.shared.apply(ExampleTheme())
        title = "LumiKit"
        view.backgroundColor = LMKColor.backgroundPrimary

        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    // MARK: - Data Source

    func numberOfSections(in tableView: UITableView) -> Int {
        exampleSections.count + 1 // +1 for About
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == Self.aboutSectionIndex { return "About" }
        return exampleSections[section].title
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == Self.aboutSectionIndex { return aboutItems.count }
        return exampleSections[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        if indexPath.section == Self.aboutSectionIndex {
            let info = aboutItems[indexPath.row]
            var config = cell.defaultContentConfiguration()
            config.text = info.title
            config.secondaryText = info.detail
            config.secondaryTextProperties.color = info.isLink ? LMKColor.primary : LMKColor.textSecondary
            config.image = UIImage(systemName: info.iconName)
            config.imageProperties.tintColor = LMKColor.primary
            cell.contentConfiguration = config
            cell.accessoryType = info.isLink ? .disclosureIndicator : .none
            cell.selectionStyle = info.isLink ? .default : .none
            return cell
        }

        let item = exampleSections[indexPath.section].items[indexPath.row]
        var config = cell.defaultContentConfiguration()
        config.text = item.title
        config.secondaryText = item.subtitle
        config.image = UIImage(systemName: item.iconName)
        config.imageProperties.tintColor = LMKColor.primary
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        return cell
    }

    // MARK: - Delegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == Self.aboutSectionIndex {
            guard aboutItems[indexPath.row].isLink else { return }
            UIApplication.shared.open(Self.githubURL)
            return
        }

        let item = exampleSections[indexPath.section].items[indexPath.row]
        let detail = item.makeViewController()
        detail.title = item.title
        navigationController?.pushViewController(detail, animated: true)
    }
}
