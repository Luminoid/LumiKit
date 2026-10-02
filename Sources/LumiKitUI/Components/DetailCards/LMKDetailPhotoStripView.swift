//
//  LMKDetailPhotoStripView.swift
//  LumiKit
//
//  The photo-strip row of a detail card: a horizontal collection of square
//  tiles with captions, selection checkmarks, badges, async images guarded by
//  a generation token, and an empty state. A reconfigure reloads the tiles
//  only when their count or size changed; otherwise the visible tiles are
//  restyled in place and keep their images.
//

import SnapKit
import UIKit

final class LMKDetailPhotoStripRowView: UIView, LMKDetailRowView {
    let rowID: String
    let kind = 3
    let collectionView: UICollectionView
    let emptyStateView = LMKEmptyStateView(style: LMKEmptyStateView.Style(layout: .card))
    private let layout = UICollectionViewFlowLayout()
    private var strings = LMKDetailCardView.Strings()
    private var model: LMKDetailCard.PhotoStrip?
    private var style = LMKDetailCardView.Style()
    private var theme = LMKTheme()
    private var heightConstraint: Constraint?
    /// What the tiles were last laid out for; a change here reloads them.
    private var tileLayout: TileLayout?
    private static let reuseIdentifier = "LMKDetailPhotoTileCell"

    /// The tile side behind `Style.photoTileHeight == nil`.
    static let defaultTileSide: CGFloat = 100

    private struct TileLayout: Equatable {
        var count: Int
        var itemSize: CGSize
        var hasCaptions: Bool
    }

    init(rowID: String) {
        self.rowID = rowID
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
            heightConstraint = make.height.equalTo(Self.defaultTileSide).constraint
        }
        emptyStateView.snp.makeConstraints { $0.edges.equalToSuperview() }
        emptyStateView.isHidden = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// The tile side and the row height at the current style.
    var tileSide: CGFloat { style.photoTileHeight ?? Self.defaultTileSide }

    func update(_ row: LMKDetailCard.Row, context: LMKDetailCardView.RowContext) {
        guard case let .photoStrip(model) = row else { return }
        self.model = model
        style = context.style
        theme = context.theme
        strings = context.strings
        let spacing = style.photoSpacing ?? theme.spacing.small
        layout.minimumLineSpacing = spacing
        layout.minimumInteritemSpacing = spacing
        let captionHeight = model.caption == nil ? 0 : theme.spacing.xs + ceil(LMKTextMeasurement.lineHeight(of: style.photoCaptionTextStyle ?? .smallMedium, traits: context.traits))
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
        let tileLayout = TileLayout(count: tileCount, itemSize: layout.itemSize, hasCaptions: model.caption != nil)
        if tileLayout != self.tileLayout {
            self.tileLayout = tileLayout
            collectionView.reloadData()
        } else {
            for indexPath in collectionView.indexPathsForVisibleItems {
                guard let tile = collectionView.cellForItem(at: indexPath) as? LMKDetailPhotoTileCell else { continue }
                configureTile(tile, at: indexPath.item)
            }
        }
    }

    /// Reloads every tile (images are fetched again).
    func reload() {
        collectionView.reloadData()
    }

    /// Applies everything but the image: caption, selection, badge, style, and accessibility.
    private func configureTile(_ tile: LMKDetailPhotoTileCell, at index: Int) {
        guard let model else { return }
        tile.configure(
            caption: model.caption?(index),
            isSelected: model.isSelected?(index) ?? false,
            badgeSymbol: model.badgeSymbol?(index),
            style: style,
            theme: theme,
            tileSide: tileSide
        )
        tile.accessibilityLabel = String(format: strings.photoAccessibilityLabelFormat, index + 1, max(0, model.count)) + (model.caption?(index).map { ", \($0)" } ?? "")
        tile.accessibilityValue = (model.isSelected?(index) ?? false) ? strings.photoSelectedAccessibilityValue : nil
        tile.accessibilityTraits = model.onTap == nil ? .image : [.image, .button]
    }
}

extension LMKDetailPhotoStripRowView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        max(0, model?.count ?? 0)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.reuseIdentifier, for: indexPath)
        guard let tile = cell as? LMKDetailPhotoTileCell, let model else { return cell }
        let index = indexPath.item
        configureTile(tile, at: index)
        tile.load { await model.image(index) }
        return cell
    }

    /// A tile prepared ahead of display (prefetching) takes the latest model before it shows.
    func collectionView(_: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let tile = cell as? LMKDetailPhotoTileCell else { return }
        configureTile(tile, at: indexPath.item)
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

    /// The badge glyph sits on the photo, not on the screen's background, so it keeps one light
    /// look (over its shadow) in every appearance and theme; `onAccent` can be dark in Dark Mode.
    static let badgeGlyphTint = UIColor.white

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
            imageHeightConstraint = make.height.equalTo(LMKDetailPhotoStripRowView.defaultTileSide).constraint
        }
        captionLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        isAccessibilityElement = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        loadTask?.cancel()
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
            badgeView.tintColor = Self.badgeGlyphTint
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
