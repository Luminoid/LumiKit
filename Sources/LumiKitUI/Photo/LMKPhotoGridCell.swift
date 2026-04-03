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
    }

    // MARK: - Configuration

    func configure(with image: UIImage?, contentMode: UIView.ContentMode) {
        imageView.image = image
        imageView.contentMode = contentMode
    }

    // MARK: - Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
}
