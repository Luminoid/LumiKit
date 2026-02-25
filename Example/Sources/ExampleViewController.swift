//
//  ExampleViewController.swift
//  LumiKitExample
//
//  Catalog list that navigates to detail pages for each component group.
//  Organized into sections: Design System, Components, Controls, Feedback, Overlays, Media.
//

import LumiKitUI
import SnapKit
import UIKit

final class ExampleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: - Data

    private enum Section: Int, CaseIterable {
        case designSystem
        case components
        case controls
        case feedback
        case overlays
        case media

        var title: String {
            switch self {
            case .designSystem: "Design System"
            case .components: "Components"
            case .controls: "Controls"
            case .feedback: "Feedback"
            case .overlays: "Overlays"
            case .media: "Media"
            }
        }

        var rows: [Row] {
            switch self {
            case .designSystem: [.typography, .colors]
            case .components: [.cards, .badges, .chips, .banners, .emptyState, .gradient, .loadingState]
            case .controls: [.buttons, .segmentedControl, .textField, .textView, .searchToggle]
            case .feedback: [.toast, .alerts, .progress, .haptics]
            case .overlays: [.actionSheet, .datePicker, .userTip, .cardPage, .cardPanel, .floatingButton]
            case .media: [.photoBrowser, .photoCrop, .qrCode]
            }
        }
    }

    private enum Row {
        case typography
        case colors
        case cards
        case badges
        case chips
        case banners
        case emptyState
        case gradient
        case loadingState
        case buttons
        case segmentedControl
        case textField
        case textView
        case searchToggle
        case toast
        case alerts
        case progress
        case haptics
        case actionSheet
        case datePicker
        case userTip
        case cardPage
        case cardPanel
        case floatingButton
        case photoBrowser
        case photoCrop
        case qrCode

        var title: String {
            switch self {
            case .typography: "Typography"
            case .colors: "Colors"
            case .cards: "Cards"
            case .badges: "Badges"
            case .chips: "Chips"
            case .banners: "Banners"
            case .emptyState: "Empty State"
            case .gradient: "Gradient"
            case .loadingState: "Loading State"
            case .buttons: "Buttons"
            case .segmentedControl: "Segmented Control"
            case .textField: "Text Field"
            case .textView: "Text View"
            case .searchToggle: "Search & Toggle"
            case .toast: "Toast"
            case .alerts: "Alerts & Errors"
            case .progress: "Progress"
            case .haptics: "Haptics"
            case .actionSheet: "Action Sheet"
            case .datePicker: "Date Picker"
            case .userTip: "User Tip"
            case .cardPage: "Card Page"
            case .cardPanel: "Card Panel"
            case .floatingButton: "Floating Button"
            case .photoBrowser: "Photo Browser"
            case .photoCrop: "Photo Crop"
            case .qrCode: "QR Code"
            }
        }

        var subtitle: String {
            switch self {
            case .typography: "Headings, body, caption, scientific name"
            case .colors: "Primary, semantic, text, and background colors"
            case .cards: "Card view and card factory"
            case .badges: "Count, text, and dot badges"
            case .chips: "Filled and outlined chip styles"
            case .banners: "Persistent info, warning, and error banners"
            case .emptyState: "Full screen, card, and inline styles"
            case .gradient: "Linear gradients with configurable directions"
            case .loadingState: "Inline, overlay, and skeleton loading"
            case .buttons: "Primary, secondary, destructive, warning"
            case .segmentedControl: "Multi-option selection with handlers"
            case .textField: "Validation states, icons, helper text"
            case .textView: "Multi-line input with character limit"
            case .searchToggle: "Search bar, toggle button, divider"
            case .toast: "Success, error, warning, info toasts"
            case .alerts: "Confirmation, alert, and error presentation"
            case .progress: "Determinate and indeterminate progress"
            case .haptics: "Success, warning, error, impact feedback"
            case .actionSheet: "Action sheets with icons and sub-pages"
            case .datePicker: "Single date, range, and date with notes"
            case .userTip: "Centered and pointed onboarding tips"
            case .cardPage: "Card page with multi-page navigation"
            case .cardPanel: "Floating card panel with passthrough"
            case .floatingButton: "Draggable floating action button"
            case .photoBrowser: "Full-screen photo viewer with zoom"
            case .photoCrop: "Crop with aspect ratios and zoom"
            case .qrCode: "Generate QR codes from text"
            }
        }

        var iconName: String {
            switch self {
            case .typography: "textformat"
            case .colors: "paintpalette"
            case .cards: "rectangle.on.rectangle"
            case .badges: "app.badge"
            case .chips: "tag"
            case .banners: "exclamationmark.bubble"
            case .emptyState: "square.dashed"
            case .gradient: "rectangle.fill"
            case .loadingState: "progress.indicator"
            case .buttons: "rectangle.and.hand.point.up.left"
            case .segmentedControl: "rectangle.split.3x1"
            case .textField: "character.cursor.ibeam"
            case .textView: "text.alignleft"
            case .searchToggle: "slider.horizontal.3"
            case .toast: "bell"
            case .alerts: "exclamationmark.triangle"
            case .progress: "gauge.with.dots.needle.33percent"
            case .haptics: "iphone.radiowaves.left.and.right"
            case .actionSheet: "list.bullet"
            case .datePicker: "calendar"
            case .userTip: "lightbulb"
            case .cardPage: "square.stack"
            case .cardPanel: "rectangle.inset.filled"
            case .floatingButton: "circle.circle"
            case .photoBrowser: "photo.on.rectangle"
            case .photoCrop: "crop"
            case .qrCode: "qrcode"
            }
        }

        @MainActor func makeDetailViewController() -> UIViewController {
            switch self {
            case .typography: TypographyDetailViewController()
            case .colors: ColorsDetailViewController()
            case .cards: CardsDetailViewController()
            case .badges: BadgesDetailViewController()
            case .chips: ChipsDetailViewController()
            case .banners: BannerDetailViewController()
            case .emptyState: EmptyStateDetailViewController()
            case .gradient: GradientDetailViewController()
            case .loadingState: LoadingStateDetailViewController()
            case .buttons: ButtonsDetailViewController()
            case .segmentedControl: SegmentedControlDetailViewController()
            case .textField: TextFieldDetailViewController()
            case .textView: TextViewDetailViewController()
            case .searchToggle: SearchToggleDetailViewController()
            case .toast: ToastDetailViewController()
            case .alerts: AlertsDetailViewController()
            case .progress: ProgressDetailViewController()
            case .haptics: HapticsDetailViewController()
            case .actionSheet: ActionSheetDetailViewController()
            case .datePicker: DatePickerDetailViewController()
            case .userTip: UserTipDetailViewController()
            case .cardPage: CardPageDetailViewController()
            case .cardPanel: CardPanelDetailViewController()
            case .floatingButton: FloatingButtonDetailViewController()
            case .photoBrowser: PhotoBrowserDetailViewController()
            case .photoCrop: PhotoCropDetailViewController()
            case .qrCode: QRCodeDetailViewController()
            }
        }
    }

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
        Section.allCases.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        Section(rawValue: section)?.title
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Section(rawValue: section)?.rows.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        guard let section = Section(rawValue: indexPath.section) else { return cell }
        let row = section.rows[indexPath.row]

        var config = cell.defaultContentConfiguration()
        config.text = row.title
        config.secondaryText = row.subtitle
        config.image = UIImage(systemName: row.iconName)
        config.imageProperties.tintColor = LMKColor.primary
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    // MARK: - Delegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let section = Section(rawValue: indexPath.section) else { return }
        let row = section.rows[indexPath.row]
        let detail = row.makeDetailViewController()
        detail.title = row.title
        navigationController?.pushViewController(detail, animated: true)
    }
}
