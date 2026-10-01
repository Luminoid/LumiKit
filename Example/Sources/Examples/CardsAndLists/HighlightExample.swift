//
//  HighlightExample.swift
//  LumiKitExample
//
//  Cell Highlight: lmk_applyCustomHighlight and lmk_configureCustomHighlight.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Cell Highlight

final class HighlightDetailViewController: DetailViewController,
    UITableViewDelegate, UITableViewDataSource,
    UICollectionViewDelegate, UICollectionViewDataSource {
    private static let cardCellID = "HighlightCardCell"
    private static let plainCellID = "HighlightPlainCell"
    private static let gridCellID = "HighlightGridCell"
    private static let gridRowHeight: CGFloat = 96
    private static let gridItemCount: Int = 3

    private lazy var cardTable: UITableView = {
        let table = ExampleSelfSizingTableView(frame: .zero, style: .plain)
        table.delegate = self
        table.dataSource = self
        table.isScrollEnabled = false
        table.separatorStyle = .none
        table.backgroundColor = .clear
        table.register(HighlightCardCell.self, forCellReuseIdentifier: Self.cardCellID)
        return table
    }()

    private lazy var plainTable: UITableView = {
        let table = ExampleSelfSizingTableView(frame: .zero, style: .plain)
        table.delegate = self
        table.dataSource = self
        table.isScrollEnabled = false
        table.separatorStyle = .none
        table.backgroundColor = .clear
        table.register(UITableViewCell.self, forCellReuseIdentifier: Self.plainCellID)
        return table
    }()

    /// Horizontal scroll of three rounded cards demonstrating the
    /// `LMKHighlightable` conformance on `UICollectionViewCell`.
    /// Cells override `isHighlighted` / `isSelected` `didSet` rather than the
    /// `setHighlighted` / `setSelected` methods used by table cells:
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

    override func setupStackContent() {
        addSectionHeader("lmk_applyCustomHighlight (UITableViewCell)")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "Call from setHighlighted and setSelected in a custom cell subclass. "
                + "The overlay lands on rounded background views inside contentView; "
                + "otherwise it tints contentView itself. Tap and hold the row below."))
        stackView.addArrangedSubview(cardTable)

        addDivider()

        addSectionHeader("lmk_configureCustomHighlight (UITableViewCell only)")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "Configures a tinted selectedBackgroundView on a plain UITableViewCell. "
                + "No subclass required. Tap the row below. UICollectionViewCell has no "
                + "selectedBackgroundView, so use the protocol-based path instead (next section)."))
        stackView.addArrangedSubview(plainTable)

        addDivider()

        addSectionHeader("lmk_applyCustomHighlight (UICollectionViewCell)")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "Conforms to LMKHighlightable just like UITableViewCell. Override isHighlighted and isSelected didSet in the cell subclass and call lmk_applyCustomHighlight. Tap and hold any card."
        ))
        gridCollection.snp.makeConstraints { $0.height.equalTo(Self.gridRowHeight) }
        stackView.addArrangedSubview(gridCollection)
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
        content.lmk_applyTextStyle(primary: .body)
        cell.contentConfiguration = content
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
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
        view.lmk_applyCornerRadius(LMKCornerRadius.medium)
        return view
    }()

    private let titleLabel = UILabel.lmk_make(.body, text: "")

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
        titleLabel.lmk_setText(title)
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
        view.lmk_applyCornerRadius(LMKCornerRadius.medium)
        return view
    }()

    private let titleLabel = UILabel.lmk_make(.body, text: "")

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
        titleLabel.lmk_setText(title)
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
        LMKPointerStyle.lift(for: interaction.view)
    }
}
