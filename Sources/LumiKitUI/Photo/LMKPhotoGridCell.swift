//
//  LMKPhotoGridCell.swift
//  LumiKit
//
//  Square photo cell for the photo grid collection view.
//

import SnapKit
import UIKit

// MARK: - LMKPhotoGridCell

final class LMKPhotoGridCell: UICollectionViewCell {
    static let identifier = "LMKPhotoGridCell"

    // MARK: - Properties

    private lazy var imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = LMKColor.backgroundSecondary
        return iv
    }()

    private lazy var liveBadge: UIView = {
        // Plain UIView container rather than UIImageView — the latter's
        // intrinsic content size (from the SF Symbol glyph, which isn't
        // perfectly square) can bleed into the size constraints on some
        // layout passes and produce a ~22×23 box. A UIView has no intrinsic
        // size, so the explicit 22×22 constraints fully determine the frame.
        let container = UIView()
        container.backgroundColor = UIColor.black.withAlphaComponent(LMKAlpha.overlayStrong)
        container.layer.cornerRadius = 11
        container.clipsToBounds = true
        container.isHidden = true
        container.isAccessibilityElement = true
        container.accessibilityLabel = "Live Photo"

        let config = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        let icon = UIImageView(image: UIImage(systemName: "livephoto", withConfiguration: config))
        icon.tintColor = LMKColor.white
        icon.contentMode = .scaleAspectFit
        container.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(14)
        }
        return container
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.addSubview(liveBadge)
        liveBadge.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(4)
            make.width.height.equalTo(22)
        }
    }

    // MARK: - Configuration

    func configure(with image: UIImage?, contentMode: UIView.ContentMode, isLive: Bool = false) {
        imageView.image = image
        imageView.contentMode = contentMode
        liveBadge.isHidden = !isLive
    }

    // MARK: - Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        liveBadge.isHidden = true
    }
}
