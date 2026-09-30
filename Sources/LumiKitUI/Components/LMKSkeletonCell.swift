//
//  LMKSkeletonCell.swift
//  LumiKit
//
//  Table cell hosting an `LMKSkeletonView` on a card, shimmering while on screen.
//

import SnapKit
import UIKit

/// Skeleton loading row.
///
/// The cell starts its shimmer when it enters a window, so hosts need no
/// `willDisplay` bookkeeping; `UITableView.lmk_startSkeletons()` restarts the
/// visible rows with a stagger after a reload.
public final class LMKSkeletonCell: UITableViewCell, LMKThemeApplying {
    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// Card surface: background (`backgroundPrimary`), corners (`medium`), shadow (`level1`), insets (`xs` / `large`).
        public var surface: LMKSurfaceStyle
        /// `nil` = 80.
        public var height: CGFloat?
        /// The placeholder rows; `nil` = one full-width block.
        public var shapes: [LMKSkeletonView.Shape]?
        /// Skeleton style for the hosted view.
        public var skeleton: LMKSkeletonView.Style?

        public init(surface: LMKSurfaceStyle = LMKSurfaceStyle(), height: CGFloat? = nil, shapes: [LMKSkeletonView.Shape]? = nil, skeleton: LMKSkeletonView.Style? = nil) {
            self.surface = surface
            self.height = height
            self.shapes = shapes
            self.skeleton = skeleton
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                surface: surface.merging(other.surface),
                height: other.height ?? height,
                shapes: other.shapes ?? shapes,
                skeleton: other.skeleton.map { skeleton?.merging($0) ?? $0 } ?? skeleton
            )
        }
    }

    // MARK: - Properties

    public let containerView = UIView()
    public let skeletonView = LMKSkeletonView(shapes: [])

    /// Per-instance style; `nil` fields resolve from `theme.skeletonCell`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Delay index for the shimmer (rows of a list). Set before the cell appears.
    public var staggerIndex = 0

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKSkeletonCell) -> Void)?

    private var heightConstraint: Constraint?
    private var insetsConstraint: Constraint?
    private static let defaultHeight: CGFloat = 80

    // MARK: - Initialization

    override public init(style cellStyle: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        style = Style()
        super.init(style: cellStyle, reuseIdentifier: reuseIdentifier)
        setupUI()
        lmk_startApplyingTheme()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        isAccessibilityElement = true
        accessibilityTraits = .updatesFrequently
        accessibilityLabel = skeletonView.strings.loadingAccessibilityLabel

        contentView.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            insetsConstraint = make.edges.equalToSuperview().constraint
            heightConstraint = make.height.equalTo(Self.defaultHeight).constraint
        }
        containerView.addSubview(skeletonView)
        skeletonView.snp.makeConstraints { $0.edges.equalToSuperview() }
        skeletonView.isAccessibilityElement = false
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        containerView.lmk_layoutSurfaceIfNeeded()
    }

    override public func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            startShimmer(staggerIndex: staggerIndex)
        } else {
            stopShimmer()
        }
    }

    override public func prepareForReuse() {
        super.prepareForReuse()
        staggerIndex = 0
        stopShimmer()
    }

    override public func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        lmk_applyCustomHighlight(highlighted: highlighted, animated: animated)
    }

    override public func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        lmk_applyCustomHighlight(highlighted: selected, animated: animated)
    }

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        let resolved = theme.skeletonCell.merging(style)
        let defaults = LMKSurfaceStyle(
            background: .solid(LMKColor.backgroundPrimary),
            corners: .fixed(theme.cornerRadius.medium),
            shadow: .level(.level1),
            contentInsets: .lmk_symmetric(vertical: theme.spacing.xs, horizontal: theme.spacing.large)
        )
        let applied = containerView.lmk_apply(surface: resolved.surface, defaults: defaults, clipsContent: false)
        let insets = applied.contentInsets ?? .lmk_symmetric(vertical: theme.spacing.xs, horizontal: theme.spacing.large)
        insetsConstraint?.update(inset: UIEdgeInsets(top: insets.top, left: insets.leading, bottom: insets.bottom, right: insets.trailing))
        heightConstraint?.update(offset: resolved.height ?? Self.defaultHeight)
        skeletonView.shapes = resolved.shapes ?? [.rect(height: resolved.height ?? Self.defaultHeight)]
        skeletonView.style = resolved.skeleton ?? LMKSkeletonView.Style()
        didApplyStyle?(self)
    }

    // MARK: - Shimmer

    /// Starts the shimmer; the cell does this itself when it enters a window.
    public func startShimmer(staggerIndex: Int = 0) {
        self.staggerIndex = staggerIndex
        skeletonView.startShimmer(staggerIndex: staggerIndex)
    }

    public func stopShimmer() {
        skeletonView.stopShimmer()
    }

    /// Restarts the shimmer on every visible skeleton cell with a stagger.
    public static func startShimmers(in tableView: UITableView) {
        tableView.lmk_startSkeletons()
    }
}

public extension UITableView {
    /// Restarts the shimmer on every visible `LMKSkeletonCell`, staggered by row.
    func lmk_startSkeletons() {
        for (index, cell) in visibleCells.enumerated() {
            (cell as? LMKSkeletonCell)?.startShimmer(staggerIndex: index)
        }
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKSkeletonCell`.
    var skeletonCell: LMKSkeletonCell.Style {
        get { self[LMKSkeletonCell.Style.self] }
        set { self[LMKSkeletonCell.Style.self] = newValue }
    }
}
