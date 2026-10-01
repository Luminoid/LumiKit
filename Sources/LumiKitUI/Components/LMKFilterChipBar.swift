//
//  LMKFilterChipBar.swift
//  LumiKit
//
//  Horizontally scrolling row of `LMKChipView`s with single or multiple
//  selection and an optional "All" chip that clears the selection.
//

import SnapKit
import UIKit

/// Filter chip bar.
///
/// ```swift
/// let bar = LMKFilterChipBar()
/// bar.configure(items: [.init(title: "Indoor", icon: leaf), .init(title: "Outdoor")], allTitle: "All")
/// bar.onSelectionChange = { indices in filter(indices) }   // empty = "All" / nothing
/// bar.selectionMode = .multiple
/// ```
public final class LMKFilterChipBar: UIView, LMKThemeApplying {
    // MARK: - Types

    /// One chip.
    public struct Item {
        public var title: String
        public var icon: UIImage?

        public init(title: String, icon: UIImage? = nil) {
            self.title = title
            self.icon = icon
        }
    }

    /// How taps change the selection.
    public nonisolated enum SelectionMode: Sendable, Hashable {
        /// One chip at a time; `allowsEmpty` lets a tap on the selected chip clear it.
        case single(allowsEmpty: Bool)
        /// Taps toggle chips independently.
        case multiple
    }

    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// Style of every chip, layered over an outlined chip (so a partial style, a tint alone,
        /// keeps the outlined look). A filled style draws the chips that are not selected in the
        /// soft tint, so the selected one, in the full tint, stands out; set `selectedVariant` or
        /// `selected` on the style to decide both looks yourself.
        public var chip: LMKChipView.Style?
        /// Gap between chips; `nil` = `small`.
        public var spacing: CGFloat?
        /// Insets around the row; `nil` = `large` horizontally.
        public var contentInsets: NSDirectionalEdgeInsets?
        /// iOS 26 scroll edge effects at both ends; `nil` = yes.
        public var showsEdgeEffects: Bool?
        /// Scroll the selected chip into view after a tap; `nil` = yes.
        public var scrollsSelectionToVisible: Bool?

        public init(chip: LMKChipView.Style? = nil, spacing: CGFloat? = nil, contentInsets: NSDirectionalEdgeInsets? = nil, showsEdgeEffects: Bool? = nil, scrollsSelectionToVisible: Bool? = nil) {
            self.chip = chip
            self.spacing = spacing
            self.contentInsets = contentInsets
            self.showsEdgeEffects = showsEdgeEffects
            self.scrollsSelectionToVisible = scrollsSelectionToVisible
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                chip: other.chip.map { chip?.merging($0) ?? $0 } ?? chip,
                spacing: other.spacing ?? spacing,
                contentInsets: other.contentInsets ?? contentInsets,
                showsEdgeEffects: other.showsEdgeEffects ?? showsEdgeEffects,
                scrollsSelectionToVisible: other.scrollsSelectionToVisible ?? scrollsSelectionToVisible
            )
        }
    }

    // MARK: - Public

    /// Called after a user tap changes the selection, with the selected item indices
    /// (empty = "All" / no selection).
    public var onSelectionChange: ((Set<Int>) -> Void)?

    /// The selected item indices (empty = "All" / no selection).
    public private(set) var selection: Set<Int> = []

    /// Single (default, empty allowed) or multiple selection.
    public var selectionMode: SelectionMode = .single(allowsEmpty: true) {
        didSet {
            guard selectionMode != oldValue else { return }
            if case .single = selectionMode, selection.count > 1, let first = selection.min() {
                selection = [first]
            }
            updateChipStates()
        }
    }

    /// Enables or disables every chip.
    public var isEnabled = true {
        didSet {
            guard isEnabled != oldValue else { return }
            chips.forEach { $0.isEnabled = isEnabled }
        }
    }

    /// Per-instance style; `nil` fields resolve from `theme.filterChipBar`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKFilterChipBar) -> Void)?

    /// The chips in display order (the "All" chip first when configured).
    public private(set) var chips: [LMKChipView] = []
    public let scrollView = UIScrollView()
    public let chipStack = UIStackView()

    /// The configured items.
    public private(set) var items: [Item] = []
    private var hasAllChip = false
    private var resolved = Style()
    private var insetsConstraint: Constraint?
    private var stackHeightConstraint: Constraint?
    /// Set by `configure`: a right-to-left bar opens on its first chips once it has a width.
    private var needsLeadingEdgeOffset = false

    // MARK: - Init

    public init(style: Style = Style()) {
        self.style = style
        super.init(frame: .zero)
        setupUI()
        lmk_startApplyingTheme()
    }

    override public convenience init(frame: CGRect) {
        self.init(style: Style())
        self.frame = frame
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        scrollView.showsHorizontalScrollIndicator = false
        addSubview(scrollView)
        scrollView.addSubview(chipStack)
        chipStack.axis = .horizontal
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        chipStack.snp.makeConstraints { make in
            insetsConstraint = make.directionalEdges.equalToSuperview().inset(0).constraint
            // The frame height less the vertical insets, so the row never scrolls vertically.
            stackHeightConstraint = make.height.equalToSuperview().offset(0).constraint
        }
    }

    /// A scroll view starts at its physical left, where a right-to-left row keeps its last
    /// chips: the first layout with a width scrolls to the leading edge instead.
    override public func layoutSubviews() {
        super.layoutSubviews()
        guard needsLeadingEdgeOffset, bounds.width > 0 else { return }
        needsLeadingEdgeOffset = false
        guard effectiveUserInterfaceLayoutDirection == .rightToLeft else { return }
        scrollView.layoutIfNeeded()
        scrollView.contentOffset.x = max(0, scrollView.contentSize.width - scrollView.bounds.width)
    }

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        resolved = theme.filterChipBar.merging(style)
        chipStack.spacing = resolved.spacing ?? theme.spacing.small
        let insets = resolved.contentInsets ?? .lmk_symmetric(vertical: 0, horizontal: theme.spacing.large)
        insetsConstraint?.update(inset: insets)
        stackHeightConstraint?.update(offset: -(insets.top + insets.bottom))
        for chip in chips {
            chip.style = chipStyle
        }
        if #available(iOS 26, *) {
            let showsEdgeEffects = resolved.showsEdgeEffects ?? true
            scrollView.leftEdgeEffect.isHidden = !showsEdgeEffects
            scrollView.rightEdgeEffect.isHidden = !showsEdgeEffects
        }
        didApplyStyle?(self)
    }

    /// The style the chips take: the bar's, with a filled style softened while not selected.
    var chipStyle: LMKChipView.Style {
        Self.chipStyle(for: resolved.chip)
    }

    /// The bar's chip style over the outlined default, so a partial style keeps that look. In a
    /// row where every chip carries the full tint, the selected one is a shade apart and hard to
    /// pick out: a filled bar keeps the full tint for the selection.
    static func chipStyle(for style: LMKChipView.Style?) -> LMKChipView.Style {
        var merged = LMKChipView.Style.outlined.merging(style ?? LMKChipView.Style())
        if merged.variant == .filled, merged.selectedVariant == nil, merged.selected?.background == nil {
            merged.variant = .tinted
            merged.selectedVariant = .filled
        }
        return merged
    }

    // MARK: - Configuration

    /// Rebuilds the chips. `allTitle` prepends an "All" chip that clears the selection.
    public func configure(items: [Item], allTitle: String? = nil) {
        chipStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        chips.removeAll()
        self.items = items
        hasAllChip = allTitle != nil
        selection = []

        if let allTitle {
            let allChip = makeChip(title: allTitle, icon: nil)
            allChip.onTap = { [weak self] in self?.selectAll() }
            chipStack.addArrangedSubview(allChip)
            chips.append(allChip)
        }
        for (index, item) in items.enumerated() {
            let chip = makeChip(title: item.title, icon: item.icon)
            chip.onTap = { [weak self] in self?.tapItem(at: index) }
            chipStack.addArrangedSubview(chip)
            chips.append(chip)
        }
        updateChipStates()
        needsLeadingEdgeOffset = true
        setNeedsLayout()
    }

    /// Rebuilds the chips from titles and positionally matched icons.
    public func configure(allTitle: String? = nil, filterTitles: [String], filterIcons: [UIImage?]? = nil) {
        let items = filterTitles.enumerated().map { index, title in
            Item(title: title, icon: filterIcons.flatMap { index < $0.count ? $0[index] : nil })
        }
        configure(items: items, allTitle: allTitle)
    }

    private func makeChip(title: String, icon: UIImage?) -> LMKChipView {
        let chip = LMKChipView(text: title, icon: icon, style: chipStyle)
        chip.isEnabled = isEnabled
        // At least as wide as tall, so the capsule ends never overlap on one-letter titles.
        chip.snp.makeConstraints { $0.width.greaterThanOrEqualTo(chip.snp.height) }
        return chip
    }

    /// Sets the selection without firing `onSelectionChange`.
    public func setSelection(_ indices: Set<Int>, animated: Bool = false, scrollsToVisible: Bool = false) {
        var indices = indices.filter { $0 >= 0 && $0 < items.count }
        if case .single = selectionMode, indices.count > 1, let first = indices.min() {
            indices = [first]
        }
        selection = indices
        updateChipStates()
        if scrollsToVisible, let first = indices.min() {
            scrollChipToVisible(itemIndex: first, animated: animated)
        }
    }

    // MARK: - Selection

    private func selectAll() {
        guard !selection.isEmpty else { return }
        selection = []
        updateChipStates()
        onSelectionChange?(selection)
    }

    private func tapItem(at index: Int) {
        switch selectionMode {
        case let .single(allowsEmpty):
            if selection == [index] {
                guard allowsEmpty else { return }
                selection = []
            } else {
                selection = [index]
            }
        case .multiple:
            if selection.contains(index) {
                selection.remove(index)
            } else {
                selection.insert(index)
            }
        }
        updateChipStates()
        if resolved.scrollsSelectionToVisible ?? true {
            scrollChipToVisible(itemIndex: index, animated: true)
        }
        onSelectionChange?(selection)
    }

    private func updateChipStates() {
        for (chipIndex, chip) in chips.enumerated() {
            if hasAllChip, chipIndex == 0 {
                chip.isSelected = selection.isEmpty
            } else {
                let itemIndex = hasAllChip ? chipIndex - 1 : chipIndex
                chip.isSelected = selection.contains(itemIndex)
            }
        }
    }

    private func scrollChipToVisible(itemIndex: Int, animated: Bool) {
        let chipIndex = hasAllChip ? itemIndex + 1 : itemIndex
        guard chips.indices.contains(chipIndex), bounds.width > 0 else { return }
        layoutIfNeeded()
        let frame = chips[chipIndex].convert(chips[chipIndex].bounds, to: scrollView)
        scrollView.scrollRectToVisible(frame.insetBy(dx: -(resolved.spacing ?? traitCollection.lmkTheme.spacing.small), dy: 0), animated: animated && LMKAnimation.shouldAnimate)
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKFilterChipBar`.
    var filterChipBar: LMKFilterChipBar.Style {
        get { self[LMKFilterChipBar.Style.self] }
        set { self[LMKFilterChipBar.Style.self] = newValue }
    }
}
