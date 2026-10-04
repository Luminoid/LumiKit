//
//  LMKChipFlowView.swift
//  LumiKit
//
//  A wrapping flow of chips (or any views): items run along a line from the
//  leading edge and wrap to the next line when the width runs out, and the
//  view's height follows its width, so it works in stacks and self-sizing cells.
//

import UIKit

/// Lays out chips (or any views) in lines that wrap at the view's width, from the leading edge.
///
/// ```swift
/// let tags = LMKChipFlowView()
/// tags.setArrangedSubviews(symptoms.map { LMKChipView(text: $0.name, style: .outlined) })
/// stack.addArrangedSubview(tags)   // its height follows the width it is given
/// ```
///
/// Items keep their fitting size; an item wider than the view is narrowed to the view's width.
/// Lines follow the layout direction (right to left starts each line at the right), and hidden
/// items take no space. The view reports its height for its current width through
/// `intrinsicContentSize`, `sizeThatFits(_:)`, and `systemLayoutSizeFitting(_:…)`; when a new
/// width or a changed item changes the height it invalidates its intrinsic size and that of the
/// cell it sits in, so a self-sizing table or collection view cell resizes. After changing an
/// item's content or `isHidden`, call `setNeedsLayout()` so the lines are measured again.
public final class LMKChipFlowView: UIView, LMKThemeApplying {
    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// Between neighbours on a line; `nil` = `spacing.small`.
        public var spacing: CGFloat?
        /// Between lines; `nil` = `spacing.small`.
        public var lineSpacing: CGFloat?

        public init(spacing: CGFloat? = nil, lineSpacing: CGFloat? = nil) {
            self.spacing = spacing.map { max(0, $0) }
            self.lineSpacing = lineSpacing.map { max(0, $0) }
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(spacing: other.spacing ?? spacing, lineSpacing: other.lineSpacing ?? lineSpacing)
        }
    }

    // MARK: - Properties

    /// The laid-out items, in reading order.
    public private(set) var arrangedSubviews: [UIView] = []

    /// Per-instance style; `nil` fields resolve from `theme.chipFlow`, then the built-in spacing.
    public var style: Style {
        didSet {
            guard style != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// The width to measure lines against before the view has one of its own (a cell sized
    /// before its first layout); `0` = one line until the view is laid out.
    public var preferredMaxLayoutWidth: CGFloat = 0 {
        didSet {
            guard preferredMaxLayoutWidth != oldValue else { return }
            invalidateIntrinsicContentSize()
        }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKChipFlowView) -> Void)?

    /// The spacing in effect.
    public private(set) var resolvedSpacing: CGFloat = 0
    /// The line spacing in effect.
    public private(set) var resolvedLineSpacing: CGFloat = 0

    /// The width and line height the last layout pass reported.
    private var reportedSize: CGSize?

    // MARK: - Initialization

    public init(arrangedSubviews: [UIView] = [], style: Style = Style()) {
        self.style = style
        super.init(frame: .zero)
        setArrangedSubviews(arrangedSubviews)
        lmk_startApplyingTheme()
    }

    override public convenience init(frame: CGRect) {
        self.init(arrangedSubviews: [], style: Style())
        self.frame = frame
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Items

    /// Appends `view` to the flow.
    public func addArrangedSubview(_ view: UIView) {
        insertArrangedSubview(view, at: arrangedSubviews.count)
    }

    /// Inserts `view` at `index` (clamped to the item count); a view already in the flow moves.
    public func insertArrangedSubview(_ view: UIView, at index: Int) {
        if let existing = arrangedSubviews.firstIndex(of: view) {
            arrangedSubviews.remove(at: existing)
        }
        arrangedSubviews.insert(view, at: min(max(index, 0), arrangedSubviews.count))
        // Positioned by frame: constraints the item carries from an earlier host must not pin it.
        view.translatesAutoresizingMaskIntoConstraints = true
        if view.superview !== self {
            addSubview(view)
        }
        itemsDidChange()
    }

    /// Removes `view` from the flow and from the view hierarchy.
    public func removeArrangedSubview(_ view: UIView) {
        guard let index = arrangedSubviews.firstIndex(of: view) else { return }
        arrangedSubviews.remove(at: index)
        view.removeFromSuperview()
        itemsDidChange()
    }

    /// Replaces every item.
    public func setArrangedSubviews(_ views: [UIView]) {
        for view in arrangedSubviews where !views.contains(view) {
            view.removeFromSuperview()
        }
        arrangedSubviews = []
        for view in views {
            arrangedSubviews.append(view)
            view.translatesAutoresizingMaskIntoConstraints = true
            if view.superview !== self {
                addSubview(view)
            }
        }
        itemsDidChange()
    }

    /// A subview removed by other means leaves the flow too.
    override public func willRemoveSubview(_ subview: UIView) {
        super.willRemoveSubview(subview)
        guard let index = arrangedSubviews.firstIndex(of: subview) else { return }
        arrangedSubviews.remove(at: index)
        itemsDidChange()
    }

    private func itemsDidChange() {
        reportedSize = nil
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        let resolved = theme.chipFlow.merging(style)
        resolvedSpacing = resolved.spacing ?? theme.spacing.small
        resolvedLineSpacing = resolved.lineSpacing ?? theme.spacing.small
        // Spacing and Dynamic Type both change the lines.
        itemsDidChange()
        didApplyStyle?(self)
    }

    // MARK: - Layout

    override public func layoutSubviews() {
        super.layoutSubviews()
        let layout = lines(fitting: bounds.width)
        let isRightToLeft = effectiveUserInterfaceLayoutDirection == .rightToLeft
        for (view, frame) in zip(layout.items, layout.frames) {
            view.frame = isRightToLeft ? CGRect(x: bounds.width - frame.maxX, y: frame.minY, width: frame.width, height: frame.height) : frame
        }
        // A new width or a changed item can change the line count: when the lines no longer
        // match the height the host gave the view, report the new height (once per width and
        // line height, so a host that sizes the view by frame is not asked again on every pass).
        let measured = CGSize(width: bounds.width, height: layout.height)
        guard bounds.width > 0, measured != reportedSize else { return }
        reportedSize = measured
        guard abs(layout.height - bounds.height) > 0.5 else { return }
        invalidateIntrinsicContentSize()
        // A self-sizing cell resizes when its content view's intrinsic size is invalidated.
        enclosingCellContentView?.invalidateIntrinsicContentSize()
    }

    override public var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: intrinsicHeight)
    }

    /// The lines' size within `size.width` (the widest line's width when `size.width` is `0`).
    override public func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = lines(fitting: size.width > 0 ? size.width : measuringWidth)
        return CGSize(width: size.width > 0 ? size.width : layout.width, height: layout.height)
    }

    override public func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {
        guard horizontalFittingPriority == .required, targetSize.width > 0, targetSize.width < UIView.layoutFittingExpandedSize.width else {
            return super.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)
        }
        return CGSize(width: targetSize.width, height: lines(fitting: targetSize.width).height)
    }

    /// The height the lines take at `width`.
    public func height(forWidth width: CGFloat) -> CGFloat {
        lines(fitting: width).height
    }

    private var intrinsicHeight: CGFloat {
        lines(fitting: measuringWidth).height
    }

    /// The view's own width once it has one, else `preferredMaxLayoutWidth`, else unbounded (one line).
    private var measuringWidth: CGFloat {
        if bounds.width > 0 { return bounds.width }
        return preferredMaxLayoutWidth > 0 ? preferredMaxLayoutWidth : .greatestFiniteMagnitude
    }

    private var enclosingCellContentView: UIView? {
        var view = superview
        while let current = view {
            if let cell = current as? UITableViewCell { return cell.contentView }
            if let cell = current as? UICollectionViewCell { return cell.contentView }
            view = current.superview
        }
        return nil
    }

    /// Left-to-right frames for the visible items at `width`, the height they take, and the
    /// widest line.
    private func lines(fitting width: CGFloat) -> (items: [UIView], frames: [CGRect], height: CGFloat, width: CGFloat) {
        let visible = arrangedSubviews.filter { !$0.isHidden }
        guard width > 0, !visible.isEmpty else { return (visible, [], 0, 0) }
        var frames: [CGRect] = []
        var lineStart = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var widest: CGFloat = 0

        func finishLine(upTo end: Int) {
            // Items on a line share its center, so a shorter chip sits level with a taller one.
            for index in lineStart ..< end {
                frames[index].origin.y = y + (lineHeight - frames[index].height) / 2
            }
        }

        for view in visible {
            let size = Self.fittingSize(of: view, maxWidth: width)
            if x > 0, x + size.width > width {
                finishLine(upTo: frames.count)
                widest = max(widest, x - resolvedSpacing)
                y += lineHeight + resolvedLineSpacing
                x = 0
                lineHeight = 0
                lineStart = frames.count
            }
            frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
            lineHeight = max(lineHeight, size.height)
            x += size.width + resolvedSpacing
        }
        finishLine(upTo: frames.count)
        widest = max(widest, x - resolvedSpacing)
        return (visible, frames, y + lineHeight, widest)
    }

    /// `view`'s natural size, narrowed to `maxWidth` (and measured again there) when wider.
    ///
    /// A view with an intrinsic size in both dimensions (a label, an image view, a button) is
    /// measured by it: UIKit answers a fitting request for a frame-positioned view without
    /// internal constraints with its current frame. Anything else is measured by Auto Layout.
    private static func fittingSize(of view: UIView, maxWidth: CGFloat) -> CGSize {
        let intrinsic = view.intrinsicContentSize
        if intrinsic.width != UIView.noIntrinsicMetric, intrinsic.height != UIView.noIntrinsicMetric {
            guard intrinsic.width > maxWidth else { return CGSize(width: ceil(intrinsic.width), height: ceil(intrinsic.height)) }
            let wrapped = view.sizeThatFits(CGSize(width: maxWidth, height: .greatestFiniteMagnitude))
            return CGSize(width: maxWidth, height: ceil(wrapped.height > 0 ? wrapped.height : intrinsic.height))
        }
        let compressed = UIView.layoutFittingCompressedSize.height
        let natural = view.systemLayoutSizeFitting(
            CGSize(width: maxWidth, height: compressed),
            withHorizontalFittingPriority: .fittingSizeLevel,
            verticalFittingPriority: .fittingSizeLevel
        )
        guard natural.width > maxWidth else { return CGSize(width: ceil(natural.width), height: ceil(natural.height)) }
        let narrowed = view.systemLayoutSizeFitting(
            CGSize(width: maxWidth, height: compressed),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        return CGSize(width: maxWidth, height: ceil(narrowed.height))
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKChipFlowView`.
    var chipFlow: LMKChipFlowView.Style {
        get { self[LMKChipFlowView.Style.self] }
        set { self[LMKChipFlowView.Style.self] = newValue }
    }
}
