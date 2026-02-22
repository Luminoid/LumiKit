//
//  DetailViewControllers.swift
//  LumiKitExample
//
//  Detail pages for each component group.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Base

class DetailViewController: UIViewController {
    let scrollView = UIScrollView()
    let stack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = LMKColor.backgroundPrimary

        scrollView.keyboardDismissMode = .onDrag
        stack.axis = .vertical
        stack.spacing = LMKSpacing.large

        view.addSubview(scrollView)
        scrollView.addSubview(stack)

        scrollView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        stack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(LMKSpacing.large)
            $0.width.equalToSuperview().offset(-LMKSpacing.large * 2)
        }
    }

    func addSectionHeader(_ text: String) {
        stack.addArrangedSubview(LMKLabelFactory.heading(text: text, level: 3))
    }

    func addDivider() {
        stack.addArrangedSubview(LMKDividerView())
    }
}

// MARK: - Typography

final class TypographyDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Headings")
        stack.addArrangedSubview(LMKLabelFactory.heading(text: "Heading 1", level: 1))
        stack.addArrangedSubview(LMKLabelFactory.heading(text: "Heading 2", level: 2))
        stack.addArrangedSubview(LMKLabelFactory.heading(text: "Heading 3", level: 3))
        stack.addArrangedSubview(LMKLabelFactory.heading(text: "Heading 4", level: 4))

        addDivider()
        addSectionHeader("Body Styles")
        stack.addArrangedSubview(LMKLabelFactory.body(text: "Body — the quick brown fox jumps over the lazy dog. This is the default paragraph style used for content."))
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Caption — used for secondary information and metadata"))
        stack.addArrangedSubview(LMKLabelFactory.small(text: "Small — fine print and tertiary details"))

        addDivider()
        addSectionHeader("Special")
        stack.addArrangedSubview(LMKLabelFactory.scientificName(text: "Monstera deliciosa"))
        stack.addArrangedSubview(LMKLabelFactory.scientificName(text: "Epipremnum aureum"))
    }
}

// MARK: - Colors

final class ColorsDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addColorRow("Primary", [
            ("Primary", LMKColor.primary),
            ("Secondary", LMKColor.secondary),
        ])

        addDivider()
        addColorRow("Semantic", [
            ("Success", LMKColor.success),
            ("Warning", LMKColor.warning),
            ("Error", LMKColor.error),
            ("Info", LMKColor.info),
        ])

        addDivider()
        addColorRow("Text", [
            ("Primary", LMKColor.textPrimary),
            ("Secondary", LMKColor.textSecondary),
            ("Tertiary", LMKColor.textTertiary),
        ])

        addDivider()
        addColorRow("Backgrounds", [
            ("Primary", LMKColor.backgroundPrimary),
            ("Secondary", LMKColor.backgroundSecondary),
            ("Tertiary", LMKColor.backgroundTertiary),
        ])
    }

    private func addColorRow(_ title: String, _ colors: [(String, UIColor)]) {
        addSectionHeader(title)
        let row = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        row.distribution = .fillEqually

        for (name, color) in colors {
            let swatch = UIView()
            swatch.backgroundColor = color
            swatch.layer.cornerRadius = LMKCornerRadius.small
            swatch.layer.borderWidth = 0.5
            swatch.layer.borderColor = LMKColor.divider.cgColor

            let label = LMKLabelFactory.small(text: name)
            label.textAlignment = .center

            let col = UIStackView(lmk_axis: .vertical, spacing: LMKSpacing.xs)
            col.addArrangedSubview(swatch)
            col.addArrangedSubview(label)
            swatch.snp.makeConstraints { $0.height.equalTo(52) }
            row.addArrangedSubview(col)
        }
        stack.addArrangedSubview(row)
    }
}

// MARK: - Cards

final class CardsDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("LMKCardView")
        let card = LMKCardView()
        let label = LMKLabelFactory.body(text: "Card with shadow, corner radius, and content insets. Uses LMKShadow.cellCard() and LMKCornerRadius.medium.")
        card.contentView.addSubview(label)
        label.snp.makeConstraints { $0.edges.equalToSuperview().inset(LMKSpacing.large) }
        stack.addArrangedSubview(card)

        addDivider()
        addSectionHeader("LMKCardFactory")
        let factoryCard = LMKCardFactory.cardView()
        let factoryLabel = LMKLabelFactory.body(text: "Created via LMKCardFactory.cardView() — secondary background with standard shadow.")
        factoryCard.addSubview(factoryLabel)
        factoryLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(LMKSpacing.large) }
        stack.addArrangedSubview(factoryCard)
    }
}

// MARK: - Badges

final class BadgesDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Badge Styles")
        let row = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.xxl)
        row.alignment = .center

        let configs: [(String, () -> Void)] = [
            ("Count", { [self] in addBadgeColumn(to: row, label: "Count") { $0.configure(count: 5) } }),
            ("Text", { [self] in addBadgeColumn(to: row, label: "Text") { $0.configure(text: "New") } }),
            ("99+", { [self] in addBadgeColumn(to: row, label: "99+") { $0.configure(count: 150) } }),
            ("Dot", { [self] in addBadgeColumn(to: row, label: "Dot") { $0.configure() } }),
        ]
        configs.forEach { $0.1() }
        row.addArrangedSubview(UIView())
        stack.addArrangedSubview(row)

        addDivider()
        addSectionHeader("Custom Colors")
        let colorRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.xxl)
        colorRow.alignment = .center

        for (name, color) in [("Success", LMKColor.success), ("Info", LMKColor.info), ("Warning", LMKColor.warning)] {
            let badge = LMKBadgeView()
            badge.badgeColor = color
            badge.configure(text: name)
            let label = LMKLabelFactory.small(text: name)
            let col = UIStackView(lmk_axis: .vertical, spacing: LMKSpacing.xs)
            col.alignment = .center
            col.addArrangedSubview(badge)
            col.addArrangedSubview(label)
            colorRow.addArrangedSubview(col)
        }
        colorRow.addArrangedSubview(UIView())
        stack.addArrangedSubview(colorRow)
    }

    private func addBadgeColumn(to row: UIStackView, label text: String, configure: (LMKBadgeView) -> Void) {
        let badge = LMKBadgeView()
        configure(badge)
        let label = LMKLabelFactory.small(text: text)
        let col = UIStackView(lmk_axis: .vertical, spacing: LMKSpacing.xs)
        col.alignment = .center
        col.addArrangedSubview(badge)
        col.addArrangedSubview(label)
        row.addArrangedSubview(col)
    }
}

// MARK: - Chips

final class ChipsDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Filled")
        let filledRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        filledRow.addArrangedSubview(LMKChipView(text: "Design", style: .filled))
        filledRow.addArrangedSubview(LMKChipView(text: "Swift", style: .filled))
        filledRow.addArrangedSubview(LMKChipView(text: "UIKit", style: .filled))
        filledRow.addArrangedSubview(UIView())
        stack.addArrangedSubview(filledRow)

        addDivider()
        addSectionHeader("Outlined")
        let outlinedRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        outlinedRow.addArrangedSubview(LMKChipView(text: "Layout", style: .outlined))
        outlinedRow.addArrangedSubview(LMKChipView(text: "Theme", style: .outlined))
        outlinedRow.addArrangedSubview(LMKChipView(text: "Token", style: .outlined))
        outlinedRow.addArrangedSubview(UIView())
        stack.addArrangedSubview(outlinedRow)

        addDivider()
        addSectionHeader("Custom Colors")
        let colorRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        let colors: [(String, UIColor)] = [
            ("Success", LMKColor.success),
            ("Warning", LMKColor.warning),
            ("Info", LMKColor.info),
        ]
        for (text, color) in colors {
            let chip = LMKChipView(text: text, style: .filled)
            chip.chipColor = color
            colorRow.addArrangedSubview(chip)
        }
        colorRow.addArrangedSubview(UIView())
        stack.addArrangedSubview(colorRow)

        addDivider()
        addSectionHeader("With Icons")
        let iconRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        iconRow.addArrangedSubview(LMKChipView(text: "Star", icon: UIImage(systemName: "star"), style: .filled))
        iconRow.addArrangedSubview(LMKChipView(text: "Heart", icon: UIImage(systemName: "heart"), style: .outlined))
        iconRow.addArrangedSubview(UIView())
        stack.addArrangedSubview(iconRow)
    }
}

// MARK: - Empty State

final class EmptyStateDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Card Style")
        let cardEmpty = LMKEmptyStateView()
        cardEmpty.configure(message: "Nothing here yet — add your first item.", icon: "tray", style: .card)
        cardEmpty.snp.makeConstraints { $0.height.equalTo(LMKEmptyStateView.cardCellHeight) }
        stack.addArrangedSubview(cardEmpty)

        addDivider()
        addSectionHeader("Inline Style")
        let inlineEmpty = LMKEmptyStateView()
        inlineEmpty.configure(message: "No results found", icon: "magnifyingglass", style: .inline)
        inlineEmpty.snp.makeConstraints { $0.height.equalTo(LMKEmptyStateView.inlineCellHeight) }
        stack.addArrangedSubview(inlineEmpty)

        addDivider()
        addSectionHeader("Full Screen Style")
        let fullEmpty = LMKEmptyStateView()
        fullEmpty.configure(message: "Your collection is empty. Start by adding some items!", icon: "square.stack.3d.up.slash", style: .fullScreen)
        fullEmpty.snp.makeConstraints { $0.height.equalTo(LMKEmptyStateView.fullScreenCellHeight) }
        stack.addArrangedSubview(fullEmpty)
    }
}

// MARK: - Buttons

final class ButtonsDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("LMKButtonFactory")
        stack.addArrangedSubview(LMKButtonFactory.primary(title: "Primary Action", target: self, action: #selector(tapped)))
        stack.addArrangedSubview(LMKButtonFactory.secondary(title: "Secondary Action", target: self, action: #selector(tapped)))
        stack.addArrangedSubview(LMKButtonFactory.destructive(title: "Delete", target: self, action: #selector(tapped)))
        stack.addArrangedSubview(LMKButtonFactory.warning(title: "Warning", target: self, action: #selector(tapped)))

        addDivider()
        addSectionHeader("LMKButton")
        let button = LMKButton()
        button.setTitle("Tap me (closure-based)", for: .normal)
        button.setTitleColor(LMKColor.primary, for: .normal)
        button.tapHandler = { [weak self] in
            guard let self else { return }
            LMKToast.showSuccess(message: "LMKButton tapped!", on: self)
        }
        stack.addArrangedSubview(button)

        let animatedButton = LMKButton()
        animatedButton.setTitle("With press animation", for: .normal)
        animatedButton.setTitleColor(LMKColor.secondary, for: .normal)
        animatedButton.pressAnimationEnabled = true
        animatedButton.tapHandler = { [weak self] in
            guard let self else { return }
            LMKToast.showInfo(message: "Press animation enabled!", on: self)
        }
        stack.addArrangedSubview(animatedButton)
    }

    @objc private func tapped() {
        LMKToast.showSuccess(message: "Button tapped!", on: self)
    }
}

// MARK: - Toast

final class ToastDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let types: [(String, UIColor, Selector)] = [
            ("Show Success Toast", LMKColor.success, #selector(showSuccess)),
            ("Show Error Toast", LMKColor.error, #selector(showError)),
            ("Show Warning Toast", LMKColor.warning, #selector(showWarning)),
            ("Show Info Toast", LMKColor.info, #selector(showInfo)),
        ]

        addSectionHeader("Tap to show")
        for (title, color, action) in types {
            let button = LMKButton()
            button.setTitle(title, for: .normal)
            button.setTitleColor(color, for: .normal)
            button.titleLabel?.font = LMKTypography.bodyMedium
            button.addTarget(self, action: action, for: .touchUpInside)
            button.snp.makeConstraints { $0.height.equalTo(LMKLayout.minimumTouchTarget) }
            stack.addArrangedSubview(button)
        }
    }

    @objc private func showSuccess() { LMKToast.showSuccess(message: "Item saved successfully!", on: self) }
    @objc private func showError() { LMKToast.showError(message: "Failed to save item", on: self) }
    @objc private func showWarning() { LMKToast.showWarning(message: "Low storage warning", on: self) }
    @objc private func showInfo() { LMKToast.showInfo(message: "Tap an item for details", on: self) }
}

// MARK: - Controls

final class ControlsDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Toggle Button")
        let toggle = LMKToggleButton(
            titleForStatusOn: "Notifications On",
            titleForStatusOff: "Notifications Off"
        )
        toggle.setTitleColor(LMKColor.primary, for: .normal)
        toggle.titleLabel?.font = LMKTypography.bodyMedium
        toggle.flipStatusOnTap = true
        toggle.status = .off
        toggle.snp.makeConstraints { $0.height.equalTo(LMKLayout.minimumTouchTarget) }
        stack.addArrangedSubview(toggle)

        addDivider()
        addSectionHeader("Search Bar")
        let searchBar = LMKSearchBar()
        searchBar.placeholder = "Search items..."
        stack.addArrangedSubview(searchBar)

        addDivider()
        addSectionHeader("Divider")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Horizontal divider below:"))
        stack.addArrangedSubview(LMKDividerView())
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Content continues here"))
    }
}

// MARK: - Gradient

final class GradientDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let directions: [(String, LMKGradientDirection)] = [
            ("Top \u{2192} Bottom", .topToBottom),
            ("Left \u{2192} Right", .leftToRight),
            ("Top-Left \u{2192} Bottom-Right", .topLeftToBottomRight),
            ("Top-Right \u{2192} Bottom-Left", .topRightToBottomLeft),
        ]

        for (name, direction) in directions {
            addSectionHeader(name)
            let gradient = LMKGradientView(
                colors: [LMKColor.primary, LMKColor.secondary],
                direction: direction
            )
            gradient.layer.cornerRadius = LMKCornerRadius.medium
            gradient.clipsToBounds = true
            gradient.snp.makeConstraints { $0.height.equalTo(80) }
            stack.addArrangedSubview(gradient)
        }

        addDivider()
        addSectionHeader("Custom Colors")
        let sunset = LMKGradientView(
            colors: [LMKColor.warning, LMKColor.error, LMKColor.primary],
            direction: .leftToRight
        )
        sunset.layer.cornerRadius = LMKCornerRadius.medium
        sunset.clipsToBounds = true
        sunset.snp.makeConstraints { $0.height.equalTo(80) }
        stack.addArrangedSubview(sunset)
    }
}

// MARK: - Loading State

final class LoadingStateDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Inline Style")
        let inlineLoading = LMKLoadingStateView()
        inlineLoading.startLoading(message: "Loading data...")
        inlineLoading.snp.makeConstraints { $0.height.equalTo(120) }
        stack.addArrangedSubview(inlineLoading)

        addDivider()
        addSectionHeader("Overlay Style")
        let overlayContainer = UIView()
        overlayContainer.backgroundColor = LMKColor.backgroundSecondary
        overlayContainer.layer.cornerRadius = LMKCornerRadius.medium
        overlayContainer.clipsToBounds = true
        overlayContainer.snp.makeConstraints { $0.height.equalTo(160) }

        let overlayLoading = LMKLoadingStateView(overlayStyle: true)
        overlayLoading.startLoading(message: "Saving changes...")
        overlayContainer.addSubview(overlayLoading)
        overlayLoading.snp.makeConstraints { $0.edges.equalToSuperview() }
        stack.addArrangedSubview(overlayContainer)

        addDivider()
        addSectionHeader("Skeleton Cell")
        let skeletonTable = SkeletonTableView()
        skeletonTable.snp.makeConstraints { $0.height.equalTo(280) }
        stack.addArrangedSubview(skeletonTable)
    }
}

/// Embedded table view that displays skeleton cells with shimmer animation.
private final class SkeletonTableView: UIView, UITableViewDataSource {
    private static let cellID = "skeleton"
    private static let rowCount = 3

    private let tableView = UITableView(frame: .zero, style: .plain)

    override init(frame: CGRect) {
        super.init(frame: frame)
        tableView.dataSource = self
        tableView.register(LMKSkeletonCell.self, forCellReuseIdentifier: Self.cellID)
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.backgroundColor = .clear
        tableView.allowsSelection = false

        addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        // Start shimmer after appearing in the window
        DispatchQueue.main.async { [weak self] in
            self?.startShimmer()
        }
    }

    private func startShimmer() {
        for (index, cell) in tableView.visibleCells.enumerated() {
            (cell as? LMKSkeletonCell)?.startShimmer(staggerIndex: index)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Self.rowCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellID, for: indexPath) as? LMKSkeletonCell else {
            return UITableViewCell()
        }
        cell.startShimmer(staggerIndex: indexPath.row)
        return cell
    }
}

// MARK: - Banner

final class BannerDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Tap to show")
        let types: [(String, LMKBannerType, UIColor)] = [
            ("Show Info Banner", .info, LMKColor.info),
            ("Show Warning Banner", .warning, LMKColor.warning),
            ("Show Error Banner", .error, LMKColor.error),
            ("Show Success Banner", .success, LMKColor.success),
        ]

        for (title, type, color) in types {
            let button = LMKButton()
            button.setTitle(title, for: .normal)
            button.setTitleColor(color, for: .normal)
            button.titleLabel?.font = LMKTypography.bodyMedium
            button.snp.makeConstraints { $0.height.equalTo(LMKLayout.minimumTouchTarget) }
            button.tapHandler = { [weak self] in
                guard let self else { return }
                let banner = LMKBannerView(type: type, message: "This is a \(type) banner message.")
                banner.actionTitle = "Action"
                banner.show(on: self)
            }
            stack.addArrangedSubview(button)
        }

        addDivider()
        addSectionHeader("Non-dismissible")
        let button = LMKButton()
        button.setTitle("Show Persistent Banner", for: .normal)
        button.setTitleColor(LMKColor.primary, for: .normal)
        button.titleLabel?.font = LMKTypography.bodyMedium
        button.snp.makeConstraints { $0.height.equalTo(LMKLayout.minimumTouchTarget) }
        button.tapHandler = { [weak self] in
            guard let self else { return }
            let banner = LMKBannerView(type: .warning, message: "No internet connection")
            banner.showsDismissButton = false
            banner.actionTitle = "Retry"
            banner.show(on: self)
        }
        stack.addArrangedSubview(button)
    }
}

// MARK: - Action Sheet

final class ActionSheetDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Basic Action Sheet")
        let basicButton = LMKButtonFactory.primary(title: "Show Action Sheet", target: self, action: #selector(showBasicSheet))
        stack.addArrangedSubview(basicButton)

        addDivider()
        addSectionHeader("With Icons")
        let iconButton = LMKButtonFactory.secondary(title: "Show Action Sheet with Icons", target: self, action: #selector(showIconSheet))
        stack.addArrangedSubview(iconButton)
    }

    @objc private func showBasicSheet() {
        LMKActionSheet.present(
            in: self,
            title: "Item Actions",
            message: "Choose an action for this item.",
            actions: [
                .init(title: "Mark as Favorite") { [weak self] in
                    guard let self else { return }
                    LMKToast.showSuccess(message: "Added to favorites!", on: self)
                },
                .init(title: "Edit Details") { [weak self] in
                    guard let self else { return }
                    LMKToast.showInfo(message: "Edit tapped", on: self)
                },
                .init(title: "Delete", style: .destructive) { [weak self] in
                    guard let self else { return }
                    LMKToast.showError(message: "Delete tapped", on: self)
                },
            ]
        )
    }

    @objc private func showIconSheet() {
        LMKActionSheet.present(
            in: self,
            title: "Media Actions",
            actions: [
                .init(title: "Take Photo", icon: UIImage(systemName: "camera")) { [weak self] in
                    guard let self else { return }
                    LMKToast.showInfo(message: "Camera tapped", on: self)
                },
                .init(title: "Choose from Library", icon: UIImage(systemName: "photo.on.rectangle")) { [weak self] in
                    guard let self else { return }
                    LMKToast.showInfo(message: "Library tapped", on: self)
                },
                .init(title: "Delete Photo", style: .destructive, icon: UIImage(systemName: "trash")) { [weak self] in
                    guard let self else { return }
                    LMKToast.showError(message: "Delete tapped", on: self)
                },
            ]
        )
    }
}

// MARK: - QR Code

final class QRCodeDetailViewController: DetailViewController {
    private let imageView = UIImageView()
    private let textField = UITextField()

    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Generator")
        textField.placeholder = "Enter text or URL..."
        textField.text = "https://github.com/Luminoid/LumiKit"
        textField.borderStyle = .roundedRect
        textField.font = LMKTypography.body
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .done
        textField.addTarget(self, action: #selector(generateQR), for: .editingChanged)
        textField.addTarget(self, action: #selector(dismissKeyboard), for: .editingDidEndOnExit)
        stack.addArrangedSubview(textField)

        let generateButton = LMKButtonFactory.primary(title: "Generate QR Code", target: self, action: #selector(generateQR))
        stack.addArrangedSubview(generateButton)

        addDivider()
        addSectionHeader("Result")

        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = LMKColor.backgroundSecondary
        imageView.layer.cornerRadius = LMKCornerRadius.medium
        imageView.clipsToBounds = true
        imageView.snp.makeConstraints { $0.height.equalTo(200) }
        stack.addArrangedSubview(imageView)

        generateQR()

        addDivider()
        addSectionHeader("Correction Levels")
        let levels: [(String, LMKQRCodeGenerator.CorrectionLevel)] = [
            ("Low (~7%)", .low),
            ("Medium (~15%)", .medium),
            ("Quartile (~25%)", .quartile),
            ("High (~30%)", .high),
        ]
        let levelRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        levelRow.distribution = .fillEqually
        for (name, level) in levels {
            let col = UIStackView(lmk_axis: .vertical, spacing: LMKSpacing.xs)
            col.alignment = .center

            let qrImage = LMKQRCodeGenerator.generateQRCode(from: "LumiKit", size: 80, correctionLevel: level)
            let qrView = UIImageView(image: qrImage)
            qrView.contentMode = .scaleAspectFit
            qrView.snp.makeConstraints { $0.width.height.equalTo(80) }

            let label = LMKLabelFactory.small(text: name)
            label.textAlignment = .center

            col.addArrangedSubview(qrView)
            col.addArrangedSubview(label)
            levelRow.addArrangedSubview(col)
        }
        stack.addArrangedSubview(levelRow)
    }

    @objc private func generateQR() {
        let text = textField.text ?? ""
        imageView.image = LMKQRCodeGenerator.generateQRCode(from: text, size: 200)
    }

    @objc private func dismissKeyboard() {
        textField.resignFirstResponder()
    }
}

// MARK: - Photo Browser

final class PhotoBrowserDetailViewController: DetailViewController, LMKPhotoBrowserDataSource, LMKPhotoBrowserDelegate {
    private var sampleImages: [UIImage] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Generate sample images using SF Symbols
        let symbols = ["star.fill", "camera.fill", "sun.max.fill", "drop.fill", "flame.fill"]
        let colors: [UIColor] = [LMKColor.success, LMKColor.primary, LMKColor.warning, LMKColor.info, LMKColor.error]

        for (symbol, color) in zip(symbols, colors) {
            if let image = createSampleImage(symbolName: symbol, color: color) {
                sampleImages.append(image)
            }
        }

        addSectionHeader("Photo Browser")
        stack.addArrangedSubview(LMKLabelFactory.body(text: "Full-screen photo viewer with swipe navigation, pinch-to-zoom, and swipe-to-dismiss."))

        let previewRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        previewRow.distribution = .fillEqually
        for (index, image) in sampleImages.enumerated() {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = LMKCornerRadius.small
            imageView.isUserInteractionEnabled = true
            imageView.tag = index
            imageView.snp.makeConstraints { $0.height.equalTo(80) }

            let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
            imageView.addGestureRecognizer(tap)
            previewRow.addArrangedSubview(imageView)
        }
        stack.addArrangedSubview(previewRow)

        addDivider()
        let openButton = LMKButtonFactory.primary(title: "Open Photo Browser", target: self, action: #selector(openBrowser))
        stack.addArrangedSubview(openButton)

        addDivider()
        addSectionHeader("Features")
        let features = [
            "Swipe left/right to navigate",
            "Double-tap or pinch to zoom",
            "Swipe down to dismiss",
            "Page indicators and photo counter",
            "Date label overlay",
            "Keyboard navigation on Mac Catalyst",
        ]
        for feature in features {
            let label = LMKLabelFactory.caption(text: "\u{2022} \(feature)")
            stack.addArrangedSubview(label)
        }
    }

    @objc private func imageTapped(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view else { return }
        presentBrowser(at: view.tag)
    }

    @objc private func openBrowser() {
        presentBrowser(at: 0)
    }

    private func presentBrowser(at index: Int) {
        let browser = LMKPhotoBrowserViewController(initialIndex: index)
        browser.dataSource = self
        browser.delegate = self
        browser.modalPresentationStyle = .overFullScreen
        present(browser, animated: true)
    }

    private func createSampleImage(symbolName: String, color: UIColor) -> UIImage? {
        let size = CGSize(width: 300, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            color.withAlphaComponent(0.2).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            let config = UIImage.SymbolConfiguration(pointSize: 80, weight: .regular)
            if let symbol = UIImage(systemName: symbolName, withConfiguration: config) {
                let symbolSize = symbol.size
                let origin = CGPoint(
                    x: (size.width - symbolSize.width) / 2,
                    y: (size.height - symbolSize.height) / 2
                )
                color.setFill()
                symbol.withTintColor(color, renderingMode: .alwaysOriginal)
                    .draw(at: origin)
            }
        }
    }

    // MARK: - LMKPhotoBrowserDataSource

    var numberOfPhotos: Int { sampleImages.count }

    func photo(at index: Int) -> UIImage? {
        guard index >= 0, index < sampleImages.count else { return nil }
        return sampleImages[index]
    }

    func photoDate(at index: Int) -> Date? {
        Calendar.current.date(byAdding: .day, value: -index, to: Date())
    }

    func photoSubtitle(at index: Int) -> String? { nil }

    // MARK: - LMKPhotoBrowserDelegate

    func photoBrowser(_ browser: LMKPhotoBrowserViewController, didRequestActionAt index: Int) {
        LMKToast.showInfo(message: "Action requested for photo \(index + 1)", on: browser)
    }

    func photoBrowserDidDismiss(_ browser: LMKPhotoBrowserViewController) {}
}

// MARK: - Photo Crop

final class PhotoCropDetailViewController: DetailViewController, LMKPhotoCropDelegate {
    private var sampleImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()

        sampleImage = createSampleImage()

        addSectionHeader("Photo Crop")
        stack.addArrangedSubview(LMKLabelFactory.body(text: "Resizable crop frame with aspect ratio presets, pinch-to-zoom, and rule-of-thirds grid."))

        if let sampleImage {
            let preview = UIImageView(image: sampleImage)
            preview.contentMode = .scaleAspectFill
            preview.clipsToBounds = true
            preview.layer.cornerRadius = LMKCornerRadius.medium
            preview.snp.makeConstraints { $0.height.equalTo(200) }
            stack.addArrangedSubview(preview)
        }

        let cropButton = LMKButtonFactory.primary(title: "Open Photo Crop", target: self, action: #selector(openCrop))
        stack.addArrangedSubview(cropButton)

        addDivider()
        addSectionHeader("Aspect Ratios")
        let ratioRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        ratioRow.distribution = .fillEqually
        for ratio in LMKCropAspectRatio.allCases {
            let chip = LMKChipView(text: ratio.displayName, style: .outlined)
            ratioRow.addArrangedSubview(chip)
        }
        stack.addArrangedSubview(ratioRow)

        addDivider()
        addSectionHeader("Features")
        let features = [
            "Drag corners and edges to resize",
            "Pinch to zoom the image",
            "Aspect ratio presets (1:1, 4:3, 3:2, etc.)",
            "Free-form cropping",
            "Rule-of-thirds grid overlay",
        ]
        for feature in features {
            let label = LMKLabelFactory.caption(text: "\u{2022} \(feature)")
            stack.addArrangedSubview(label)
        }
    }

    @objc private func openCrop() {
        guard let sampleImage else { return }
        let cropVC = LMKPhotoCropViewController(image: sampleImage)
        cropVC.delegate = self
        cropVC.modalPresentationStyle = .overFullScreen
        present(cropVC, animated: true)
    }

    private func createSampleImage() -> UIImage? {
        let size = CGSize(width: 600, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            // Background gradient
            let colors = [LMKColor.primary.cgColor, LMKColor.secondary.cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1])!
            ctx.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])

            // Center symbol
            let config = UIImage.SymbolConfiguration(pointSize: 80, weight: .regular)
            if let symbol = UIImage(systemName: "leaf.fill", withConfiguration: config) {
                let symbolSize = symbol.size
                let origin = CGPoint(
                    x: (size.width - symbolSize.width) / 2,
                    y: (size.height - symbolSize.height) / 2
                )
                symbol.withTintColor(.white.withAlphaComponent(0.8), renderingMode: .alwaysOriginal)
                    .draw(at: origin)
            }
        }
    }

    // MARK: - LMKPhotoCropDelegate

    func photoCropViewController(_ controller: LMKPhotoCropViewController, didCropImage image: UIImage) {
        controller.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            LMKToast.showSuccess(message: "Image cropped (\(Int(image.size.width))×\(Int(image.size.height)))", on: self)
        }
    }

    func photoCropViewControllerDidCancel(_ controller: LMKPhotoCropViewController) {
        controller.dismiss(animated: true)
    }
}

// MARK: - User Tip

final class UserTipDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Center Style")
        let centerButton = LMKButton()
        centerButton.setTitle("Show Centered Tip", for: .normal)
        centerButton.setTitleColor(LMKColor.primary, for: .normal)
        centerButton.titleLabel?.font = LMKTypography.bodyMedium
        centerButton.snp.makeConstraints { $0.height.equalTo(LMKLayout.minimumTouchTarget) }
        centerButton.tapHandler = { [weak self] in
            guard let self else { return }
            LMKUserTip.show(
                title: "Did you know?",
                message: "You can long-press any item to see more options. Try it out!",
                icon: UIImage(systemName: "lightbulb"),
                style: .center,
                on: self
            )
        }
        stack.addArrangedSubview(centerButton)

        addDivider()
        addSectionHeader("Pointed Style")

        let targetChip = LMKChipView(text: "Target View", style: .filled)
        stack.addArrangedSubview(targetChip)

        let pointedButton = LMKButton()
        pointedButton.setTitle("Show Pointed Tip", for: .normal)
        pointedButton.setTitleColor(LMKColor.secondary, for: .normal)
        pointedButton.titleLabel?.font = LMKTypography.bodyMedium
        pointedButton.snp.makeConstraints { $0.height.equalTo(LMKLayout.minimumTouchTarget) }
        pointedButton.tapHandler = { [weak self] in
            guard let self else { return }
            LMKUserTip.show(
                message: "This tip points at the target view above",
                style: .pointed(sourceView: targetChip, arrowDirection: .automatic),
                on: self
            )
        }
        stack.addArrangedSubview(pointedButton)

        addDivider()
        addSectionHeader("Message Only")
        let simpleButton = LMKButton()
        simpleButton.setTitle("Show Simple Tip", for: .normal)
        simpleButton.setTitleColor(LMKColor.info, for: .normal)
        simpleButton.titleLabel?.font = LMKTypography.bodyMedium
        simpleButton.snp.makeConstraints { $0.height.equalTo(LMKLayout.minimumTouchTarget) }
        simpleButton.tapHandler = { [weak self] in
            guard let self else { return }
            LMKUserTip.show(
                message: "Swipe down to refresh the list. New items will appear at the top.",
                on: self
            )
        }
        stack.addArrangedSubview(simpleButton)
    }
}

// MARK: - Floating Button

final class FloatingButtonDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Floating Button")
        stack.addArrangedSubview(LMKLabelFactory.body(text: "A draggable button that stays on top of all content. Drag it to reposition — it snaps to the nearest edge."))

        let showButton = LMKButtonFactory.primary(title: "Show Floating Button", target: self, action: #selector(showFloating))
        stack.addArrangedSubview(showButton)

        addDivider()
        addSectionHeader("Badge")
        let badgeButton = LMKButton()
        badgeButton.setTitle("Show Badge (count: 5)", for: .normal)
        badgeButton.setTitleColor(LMKColor.error, for: .normal)
        badgeButton.titleLabel?.font = LMKTypography.bodyMedium
        badgeButton.snp.makeConstraints { $0.height.equalTo(LMKLayout.minimumTouchTarget) }
        badgeButton.tapHandler = {
            LMKFloatingButton.current?.showBadge(count: 5)
        }
        stack.addArrangedSubview(badgeButton)

        let dotButton = LMKButton()
        dotButton.setTitle("Show Dot Badge", for: .normal)
        dotButton.setTitleColor(LMKColor.warning, for: .normal)
        dotButton.titleLabel?.font = LMKTypography.bodyMedium
        dotButton.snp.makeConstraints { $0.height.equalTo(LMKLayout.minimumTouchTarget) }
        dotButton.tapHandler = {
            LMKFloatingButton.current?.showBadge()
        }
        stack.addArrangedSubview(dotButton)

        let hideBadgeButton = LMKButton()
        hideBadgeButton.setTitle("Hide Badge", for: .normal)
        hideBadgeButton.setTitleColor(LMKColor.textSecondary, for: .normal)
        hideBadgeButton.titleLabel?.font = LMKTypography.bodyMedium
        hideBadgeButton.snp.makeConstraints { $0.height.equalTo(LMKLayout.minimumTouchTarget) }
        hideBadgeButton.tapHandler = {
            LMKFloatingButton.current?.hideBadge()
        }
        stack.addArrangedSubview(hideBadgeButton)

        addDivider()
        addSectionHeader("Dismiss")
        let dismissButton = LMKButtonFactory.destructive(title: "Dismiss Floating Button", target: self, action: #selector(dismissFloating))
        stack.addArrangedSubview(dismissButton)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        LMKFloatingButton.dismissCurrent()
    }

    @objc private func showFloating() {
        LMKFloatingButton.show(icon: UIImage(systemName: "ladybug")) { [weak self] in
            guard let self else { return }
            LMKToast.showInfo(message: "Floating button tapped!", on: self)
        }
    }

    @objc private func dismissFloating() {
        LMKFloatingButton.dismissCurrent()
    }
}
