//
//  LMKPhotoGridCell.swift
//  LumiKit
//
//  Square photo cell of the photo grid: async image, LIVE badge, and the
//  multi-selection checkmark.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - LMKPhotoGridCell

final class LMKPhotoGridCell: UICollectionViewCell {
    static let identifier = "LMKPhotoGridCell"

    // MARK: - Properties

    private let imageView = UIImageView()
    /// A plain container rather than a `UIImageView`: the symbol's intrinsic size (not perfectly
    /// square) can bleed into the size constraints on some passes and produce a 22×23 box.
    private let liveBadgeView = UIView()
    private let liveBadgeIcon = UIImageView()
    private let selectionOverlay = UIView()
    private let checkmarkView = UIImageView()
    private var liveBadgeSizeConstraint: Constraint?
    private var liveBadgeInsetConstraint: Constraint?
    private var checkmarkSizeConstraint: Constraint?
    private var checkmarkInsetConstraint: Constraint?
    private var liveIconSizeConstraint: Constraint?
    private var corners = LMKCornerStyle.square
    private var pressedAlpha: CGFloat = 0.7

    /// Monotonic token identifying the latest configure/reuse cycle. Every `configure` and
    /// `prepareForReuse` bumps it, and a load task compares its captured token before applying,
    /// so a stale result never lands on a recycled cell.
    private var loadGeneration: UInt64 = 0
    private var imageLoadTask: Task<Void, Never>?

    /// The currently displayed image, if any (nil while showing the placeholder).
    /// Test hook
    var installedImage: UIImage? { imageView.image }

    /// Whether the cell draws its selected state.
    private(set) var showsSelected = false

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
        isAccessibilityElement = true
        accessibilityTraits = .image

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        selectionOverlay.isHidden = true
        selectionOverlay.isUserInteractionEnabled = false
        contentView.addSubview(selectionOverlay)
        selectionOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Sizes and insets start at zero and take their values from the theme in `apply`.
        liveBadgeView.isHidden = true
        liveBadgeIcon.contentMode = .scaleAspectFit
        liveBadgeView.addSubview(liveBadgeIcon)
        liveBadgeIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            liveIconSizeConstraint = make.size.equalTo(0).constraint
        }
        contentView.addSubview(liveBadgeView)
        liveBadgeView.snp.makeConstraints { make in
            liveBadgeInsetConstraint = make.top.leading.equalToSuperview().inset(0).constraint
            liveBadgeSizeConstraint = make.size.equalTo(0).constraint
        }

        checkmarkView.isHidden = true
        checkmarkView.contentMode = .scaleAspectFit
        contentView.addSubview(checkmarkView)
        checkmarkView.snp.makeConstraints { make in
            checkmarkInsetConstraint = make.bottom.trailing.equalToSuperview().inset(0).constraint
            checkmarkSizeConstraint = make.size.equalTo(0).constraint
        }
    }

    // MARK: - Style

    /// Applies the grid's resolved style.
    func apply(style: LMKPhotoGridViewController.Style, theme: LMKTheme) {
        imageView.backgroundColor = style.placeholder
        pressedAlpha = style.pressedAlpha ?? theme.alpha.xl
        corners = style.cellCorners ?? .square
        imageView.lmk_applyCornerStyle(corners)
        selectionOverlay.lmk_applyCornerStyle(corners)

        let side = style.badgeSide
        liveBadgeView.lmk_apply(
            surface: style.liveBadge,
            defaults: LMKSurfaceStyle(background: .solid(LMKPhotoPalette.badgeBacking.withAlphaComponent(theme.alpha.xl)), corners: .circle)
        )
        liveBadgeSizeConstraint?.update(offset: side)
        liveBadgeInsetConstraint?.update(inset: theme.spacing.xs)
        liveIconSizeConstraint?.update(offset: theme.layout.symbolInline)
        liveBadgeIcon.image = UIImage(systemName: "livephoto", withConfiguration: UIImage.SymbolConfiguration(pointSize: theme.layout.symbolBadge, weight: .semibold))
        liveBadgeIcon.tintColor = style.badgeGlyphTint

        let selection = style.selectionColor
        selectionOverlay.backgroundColor = selection.withAlphaComponent(style.selectionOverlayAlpha ?? theme.alpha.small)
        checkmarkSizeConstraint?.update(offset: side)
        checkmarkInsetConstraint?.update(inset: theme.spacing.xs)
        let palette = UIImage.SymbolConfiguration(paletteColors: [style.badgeGlyphTint, selection])
        checkmarkView.image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: side, weight: .semibold).applying(palette))
        checkmarkView.preferredSymbolConfiguration = palette
    }

    // MARK: - Async Image Loading

    /// Loads the cell's image asynchronously. Until the provider returns, the cell shows the
    /// placeholder; the result is applied only when this cell has not been reconfigured or
    /// reused in the meantime.
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

    /// Configures the cell. Passing `nil` shows the placeholder and, like `prepareForReuse`,
    /// invalidates any in-flight `loadImage` result.
    func configure(with image: UIImage?, contentMode: UIView.ContentMode, isLive: Bool = false) {
        loadGeneration &+= 1
        imageLoadTask?.cancel()
        imageLoadTask = nil
        imageView.image = image
        imageView.contentMode = contentMode
        liveBadgeView.isHidden = !isLive
    }

    /// Dims the photo while a touch is down on it.
    func setPressed(_ pressed: Bool, animated: Bool) {
        let apply = { self.imageView.alpha = pressed ? self.pressedAlpha : 1 }
        guard animated, LMKAnimation.shouldAnimate else {
            apply()
            return
        }
        UIView.animate(withDuration: LMKAnimation.Duration.instant, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction], animations: apply)
    }

    /// Whether the photo is dimmed for a touch.
    /// Test hook
    var isPressed: Bool { imageView.alpha < 1 }

    /// Draws or clears the selected state (checkmark and overlay).
    func setShowsSelected(_ selected: Bool) {
        showsSelected = selected
        selectionOverlay.isHidden = !selected
        checkmarkView.isHidden = !selected
        if selected {
            accessibilityTraits.insert(.selected)
        } else {
            accessibilityTraits.remove(.selected)
        }
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        if corners.tracksBounds {
            imageView.lmk_layoutCornersIfNeeded()
            selectionOverlay.lmk_layoutCornersIfNeeded()
        }
        liveBadgeView.lmk_layoutSurfaceIfNeeded()
    }

    // MARK: - Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()
        loadGeneration &+= 1
        imageLoadTask?.cancel()
        imageLoadTask = nil
        imageView.image = nil
        imageView.alpha = 1
        liveBadgeView.isHidden = true
        setShowsSelected(false)
        accessibilityLabel = nil
    }

    deinit {
        imageLoadTask?.cancel()
    }
}
