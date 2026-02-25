//
//  ComponentExamples.swift
//  LumiKitExample
//
//  Cards, badges, chips, banners, empty state, gradient, and loading state examples.
//

import LumiKitUI
import SnapKit
import UIKit

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
