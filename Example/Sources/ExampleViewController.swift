//
//  ExampleViewController.swift
//  LumiKitExample
//
//  Catalog list that navigates to detail pages for each component group.
//

import LumiKitUI
import SnapKit
import UIKit

final class ExampleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: - Data

    private enum Row: Int, CaseIterable {
        case typography
        case colors
        case cards
        case badges
        case chips
        case emptyState
        case buttons
        case toast
        case controls
        case gradient
        case loadingState
        case banner
        case actionSheet
        case qrCode
        case photoBrowser
        case photoCrop
        case userTip
        case floatingButton

        var title: String {
            switch self {
            case .typography: "Typography"
            case .colors: "Colors"
            case .cards: "Cards"
            case .badges: "Badges"
            case .chips: "Chips"
            case .emptyState: "Empty State"
            case .buttons: "Buttons"
            case .toast: "Toast"
            case .controls: "Controls"
            case .gradient: "Gradient"
            case .loadingState: "Loading State"
            case .banner: "Banner"
            case .actionSheet: "Action Sheet"
            case .qrCode: "QR Code"
            case .photoBrowser: "Photo Browser"
            case .photoCrop: "Photo Crop"
            case .userTip: "User Tip"
            case .floatingButton: "Floating Button"
            }
        }

        var subtitle: String {
            switch self {
            case .typography: "Headings, body, caption, scientific name"
            case .colors: "Primary, semantic, and neutral colors"
            case .cards: "Card view and card factory"
            case .badges: "Count, text, and dot badges"
            case .chips: "Filled and outlined chip styles"
            case .emptyState: "Full screen, card, and inline styles"
            case .buttons: "Primary, secondary, destructive, warning"
            case .toast: "Success, error, warning, info toasts"
            case .controls: "Toggle, search bar, text field"
            case .gradient: "Linear gradients with configurable directions"
            case .loadingState: "Inline and overlay loading indicators"
            case .banner: "Persistent info, warning, and error banners"
            case .actionSheet: "Action sheets with icons and sub-pages"
            case .qrCode: "Generate QR codes from text"
            case .photoBrowser: "Full-screen photo viewer with zoom"
            case .photoCrop: "Crop with aspect ratios and zoom"
            case .userTip: "Centered and pointed onboarding tips"
            case .floatingButton: "Draggable floating action button"
            }
        }

        var iconName: String {
            switch self {
            case .typography: "textformat"
            case .colors: "paintpalette"
            case .cards: "rectangle.on.rectangle"
            case .badges: "app.badge"
            case .chips: "tag"
            case .emptyState: "square.dashed"
            case .buttons: "rectangle.and.hand.point.up.left"
            case .toast: "bell"
            case .controls: "slider.horizontal.3"
            case .gradient: "rectangle.fill"
            case .loadingState: "progress.indicator"
            case .banner: "exclamationmark.bubble"
            case .actionSheet: "list.bullet"
            case .qrCode: "qrcode"
            case .photoBrowser: "photo.on.rectangle"
            case .photoCrop: "crop"
            case .userTip: "lightbulb"
            case .floatingButton: "circle.circle"
            }
        }

        @MainActor func makeDetailViewController() -> UIViewController {
            switch self {
            case .typography: TypographyDetailViewController()
            case .colors: ColorsDetailViewController()
            case .cards: CardsDetailViewController()
            case .badges: BadgesDetailViewController()
            case .chips: ChipsDetailViewController()
            case .emptyState: EmptyStateDetailViewController()
            case .buttons: ButtonsDetailViewController()
            case .toast: ToastDetailViewController()
            case .controls: ControlsDetailViewController()
            case .gradient: GradientDetailViewController()
            case .loadingState: LoadingStateDetailViewController()
            case .banner: BannerDetailViewController()
            case .actionSheet: ActionSheetDetailViewController()
            case .qrCode: QRCodeDetailViewController()
            case .photoBrowser: PhotoBrowserDetailViewController()
            case .photoCrop: PhotoCropDetailViewController()
            case .userTip: UserTipDetailViewController()
            case .floatingButton: FloatingButtonDetailViewController()
            }
        }
    }

    // MARK: - Properties

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.contentInset.top = -LMKSpacing.large
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

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Row.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        guard let row = Row(rawValue: indexPath.row) else { return cell }

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
        guard let row = Row(rawValue: indexPath.row) else { return }
        let detail = row.makeDetailViewController()
        detail.title = row.title
        navigationController?.pushViewController(detail, animated: true)
    }
}
