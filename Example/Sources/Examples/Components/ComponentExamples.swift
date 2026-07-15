//
//  ComponentExamples.swift
//  LumiKitExample
//
//  Divider, badges, chips, cards, gradient, page indicator, navigation bar,
//  banners, empty state, loading state, and overscroll footer examples.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Divider

final class DividerDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Horizontal")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Pixel-perfect separator between content sections:"))
        stack.addArrangedSubview(LMKDividerView())
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Content continues here"))
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

        addDivider()
        addSectionHeader("Dismissible")
        let dismissRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        for text in ["Active", "Recent", "Archived"] {
            let chip = LMKChipView(text: text, style: .outlined)
            chip.chipColor = LMKColor.secondary
            chip.dismissHandler = { [weak chip] in chip?.removeFromSuperview() }
            dismissRow.addArrangedSubview(chip)
        }
        dismissRow.addArrangedSubview(UIView())
        stack.addArrangedSubview(dismissRow)

        addDivider()
        addSectionHeader("Toggle Selection")
        let toggleRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        for text in ["All", "Photos", "Notes"] {
            let chip = LMKChipView(text: text, style: .outlined)
            chip.tapHandler = { chip.isChipSelected.toggle() }
            toggleRow.addArrangedSubview(chip)
        }
        toggleRow.addArrangedSubview(UIView())
        stack.addArrangedSubview(toggleRow)
    }
}

// MARK: - Filter Chip Bar

final class FilterChipBarDetailViewController: DetailViewController {
    private let selectionLabel = LMKLabelFactory.body(text: "Selected: All")

    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("With All Chip")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "An 'All' chip is prepended; tapping it clears the filter and fires with nil."))

        let withAll = LMKFilterChipBar()
        withAll.configure(allTitle: "All", filterTitles: ["Photos", "Notes", "Tasks", "Links", "Files"])
        withAll.selectionChangedHandler = { [weak self] index in
            if let index {
                self?.selectionLabel.text = "Selected: filter index \(index)"
            } else {
                self?.selectionLabel.text = "Selected: All"
            }
        }
        withAll.snp.makeConstraints { $0.height.equalTo(44) }
        stack.addArrangedSubview(withAll)
        stack.addArrangedSubview(selectionLabel)

        addDivider()
        addSectionHeader("Without All Chip")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Omit `allTitle` for a pure filter row — initial state has no selection."))

        let withoutAll = LMKFilterChipBar()
        withoutAll.configure(filterTitles: ["Today", "Week", "Month", "Year"])
        withoutAll.snp.makeConstraints { $0.height.equalTo(44) }
        stack.addArrangedSubview(withoutAll)

        addDivider()
        addSectionHeader("Filled Style + Preselected")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "`style: .filled` and `setSelectedIndex(_:)` to seed the selection silently."))

        let filled = LMKFilterChipBar()
        filled.configure(allTitle: "All", filterTitles: ["Draft", "In Review", "Published"], style: .filled)
        filled.setSelectedIndex(1)
        filled.snp.makeConstraints { $0.height.equalTo(44) }
        stack.addArrangedSubview(filled)
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

// MARK: - Page Indicator

final class PageIndicatorDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Basic (dots only)")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Default style — all dots same size, active dot uses primary color."))

        let basicLabel = LMKLabelFactory.body(text: "Page 1 of 5")
        basicLabel.textAlignment = .center

        let basicIndicator = LMKPageIndicator()
        basicIndicator.numberOfPages = 5
        basicIndicator.currentPage = 0
        basicIndicator.pageChangedHandler = { page in
            basicLabel.text = "Page \(page + 1) of 5"
        }
        basicIndicator.snp.makeConstraints { $0.height.equalTo(20) }
        stack.addArrangedSubview(basicIndicator)
        stack.addArrangedSubview(basicLabel)

        addDivider()
        addSectionHeader("Expanding Pill")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "expandsActiveDot = true — active dot grows into a pill shape."))

        let pillLabel = LMKLabelFactory.body(text: "Page 1 of 5")
        pillLabel.textAlignment = .center

        let pillIndicator = LMKPageIndicator()
        pillIndicator.numberOfPages = 5
        pillIndicator.currentPage = 0
        pillIndicator.expandsActiveDot = true
        pillIndicator.pageChangedHandler = { page in
            pillLabel.text = "Page \(page + 1) of 5"
        }
        pillIndicator.snp.makeConstraints { $0.height.equalTo(20) }
        stack.addArrangedSubview(pillIndicator)
        stack.addArrangedSubview(pillLabel)

        addDivider()
        addSectionHeader("Many Pages — Windowed (12 pages, max 7 dots)")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "When pages > maxVisibleDots, a sliding window shows 7 dots. Edge dots are smaller."))

        let manyLabel = LMKLabelFactory.body(text: "Page 1 of 12")
        manyLabel.textAlignment = .center

        let manyIndicator = LMKPageIndicator()
        manyIndicator.numberOfPages = 12
        manyIndicator.maxVisibleDots = 7
        manyIndicator.currentPage = 0
        manyIndicator.pageChangedHandler = { page in
            manyLabel.text = "Page \(page + 1) of 12"
        }
        manyIndicator.snp.makeConstraints { $0.height.equalTo(20) }
        stack.addArrangedSubview(manyIndicator)
        stack.addArrangedSubview(manyLabel)

        addDivider()
        addSectionHeader("Many Pages — Windowed + Expanding Pill")

        let manyPillLabel = LMKLabelFactory.body(text: "Page 1 of 15")
        manyPillLabel.textAlignment = .center

        let manyPillIndicator = LMKPageIndicator()
        manyPillIndicator.numberOfPages = 15
        manyPillIndicator.maxVisibleDots = 7
        manyPillIndicator.expandsActiveDot = true
        manyPillIndicator.currentPage = 0
        manyPillIndicator.pageChangedHandler = { page in
            manyPillLabel.text = "Page \(page + 1) of 15"
        }
        manyPillIndicator.snp.makeConstraints { $0.height.equalTo(20) }
        stack.addArrangedSubview(manyPillIndicator)
        stack.addArrangedSubview(manyPillLabel)

        addDivider()
        addSectionHeader("Programmatic Navigation")

        let navIndicator = LMKPageIndicator()
        navIndicator.numberOfPages = 4
        navIndicator.currentPage = 0
        navIndicator.snp.makeConstraints { $0.height.equalTo(20) }
        stack.addArrangedSubview(navIndicator)

        let prevBtn = LMKButton(title: "Previous", style: .ghost(LMKColor.primary))
        prevBtn.tapHandler = { [weak navIndicator] in
            guard let ind = navIndicator, ind.currentPage > 0 else { return }
            ind.currentPage -= 1
        }

        let nextBtn = LMKButton(title: "Next", style: .ghost(LMKColor.primary))
        nextBtn.tapHandler = { [weak navIndicator] in
            guard let ind = navIndicator, ind.currentPage < ind.numberOfPages - 1 else { return }
            ind.currentPage += 1
        }

        let navRow = UIStackView(lmk_axis: .horizontal)
        navRow.addArrangedSubview(prevBtn)
        navRow.addArrangedSubview(UIView())
        navRow.addArrangedSubview(nextBtn)
        stack.addArrangedSubview(navRow)
    }
}

// MARK: - Navigation Bar

final class NavigationBarDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Large Title")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Bold left-aligned title with button row above. Used on root screens."))

        let largeBar = LMKNavigationBar()
        largeBar.title = "My Items"
        largeBar.largeTitleEnabled = true
        largeBar.setRightItems([
            .init(systemName: "plus") {},
            .init(systemName: "ellipsis.circle") {},
        ])
        wrapInContainer(largeBar)

        addDivider()
        addSectionHeader("Standard (Inline) Title")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Centered title with back button. Used on pushed screens."))

        let standardBar = LMKNavigationBar()
        standardBar.title = "Item Details"
        standardBar.showsBackButton = true
        standardBar.setRightItems([
            .init(systemName: "square.and.arrow.up") {},
        ])
        wrapInContainer(standardBar)

        addDivider()
        addSectionHeader("Left Items")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Custom left items replace the back button."))

        let leftItemsBar = LMKNavigationBar()
        leftItemsBar.title = "Calendar"
        leftItemsBar.setLeftItems([
            .init(systemName: "sidebar.left") {},
        ])
        leftItemsBar.setRightItems([
            .init(systemName: "plus") {},
        ])
        wrapInContainer(leftItemsBar)

        addDivider()
        addSectionHeader("Custom Colors")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Customizable background, title color, and button tint."))

        let customBar = LMKNavigationBar()
        customBar.title = "Settings"
        customBar.largeTitleEnabled = true
        customBar.barBackgroundColor = LMKColor.primary
        customBar.largeTitleColor = .white
        customBar.buttonTintColor = .white
        customBar.showsSeparator = false
        customBar.setRightItems([
            .init(systemName: "gearshape") {},
        ])
        wrapInContainer(customBar)

        addDivider()
        addSectionHeader("No Separator")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "showsSeparator = false for clean content-heavy screens."))

        let noSepBar = LMKNavigationBar()
        noSepBar.title = "Photos"
        noSepBar.showsSeparator = false
        noSepBar.setRightItems([
            .init(systemName: "camera") {},
        ])
        wrapInContainer(noSepBar)

        addDivider()
        addSectionHeader("Right Accessory View")
        stack.addArrangedSubview(LMKLabelFactory.caption(
            text: "Place a non-tappable view (sync indicator, status icon) "
                + "to the left of the right items via setRightAccessoryView(_:). "
                + "It survives later setRightItems(_:) calls."
        ))

        let accessoryBar = LMKNavigationBar()
        accessoryBar.title = "Inbox"
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = LMKColor.textSecondary
        spinner.startAnimating()
        accessoryBar.setRightAccessoryView(spinner)
        accessoryBar.setRightItems([
            .init(systemName: "square.and.pencil") {},
        ])
        wrapInContainer(accessoryBar)

        addDivider()
        addSectionHeader("Large Title Accessory")
        stack.addArrangedSubview(LMKLabelFactory.caption(
            text: "iOS Mail / Notes pattern: hang an inline accessory off the "
                + "trailing edge of the large title via setLargeTitleAccessoryView(_:). "
                + "Useful for sync state next to a section title."
        ))

        let titleAccessoryBar = LMKNavigationBar()
        titleAccessoryBar.title = "Pets"
        titleAccessoryBar.largeTitleEnabled = true
        let cloudIcon = UIImageView(image: UIImage(systemName: "icloud"))
        cloudIcon.tintColor = LMKColor.textSecondary
        cloudIcon.contentMode = .scaleAspectFit
        cloudIcon.snp.makeConstraints { make in
            make.width.height.equalTo(LMKLayout.iconMedium)
        }
        titleAccessoryBar.setLargeTitleAccessoryView(cloudIcon)
        wrapInContainer(titleAccessoryBar)
    }

    private func wrapInContainer(_ bar: LMKNavigationBar) {
        let container = UIView()
        container.backgroundColor = bar.barBackgroundColor == LMKColor.backgroundPrimary
            ? LMKColor.backgroundSecondary
            : bar.barBackgroundColor
        container.layer.cornerRadius = LMKCornerRadius.medium
        container.clipsToBounds = true
        container.addSubview(bar)
        bar.snp.makeConstraints { $0.edges.equalToSuperview() }
        stack.addArrangedSubview(container)
    }
}

// MARK: - Navigation Controller

final class NavigationControllerDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Swipe-to-go-back with hidden system nav bar")
        stack.addArrangedSubview(LMKLabelFactory.caption(
            text: "LMKNavigationController keeps the edge-swipe-to-go-back gesture "
                + "working when the system navigation bar is hidden — which happens on "
                + "every screen that uses LMKNavigationBar. Tap the button to present a "
                + "demo stack: push a few screens, then swipe from the left edge to pop."
        ))

        let presentButton = LMKButtonFactory.filled(
            role: .primary,
            title: "Present Demo Stack",
            target: self,
            action: #selector(presentDemoStack)
        )
        stack.addArrangedSubview(presentButton)
    }

    @objc private func presentDemoStack() {
        let root = SwipeDemoViewController(depth: 1)
        let nav = LMKNavigationController(rootViewController: root)
        nav.setNavigationBarHidden(true, animated: false)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
}

private final class SwipeDemoViewController: UIViewController {
    private let depth: Int

    init(depth: Int) {
        self.depth = depth
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = LMKColor.backgroundPrimary

        let navBar = LMKNavigationBar()
        navBar.title = "Screen \(depth)"
        if depth > 1 {
            navBar.showsBackButton = true
            navBar.backAction = { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
        } else {
            navBar.setLeftItems([
                .init(title: "Close") { [weak self] in
                    self?.dismiss(animated: true)
                },
            ])
        }
        view.addSubview(navBar)
        navBar.pinToTop(of: view)

        let caption = LMKLabelFactory.caption(
            text: depth > 1
                ? "Swipe from the left edge to pop back, or tap the chevron."
                : "Push a screen, then try the edge-swipe gesture to pop."
        )
        caption.textAlignment = .center
        caption.numberOfLines = 0

        let pushButton = LMKButtonFactory.filled(
            role: .primary,
            title: "Push Screen \(depth + 1)",
            target: self,
            action: #selector(push)
        )

        let column = UIStackView(arrangedSubviews: [caption, pushButton])
        column.axis = .vertical
        column.spacing = LMKSpacing.large
        column.alignment = .fill
        view.addSubview(column)
        column.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(LMKSpacing.large)
            make.centerY.equalToSuperview()
        }
    }

    @objc private func push() {
        navigationController?.pushViewController(SwipeDemoViewController(depth: depth + 1), animated: true)
    }
}

// MARK: - Segmented Pages

final class SegmentedPagesDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Tab container with interactive swipe paging")
        stack.addArrangedSubview(LMKLabelFactory.caption(
            text: "LMKSegmentedPageController pages between child view controllers selected by a "
                + "top LMKSegmentedControl. Drag horizontally and both pages track your finger; "
                + "release past the halfway point (or flick) to commit, otherwise it springs back. "
                + "Tapping a segment slides without the drag. Pages can opt into edge-only panning "
                + "via usesFullWidthSwipe(forPageAt:) so a map or custom grid keeps its interior drags."
        ))

        let presentButton = LMKButtonFactory.filled(
            role: .primary,
            title: "Present Segmented Pages",
            target: self,
            action: #selector(presentDemo)
        )
        stack.addArrangedSubview(presentButton)
    }

    @objc private func presentDemo() {
        let nav = UINavigationController(rootViewController: SegmentedPagesDemoViewController())
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
}

private final class SegmentedPagesDemoViewController: LMKSegmentedPageController {
    init() {
        super.init(titles: ["First", "Second", "Third"])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(close)
        )
    }

    override func makePages() -> [UIViewController] {
        [
            SegmentedDemoPageViewController(index: 0, tint: LMKColor.primary),
            SegmentedDemoPageViewController(index: 1, tint: LMKColor.success),
            SegmentedDemoPageViewController(index: 2, tint: LMKColor.warning),
        ]
    }

    @objc private func close() {
        dismiss(animated: true)
    }
}

private final class SegmentedDemoPageViewController: UIViewController {
    private let index: Int
    private let tint: UIColor

    init(index: Int, tint: UIColor) {
        self.index = index
        self.tint = tint
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = tint.withAlphaComponent(LMKAlpha.overlayMedium)

        let titleLabel = LMKLabelFactory.heading(text: "Page \(index + 1)")
        let caption = LMKLabelFactory.caption(text: "Swipe left or right, or tap a segment above.")
        caption.textAlignment = .center
        caption.numberOfLines = 0

        let column = UIStackView(arrangedSubviews: [titleLabel, caption])
        column.axis = .vertical
        column.spacing = LMKSpacing.medium
        column.alignment = .center
        view.addSubview(column)
        column.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(LMKSpacing.large)
            make.centerY.equalToSuperview()
        }
    }
}

// MARK: - Banner

final class BannerDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Tap to show")

        let infoButton = LMKButtonFactory.outlined(role: .info, title: "Show Info Banner", target: self, action: #selector(showInfoBanner))
        stack.addArrangedSubview(infoButton)

        let warningButton = LMKButtonFactory.outlined(role: .warning, title: "Show Warning Banner", target: self, action: #selector(showWarningBanner))
        stack.addArrangedSubview(warningButton)

        let errorButton = LMKButtonFactory.outlined(role: .destructive, title: "Show Error Banner", target: self, action: #selector(showErrorBanner))
        stack.addArrangedSubview(errorButton)

        let successButton = LMKButtonFactory.outlined(role: .success, title: "Show Success Banner", target: self, action: #selector(showSuccessBanner))
        stack.addArrangedSubview(successButton)

        addDivider()
        addSectionHeader("Non-dismissible")
        let persistentButton = LMKButtonFactory.outlined(role: .primary, title: "Show Persistent Banner", target: self, action: #selector(showPersistentBanner))
        stack.addArrangedSubview(persistentButton)
    }

    @objc private func showInfoBanner() {
        let banner = LMKBannerView(type: .info, message: "This is a info banner message.")
        banner.actionTitle = "Action"
        banner.show(on: self)
    }

    @objc private func showWarningBanner() {
        let banner = LMKBannerView(type: .warning, message: "This is a warning banner message.")
        banner.actionTitle = "Action"
        banner.show(on: self)
    }

    @objc private func showErrorBanner() {
        let banner = LMKBannerView(type: .error, message: "This is a error banner message.")
        banner.actionTitle = "Action"
        banner.show(on: self)
    }

    @objc private func showSuccessBanner() {
        let banner = LMKBannerView(type: .success, message: "This is a success banner message.")
        banner.actionTitle = "Action"
        banner.show(on: self)
    }

    @objc private func showPersistentBanner() {
        let banner = LMKBannerView(type: .warning, message: "No internet connection")
        banner.showsDismissButton = false
        banner.actionTitle = "Retry"
        banner.show(on: self)
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
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        DispatchQueue.main.async { [weak self] in
            self?.startShimmer()
        }
    }

    private func startShimmer() {
        LMKSkeletonCell.startShimmers(in: tableView)
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

// MARK: - Checkbox Cell

final class CheckboxCellDetailViewController: DetailViewController, UITableViewDataSource, UITableViewDelegate {
    private static let rowHeight: CGFloat = 52

    private var items: [(title: String, isDone: Bool)] = [
        ("Water the monstera", true),
        ("Book the vet appointment", false),
        ("Pack chargers and adapters", false),
        ("Renew the passport", false),
    ]

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.dataSource = self
        table.delegate = self
        table.isScrollEnabled = false
        table.separatorStyle = .none
        table.backgroundColor = .clear
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = Self.rowHeight
        table.register(LMKCheckboxCell.self, forCellReuseIdentifier: LMKCheckboxCell.reuseIdentifier)
        return table
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("LMKCheckboxCell")
        stack.addArrangedSubview(LMKLabelFactory.caption(
            text: "Check-off row for to-dos and checklists: checkbox + strike-through title. "
                + "The checkbox hit area expands to the minimum touch target, and the host "
                + "also toggles from didSelectRowAt so the whole row is a target."
        ))

        tableView.snp.makeConstraints { $0.height.equalTo(Self.rowHeight * CGFloat(items.count)) }
        stack.addArrangedSubview(tableView)
    }

    private func toggleItem(at index: Int) {
        items[index].isDone.toggle()
        // Reload the whole table — the cell sets its checkbox image directly
        // (never via cross-dissolve), so recycled cells can't flash a checkmark.
        tableView.reloadData()
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: LMKCheckboxCell.reuseIdentifier,
            for: indexPath
        ) as? LMKCheckboxCell else {
            return UITableViewCell()
        }
        let item = items[indexPath.row]
        cell.configure(title: item.title, isDone: item.isDone)
        cell.onToggle = { [weak self] in
            self?.toggleItem(at: indexPath.row)
        }
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        toggleItem(at: indexPath.row)
    }
}

// MARK: - Overscroll Footer

final class OverscrollFooterDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private static let cellID = "cell"
    private static let footerHeight: CGFloat = 160

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let footerView = OverscrollFooterView()
    private var footerHelper: LMKOverscrollFooterHelper?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = LMKColor.backgroundPrimary

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellID)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }

        // Footer revealed on overscroll
        footerHelper = LMKOverscrollFooterHelper(
            footerView: footerView,
            scrollView: tableView,
            footerHeight: Self.footerHeight
        )
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        footerHelper?.updatePosition()
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        footerHelper?.updatePosition()
        if let helper = footerHelper {
            footerView.alpha = helper.overscrollProgress
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        20
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellID, for: indexPath)
        var config = cell.defaultContentConfiguration()
        config.text = "Row \(indexPath.row + 1)"
        config.secondaryText = "Pull past the bottom to reveal the footer"
        config.image = UIImage(systemName: "\(indexPath.row + 1).circle")
        config.imageProperties.tintColor = LMKColor.primary
        cell.contentConfiguration = config
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

/// Simple footer shown on overscroll.
private final class OverscrollFooterView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        alpha = 0

        let stack = UIStackView(lmk_axis: .vertical, spacing: LMKSpacing.small)
        stack.alignment = .center

        let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .light)
        let imageView = UIImageView(image: UIImage(systemName: "arrow.down.circle", withConfiguration: config))
        imageView.tintColor = LMKColor.textTertiary
        stack.addArrangedSubview(imageView)

        let label = LMKLabelFactory.caption(text: "You've reached the end")
        label.textAlignment = .center
        stack.addArrangedSubview(label)

        addSubview(stack)
        stack.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
