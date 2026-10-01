//
//  LMKSegmentedControlTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKSegmentedControlTests {
    /// Lays the control out inside a host of the given size, the way a real superview would
    /// (the control's own height constraint disables autoresizing translation, so a bare
    /// `layoutIfNeeded` on a superview-less control sizes it to its intrinsic width instead).
    private func layout(_ control: LMKSegmentedControl, width: CGFloat, height: CGFloat = 44) -> UIView {
        let host = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        host.addSubview(control)
        control.snp.makeConstraints { $0.edges.equalToSuperview() }
        host.layoutIfNeeded()
        return host
    }

    private func near(_ a: CGFloat, _ b: CGFloat) -> Bool {
        abs(a - b) < 0.01
    }

    // MARK: - Selection

    @Test
    func `Default selection is the first segment and out-of-range values mean none`() {
        let control = LMKSegmentedControl(items: ["A", "B", "C"])
        #expect(control.selectedSegmentIndex == 0)
        #expect(control.numberOfSegments == 3)
        control.selectedSegmentIndex = 2
        #expect(control.segmentLabels[2].accessibilityTraits.contains(.selected))
        #expect(!control.segmentLabels[0].accessibilityTraits.contains(.selected))
        control.selectedSegmentIndex = -1
        #expect(control.indicatorView.isHidden)
        control.selectedSegmentIndex = 99
        #expect(control.indicatorView.isHidden)
        control.selectedSegmentIndex = 1
        #expect(!control.indicatorView.isHidden)
    }

    @Test
    func `setSelectedSegmentIndex is silent, accepts -1, and ignores an index past the end`() {
        let control = LMKSegmentedControl(items: ["A", "B", "C"])
        var received: [Int] = []
        control.onValueChange = { received.append($0) }
        control.setSelectedSegmentIndex(2, animated: false)
        #expect(control.selectedSegmentIndex == 2)
        control.setSelectedSegmentIndex(5, animated: false)
        #expect(control.selectedSegmentIndex == 2)
        control.setSelectedSegmentIndex(-1, animated: false)
        #expect(control.selectedSegmentIndex == -1)
        #expect(control.indicatorView.isHidden)
        #expect(received.isEmpty)
    }

    @Test
    func `A user selection fires the handler and the control event`() {
        let control = LMKSegmentedControl(items: ["A", "B", "C"])
        var received: [Int] = []
        control.onValueChange = { received.append($0) }
        control.select(1)
        #expect(control.selectedSegmentIndex == 1)
        #expect(received == [1])
        control.select(1)
        #expect(received == [1], "re-selecting the current segment is a no-op")
        control.setEnabled(false, forSegmentAt: 2)
        control.select(2)
        #expect(received == [1], "a disabled segment cannot be selected")
        control.isEnabled = false
        control.select(0)
        #expect(received == [1], "a disabled control ignores selection")
    }

    @Test
    func `Selected label carries the selected trait and the selected text style`() {
        let control = LMKSegmentedControl(items: ["A", "B"])
        #expect(control.segmentLabels[0].accessibilityTraits.contains(.selected))
        #expect(!control.segmentLabels[1].accessibilityTraits.contains(.selected))
        #expect(control.segmentLabels[0].lmk_textStyle == .bodyMedium)
        #expect(control.segmentLabels[1].lmk_textStyle == .subbodyMedium)
        #expect(control.segmentLabels[0].textColor === LMKColor.primary)
        #expect(control.segmentLabels[1].textColor === LMKColor.textSecondary)
        control.selectedSegmentIndex = 1
        #expect(control.segmentLabels[1].lmk_textStyle == .bodyMedium)
        #expect(control.segmentLabels[0].lmk_textStyle == .subbodyMedium)
    }

    // MARK: - Items

    @Test
    func `setItems rebuilds the labels and clears an out-of-range selection`() {
        let control = LMKSegmentedControl(items: ["A", "B", "C"])
        control.selectedSegmentIndex = 2
        control.setItems(["X", "Y"])
        #expect(control.items == ["X", "Y"])
        #expect(control.segmentLabels.map(\.text) == ["X", "Y"])
        #expect(control.selectedSegmentIndex == -1)
        control.selectedSegmentIndex = 1
        control.setItems(["P", "Q", "R"])
        #expect(control.selectedSegmentIndex == 1, "an in-range selection survives")
        #expect(control.title(forSegmentAt: 2) == "R")
        #expect(control.title(forSegmentAt: 3) == nil)
    }

    @Test
    func `Inserting and removing segments moves the selection with its segment`() {
        let control = LMKSegmentedControl(items: ["A", "B", "C"])
        control.selectedSegmentIndex = 1
        control.setEnabled(false, forSegmentAt: 2)
        control.insertSegment(withTitle: "Z", at: 0)
        #expect(control.items == ["Z", "A", "B", "C"])
        #expect(control.selectedSegmentIndex == 2)
        #expect(!control.isEnabledForSegment(at: 3))
        #expect(control.isEnabledForSegment(at: 2))

        control.removeSegment(at: 0)
        #expect(control.items == ["A", "B", "C"])
        #expect(control.selectedSegmentIndex == 1)
        #expect(!control.isEnabledForSegment(at: 2))

        control.removeSegment(at: 1)
        #expect(control.items == ["A", "C"])
        #expect(control.selectedSegmentIndex == -1, "removing the selected segment clears the selection")
        #expect(!control.isEnabledForSegment(at: 1))
        control.removeSegment(at: 9)
        #expect(control.items == ["A", "C"])

        let empty = LMKSegmentedControl(items: [])
        #expect(empty.indicatorView.isHidden)
        empty.insertSegment(withTitle: "First", at: 0)
        #expect(empty.selectedSegmentIndex == 0, "the first segment takes the default selection, as setItems would")
        #expect(!empty.indicatorView.isHidden)
        empty.setItems([])
        #expect(empty.indicatorView.isHidden, "no items, no indicator")
    }

    // MARK: - Enabled state

    @Test
    func `Disabled segments dim and expose the trait; a disabled control dims whole`() {
        let control = LMKSegmentedControl(items: ["A", "B"])
        control.setEnabled(false, forSegmentAt: 1)
        #expect(abs(control.segmentLabels[1].alpha - LMKTheme.current.alpha.disabled) < 0.001)
        #expect(control.segmentLabels[1].accessibilityTraits.contains(.notEnabled))
        #expect(control.segmentLabels[0].alpha == 1)
        control.setEnabled(true, forSegmentAt: 1)
        #expect(control.segmentLabels[1].alpha == 1)

        control.isEnabled = false
        #expect(abs(control.alpha - LMKTheme.current.alpha.disabled) < 0.001)
        #expect(control.segmentLabels[0].accessibilityTraits.contains(.notEnabled))
        #expect(control.panGesture?.isEnabled == false)
        control.frame = CGRect(x: 0, y: 0, width: 200, height: 36)
        #expect(!control.point(inside: CGPoint(x: 100, y: -3), with: nil), "no hit inflation while disabled")
        #expect(control.point(inside: CGPoint(x: 100, y: 3), with: nil), "a disabled control absorbs a touch inside its bounds")
        control.isEnabled = true
        #expect(control.alpha == 1)
        #expect(control.panGesture?.isEnabled == true)
        control.isHidden = true
        #expect(!control.point(inside: CGPoint(x: 100, y: 3), with: nil))
    }

    // MARK: - Gestures

    @Test
    func `The indicator pan begins only for a horizontal drag that starts on the pill`() {
        let control = LMKSegmentedControl(items: ["A", "B", "C"])
        _ = layout(control, width: 300)
        let onPill = CGPoint(x: control.indicatorView.frame.midX, y: control.indicatorView.frame.midY)
        let offPill = CGPoint(x: control.containerView.bounds.maxX - 10, y: control.indicatorView.frame.midY)
        #expect(control.indicatorPanShouldBegin(velocity: CGPoint(x: 200, y: 20), touchDown: onPill))
        #expect(!control.indicatorPanShouldBegin(velocity: CGPoint(x: 20, y: 200), touchDown: onPill), "a vertical drag scrolls the ancestor")
        #expect(!control.indicatorPanShouldBegin(velocity: CGPoint(x: 200, y: 20), touchDown: offPill), "a drag off the pill belongs to a pager or the back swipe")
        let nearPill = CGPoint(x: control.indicatorView.frame.maxX + LMKTheme.current.spacing.small - 1, y: onPill.y)
        #expect(control.indicatorPanShouldBegin(velocity: CGPoint(x: 200, y: 0), touchDown: nearPill), "a little slack around the pill")
        control.selectedSegmentIndex = -1
        #expect(!control.indicatorPanShouldBegin(velocity: CGPoint(x: 200, y: 20), touchDown: onPill), "nothing to drag without a selection")
        control.selectedSegmentIndex = 0
        control.isEnabled = false
        #expect(!control.indicatorPanShouldBegin(velocity: CGPoint(x: 200, y: 20), touchDown: onPill))
    }

    @Test
    func `A cancelled drag restores the pre-drag segment and reports nothing; an ended one commits`() {
        let control = LMKSegmentedControl(items: ["A", "B", "C"])
        _ = layout(control, width: 300)
        var received: [Int] = []
        control.onValueChange = { received.append($0) }
        control.isDragging = true
        control.preDragIndex = 0
        control.selectedSegmentIndex = 2
        control.endIndicatorDrag(committing: false)
        #expect(control.selectedSegmentIndex == 0)
        #expect(received.isEmpty)
        #expect(!control.isDragging)

        control.isDragging = true
        control.preDragIndex = 0
        control.selectedSegmentIndex = 1
        control.endIndicatorDrag(committing: true)
        #expect(received == [1])
        control.endIndicatorDrag(committing: true)
        #expect(received == [1], "ending twice is a no-op")

        control.isDragging = true
        control.preDragIndex = 1
        control.selectedSegmentIndex = 2
        control.isEnabled = false
        #expect(!control.isDragging, "disabling mid-drag abandons the drag")
        #expect(control.selectedSegmentIndex == 1)
        #expect(received == [1])
    }

    @Test
    func `Taps resolve by x alone, so the hit band and the inset ring select the segment under them`() {
        let control = LMKSegmentedControl(items: ["A", "B", "C"])
        _ = layout(control, width: 300)
        let second = control.segmentLabels[1].frame
        #expect(control.segmentIndex(atX: second.midX, clampingToEdges: true) == 1)
        #expect(control.segmentIndex(atX: -20, clampingToEdges: true) == 0, "past the leading edge clamps to the first segment")
        #expect(control.segmentIndex(atX: control.segmentStack.bounds.width + 20, clampingToEdges: true) == 2)
        #expect(control.segmentIndex(atX: -20, clampingToEdges: false) == nil)

        let scrollable = LMKSegmentedControl(items: ["A", "B", "C"], style: .scrollable)
        _ = layout(scrollable, width: 400)
        let gap = (scrollable.segmentLabels[0].frame.maxX + scrollable.segmentLabels[1].frame.minX) / 2
        #expect(scrollable.segmentIndex(atX: gap, clampingToEdges: true) == nil, "a gap between scrollable segments selects nothing")
    }

    // MARK: - Layout

    @Test
    func `Height constraint yields to a host override and the hit area inflates`() {
        let control = LMKSegmentedControl(items: ["A", "B"])
        let heightConstraints = control.constraints.filter {
            $0.firstAttribute == .height && $0.firstItem === control && $0.secondItem == nil
        }
        #expect(heightConstraints.count == 1)
        #expect(heightConstraints[0].constant == 44)
        #expect(heightConstraints[0].priority.rawValue < UILayoutPriority.required.rawValue)

        control.frame = CGRect(x: 0, y: 0, width: 200, height: 36)
        #expect(control.point(inside: CGPoint(x: 100, y: -3), with: nil))
        #expect(!control.point(inside: CGPoint(x: 100, y: -5), with: nil))
        control.frame = CGRect(x: 0, y: 0, width: 200, height: 44)
        #expect(!control.point(inside: CGPoint(x: 100, y: -1), with: nil))
    }

    @Test
    func `Equal-width layout installs no per-segment widths and sizes to the widest title`() {
        let control = LMKSegmentedControl(items: ["A", "Much longer", "B"])
        #expect(control.resolvedLayout == .equalWidth)
        #expect(control.segmentWidthConstraints.isEmpty)
        #expect(control.segmentStack.distribution == .fillEqually)
        #expect(!control.scrollView.isScrollEnabled)
        let widest = control.segmentReferenceWidths.max() ?? 0
        let expected = (widest + LMKSpacing.medium * 2) * 3 + LMKSegmentedControl.defaultContentInset * 2
        #expect(control.intrinsicContentSize.width == expected)
        #expect(control.intrinsicContentSize.height == 44)
    }

    @Test
    func `Fit-content layout pins each segment to its title and hugs horizontally`() {
        let control = LMKSegmentedControl(items: (1 ... 5).map { String(repeating: "\u{2605}", count: $0) }, style: .fitContent)
        #expect(control.contentHuggingPriority(for: .horizontal) == .required)
        #expect(control.segmentWidthConstraints.count == 5)
        let sum = control.segmentReferenceWidths.reduce(0, +)
        let expected = sum + LMKSpacing.medium * 2 * 5 + LMKSegmentedControl.defaultContentInset * 2
        #expect(control.intrinsicContentSize.width == expected)

        control.selectedSegmentIndex = -1
        let unselected = control.intrinsicContentSize.width
        control.selectedSegmentIndex = 4
        #expect(control.intrinsicContentSize.width == unselected, "selection never shifts the widths")

        control.style.itemPadding = LMKSpacing.medium + 10
        #expect(control.intrinsicContentSize.width == expected + 100)

        _ = layout(control, width: control.intrinsicContentSize.width)
        #expect(!control.hasAmbiguousLayout)
    }

    @Test
    func `Scrollable layout scrolls, floors narrow segments, and adds the gap`() {
        let control = LMKSegmentedControl(items: ["A", "BB", "Long Label Here"], style: .scrollable)
        #expect(control.scrollView.isScrollEnabled)
        #expect(control.panGesture?.isEnabled == false, "the indicator drag yields to scrolling")
        #expect(control.segmentStack.spacing == LMKSpacing.medium)
        #expect(control.segmentStack.distribution == .fill)
        #expect(control.contentCompressionResistancePriority(for: .horizontal) == .defaultLow)
        let floored = control.segmentReferenceWidths.reduce(0) { $0 + max($1, LMKLayout.minimumTouchTarget) }
        let expected = floored + LMKSpacing.large * 2 * 3 + LMKSpacing.medium * 2 + LMKSegmentedControl.defaultContentInset * 2
        #expect(control.intrinsicContentSize.width == expected)

        control.style.layout = .scrollable(padding: 10, spacing: 4)
        #expect(control.segmentStack.spacing == 4)
        #expect(control.intrinsicContentSize.width == floored + 10 * 2 * 3 + 4 * 2 + LMKSegmentedControl.defaultContentInset * 2)

        _ = layout(control, width: 200)
        #expect(!control.hasAmbiguousLayout)
        #expect(control.bounds.width == 200, "the host width wins over the content width")
        #expect(control.scrollView.contentSize.width >= control.intrinsicContentSize.width - 1)
        #expect(control.containerView.bounds.width > 200, "content is wider than the viewport, so it scrolls")
    }

    @Test
    func `Switching layouts leaves no stale constraints`() {
        let control = LMKSegmentedControl(items: ["A", "BB"])
        control.style.layout = .scrollable()
        control.style.layout = .fitContent
        control.style.layout = .equalWidth
        #expect(control.segmentWidthConstraints.isEmpty)
        #expect(!control.scrollView.isScrollEnabled)
        control.style.layout = .fitContent
        #expect(control.segmentWidthConstraints.count == 2)
        _ = layout(control, width: 300)
        #expect(!control.hasAmbiguousLayout)
    }

    // MARK: - Style

    @Test
    func `Default surfaces and the rounded corner style`() {
        let control = LMKSegmentedControl(items: ["A", "B"])
        #expect(control.containerView.backgroundColor === LMKColor.backgroundTertiary)
        _ = layout(control, width: 200)
        #expect(near(control.containerView.layer.cornerRadius, 22))
        #expect(near(control.indicatorView.layer.cornerRadius, 16))

        control.style = .rounded
        control.layoutIfNeeded()
        #expect(near(control.containerView.layer.cornerRadius, LMKCornerRadius.medium))
        #expect(near(control.indicatorView.layer.cornerRadius, LMKCornerRadius.medium - 6))
    }

    @Test
    func `The indicator inset applies horizontally from the start and follows the style`() {
        let control = LMKSegmentedControl(items: ["A", "B"], style: LMKSegmentedControl.Style(indicatorInset: 6))
        _ = layout(control, width: 200)
        let label = control.containerView.convert(control.segmentLabels[0].frame, from: control.segmentStack)
        #expect(near(control.indicatorView.frame.minX - label.minX, 6))
        #expect(near(label.maxX - control.indicatorView.frame.maxX, 6))
        #expect(near(control.indicatorView.frame.minY - label.minY, 6))
        control.style.indicatorInset = 1
        control.setNeedsLayout()
        control.layoutIfNeeded()
        #expect(near(control.indicatorView.frame.minX - label.minX, 1))
        #expect(near(control.indicatorView.frame.minY - label.minY, 1))
    }

    @Test
    func `Style overrides colors, insets, and the height floor`() {
        let style = LMKSegmentedControl.Style(
            surface: LMKSurfaceStyle(background: .solid(.red)),
            indicator: LMKSurfaceStyle(background: .solid(.blue)),
            contentInset: 6,
            textColor: .green,
            selectedTextColor: .purple,
            height: 50
        )
        let control = LMKSegmentedControl(items: ["A", "B"], style: style)
        #expect(control.containerView.backgroundColor == UIColor.red)
        #expect(control.indicatorView.backgroundColor == UIColor.blue)
        #expect(control.segmentLabels[0].textColor == UIColor.purple)
        #expect(control.segmentLabels[1].textColor == UIColor.green)
        #expect(control.intrinsicContentSize.height == 50)
        #expect(control.intrinsicContentSize.width == (control.segmentReferenceWidths.max() ?? 0) * 2 + LMKSpacing.medium * 4 + 12)

        control.style.selected = LMKControlStateStyle(background: .solid(.orange), foregroundColor: .brown)
        #expect(control.indicatorView.backgroundColor == UIColor.orange)
        #expect(control.segmentLabels[0].textColor == UIColor.brown)
    }

    @Test
    func `Text styles and the layout vocabulary`() {
        let control = LMKSegmentedControl(items: ["A", "B"], style: LMKSegmentedControl.Style(textStyle: .small, selectedTextStyle: .h4))
        #expect(control.segmentLabels[0].lmk_textStyle == .h4)
        #expect(control.segmentLabels[1].lmk_textStyle == .small)
        #expect(LMKSegmentedControl.Layout.scrollable().isScrollable)
        #expect(!LMKSegmentedControl.Layout.fitContent.isScrollable)
        #expect(!LMKSegmentedControl.Layout.equalWidth.isScrollable)
    }

    @Test
    func `theme.segmentedControl supplies app-wide defaults`() {
        var theme = LMKTheme()
        theme.segmentedControl = LMKSegmentedControl.Style(corners: .rounded, textColor: .magenta)
        let control = LMKSegmentedControl(items: ["A", "B"])
        let window = LMKThemeTesting.host(control, theme: theme)
        defer { window.isHidden = true }
        #expect(control.resolved.corners == .rounded)
        #expect(control.segmentLabels[1].textColor == UIColor.magenta)
    }

    @Test
    func `Dynamic Type grows the height floor and the segment widths`() {
        let control = LMKSegmentedControl(items: ["Alpha", "Beta"], style: .fitContent)
        let window = LMKThemeTesting.host(control)
        defer { window.isHidden = true }
        let baseWidth = control.intrinsicContentSize.width
        window.traitOverrides.preferredContentSizeCategory = .accessibilityExtraExtraExtraLarge
        control.updateTraitsIfNeeded()
        #expect(control.intrinsicContentSize.height > 44)
        #expect(control.intrinsicContentSize.width > baseWidth)
        #expect(control.segmentLabels[0].font.pointSize > 17)
    }
}
