//
//  LMKDetailPhotoStripView.swift
//  LumiKit
//
//  The photo-strip row of a detail card: a horizontal collection of square
//  tiles with captions, selection checkmarks, badges, async images guarded by
//  a generation token, and an empty state.
//

import LumiKitCore
import SnapKit
import UIKit

final class LMKDetailPhotoStripRowView: UIView, LMKDetailRowView {
    let rowID: String
    let kind = 3
    let collectionView: UICollectionView
    let emptyStateView = LMKEmptyStateView(style: LMKEmptyStateView.Style(layout: .card))
    private let layout = UICollectionViewFlowLayout()
    private let strings: LMKDetailCardView.Strings
    private var model: LMKDetailCard.PhotoStrip?
    private var style = LMKDetailCardView.Style()
    private var theme = LMKTheme()
    private var heightConstraint: Constraint?
    private static let reuseIdentifier = "LMKDetailPhotoTileCell"

    init(rowID: String, strings: LMKDetailCardView.Strings) {
        self.rowID = rowID
        self.strings = strings
        layout.scrollDirection = .horizontal
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: .zero)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.clipsToBounds = false
        collectionView.register(LMKDetailPhotoTileCell.self, forCellWithReuseIdentifier: Self.reuseIdentifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        addSubview(collectionView)
        addSubview(emptyStateView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            heightConstraint = make.height.equalTo(100).constraint
        }
        emptyStateView.snp.makeConstraints { $0.edges.equalToSuperview() }
        emptyStateView.isHidden = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// The tile side and the row height at the current style.
    var tileSide: CGFloat { style.photoTileHeight ?? 100 }

    var hasCaptions: Bool { model?.caption != nil }

    func update(_ row: LMKDetailCard.Row, style: LMKDetailCardView.Style, theme: LMKTheme) {
        guard case let .photoStrip(model) = row else { return }
        self.model = model
        self.style = style
        self.theme = theme
        let spacing = style.photoSpacing ?? theme.spacing.small
        layout.minimumLineSpacing = spacing
        layout.minimumInteritemSpacing = spacing
        let captionHeight = model.caption == nil ? 0 : theme.spacing.xs + ceil(LMKTextMeasurement.lineHeight(of: style.photoCaptionTextStyle ?? .smallMedium, traits: traitCollection))
        layout.itemSize = CGSize(width: tileSide, height: tileSide + captionHeight)
        let tileCount = max(0, model.count)
        let empty = tileCount == 0
        if empty, let content = model.emptyState {
            emptyStateView.configure(content)
            emptyStateView.isHidden = false
            collectionView.isHidden = true
            heightConstraint?.deactivate()
        } else {
            emptyStateView.isHidden = true
            collectionView.isHidden = empty
            heightConstraint?.activate()
            heightConstraint?.update(offset: empty ? 0 : tileSide + captionHeight)
        }
        collectionView.reloadData()
    }

    /// Reloads every tile (images are fetched again).
    func reload() {
        collectionView.reloadData()
    }
}

extension LMKDetailPhotoStripRowView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        model?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.reuseIdentifier, for: indexPath)
        guard let tile = cell as? LMKDetailPhotoTileCell, let model else { return cell }
        let index = indexPath.item
        tile.configure(
            caption: model.caption?(index),
            isSelected: model.isSelected?(index) ?? false,
            badgeSymbol: model.badgeSymbol?(index),
            style: style,
            theme: theme,
            tileSide: tileSide
        )
        tile.accessibilityLabel = String(format: strings.photoAccessibilityLabelFormat, index + 1, model.count) + (model.caption?(index).map { ", \($0)" } ?? "")
        tile.accessibilityValue = (model.isSelected?(index) ?? false) ? strings.photoSelectedAccessibilityValue : nil
        tile.accessibilityTraits = model.onTap == nil ? .image : [.image, .button]
        tile.load { await model.image(index) }
        return cell
    }

    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        model?.onTap?(indexPath.item)
    }
}

/// One tile: image, optional caption, selection checkmark, corner badge.
final class LMKDetailPhotoTileCell: UICollectionViewCell {
    let imageView = UIImageView()
    let captionLabel = UILabel()
    let badgeView = UIImageView()
    let checkmarkView = UIImageView()
    private var loadTask: Task<Void, Never>?
    private var generation = 0
    private var imageHeightConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        captionLabel.textAlignment = .center
        captionLabel.numberOfLines = 1
        badgeView.contentMode = .scaleAspectFit
        checkmarkView.contentMode = .scaleAspectFit
        contentView.addSubview(imageView)
        contentView.addSubview(captionLabel)
        imageView.addSubview(badgeView)
        imageView.addSubview(checkmarkView)
        imageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            imageHeightConstraint = make.height.equalTo(100).constraint
        }
        captionLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(4)
            make.leading.trailing.bottom.equalToSuperview()
        }
        isAccessibilityElement = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        loadTask?.cancel()
        generation += 1
        imageView.image = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.lmk_layoutSurfaceIfNeeded()
    }

    func configure(caption: String?, isSelected: Bool, badgeSymbol: String?, style: LMKDetailCardView.Style, theme: LMKTheme, tileSide: CGFloat) {
        imageHeightConstraint?.update(offset: tileSide)
        _ = imageView.lmk_apply(surface: LMKSurfaceStyle(
            background: .solid(style.photoPlaceholderColor ?? LMKColor.backgroundTertiary),
            corners: style.photoTileCorners ?? .fixed(theme.cornerRadius.medium),
            border: .solid()
        ))
        captionLabel.lmk_apply(style.photoCaptionTextStyle ?? .smallMedium, color: style.photoCaptionColor ?? LMKColor.textSecondary)
        captionLabel.lmk_setText(caption)
        captionLabel.isHidden = caption == nil
        captionLabel.snp.updateConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(caption == nil ? 0 : theme.spacing.xs)
        }
        let inset = theme.spacing.xs
        if let badgeSymbol {
            badgeView.image = UIImage(systemName: badgeSymbol)
            badgeView.tintColor = LMKColor.onAccent
            badgeView.lmk_applyShadow(.level1)
            badgeView.snp.remakeConstraints { make in
                make.top.trailing.equalToSuperview().inset(inset)
                make.width.height.equalTo(theme.layout.iconSmall)
            }
            badgeView.isHidden = false
        } else {
            badgeView.isHidden = true
        }
        if isSelected {
            checkmarkView.image = UIImage(systemName: "checkmark.circle.fill")
            checkmarkView.tintColor = LMKColor.primary
            checkmarkView.backgroundColor = LMKColor.onAccent
            checkmarkView.lmk_applyCornerStyle(.circle)
            checkmarkView.snp.remakeConstraints { make in
                make.bottom.trailing.equalToSuperview().inset(inset)
                make.width.height.equalTo(theme.layout.iconMedium)
            }
            checkmarkView.isHidden = false
        } else {
            checkmarkView.isHidden = true
        }
    }

    /// Loads the tile image, discarding a result that lands after reuse.
    func load(_ provider: @escaping @MainActor () async -> UIImage?) {
        loadTask?.cancel()
        generation += 1
        let current = generation
        loadTask = Task { [weak self] in
            let image = await provider()
            guard let self, current == generation, !Task.isCancelled else { return }
            imageView.image = image
        }
    }
}
