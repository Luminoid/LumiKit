//
//  ExtensionExamples.swift
//  LumiKitExample
//
//  Shadow, border, fade, and layout extension examples.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Shadow

final class ShadowDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("LMKShadow Presets")
        let presets: [(String, LMKShadowStyle)] = [
            ("cellCard()", LMKShadow.cellCard()),
            ("card()", LMKShadow.card()),
            ("button()", LMKShadow.button()),
            ("small()", LMKShadow.small()),
        ]

        for (name, shadow) in presets {
            let container = UIView()
            container.backgroundColor = LMKColor.backgroundPrimary
            container.layer.cornerRadius = LMKCornerRadius.medium
            container.lmk_applyShadow(shadow)

            let label = LMKLabelFactory.body(text: name)
            label.textAlignment = .center
            container.addSubview(label)
            label.snp.makeConstraints { $0.edges.equalToSuperview().inset(LMKSpacing.large) }
            container.snp.makeConstraints { $0.height.equalTo(60) }
            stack.addArrangedSubview(container)
        }

        addDivider()
        addSectionHeader("Remove Shadow")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "lmk_removeShadow() clears the shadow layer."))
        let toggleView = UIView()
        toggleView.backgroundColor = LMKColor.backgroundPrimary
        toggleView.layer.cornerRadius = LMKCornerRadius.medium
        toggleView.lmk_applyShadow(LMKShadow.card())
        toggleView.snp.makeConstraints { $0.height.equalTo(60) }

        let toggleLabel = LMKLabelFactory.body(text: "Tap to toggle shadow")
        toggleLabel.textAlignment = .center
        toggleView.addSubview(toggleLabel)
        toggleLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(LMKSpacing.large) }

        let tap = UITapGestureRecognizer()
        tap.addTarget(self, action: #selector(toggleShadow(_:)))
        toggleView.addGestureRecognizer(tap)
        toggleView.isUserInteractionEnabled = true
        toggleView.tag = 100
        toggleView.accessibilityLabel = "shadow on"
        stack.addArrangedSubview(toggleView)
    }

    @objc private func toggleShadow(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view else { return }
        if view.layer.shadowOpacity > 0 {
            view.lmk_removeShadow()
        } else {
            view.lmk_applyShadow(LMKShadow.card())
        }
    }
}

// MARK: - Border & Corner Radius

final class BorderDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("lmk_applyBorder")
        let borderedView = UIView()
        borderedView.backgroundColor = LMKColor.backgroundSecondary
        borderedView.lmk_applyBorder(color: LMKColor.primary, width: 2)
        borderedView.lmk_applyCornerRadius(LMKCornerRadius.medium)

        let label = LMKLabelFactory.body(text: "Primary color, 2pt width, medium radius")
        label.textAlignment = .center
        borderedView.addSubview(label)
        label.snp.makeConstraints { $0.edges.equalToSuperview().inset(LMKSpacing.large) }
        borderedView.snp.makeConstraints { $0.height.equalTo(60) }
        stack.addArrangedSubview(borderedView)

        addDivider()
        addSectionHeader("lmk_makeCircular")
        let circleSize: CGFloat = 80
        let circleView = UIView()
        circleView.backgroundColor = LMKColor.primary
        circleView.snp.makeConstraints { $0.width.height.equalTo(circleSize) }

        // Force layout so makeCircular can calculate
        circleView.frame = CGRect(x: 0, y: 0, width: circleSize, height: circleSize)
        circleView.lmk_makeCircular()

        let circleLabel = LMKLabelFactory.small(text: "Circle")
        circleLabel.textColor = LMKColor.white
        circleLabel.textAlignment = .center
        circleView.addSubview(circleLabel)
        circleLabel.snp.makeConstraints { $0.center.equalToSuperview() }

        let row = UIStackView(lmk_axis: .horizontal)
        row.addArrangedSubview(circleView)
        row.addArrangedSubview(UIView())
        stack.addArrangedSubview(row)

        addDivider()
        addSectionHeader("Corner Radius Tokens")
        let radii: [(String, CGFloat)] = [
            ("xs (4)", LMKCornerRadius.xs),
            ("small (8)", LMKCornerRadius.small),
            ("medium (12)", LMKCornerRadius.medium),
            ("large (16)", LMKCornerRadius.large),
            ("xl (20)", LMKCornerRadius.xl),
        ]
        let radiusRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        radiusRow.distribution = .fillEqually
        for (name, radius) in radii {
            let box = UIView()
            box.backgroundColor = LMKColor.secondary
            box.lmk_applyCornerRadius(radius)
            box.snp.makeConstraints { $0.height.equalTo(52) }

            let lbl = LMKLabelFactory.small(text: name)
            lbl.textColor = LMKColor.white
            lbl.textAlignment = .center
            box.addSubview(lbl)
            lbl.snp.makeConstraints { $0.center.equalToSuperview() }
            radiusRow.addArrangedSubview(box)
        }
        stack.addArrangedSubview(radiusRow)
    }
}

// MARK: - Fade Animations

final class FadeDetailViewController: DetailViewController {
    private let targetView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("lmk_fadeIn / lmk_fadeOut")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Animated opacity transitions with configurable duration. Respects Reduce Motion."))

        targetView.backgroundColor = LMKColor.primary
        targetView.layer.cornerRadius = LMKCornerRadius.medium
        targetView.snp.makeConstraints { $0.height.equalTo(100) }

        let label = LMKLabelFactory.body(text: "Fade Target")
        label.textColor = LMKColor.white
        label.textAlignment = .center
        targetView.addSubview(label)
        label.snp.makeConstraints { $0.center.equalToSuperview() }
        stack.addArrangedSubview(targetView)

        let buttonRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        buttonRow.distribution = .fillEqually

        let fadeOutButton = LMKButtonFactory.outlined(role: .destructive, title: "Fade Out", target: self, action: #selector(fadeOut))
        buttonRow.addArrangedSubview(fadeOutButton)

        let fadeInButton = LMKButtonFactory.outlined(role: .success, title: "Fade In", target: self, action: #selector(fadeIn))
        buttonRow.addArrangedSubview(fadeInButton)

        stack.addArrangedSubview(buttonRow)
    }

    @objc private func fadeOut() {
        targetView.lmk_fadeOut()
    }

    @objc private func fadeIn() {
        targetView.lmk_fadeIn()
    }
}

// MARK: - Cell Highlight

final class HighlightDetailViewController: DetailViewController,
    UITableViewDelegate, UITableViewDataSource,
    UICollectionViewDelegate, UICollectionViewDataSource {
    private static let cardCellID = "HighlightCardCell"
    private static let plainCellID = "HighlightPlainCell"
    private static let gridCellID = "HighlightGridCell"
    private static let cardRowHeight: CGFloat = 80
    private static let plainRowHeight: CGFloat = 56
    private static let gridRowHeight: CGFloat = 96
    private static let gridItemCount: Int = 3

    private lazy var cardTable: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.delegate = self
        table.dataSource = self
        table.isScrollEnabled = false
        table.separatorStyle = .none
        table.backgroundColor = .clear
        table.register(HighlightCardCell.self, forCellReuseIdentifier: Self.cardCellID)
        return table
    }()

    private lazy var plainTable: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.delegate = self
        table.dataSource = self
        table.isScrollEnabled = false
        table.separatorStyle = .none
        table.backgroundColor = .clear
        table.register(UITableViewCell.self, forCellReuseIdentifier: Self.plainCellID)
        return table
    }()

    /// Horizontal scroll of three rounded cards demonstrating the new
    /// `LMKHighlightable` protocol conformance on `UICollectionViewCell`.
    /// Cells override `isHighlighted` / `isSelected` `didSet` rather than the
    /// `setHighlighted` / `setSelected` methods used by table cells —
    /// `UICollectionViewCell` doesn't expose the method variants.
    private lazy var gridCollection: UICollectionView = {
        let layout = UICollectionViewCompositionalLayout { _, _ in
            let item = NSCollectionLayoutItem(layoutSize: .init(
                widthDimension: .absolute(180),
                heightDimension: .fractionalHeight(1)
            ))
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: .init(widthDimension: .absolute(180), heightDimension: .fractionalHeight(1)),
                subitems: [item]
            )
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .continuous
            section.interGroupSpacing = LMKSpacing.medium
            return section
        }
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.delegate = self
        collection.dataSource = self
        collection.backgroundColor = .clear
        collection.isScrollEnabled = true
        collection.showsHorizontalScrollIndicator = false
        collection.register(HighlightGridCell.self, forCellWithReuseIdentifier: Self.gridCellID)
        return collection
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("lmk_applyCustomHighlight (UITableViewCell)")
        stack.addArrangedSubview(LMKLabelFactory.caption(
            text: "Call from setHighlighted and setSelected in a custom cell subclass. "
                + "The overlay lands on rounded background views inside contentView; "
                + "otherwise it tints contentView itself. Tap and hold the row below."
        ))
        cardTable.snp.makeConstraints { $0.height.equalTo(Self.cardRowHeight) }
        stack.addArrangedSubview(cardTable)

        addDivider()

        addSectionHeader("lmk_configureCustomHighlight (UITableViewCell only)")
        stack.addArrangedSubview(LMKLabelFactory.caption(
            text: "Configures a tinted selectedBackgroundView on a plain UITableViewCell. "
                + "No subclass required. Tap the row below. UICollectionViewCell has no "
                + "selectedBackgroundView, so use the protocol-based path instead (next section)."
        ))
        plainTable.snp.makeConstraints { $0.height.equalTo(Self.plainRowHeight) }
        stack.addArrangedSubview(plainTable)

        addDivider()

        addSectionHeader("lmk_applyCustomHighlight (UICollectionViewCell)")
        stack.addArrangedSubview(LMKLabelFactory.caption(
            text: "Conforms to LMKHighlightable just like UITableViewCell. Override isHighlighted and isSelected didSet in the cell subclass and call lmk_applyCustomHighlight. Tap and hold any card."
        ))
        gridCollection.snp.makeConstraints { $0.height.equalTo(Self.gridRowHeight) }
        stack.addArrangedSubview(gridCollection)
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView === cardTable {
            let cell = tableView.dequeueReusableCell(withIdentifier: Self.cardCellID, for: indexPath)
            (cell as? HighlightCardCell)?.configure(title: "Tap and hold: overlay lands on the rounded card")
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.plainCellID, for: indexPath)
        cell.lmk_configureCustomHighlight()
        var content = cell.defaultContentConfiguration()
        content.text = "Tap: selectedBackgroundView lights up"
        content.textProperties.font = LMKLabelFactory.body(text: "").font
        cell.contentConfiguration = content
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        tableView === cardTable ? Self.cardRowHeight : Self.plainRowHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        Self.gridItemCount
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.gridCellID, for: indexPath)
        (cell as? HighlightGridCell)?.configure(title: "Card \(indexPath.item + 1)")
        return cell
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

private final class HighlightCardCell: UITableViewCell {
    private let card: UIView = {
        let view = UIView()
        view.backgroundColor = LMKColor.backgroundSecondary
        view.layer.cornerRadius = LMKCornerRadius.medium
        return view
    }()

    private let titleLabel = LMKLabelFactory.body(text: "")

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(card)
        card.addSubview(titleLabel)

        card.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(LMKSpacing.small)
            make.leading.trailing.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(LMKSpacing.large)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String) {
        titleLabel.text = title
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        lmk_applyCustomHighlight(highlighted: highlighted, animated: animated)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        lmk_applyCustomHighlight(highlighted: selected, animated: animated)
    }
}

private final class HighlightGridCell: UICollectionViewCell {
    private let card: UIView = {
        let view = UIView()
        view.backgroundColor = LMKColor.backgroundSecondary
        view.layer.cornerRadius = LMKCornerRadius.medium
        return view
    }()

    private let titleLabel = LMKLabelFactory.body(text: "")

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear

        contentView.addSubview(card)
        card.addSubview(titleLabel)

        card.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(LMKSpacing.large)
        }

        addInteraction(UIPointerInteraction(delegate: self))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String) {
        titleLabel.text = title
    }

    /// UICollectionViewCell exposes `isHighlighted` / `isSelected` as
    /// overridable properties (not setHighlighted/setSelected methods like
    /// UITableViewCell), so `didSet` is the canonical hook for routing into
    /// `lmk_applyCustomHighlight` on the LMKHighlightable protocol.
    override var isHighlighted: Bool {
        didSet { lmk_applyCustomHighlight(highlighted: isHighlighted, animated: true) }
    }

    override var isSelected: Bool {
        didSet { lmk_applyCustomHighlight(highlighted: isSelected, animated: true) }
    }
}

extension HighlightGridCell: UIPointerInteractionDelegate {
    func pointerInteraction(_ interaction: UIPointerInteraction, styleFor _: UIPointerRegion) -> UIPointerStyle? {
        guard let view = interaction.view else { return nil }
        return UIPointerStyle(effect: .lift(UITargetedPreview(view: view)))
    }
}
