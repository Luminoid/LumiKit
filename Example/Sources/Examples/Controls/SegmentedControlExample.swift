//
//  SegmentedControlExample.swift
//  LumiKitExample
//
//  Segmented Control: Draggable indicator, fit-content and scrolling layouts.
//

import LumiKitUI
import UIKit

// MARK: - Segmented Control

final class SegmentedControlDetailViewController: DetailViewController {
    private lazy var statusLabel: UILabel = {
        let label = UILabel.lmk_make(.body, text: "Selected: Item 1")
        label.textAlignment = .center
        return label
    }()

    override func setupStackContent() {
        addSectionHeader("Pill (Default)")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "Capsule corners, draggable indicator. Try dragging the pill!"))

        let segmented = LMKSegmentedControl(items: ["Item 1", "Item 2", "Item 3"])
        segmented.selectedSegmentIndex = 0
        segmented.onValueChange = { [weak self] index in
            self?.statusLabel.lmk_setText("Selected: Item \(index + 1)")
        }
        stackView.addArrangedSubview(segmented)
        stackView.addArrangedSubview(statusLabel)

        addDivider()
        addSectionHeader("Rounded Corner Style")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "style = .rounded uses the medium corner radius instead of a capsule."))

        let roundedLabel = UILabel.lmk_make(.caption, text: "Selected: List")
        roundedLabel.textAlignment = .center
        let rounded = LMKSegmentedControl(items: ["List", "Grid", "Map"], style: .rounded)
        rounded.selectedSegmentIndex = 0
        let roundedItems = ["List", "Grid", "Map"]
        rounded.onValueChange = { index in
            roundedLabel.lmk_setText("Selected: \(roundedItems[index])")
        }
        stackView.addArrangedSubview(rounded)
        stackView.addArrangedSubview(roundedLabel)

        addDivider()
        addSectionHeader("Many Segments")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "Five segments: width adapts to content."))

        let manySegmented = LMKSegmentedControl(items: ["Mon", "Tue", "Wed", "Thu", "Fri"])
        manySegmented.selectedSegmentIndex = 0
        let manyLabel = UILabel.lmk_make(.caption, text: "Selected: Mon")
        manyLabel.textAlignment = .center
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri"]
        manySegmented.onValueChange = { index in
            manyLabel.lmk_setText("Selected: \(days[index])")
        }
        stackView.addArrangedSubview(manySegmented)
        stackView.addArrangedSubview(manyLabel)

        addDivider()
        addSectionHeader("Fit Content + Unselected")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "style = .fitContent sizes each segment to its own text width. "
                + "selectedSegmentIndex = -1 hides the indicator and renders every label unselected "
                + "(matches UISegmentedControl.noSegment)."
        ))

        let ratingLabel = UILabel.lmk_make(.caption, text: "Rating: (none)")
        ratingLabel.textAlignment = .center
        let ratingSegment = LMKSegmentedControl(
            items: (1 ... 5).map { String(repeating: "\u{2605}", count: $0) },
            style: .fitContent
        )
        ratingSegment.selectedSegmentIndex = -1
        ratingSegment.onValueChange = { index in
            ratingLabel.lmk_setText("Rating: \(index + 1) star\(index == 0 ? "" : "s")")
        }

        // Wrap in a horizontal row with a trailing spacer so the control
        // sits at its intrinsic width instead of stretching with the parent stack.
        let ratingRow = UIStackView(
            lmk_axis: .horizontal,
            alignment: .center,
            arrangedSubviews: [ratingSegment, UIView()]
        )
        stackView.addArrangedSubview(ratingRow)
        stackView.addArrangedSubview(ratingLabel)

        let clearRatingButton = LMKButton(title: "Clear Rating", style: .ghost(.primary))
        clearRatingButton.onTap = { [weak ratingSegment, weak ratingLabel] in
            ratingSegment?.selectedSegmentIndex = -1
            ratingLabel?.lmk_setText("Rating: (none)")
        }
        let clearRow = UIStackView(
            lmk_axis: .horizontal,
            alignment: .center,
            arrangedSubviews: [clearRatingButton, UIView()]
        )
        stackView.addArrangedSubview(clearRow)

        addDivider()
        addSectionHeader("Scrollable")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "style = .scrollable: the control owns a horizontal scroll view for many segments."))

        let scrollableSegmented = LMKSegmentedControl(items: (1 ... 12).map { "Month \($0)" }, style: .scrollable)
        scrollableSegmented.selectedSegmentIndex = 0

        let scrollLabel = UILabel.lmk_make(.caption, text: "Selected: Month 1")
        scrollLabel.textAlignment = .center
        scrollableSegmented.onValueChange = { index in
            scrollLabel.lmk_setText("Selected: Month \(index + 1)")
        }
        stackView.addArrangedSubview(scrollableSegmented)
        stackView.addArrangedSubview(scrollLabel)

        addDivider()
        addSectionHeader("Scrollable + Tight Spacing")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "layout = .scrollable(padding:spacing:) tunes the per-segment padding and the gap. "
                + "Good for tag/filter bars where labels vary a lot: 24pt padding for breathing room, "
                + "4pt spacing for a tight chip-style gap. Segments never drop below the 44pt touch target."
        ))

        let filters = [
            "All", "New", "Favorites", "Recently Updated",
            "Needs Attention", "Overdue", "Under Care",
            "Outdoor", "Indoor",
        ]
        let fitScrollSegmented = LMKSegmentedControl(
            items: filters,
            style: LMKSegmentedControl.Style(layout: .scrollable(padding: LMKSpacing.xxl, spacing: LMKSpacing.xs))
        )
        fitScrollSegmented.selectedSegmentIndex = 0

        let fitScrollLabel = UILabel.lmk_make(.caption, text: "Selected: All")
        fitScrollLabel.textAlignment = .center
        fitScrollSegmented.onValueChange = { index in
            fitScrollLabel.lmk_setText("Selected: \(filters[index])")
        }
        stackView.addArrangedSubview(fitScrollSegmented)
        stackView.addArrangedSubview(fitScrollLabel)
    }
}
