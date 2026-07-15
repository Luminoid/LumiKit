//
//  LMKFilterChipBar.swift
//  LumiKit
//
//  Horizontal scrolling filter chip bar.
//

import SnapKit
import UIKit

/// Horizontal scrolling filter chip bar using `LMKChipView`.
///
/// Manages single-select state across chips by default. Optionally includes an
/// "All" chip that clears the filter selection. Selection callback fires with
/// the integer index of the filter or `nil` when "All" is selected.
///
/// Set `allowsMultipleSelection` for an additive mode where taps toggle chips
/// independently (no radio behavior) and selection is reported through
/// `multiSelectionChangedHandler` as a set of filter indices. Deselecting the
/// last chip is allowed and reports an empty set; consumers decide how to
/// render it (typically as "show all"). The "All" chip, when configured,
/// clears the set and stays highlighted while the selection is empty.
public final class LMKFilterChipBar: UIView {
    // MARK: - Public

    /// Called when selection changes. `nil` means "All" is selected (when `allTitle`
    /// was provided) or no chip is selected.
    public var selectionChangedHandler: ((Int?) -> Void)?

    /// Currently selected filter index, or `nil` for "All" / no selection.
    /// Tracks single-select mode only.
    public private(set) var selectedIndex: Int?

    /// When `true`, taps toggle chips independently (additive multi-select) and
    /// report through `multiSelectionChangedHandler` / `selectedIndices`;
    /// `selectionChangedHandler` and `selectedIndex` are not used. Defaults to
    /// `false` (single-select). Set before `configure(allTitle:filterTitles:style:)`.
    public var allowsMultipleSelection = false

    /// Called when selection changes in multi-select mode, with the full set of
    /// selected filter indices. Deselecting the last chip is allowed and fires
    /// with an empty set; consumers decide how to treat it (typically "show all").
    public var multiSelectionChangedHandler: ((Set<Int>) -> Void)?

    /// Currently selected filter indices. Tracks multi-select mode only; empty
    /// means no chip is selected.
    public private(set) var selectedIndices: Set<Int> = []

    // MARK: - Internal State

    private var chips: [LMKChipView] = []
    private var hasAllChip = false

    // MARK: - UI

    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        return scroll
    }()

    private lazy var chipStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = LMKSpacing.small
        return stack
    }()

    // MARK: - Init

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(scrollView)
        scrollView.addSubview(chipStack)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        chipStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(
                top: 0,
                left: LMKSpacing.large,
                bottom: 0,
                right: LMKSpacing.large
            ))
            make.height.equalToSuperview()
        }
    }

    // MARK: - Configuration

    /// Configure with filter titles and an optional "All" chip.
    /// - Parameters:
    ///   - allTitle: Title for the "All" chip. When non-nil, an "All" chip is prepended and
    ///     selecting it clears the filter (`selectionChangedHandler(nil)`).
    ///   - filterTitles: Titles for each filter chip, in display order.
    ///   - style: Chip style applied to every chip. Defaults to `.outlined`.
    public func configure(
        allTitle: String? = nil,
        filterTitles: [String],
        style: LMKChipStyle = .outlined
    ) {
        chipStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        chips.removeAll()
        hasAllChip = allTitle != nil

        if let allTitle {
            let allChip = LMKChipView(text: allTitle, style: style)
            allChip.tapHandler = { [weak self] in
                self?.selectAll()
            }
            chipStack.addArrangedSubview(allChip)
            chips.append(allChip)
        }

        for (index, title) in filterTitles.enumerated() {
            let chip = LMKChipView(text: title, style: style)
            chip.tapHandler = { [weak self] in
                self?.selectFilter(at: index)
            }
            chipStack.addArrangedSubview(chip)
            chips.append(chip)
        }

        updateChipStates()
        enforceMinimumChipWidth()
    }

    /// Ensure each chip is at least as wide as it is tall so the capsule
    /// corner radius (`bounds.height / 2`) renders in full on both ends.
    /// Without this, short labels (e.g. "A", "1") can clip the corners
    /// because the two rounded ends would otherwise overlap.
    private func enforceMinimumChipWidth() {
        for chip in chips {
            chip.snp.makeConstraints { make in
                make.width.greaterThanOrEqualTo(chip.snp.height)
            }
        }
    }

    /// Programmatically select a filter index, or `nil` for "All" / no selection.
    /// Does NOT fire `selectionChangedHandler`.
    public func setSelectedIndex(_ index: Int?) {
        selectedIndex = index
        updateChipStates()
    }

    /// Programmatically set the selected filter indices (multi-select mode).
    /// Does NOT fire `multiSelectionChangedHandler`.
    public func setSelectedIndices(_ indices: Set<Int>) {
        selectedIndices = indices
        updateChipStates()
    }

    // MARK: - Selection

    private func selectAll() {
        if allowsMultipleSelection {
            selectedIndices.removeAll()
            updateChipStates()
            multiSelectionChangedHandler?(selectedIndices)
        } else {
            selectedIndex = nil
            updateChipStates()
            selectionChangedHandler?(nil)
        }
    }

    private func selectFilter(at index: Int) {
        if allowsMultipleSelection {
            if selectedIndices.contains(index) {
                selectedIndices.remove(index)
            } else {
                selectedIndices.insert(index)
            }
            updateChipStates()
            multiSelectionChangedHandler?(selectedIndices)
        } else {
            selectedIndex = index
            updateChipStates()
            selectionChangedHandler?(index)
        }
    }

    private func updateChipStates() {
        for (chipIndex, chip) in chips.enumerated() {
            if hasAllChip, chipIndex == 0 {
                chip.isChipSelected = allowsMultipleSelection
                    ? selectedIndices.isEmpty
                    : selectedIndex == nil
            } else {
                let filterIndex = hasAllChip ? chipIndex - 1 : chipIndex
                chip.isChipSelected = allowsMultipleSelection
                    ? selectedIndices.contains(filterIndex)
                    : selectedIndex == filterIndex
            }
        }
    }
}
