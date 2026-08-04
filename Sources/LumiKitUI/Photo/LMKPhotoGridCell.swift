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
    private static let liveBadgeSize: CGFloat = 22

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
        // Circular at the fixed 22×22 size set below; set directly because the
        // cell's layoutSubviews can fire before the badge's own bounds resolve,
        // leaving a deferred bounds.height/2 stuck at 0 on some passes.
        container.layer.cornerRadius = Self.liveBadgeSize / 2
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
            make.top.leading.equalToSuperview().inset(LMKSpacing.xs)
            make.width.height.equalTo(Self.liveBadgeSize)
        }
    }

    // MARK: - Async Image Loading

    /// Monotonic token identifying the latest configure/reuse cycle. Every
    /// `configure` and `prepareForReuse` bumps it, and a load task compares its
    /// captured token before applying, so a stale result can never land on a
    /// recycled cell. `Task.cancel()` alone doesn't guarantee that — a body
    /// already past its cancellation checks still delivers.
    private var loadGeneration: UInt64 = 0
    private var imageLoadTask: Task<Void, Never>?

    /// The currently displayed image, if any (nil while showing the
    /// placeholder). Exposed for tests.
    var installedImage: UIImage? { imageView.image }

    /// Loads the cell's image asynchronously. Until the provider returns, the
    /// cell shows the neutral placeholder (`LMKColor.backgroundSecondary`, the
    /// image view's own background). The result is applied only when this cell
    /// hasn't been reconfigured or reused in the meantime.
    func loadImage(using provider: @escaping () async -> UIImage?) {
        loadGeneration &+= 1
        let generation = loadGeneration
        imageLoadTask?.cancel()
        imageLoadTask = Task { [weak self] in
            let image = await provider()
            guard let self, generation == loadGeneration else { return }
            imageView.image = image
        }
    }

    // MARK: - Configuration

    /// Configures the cell. Passing `nil` shows the neutral placeholder and,
    /// like `prepareForReuse`, invalidates any in-flight `loadImage` result.
    func configure(with image: UIImage?, contentMode: UIView.ContentMode, isLive: Bool = false) {
        loadGeneration &+= 1
        imageLoadTask?.cancel()
        imageLoadTask = nil
        imageView.image = image
        imageView.contentMode = contentMode
        liveBadge.isHidden = !isLive
    }

    // MARK: - Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()
        loadGeneration &+= 1
        imageLoadTask?.cancel()
        imageLoadTask = nil
        imageView.image = nil
        liveBadge.isHidden = true
    }

    deinit {
        imageLoadTask?.cancel()
    }
}
